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

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

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
    if (type == JOB_DELETE)
    {
        // TODO check RO ?

        // HANDLE FILE REMOVAL /////////////////////////////////////////////////

        if (d->getDeviceType() == DEVICE_MTP)
        {
#ifdef ENABLE_LIBMTP

            QList <ofb_file *> files = s->getFiles();
            for (auto file: files)
            {
                if (!file || !file->mtpDevice || file->mtpObjectId == 0)
                    continue;

                //LIBMTP_Delete_Object(file->mtpDevice, file->mtpObjectId);
            }

#endif // ENABLE_LIBMTP
        }
        else
        {
            QList <ofb_file *> files = s->getFiles();
            for (auto file: files)
            {
                if (!file || file->filesystemPath.isEmpty() == false)
                    continue;

                qDebug() << "JobManager  >  deleting:" << file->filesystemPath;
                //QFile::remove(file->filesystemPath);
            }
        }

        // TODO send shot deleted signal to the device
        d->deleteShot(s);
    }
    else if (type == JOB_COPY)
    {
        s->setState(Shared::SHOT_STATE_QUEUED);
        s->setState(Shared::SHOT_STATE_WORKING);

        // HANDLE DESTINATION DIRECTORY ////////////////////////////////////////

        SettingsManager *sm = SettingsManager::getInstance();
        bool getPreviews = !sm->getIgnoreJunk();
        bool getHdAudio = !sm->getIgnoreHdAudio();
        bool autoDelete = sm->getAutoDelete();

        QString destDir = getAutoDestinationString(s);

        // Destination directory and its subdirectories
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
            destDir += QDir::separator();
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
        }

        // Put chaptered videos in there own directory?
        if (s->getType() < Shared::SHOT_PICTURE)
        {
            if (s->getChapterCount() > 1)
            {
                destDir += "chaptered_";
                destDir += QString::number(s->getFileId());
                destDir += QDir::separator();
            }
        }

        // Put multishot in there own directory
        if (s->getType() == Shared::SHOT_PICTURE_MULTI ||
            s->getType() == Shared::SHOT_PICTURE_BURST ||
            s->getType() == Shared::SHOT_PICTURE_TIMELAPSE ||
            s->getType() == Shared::SHOT_PICTURE_NIGHTLAPSE)
        {
            if (s->getType() == Shared::SHOT_PICTURE_BURST)
                destDir += "burst_";
            else if (s->getType() == Shared::SHOT_PICTURE_TIMELAPSE)
                destDir += "timelapse_";
            else if (s->getType() == Shared::SHOT_PICTURE_NIGHTLAPSE)
                destDir += "nightlapse_";
            else
                destDir += "multi_";

            destDir += QString::number(s->getFileId());
            destDir += QDir::separator();
        }

        QDir dd(destDir);
        if (!(dd.exists() || dd.mkpath(destDir)))
        {
            qDebug() << "DEST DIR IS NOT OK! ABORT!";
            return false;
        }

        // HANDLE COPY /////////////////////////////////////////////////////////

        if (d->getDeviceType() == DEVICE_MTP)
        {
#ifdef ENABLE_LIBMTP

            QList <ofb_file *> files = s->getFiles(getPreviews, getHdAudio);
            for (auto file: files)
            {
                if (!file || !file->mtpDevice || file->mtpObjectId == 0)
                    continue;

                //qDebug() << "JobManager  >  MTP copying:" << file->mtpObjectId;
                //qDebug() << "        to  > " << destDir;

                QString destFile = destDir + file->name + "." + file->extension;
                // TODO destFile exists ???

                int err = LIBMTP_Get_File_To_File(file->mtpDevice, file->mtpObjectId, destFile.toLocal8Bit(), nullptr, nullptr);
                if (err)
                {
                    // TODO handle errors
                    qDebug() << "Couldn't copy file: " << destFile;
                }
            }

#endif // ENABLE_LIBMTP
        }
        else
        {
            QList <ofb_file *> files = s->getFiles(getPreviews, getHdAudio);
            for (auto file: files)
            {
                if (!file || file->filesystemPath.isEmpty())
                    continue;

                //qDebug() << "JobManager  >  FS copying:" << file->filesystemPath;
                //qDebug() << "        to  > " << destDir;

                QFileInfo fi(file->filesystemPath);
                QString destFile = destDir + fi.baseName() + "." + fi.suffix();
                // TODO dest file exists ???

                bool success = QFile::copy(file->filesystemPath, destFile);
                if (!success)
                {
                    // TODO handle errors
                    qDebug() << "Couldn't copy file: " << destFile;
                }
            }
        }

        s->setState(Shared::SHOT_STATE_OFFLOADED);

        // Delete shot only if needed (and current job success)
        if (autoDelete)
        {
            addJob(JOB_DELETE, d, s);
        }

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
