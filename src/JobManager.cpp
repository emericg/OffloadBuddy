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

QString JobManager::getandmakeDestination(Shot *s, Device *d)
{
    SettingsManager *sm = SettingsManager::getInstance();

    // HANDLE DESTINATION DIRECTORY ////////////////////////////////////////////

    QString destDir;

    if (s && d && sm)
    {
        destDir = getAutoDestinationString(s);

        // Destination directory and its subdirectories
        if (sm->getContentHierarchy() == HIERARCHY_DATE_DEVICE)
        {
            destDir += QDir::separator();
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
            destDir += d->getModel();
            destDir += QDir::separator();
        }
        else if (sm->getContentHierarchy() == HIERARCHY_DATE)
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
            destDir.clear();
        }
    }

    return destDir;
}

/* ************************************************************************** */

bool JobManager::addJob(JobType type, Device *d, Shot *s, MediaDirectory *md)
{
    bool status = false;

    if (type == 0 || !d || !s)
        return status;

    QList<Shot *> list;
    list.push_back(s);

    return addJobs(type, d, list, md);
}

bool JobManager::addJobs(JobType type, Device *d, QList<Shot *> list, MediaDirectory *m)
{
    bool status = false;

    if (type == 0 || !d)
        return status;

    SettingsManager *sm = SettingsManager::getInstance();
    bool getPreviews = !sm->getIgnoreJunk();
    bool getHdAudio = !sm->getIgnoreHdAudio();
    bool autoDelete = sm->getAutoDelete();

    // CREATE JOB //////////////////////////////////////////////////////////////

    if (type == JOB_DELETE)
    {
        // Delete everything, MP4, LRVs...
        getPreviews = true;
        getHdAudio = true;

        // HANDLE FILE REMOVAL /////////////////////////////////////////////////

        for (auto s: list)
        {
        if (d->getDeviceType() == DEVICE_MTP)
        {
#ifdef ENABLE_LIBMTP

            QList <ofb_file *> files = s->getFiles(); // Delete everything, MP4, LRVs...
            for (auto file: files)
            {
                if (!file || !file->mtpDevice || file->mtpObjectId == 0)
                    continue;

                qDebug() << "JobManager  >  deleting:" << file->name;
                LIBMTP_Delete_Object(file->mtpDevice, file->mtpObjectId);
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
                QFile::remove(file->filesystemPath);
            }
        }

        // TODO send shot deleted signal to the device
        d->deleteShot(s);
        }
    }
    else if (type == JOB_COPY)
    {
        // CREATE JOB //////////////////////////////////////////////////////////

        Job *j = new Job;
        j->id = rand(); // lol
        j->type = type;

        for (auto s: list)
        {
            JobElement *je = new JobElement;
            je->destination_dir = getandmakeDestination(s, d);
            je->parent_shots = s;
            QList <ofb_file *> files = s->getFiles(getPreviews, getHdAudio);
            for (auto f: files)
            {
                je->files.push_back(*f);
                j->totalSize += f->size;
                j->totalFiles++;
            }
            j->elements.push_back(je);

            s->setState(Shared::SHOT_STATE_QUEUED);
        }

        JobTracker *jt = new JobTracker(j->id, j->type);
        m_trackedJobs.push_back(jt);
        emit trackedJobsUpdated();

        // START JOB
        if (m_job_w1 == nullptr)
        {
            m_job_w1_thread = new QThread();
            m_job_w1 = new JobWorker();

            if (m_job_w1_thread && m_job_w1)
            {
                m_job_w1->queueWork(j);
                m_job_w1->moveToThread(m_job_w1_thread);

                connect(m_job_w1_thread, SIGNAL(started()), m_job_w1, SLOT(work()));

                connect(m_job_w1, SIGNAL(jobProgress(int, float)), this, SLOT(jobProgress(int, float)));
                connect(m_job_w1, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
                connect(m_job_w1, SIGNAL(jobFinished(int, int)), this, SLOT(jobFinished(int, int)));
                connect(m_job_w1, SIGNAL(shotStarted(int, Shot *)), this, SLOT(shotStarted(int, Shot *)));
                connect(m_job_w1, SIGNAL(shotFinished(int, Shot *)), this, SLOT(shotFinished(int, Shot *)));
                //connect(m_job_w1, SIGNAL(), this, SLOT());
/*
                //connect(m_job_w1, SIGNAL (scanningFinished()), m_job_w1, SLOT (deleteLater()));
                //connect(m_job_w1, SIGNAL(scanningFinished()), m_job_w1_thread, SLOT(quit()));

                // automatically delete thread when its work is done
                //connect(m_job_w1_thread, SIGNAL(finished()), m_job_w1_thread, SLOT(deleteLater()));
*/
                m_job_w1_thread->start();
            }
        }
        else
        {
            m_job_w1->queueWork(j);
            emit m_job_w1->work();
        }
/*
        // Delete shot only if needed (and current job success)
        if (autoDelete)
        {
            addJob(JOB_DELETE, d, s);
        }
*/
        // TODO create new shot
        // TODO add new shot to media library
    }
    else
    {
        qWarning() << "Unimplemented job type:" << type;
    }

    qWarning() << "JOB ADDED";

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobManager::clearFinishedJobs()
{
    for (auto jj: m_trackedJobs)
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getState() >= JOB_STATE_DONE)
        {
            m_trackedJobs.removeOne(jj);
        }
    }

    emit trackedJobsUpdated();
}

/* ************************************************************************** */

void JobManager::jobProgress(int jobId, float progress)
{
    for (auto jj: m_trackedJobs)
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            j->setProgress(progress);
            emit trackedJobsUpdated();
        }
    }
}

void JobManager::jobStarted(int jobId)
{
    for (auto jj: m_trackedJobs)
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            j->setState(JOB_STATE_WORKING);

            m_workingJobs++;
            emit trackedJobsUpdated();
        }
    }
}

void JobManager::jobFinished(int jobId, int jobState)
{
    for (auto jj: m_trackedJobs)
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            j->setState(jobState);

            if (jobState == JOB_STATE_DONE)
                j->setProgress(100.0);

            m_workingJobs--;
            emit trackedJobsUpdated();
        }
    }
}

void JobManager::shotStarted(int jobId, Shot *shot)
{
    for (auto jj: m_trackedJobs)
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            shot->setState(Shared::SHOT_STATE_WORKING);
        }
    }
}

void JobManager::shotFinished(int jobId, Shot *shot)
{
    for (auto jj: m_trackedJobs)
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            if (j->getType() == JOB_DELETE)
            {
                Device *d = j->getDevice();
                if (d && shot)
                    d->deleteShot(shot);
            }
            else
            {
                if (shot)
                    shot->setState(Shared::SHOT_STATE_OFFLOADED);
            }
        }
    }
}
