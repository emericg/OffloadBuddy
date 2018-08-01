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

#include "JobManager.h"

#include <QFileInfo>
#include <QFile>
#include <QDir>
#include <QDebug>

/* ************************************************************************** */

JobManager *JobManager::instance = nullptr;

JobManager *JobManager::getInstance()
{
    if (instance == nullptr)
    {
        instance = new JobManager();
        return instance;
    }
    else
    {
        return instance;
    }
}

JobManager::JobManager()
{
    //
}

JobManager::~JobManager()
{
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

MediaDirectory * JobManager::getAutoDestination(Shot *s)
{
    MediaDirectory *md_selected = nullptr;

    SettingsManager *sm = SettingsManager::getInstance();
    const QList <QObject *> *mdl = sm->getDirectoriesList();

    for (auto md: *mdl)
    {
        MediaDirectory *md_current = qobject_cast<MediaDirectory*>(md);
        if (md_current &&
            md_current->isAvailableFor(s->getType(), s->getSize()))
        {
            md_selected = md_current;
            break;
        }
    }

    return md_selected;
}

QString JobManager::getAutoDestinationString(Shot *s)
{
    QString dest;

    if (s)
    {
        MediaDirectory *md = getAutoDestination(s);
        if (md)
        {
            dest = md->getPath();
        }
    }

    return dest;
}

bool JobManager::addJob(JobType type, Device *d, Shot *s, MediaDirectory *md)
{
    bool status = false;

    //
    if (d->getDeviceType() == DEVICE_MTP)
        return status;

    //
    if (type == JOB_DELETE)
    {
        // TODO check RO ?

        QStringList files = s->getFiles();
        for (auto file: files)
        {
            if (file.isEmpty() == false)
            {
                qDebug() << "JobManager  >  deleting:" << file;
                //QFile::remove(file);
            }
        }

        // TODO send shot deleted signal to the device
        // d->deleteShot(s);
    }
    else if (type == JOB_COPY)
    {
        s->setState(Shared::SHOT_STATE_WORKING);

        QStringList files = s->getFiles();
        QString destDir = getAutoDestinationString(s);

        // Now add subdirectories
        SettingsManager *sm = SettingsManager::getInstance();
        if (sm->getContentHierarchy() == HIERARCHY_BRAND_DEVICE_DATE)
        {
            destDir += QDir::separator();
            destDir += d->getBrand();
            destDir += QDir::separator();
            destDir += d->getModel();
            destDir += QDir::separator();
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
        }
        if (sm->getContentHierarchy() == HIERARCHY_DEVICE_DATE)
        {
            destDir += QDir::separator();
            destDir += d->getModel();
            destDir += QDir::separator();
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
        }
        if (sm->getContentHierarchy() == HIERARCHY_DATE)
        {
            //qDebug() << s->getDate();

            destDir += QDir::separator();
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
        }

        // Put multishot in there own dir
        if (s->getType() == Shared::SHOT_PICTURE_MULTI)
        {
            destDir += QString::number(s->getFileId());
            destDir += QDir::separator();
        }

        QDir d(destDir);
        //if (QDir::exists(destDir) || QDir::mkpath(destDir))
        if (!(d.exists() || d.mkpath(destDir)))
        {
            qDebug() << "DIR IS NOT OK";
        }

        for (auto f: files)
        {
            qDebug() << "JobManager  >  copying:" << f;
            qDebug() << "        to  > " << destDir;

            QFileInfo fi(f);
            QString destFile = destDir + fi.baseName() + "." + fi.suffix();

            // TODO dest file exists ???

            //QFile::copy(const QString &fileName, const QString &newName)
            QFile::copy(f, destFile);
        }

        s->setState(Shared::SHOT_STATE_OFFLOADED);

        // TODO delete shot if needed?

        // TODO create new shot
        // TODO add new shot to media library
    }

    return status;
}

bool JobManager::addJobs(JobType type, Device *d, QList<Shot *> list, MediaDirectory *m)
{
    bool status = false;

    for (auto s: list)
    {
        status |= addJob(type, d, s, m);
    }

    return status;
}

/* ************************************************************************** */
