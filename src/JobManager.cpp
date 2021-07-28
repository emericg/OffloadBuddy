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

bool JobManager::addJob(JobUtils::JobType type, Device *dev, MediaLibrary *lib,
                        Shot *shot,
                        JobDestination *dst,
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
                   dst, sett_delete, sett_offload, sett_telemetry, sett_encode);
}

bool JobManager::addJobs(JobUtils::JobType type, Device *dev, MediaLibrary *lib,
                         QList<Shot *> &list,
                         JobDestination *dst,
                         JobSettingsDelete *sett_delete,
                         JobSettingsOffload *sett_offload,
                         JobSettingsTelemetry *sett_telemetry,
                         JobSettingsEncode *sett_encode)
{
    bool status = false;

    if (type == 0) return status;
    if (list.empty()) return status;

    // GET SETTINGS ////////////////////////////////////////////////////////////

    SettingsManager *sm = SettingsManager::getInstance();
    bool getPreviews = !sm->getIgnoreJunk();
    bool getHdAudio = !sm->getIgnoreHdAudio();
    bool autoDelete = sm->getAutoDelete();
    bool extractTelemetry = sm->getAutoTelemetry();
    bool mergeChapters = sm->getAutoMerge();
    bool moveToTrash = sm->getMoveToTrash();

    if (type == JobUtils::JOB_OFFLOAD)
    {
        if (sett_offload)
        {
            getPreviews = !sett_offload->ignoreJunk;
            getHdAudio = !sett_offload->ignoreAudio;
            extractTelemetry = sett_offload->extractTelemetry;
            mergeChapters = sett_offload->mergeChapters;
            autoDelete = sett_offload->autoDelete;
        }

        // Fusion Studio needs every files from a Fusion shot in order to work
        if (dev && dev->getModel().contains("Fusion", Qt::CaseInsensitive))
        {
            getPreviews = true;
            getHdAudio = true;
        }
    }

    // Delete everything, MP4, LRVs...
    if (type == JobUtils::JOB_DELETE)
    {
        if (sett_delete)
        {
            moveToTrash = sett_delete->moveToTrash;
        }

        getPreviews = true;
        getHdAudio = true;
    }

    // GET DESTINATION /////////////////////////////////////////////////////////

    MediaDirectory *md = nullptr;
    QString dstFolder;
    QString dstFile;

    if (dst)
    {
        if (!dst->mediaDirectory.isEmpty())
        {
            StorageManager *stm = StorageManager::getInstance();
            const QList <QObject *> *mdl = stm->getDirectoriesList();
            for (auto mds: *mdl)
            {
                MediaDirectory *md_current = qobject_cast<MediaDirectory*>(mds);
                if (md_current && md_current->getPath() == dst->mediaDirectory)
                {
                    md = md_current;
                    break;
                }
            }
        }
        if (!dst->folder.isEmpty())
        {
            dstFolder = dst->folder;
        }
        if (!dst->file.isEmpty())
        {
            dstFile = dst->file;
        }
    }

    // CREATE JOB //////////////////////////////////////////////////////////////

    JobTracker *tracker = new JobTracker(rand(), type, this);
    tracker->setDevice(dev);
    tracker->setLibrary(lib);
    tracker->setAutoDelete(autoDelete);

    if (sett_delete) tracker->settings_delete = *sett_delete;
    if (sett_offload) tracker->settings_offload = *sett_offload;
    if (sett_telemetry) tracker->settings_telemetry = *sett_telemetry;
    if (sett_encode) tracker->settings_encode = *sett_encode;

    QStringList ssll;

    for (Shot *shot: list)
    {
        if (shot)
        {
            JobElement *je = new JobElement;
            if (md) je->destination_dir = getandmakeDestination(shot, dev, md);
            else je->destination_dir = dstFolder;
            je->destination_file = dstFile;
            je->parent_shot = shot;
            ssll += shot->getFilesStringList();
            QList <ofb_file *> files = shot->getFiles(getPreviews, getHdAudio, true);
            for (auto f: qAsConst(files))
            {
                je->files.push_back(*f);
                tracker->totalSize += f->size;
                tracker->totalFiles++;
            }
            tracker->elements.push_back(je);

            shot->setState(ShotUtils::SHOT_STATE_QUEUED);
        }
        else
        {
            qWarning() << "JobManager : INVALID SHOT";
        }
    }

    if (list.size() > 0)
    {
        QString tempname = list.at(0)->getName();
        tracker->setName(tempname);

        tracker->setFiles(ssll);
        tracker->setDestination(tracker->elements.front()->destination_dir);
    }

    m_trackedJobs.push_back(tracker);
    emit trackedJobsUpdated();

    // DISPATCH JOB ////////////////////////////////////////////////////////////

    if (type == JobUtils::JOB_ENCODE)
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
            connect(m_job_cpu, SIGNAL(shotFinished(int,int,Shot*)), this, SLOT(shotFinished(int,int,Shot*)));
            connect(m_job_cpu, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));
        }

        if (m_job_cpu)
        {
            m_job_cpu->queueWork(tracker);
            m_job_cpu->work();
        }
    }
    else
    {
        // Regular worker
        JobWorkerSync *m_selected_worker = nullptr;

        if (type == JobUtils::JOB_DELETE || type == JobUtils::JOB_FORMAT)
        {
            m_selected_worker = m_job_instant;

            if (m_selected_worker == nullptr)
            {
                qDebug() << "Starting a sync worker";
                m_selected_worker = new JobWorkerSync();
                m_selected_worker->start();

                connect(m_selected_worker, SIGNAL(startWorking()), m_selected_worker, SLOT(work()));
                connect(m_selected_worker, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
                connect(m_selected_worker, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
                connect(m_selected_worker, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));
                connect(m_selected_worker, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
                connect(m_selected_worker, SIGNAL(shotFinished(int,int,Shot*)), this, SLOT(shotFinished(int,int,Shot*)));
                connect(m_selected_worker, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));

                status = true;

                m_job_instant = m_selected_worker;
            }
        }
        else if (type == JobUtils::JOB_FIRMWARE_DOWNLOAD)
        {
            m_selected_worker = m_job_web; // TODO
        }
        else if (type == JobUtils::JOB_TELEMETRY || type == JobUtils::JOB_FIRMWARE_UPLOAD ||
                 type == JobUtils::JOB_CLIP ||
                 type == JobUtils::JOB_OFFLOAD || type == JobUtils::JOB_MOVE)
        {
            if (dev) m_selected_worker = m_job_disk[dev->getUuid()];
            else m_selected_worker = m_job_disk["hdd"];

            if (m_selected_worker == nullptr)
            {
                qDebug() << "Starting a sync worker";
                m_selected_worker = new JobWorkerSync();
                m_selected_worker->start();

                connect(m_selected_worker, SIGNAL(startWorking()), m_selected_worker, SLOT(work()));
                connect(m_selected_worker, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
                connect(m_selected_worker, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
                connect(m_selected_worker, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));
                connect(m_selected_worker, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
                connect(m_selected_worker, SIGNAL(shotFinished(int,int,Shot*)), this, SLOT(shotFinished(int,int,Shot*)));
                connect(m_selected_worker, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));

                status = true;

                if (dev) m_job_disk.insert(dev->getUuid(), m_selected_worker);
                else m_job_disk.insert("hdd", m_selected_worker);
            }
        }
        else
        {
            qWarning() << "Unable to select a worker to dispatch current job...";
            return status;
        }

        if (m_selected_worker)
        {
            m_selected_worker->queueWork(tracker);
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
        if (j && j->getState() >= JobUtils::JOB_STATE_DONE)
        {
            m_trackedJobs.removeOne(jj);
        }
    }

    emit trackedJobsUpdated();
}

/* ************************************************************************** */

void JobManager::playPauseJob(int jobId)
{
    //
}

void JobManager::stopJob(int jobId)
{
    //
}

/* ************************************************************************** */
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
            j->setState(JobUtils::JOB_STATE_WORKING);

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

            if (jobState == JobUtils::JOB_STATE_DONE)
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
            if (j->getType() == JobUtils::JOB_ENCODE)
                shot->setState(ShotUtils::SHOT_STATE_ENCODING);
            else
                shot->setState(ShotUtils::SHOT_STATE_OFFLOADING);
        }
    }
}

void JobManager::shotFinished(int jobId, int status, Shot *shot)
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
            if (j->getType() == JobUtils::JOB_DELETE)
            {
                Device *d = j->getDevice();
                if (d) d->deleteShot(shot);

                MediaLibrary *l = j->getLibrary();
                if (l) l->deleteShot(shot);

                // shot is now invalid
            }
            else
            {
                switch (j->getType())
                {
                case JobUtils::JOB_OFFLOAD:
                    if (j->getAutoDelete())
                        addJob(JobUtils::JOB_DELETE, j->getDevice(), j->getLibrary(), shot);
                    else
                        shot->setState(ShotUtils::SHOT_STATE_OFFLOADED);
                    break;

                case JobUtils::JOB_MOVE:
                    if (status > 0)
                        addJob(JobUtils::JOB_DELETE, j->getDevice(), j->getLibrary(), shot);
                    break;

                case JobUtils::JOB_CLIP:
                case JobUtils::JOB_ENCODE:
                    shot->setState(ShotUtils::SHOT_STATE_ENCODED);
                    break;

                default:
                    shot->setState(ShotUtils::SHOT_STATE_DONE);
                    break;
                }
            }
        }
    }
}

/* ************************************************************************** */

void JobManager::newFile(QString path)
{
    if (m_library)
    {
        ofb_file *f = new ofb_file();
        ofb_shot *s = new ofb_shot();

        if (FileScanner::scanFilesystemFile(path, f, s))
        {
            m_library->getShotModel()->addFile(f, s);
            m_library->invalidate();
        }
        else
        {
            delete f;
            delete s;
        }
    }
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
    if (s)
    {
        MediaDirectory *md = getAutoDestination(s);
        if (md)
        {
            return md->getPath();
        }
    }

    return QString();
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

        if (st->getContentHierarchy() >= StorageUtils::HierarchyDate)
        {
            destDir += s->getDate().toString("yyyy-MM-dd");
            destDir += QDir::separator();
        }
        if (st->getContentHierarchy() >= StorageUtils::HierarchyDateDevice)
        {
            if (d)
            {
                destDir += d->getModel();
                destDir += QDir::separator();
            }
        }

        // Put chaptered videos in there own directory?
        if (s->getShotType() < ShotUtils::SHOT_PICTURE)
        {
            if (s->getChapterCount() > 1)
            {
                destDir += "chaptered_";
                destDir += QString::number(s->getFileId());
                destDir += QDir::separator();
            }
        }

        // Put multishot in there own directory
        if (s->getShotType() == ShotUtils::SHOT_PICTURE_MULTI ||
            s->getShotType() == ShotUtils::SHOT_PICTURE_BURST ||
            s->getShotType() == ShotUtils::SHOT_PICTURE_TIMELAPSE ||
            s->getShotType() == ShotUtils::SHOT_PICTURE_NIGHTLAPSE)
        {
            if (s->getShotType() == ShotUtils::SHOT_PICTURE_BURST)
                destDir += "burst_";
            else if (s->getShotType() == ShotUtils::SHOT_PICTURE_TIMELAPSE)
                destDir += "timelapse_";
            else if (s->getShotType() == ShotUtils::SHOT_PICTURE_NIGHTLAPSE)
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

QString JobManager::getDestinationHierarchyDisplay(Shot *s, const QString &path)
{
    QString hierarchyString;

    if (!path.isEmpty())
    {
        StorageManager *sm = StorageManager::getInstance();
        const QList <QObject *> *mdl = sm->getDirectoriesList();

        for (auto md: *mdl)
        {
            MediaDirectory *md_current = qobject_cast<MediaDirectory*>(md);
            if (md_current && md_current->getPath() == path)
            {
                int h = md_current->getHierarchy();
                if (h == StorageUtils::HierarchyNone)
                {
                    if (s)
                    {
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                    else
                    {
                        hierarchyString = " SHOT / FILES";
                    }
                }
                else if (h == StorageUtils::HierarchyDate)
                {
                    if (s)
                    {
                        hierarchyString += s->getDate().toString("yyyy-MM-dd");
                        hierarchyString += QDir::separator();
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                    else
                    {
                        hierarchyString = " date / SHOT / FILES";
                    }
                }
                else if (h == StorageUtils::HierarchyDateDevice)
                {
                    if (s)
                    {
                        hierarchyString += s->getDate().toString("yyyy-MM-dd");
                        hierarchyString += QDir::separator();
                        hierarchyString += s->getCameraSource();
                        hierarchyString += QDir::separator();
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                    else
                    {
                        hierarchyString = " date / device / SHOT / FILES";
                    }
                }
                break;
            }
        }
    }

    return hierarchyString;
}

QString JobManager::getDestinationHierarchy(Shot *s, const QString &path)
{
    QString hierarchyString;

    if (s && !path.isEmpty())
    {
        StorageManager *sm = StorageManager::getInstance();
        const QList <QObject *> *mdl = sm->getDirectoriesList();

        for (auto md: *mdl)
        {
            MediaDirectory *md_current = qobject_cast<MediaDirectory*>(md);
            if (md_current && md_current->getPath() == path)
            {
                int h = md_current->getHierarchy();
                if (h == StorageUtils::HierarchyNone)
                {
                    hierarchyString += s->getName();
                    hierarchyString += QDir::separator();
                }
                else if (h == StorageUtils::HierarchyDate)
                {
                    hierarchyString += s->getDate().toString("yyyy-MM-dd");
                    hierarchyString += QDir::separator();
                    hierarchyString += s->getName();
                    hierarchyString += QDir::separator();
                }
                else if (h == StorageUtils::HierarchyDateDevice)
                {
                    hierarchyString += s->getDate().toString("yyyy-MM-dd");
                    hierarchyString += QDir::separator();
                    hierarchyString += s->getCameraSource();
                    hierarchyString += QDir::separator();
                    hierarchyString += s->getName();
                    hierarchyString += QDir::separator();
                }
                break;
            }
        }
    }

    return hierarchyString;
}

/* ************************************************************************** */
