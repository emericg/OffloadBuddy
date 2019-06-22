/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2018 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "MediaLibrary.h"
#include "SettingsManager.h"
#include "MediaDirectory.h"
#include "FileScanner.h"
#include "JobManager.h"

#include <QUuid>
#include <QThread>
#include <QJSValue>
#include <QDebug>

/* ************************************************************************** */

MediaLibrary::MediaLibrary()
{
    //
}

MediaLibrary::~MediaLibrary()
{
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::scanMediaDirectory(MediaDirectory *md)
{
    if (md && md->isAvailable())
    {
        QThread *thread = new QThread();
        FileScanner *fs = new FileScanner();

        if (thread && fs)
        {
            fs->chooseFilesystem(md->getPath());
            fs->moveToThread(thread);

            connect(thread, SIGNAL(started()), fs, SLOT(scanFilesystem()));
            connect(fs, SIGNAL(fileFound(ofb_file *, ofb_shot *)), m_shotModel, SLOT(addFile(ofb_file *, ofb_shot *)));
            connect(fs, SIGNAL(scanningStarted(QString)), this, SLOT(workerScanningStarted(QString)));
            connect(fs, SIGNAL(scanningFinished(QString)), this, SLOT(workerScanningFinished(QString)));

            // automatically delete thread and everything when the work is done
            connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
            connect(fs, SIGNAL (scanningFinished(QString)), fs, SLOT (deleteLater()));
            connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

            thread->start();
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::searchMediaDirectory(const QString &path)
{
    if (m_shotModel)
    {
        if (m_libraryState != DEVICE_STATE_SCANNING)
        {
            SettingsManager *s = SettingsManager::getInstance();
            if (s)
            {
                const QList <QObject *> *mediaDirectories = s->getDirectoriesList();

                for (auto d: *mediaDirectories)
                {
                    MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
                    if (dd && dd->getPath() == path)
                    {
                        m_shotModel->sanetize();
                        scanMediaDirectory(dd);
                    }
                }
            }
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::searchMediaDirectories()
{
    SettingsManager *s = SettingsManager::getInstance();
    if (s)
    {
        // TODO connect to directoriesUpdated()

        const QList <QObject *> * mediaDirectories = s->getDirectoriesList();

        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            scanMediaDirectory(dd);
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::workerScanningStarted(const QString &s)
{
    qDebug() << "> MediaLibrary::workerScanningStarted(" << s << ")";
    m_libraryState = DEVICE_STATE_SCANNING;
    emit stateUpdated();
}

void MediaLibrary::workerScanningFinished(const QString &s)
{
    qDebug() << "> MediaLibrary::workerScanningFinished(" << s << ")";
    m_libraryState = DEVICE_STATE_IDLE;
    emit stateUpdated();
}

/* ************************************************************************** */
/* ************************************************************************** */

QStringList MediaLibrary::getSelectedUuids(const QVariant &indexes)
{
    qDebug() << "MediaLibrary::getSelectedUuids(" << indexes << ")";

    QStringList selectedUuids;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const unsigned length = jsArray.property("length").toUInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (unsigned i = 0; i < length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(i).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedUuids += shot->getUuid();
        //qDebug() << "MediaLibrary::getSelectedUuids(" <<  shot->getUuid();
    }

    return selectedUuids;
}

/* ************************************************************************** */

QStringList MediaLibrary::getSelectedPaths(const QVariant &indexes)
{
    //qDebug() << "MediaLibrary::getSelectedPaths(" << indexes << ")";

    QStringList selectedPaths;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const unsigned jsArray_length = jsArray.property("length").toUInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (unsigned i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(i).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedPaths += shot->getFilesQStringList();
        //qDebug() << "MediaLibrary::listSelected(" <<  shot->getFilesQStringList();
    }

    return selectedPaths;
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::reencodeSelected(const QString &shot_uuid, const QString &codec,
                                    float quality, float speed, float fps,
                                    int start, int duration)
{
    qDebug() << "MediaLibrary::reencodeSelected(" << shot_uuid << ")";

    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    JobEncodeSettings sett;
    sett.codec = codec;
    sett.quality = quality;
    sett.speed = speed;
    if (fps > 0) sett.fps = fps;

    if (start > 0) sett.startMs = start;
    if (duration > 0) sett.durationMs = duration;

    if (jm && shot)
        jm->addJob(JOB_REENCODE, nullptr, this, shot, nullptr, &sett);
}

void MediaLibrary::deleteSelected(const QString &shot_uuid)
{
    qDebug() << "MediaLibrary::deleteSelected(" << shot_uuid << ")";

    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    if (jm && shot)
        jm->addJob(JOB_DELETE, nullptr, this, shot);
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::deleteSelection(const QVariant &indexes)
{
    qDebug() << "MediaLibrary::deleteSelection(" << indexes << ")";

    QStringList selectedUuids = getSelectedUuids(indexes);
    QList<Shot *> list;

    for (auto u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty())
        jm->addJobs(JOB_DELETE, nullptr, this, list);
}

/* ************************************************************************** */
