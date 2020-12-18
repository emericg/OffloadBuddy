/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
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
#include "MediaDirectory.h"
#include "FileScanner.h"
#include "JobManager.h"
#include "SettingsManager.h"

#include <QMap>
#include <QJSValue>
#include <QVariant>

#include <QUuid>
#include <QThread>
#include <QDebug>

/* ************************************************************************** */

MediaLibrary::MediaLibrary()
{
    SettingsManager *sm = SettingsManager::getInstance();
    if (sm)
    {
        connect(sm, SIGNAL(directoryAdded(QString)), this, SLOT(searchMediaDirectory(QString)));
        connect(sm, SIGNAL(directoryRemoved(QString)), this, SLOT(cleanMediaDirectory(QString)));
    }
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
        if (m_shotModel)
        {
            //qDebug() << "scanMediaDirectory() with MediaDirectory path:" << md->getPath();

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
                connect(fs, SIGNAL(scanningFinished(QString)), fs, SLOT (deleteLater()));
                connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

                thread->start();
            }
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::searchMediaDirectory(const QString &path)
{
    //qDebug() << "searchMediaDirectory() with path:" << path;

    SettingsManager *sm = SettingsManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                scanMediaDirectory(dd);
            }
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::searchMediaDirectories()
{
    //qDebug() << "searchMediaDirectories()";

    SettingsManager *sm = SettingsManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            scanMediaDirectory(dd);
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::cleanMediaDirectory(const QString &path)
{
    //qDebug() << "cleanMediaDirectory() with path:" << path;
    Q_UNUSED(path)

    if (m_shotModel)
    {
        if (m_libraryState != DEVICE_STATE_SCANNING)
        {
            m_shotModel->sanetize();

            // TODO...
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::workerScanningStarted(const QString &path)
{
    //qDebug() << "> MediaLibrary::workerScanningStarted(" << path << ")";

    SettingsManager *sm = SettingsManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                dd->setScanning(true);
            }
        }
    }

    if (m_libraryScan < 0) m_libraryScan = 0;
    m_libraryScan++;

    m_libraryState = DEVICE_STATE_SCANNING;
    emit stateUpdated();
}

void MediaLibrary::workerScanningFinished(const QString &path)
{
    //qDebug() << "> MediaLibrary::workerScanningFinished(" << path << ")";

    SettingsManager *sm = SettingsManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                dd->setScanning(false);
            }
        }
    }

    m_libraryScan--;
    if (m_libraryScan <= 0)
    {
        m_libraryState = DEVICE_STATE_IDLE;
        emit stateUpdated();
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

QStringList MediaLibrary::getSelectedUuids(const QVariant &indexes)
{
    //qDebug() << "MediaLibrary::getSelectedUuids(" << indexes << ")";

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    QStringList selectedUuids;
    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
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

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    QStringList selectedPaths;
    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedPaths += shot->getFilesStringList();
        //qDebug() << "MediaLibrary::listSelected(" <<  shot->getFilesQStringList();
    }

    return selectedPaths;
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::reencodeSelected(const QString &shot_uuid, const QVariant &values)
{
    qDebug() << "MediaLibrary::reencodeSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(values).toVariant();
    if (variant.type() != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Job settings
    JobEncodeSettings sett;

    if (variantMap.contains("codec"))
        sett.codec = variantMap.value("codec").toString();

    if (variantMap.contains("quality"))
        sett.encoding_quality = variantMap.value("quality").toInt();
    if (variantMap.contains("speed"))
        sett.encoding_speed = variantMap.value("speed").toInt();

    if (variantMap.contains("resolution"))
        sett.resolution = variantMap.value("resolution").toInt();

    if (variantMap.contains("scale"))
        sett.scale = variantMap.value("scale").toString();

    if (variantMap.contains("transform"))
        sett.transform = variantMap.value("transform").toInt();

    if (variantMap.contains("crop"))
        sett.crop = variantMap.value("crop").toString();

    if (variantMap.contains("fps"))
        sett.fps = variantMap.value("fps").toFloat();

    if (variantMap.contains("gif_effect"))
        sett.gif_effect = variantMap.value("gif_effect").toString();

    if (variantMap.contains("timelapse_fps"))
        sett.timelapse_fps = variantMap.value("timelapse_fps").toInt();

    if (variantMap.contains("defisheye"))
        sett.defisheye = variantMap.value("defisheye").toString();
    if (variantMap.contains("deshake"))
        sett.deshake = variantMap.value("deshake").toBool();

    if (variantMap.contains("screenshot"))
        sett.screenshot = variantMap.value("screenshot").toBool();

    if (variantMap.contains("clipStartMs"))
        sett.startMs = variantMap.value("clipStartMs").toInt();
    if (variantMap.contains("clipDurationMs"))
        sett.durationMs = variantMap.value("clipDurationMs").toInt();

    // MediaDirectory
    MediaDirectory *md = nullptr;
    if (variantMap.contains("path"))
    {
        QString selectedPath = variantMap.value("path").toString();
        SettingsManager *sm = SettingsManager::getInstance();
        if (sm)
        {
            const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
            for (auto d: *mediaDirectories)
            {
                MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
                if (dd && dd->getPath() == selectedPath)
                {
                    md = dd;
                }
            }
        }
    }

    // Job
    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);
    if (jm && shot) jm->addJob(JOB_REENCODE, nullptr, this, shot, md, &sett);
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
