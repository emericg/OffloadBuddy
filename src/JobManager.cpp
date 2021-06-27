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

#include "JobManager.h"
#include "JobWorkerAsync.h"
#include "JobWorkerSync.h"
#include "SettingsManager.h"
#include "StorageManager.h"
#include "FileScanner.h"
#include "MediaLibrary.h"
#include "utils/utils_enums.h"

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
    }

    return instance;
}

JobManager::JobManager()
{
    //
}

JobManager::~JobManager()
{
    cleanup(); // singleton destructor is never called anyway...
}

void JobManager::cleanup()
{
    delete m_job_instant;
    m_job_disk.clear();
    delete m_job_cpu;
    delete m_job_web;

    m_job_instant = nullptr;
    m_job_cpu = nullptr;
    m_job_web = nullptr;
}

void JobManager::attachLibrary(MediaLibrary *l)
{
    m_library = l;
}

/* ************************************************************************** */
/* ************************************************************************** */

MediaDirectory *JobManager::getAutoDestination(Shot *s)
{
    MediaDirectory *md_selected = nullptr;

    StorageManager *sm = StorageManager::getInstance();
    const QList <QObject *> *mdl = sm->getDirectoriesList();

    for (auto md: *mdl)
    {
        MediaDirectory *md_current = qobject_cast<MediaDirectory*>(md);
        if (md_current &&
            md_current->isAvailableFor(s->getShotType(), s->getSize()))
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

QString JobManager::getandmakeDestination(Shot *s, Device *d, MediaDirectory *md)
{
    StorageManager *st = StorageManager::getInstance();

    // HANDLE DESTINATION DIRECTORY ////////////////////////////////////////////

    QString destDir;

    if (s && st)
    {
        if (md)
        {
            destDir = md->getPath();
        }
        else
        {
            destDir = getAutoDestinationString(s);
        }

        // Destination directory and its subdirectories

        if (st->getContentHierarchy() >= HIERARCHY_DATE)
        {
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
        }
        if (st->getContentHierarchy() >= HIERARCHY_DATE_DEVICE)
        {
            if (d)
            {
                destDir += d->getModel();
                destDir += QDir::separator();
            }
        }

        // Put chaptered videos in there own directory?
        if (s->getShotType() < Shared::SHOT_PICTURE)
        {
            if (s->getChapterCount() > 1)
            {
                destDir += "chaptered_";
                destDir += QString::number(s->getFileId());
                destDir += QDir::separator();
            }
        }

        // Put multishot in there own directory
        if (s->getShotType() == Shared::SHOT_PICTURE_MULTI ||
            s->getShotType() == Shared::SHOT_PICTURE_BURST ||
            s->getShotType() == Shared::SHOT_PICTURE_TIMELAPSE ||
            s->getShotType() == Shared::SHOT_PICTURE_NIGHTLAPSE)
        {
            if (s->getShotType() == Shared::SHOT_PICTURE_BURST)
                destDir += "burst_";
            else if (s->getShotType() == Shared::SHOT_PICTURE_TIMELAPSE)
                destDir += "timelapse_";
            else if (s->getShotType() == Shared::SHOT_PICTURE_NIGHTLAPSE)
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

bool JobManager::addJob(JobType type, Device *dev, MediaLibrary *lib, Shot *shot,
                        MediaDirectory *md, JobDestination *dst,
                        JobSettingsDelete *sett_delete,
                        JobSettingsOffload *sett_offload,
                        JobSettingsTelemetry *sett_telemetry,
                        JobSettingsEncode *sett_encode)
{
    bool status = false;

    if (type == 0 || (dev == nullptr && lib == nullptr) || !shot) return status;

    QList<Shot *> list;
    list.push_back(shot);

    return addJobs(type, dev, lib, list,
                   md, dst,
                   sett_delete, sett_offload, sett_telemetry, sett_encode);
}

bool JobManager::addJobs(JobType type, Device *dev, MediaLibrary *lib,
                         QList<Shot *> list,
                         MediaDirectory *md, JobDestination *dst,
                         JobSettingsDelete *sett_delete,
                         JobSettingsOffload *sett_offload,
                         JobSettingsTelemetry *sett_telemetry,
                         JobSettingsEncode *sett_encode)
{
    bool status = false;

    if (type == 0)
        return status;

    if (list.empty())
        return status;

    SettingsManager *sm = SettingsManager::getInstance();
    bool getPreviews = !sm->getIgnoreJunk();
    bool getHdAudio = !sm->getIgnoreHdAudio();
    bool autoDelete = sm->getAutoDelete();

    // CREATE JOB //////////////////////////////////////////////////////////////

    // FUSION hack
    if (type == JOB_COPY && (dev && dev->getModel().contains("Fusion", Qt::CaseInsensitive)))
    {
        // Fusion Studio needs every files from a shot to work
        getPreviews = true;
        getHdAudio = true;
    }

    if (type == JOB_DELETE)
    {
        // Delete everything, MP4, LRVs...
        getPreviews = true;
        getHdAudio = true;
    }

    // CREATE JOB //////////////////////////////////////////////////////////////

    Job *job = new Job;
    job->id = rand(); // TODO // Use QUuid
    job->type = type;

    if (sett_delete) job->settings_delete = *sett_delete;
    if (sett_offload) job->settings_offload = *sett_offload;
    if (sett_telemetry) job->settings_telemetry = *sett_telemetry;
    if (sett_encode) job->settings_encode = *sett_encode;

    for (auto shot: list)
    {
        JobElement *je = new JobElement;
        je->destination_dir = getandmakeDestination(shot, dev, md);
        je->parent_shots = shot;
        QList <ofb_file *> files = shot->getFiles(getPreviews, getHdAudio);
        for (auto f: qAsConst(files))
        {
            je->files.push_back(*f);
            job->totalSize += f->size;
            job->totalFiles++;
        }
        job->elements.push_back(je);

        shot->setState(Shared::SHOT_STATE_QUEUED);
    }

    JobTracker *tracker = new JobTracker(job->id, job->type);
    tracker->setDevice(dev);
    tracker->setLibrary(lib);
    tracker->setAutoDelete(autoDelete);
    if (!job->elements.empty())
        tracker->setDestination(job->elements.front()->destination_dir);
    m_trackedJobs.push_back(tracker);
    emit trackedJobsUpdated();

    // DISPATCH JOB ////////////////////////////////////////////////////////////

    if (type == JOB_ENCODE)
    {
        // ffmpeg worker
        if (m_job_cpu == nullptr)
        {
            qDebug() << "Starting an async worker";

            m_job_cpu = new JobWorkerAsync();

            connect(m_job_cpu, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
            connect(m_job_cpu, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
            connect(m_job_cpu, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));

            connect(m_job_cpu, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
            connect(m_job_cpu, SIGNAL(shotFinished(int,Shot*)), this, SLOT(shotFinished(int,Shot*)));
            connect(m_job_cpu, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));
        }

        if (m_job_cpu)
        {
            m_job_cpu->queueWork(job);
            m_job_cpu->work();
        }
    }
    else
    {
        // Regular worker
        JobWorkerSync *m_selected_worker = nullptr;

        if (type == JOB_DELETE || type == JOB_FORMAT)
        {
            m_selected_worker = m_job_instant; // TODO
        }
        else if (type == JOB_FIRMWARE_DOWNLOAD)
        {
            m_selected_worker = m_job_web; // TODO
        }
        else if (type == JOB_TELEMETRY || type == JOB_FIRMWARE_UPLOAD ||
                 type == JOB_CLIP ||
                 type == JOB_OFFLOAD || type == JOB_MOVE ||
                 type == JOB_COPY || type == JOB_MERGE)
        {
            m_selected_worker = m_job_disk[dev->getUuid()];

            if (m_selected_worker == nullptr)
            {
                qDebug() << "Starting a sync worker";

                m_selected_worker = new JobWorkerSync();
                m_selected_worker->thread = new QThread();

                if (m_selected_worker->thread && m_selected_worker)
                {
                    m_selected_worker->moveToThread(m_selected_worker->thread);

                    connect(m_selected_worker, SIGNAL(startWorking()), m_selected_worker, SLOT(work()));

                    connect(m_selected_worker, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
                    connect(m_selected_worker, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
                    connect(m_selected_worker, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));
                    connect(m_selected_worker, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
                    connect(m_selected_worker, SIGNAL(shotFinished(int,Shot*)), this, SLOT(shotFinished(int,Shot*)));
                    connect(m_selected_worker, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));

                    m_selected_worker->thread->start();
                    status = true;
                }

                m_job_disk.insert(dev->getUuid(), m_selected_worker);
            }
        }
        else
        {
            qWarning() << "Unable to select a worker to dispatch current job...";
            return status;
        }

        if (m_selected_worker)
        {
            m_selected_worker->queueWork(job);
            emit m_selected_worker->startWorking();
            status = true;
        }
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobManager::clearFinishedJobs()
{
    for (auto jj: qAsConst(m_trackedJobs))
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
    for (auto jj: qAsConst(m_trackedJobs))
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
    for (auto jj: qAsConst(m_trackedJobs))
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
    for (auto jj: qAsConst(m_trackedJobs))
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
    if (!shot)
    {
        qWarning() << "shotStarted() without a valid Shot*";
        return;
    }

    for (auto jj: qAsConst(m_trackedJobs))
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            j->setName(shot->getName());
            if (j->getType() == JOB_ENCODE)
                shot->setState(Shared::SHOT_STATE_ENCODING);
            else
                shot->setState(Shared::SHOT_STATE_OFFLOADING);
        }
    }
}

void JobManager::shotFinished(int jobId, Shot *shot)
{
    if (!shot)
    {
        qWarning() << "shotFinished() without a valid Shot*";
        return;
    }

    for (auto jj: qAsConst(m_trackedJobs))
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            if (j->getType() == JOB_DELETE)
            {
                Device *d = j->getDevice();
                if (d) d->deleteShot(shot);

                MediaLibrary *l = j->getLibrary();
                if (l) l->deleteShot(shot);

                // shot is now invalid
            }
            else
            {
                switch (j->getType()) {
                case JOB_OFFLOAD:
                case JOB_COPY:
                case JOB_MERGE:
                    shot->setState(Shared::SHOT_STATE_OFFLOADED);
                    break;

                case JOB_CLIP:
                case JOB_ENCODE:
                    shot->setState(Shared::SHOT_STATE_ENCODED);
                    break;

                default:
                    shot->setState(Shared::SHOT_STATE_DONE);
                    break;
                }

                if (j->getAutoDelete() &&
                    (j->getType() == JOB_COPY || j->getType() == JOB_MERGE))
                {
                    addJob(JOB_DELETE, j->getDevice(), j->getLibrary(), shot);
                }

                // TODO create new shot
                // TODO add new shot to media library
            }
        }
    }
}

void JobManager::newFile(QString path)
{
    if (m_library)
    {
        ofb_file *f = new ofb_file();
        ofb_shot *s = new ofb_shot();

        if (FileScanner::scanFilesystemFile(path, f, s))
        {
            m_library->getShotModel()->addFile(f, s);
        }
        else
        {
            delete f;
            delete s;
        }
    }
}
