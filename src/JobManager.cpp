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
#include "JobWorkerFFmpeg.h"
#include "JobWorkerThread.h"
#include "JobWorkerASync.h"
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

/* ************************************************************************** */

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

    if (type == 0 || (dev == nullptr && lib == nullptr)) return status;

    QList<Shot *> list;
    list.push_back(shot);

    return addJobs(type, dev, lib, list, dst,
                   sett_delete, sett_offload, sett_telemetry, sett_encode);
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
    if (list.empty() && type != JobUtils::JOB_FIRMWARE_UPDATE) return status;

    // GET SETTINGS ////////////////////////////////////////////////////////////

    SettingsManager *sm = SettingsManager::getInstance();
    bool getPreviews = !sm->getIgnoreJunk();
    bool getHdAudio = !sm->getIgnoreHdAudio();

    if (type == JobUtils::JOB_OFFLOAD)
    {
        if (sett_offload)
        {
            getPreviews = !sett_offload->ignoreJunk;
            getHdAudio = !sett_offload->ignoreAudio;
        }

        // Fusion Studio needs every files from a Fusion shot in order to work
        if (dev && dev->getModel().contains("Fusion", Qt::CaseInsensitive))
        {
            if (sett_offload)
            {
                sett_offload->ignoreJunk = false;
                sett_offload->ignoreAudio = false;
            }
            getPreviews = true;
            getHdAudio = true;
        }
    }

    // Delete everything, MP4, LRVs...
    if (type == JobUtils::JOB_DELETE)
    {
        getPreviews = true;
        getHdAudio = true;
    }

    // GET DESTINATION /////////////////////////////////////////////////////////

    MediaDirectory *md = nullptr;
    QString dstFolder;
    QString dstFile;
    QString dstExt;

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
        if (!dst->extension.isEmpty())
        {
            dstExt = dst->extension;
        }
    }

    // CREATE JOB //////////////////////////////////////////////////////////////

    JobTracker *tracker = new JobTracker(rand(), type, this);
    tracker->setDevice(dev);
    tracker->setLibrary(lib);

    if (sett_delete) tracker->settings_delete = *sett_delete;
    if (sett_offload) tracker->settings_offload = *sett_offload;
    if (sett_telemetry) tracker->settings_telemetry = *sett_telemetry;
    if (sett_encode) tracker->settings_encode = *sett_encode;

    for (Shot *shot: list)
    {
        if (shot)
        {
            JobElement *je = new JobElement;
            je->parent_shot = shot;

            if (md) je->destination_folder = getandmakeDestination(shot, dev, md);
            else je->destination_folder = dstFolder;
            je->destination_file = dstFile;
            je->destination_ext = dstExt;

            const QList <ofb_file *> files = shot->getFiles(getPreviews, getHdAudio, true);
            for (auto f: std::as_const(files))
            {
                je->files.push_back(*f);
            }

            tracker->addElement(je);

            shot->setState(ShotUtils::SHOT_STATE_QUEUED);
        }
    }

    if (tracker->getElementsCount() > 0)
    {
        tracker->setName(tracker->getElement(0)->parent_shot->getName());
        tracker->setDestinationFolder(tracker->getElement(0)->destination_folder);
    }

    m_trackedJobs.push_back(tracker);
    emit trackedJobsUpdated();

    if (dev) dev->addJob(tracker);

    // DISPATCH JOB ////////////////////////////////////////////////////////////

    if (type == JobUtils::JOB_ENCODE || type == JobUtils::JOB_MERGE || type == JobUtils::JOB_CLIP)
    {
        // ffmpeg worker
        if (m_job_cpu == nullptr)
        {
            qDebug() << "Starting a JobWorkerFFmpeg";
            m_job_cpu = new JobWorkerFFmpeg();

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
    else if (type == JobUtils::JOB_FIRMWARE_UPDATE)
    {
        // async worker
        if (m_job_web == nullptr)
        {
            qDebug() << "Starting a JobWorkerASync";
            m_job_web = new JobWorkerASync();

            connect(m_job_web, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
            connect(m_job_web, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
            connect(m_job_web, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));
            connect(m_job_web, SIGNAL(jobErrored(int,int)), this, SLOT(jobErrored(int,int)));
            connect(m_job_web, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
            connect(m_job_web, SIGNAL(shotFinished(int,int,Shot*)), this, SLOT(shotFinished(int,int,Shot*)));
            //connect(m_selected_worker, SIGNAL(shotErrored(int,int,Shot*)), this, SLOT(shotErrored(int,int,Shot*)));
            connect(m_job_web, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));
        }

        if (m_job_web)
        {
            m_job_web->queueWork(tracker);
            m_job_web->work();
        }
    }
    else
    {
        // Regular worker
        JobWorkerThread *m_selected_worker = nullptr;

        if (type == JobUtils::JOB_DELETE || type == JobUtils::JOB_FORMAT)
        {
            m_selected_worker = m_job_instant;

            if (m_selected_worker == nullptr)
            {
                qDebug() << "Starting a JobWorkerThread";
                m_selected_worker = new JobWorkerThread();

                connect(m_selected_worker, SIGNAL(startWorking()), m_selected_worker, SLOT(work()));
                connect(m_selected_worker, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
                connect(m_selected_worker, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
                connect(m_selected_worker, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));
                connect(m_selected_worker, SIGNAL(jobErrored(int,int)), this, SLOT(jobErrored(int,int)));
                connect(m_selected_worker, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
                connect(m_selected_worker, SIGNAL(shotFinished(int,int,Shot*)), this, SLOT(shotFinished(int,int,Shot*)));
                //connect(m_selected_worker, SIGNAL(shotErrored(int,int,Shot*)), this, SLOT(shotErrored(int,int,Shot*)));
                connect(m_selected_worker, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));

                m_job_instant = m_selected_worker;
                m_selected_worker->start();
                status = true;
            }
        }
        else if (type == JobUtils::JOB_OFFLOAD || type == JobUtils::JOB_MOVE || type == JobUtils::JOB_TELEMETRY)
        {
            if (dev) m_selected_worker = m_job_disk[dev->getUuid()];
            else m_selected_worker = m_job_disk["hdd"];

            if (m_selected_worker == nullptr)
            {
                qDebug() << "Starting a JobWorkerThread";
                m_selected_worker = new JobWorkerThread();

                connect(m_selected_worker, SIGNAL(startWorking()), m_selected_worker, SLOT(work()));
                connect(m_selected_worker, SIGNAL(jobProgress(int,float)), this, SLOT(jobProgress(int,float)));
                connect(m_selected_worker, SIGNAL(jobStarted(int)), this, SLOT(jobStarted(int)));
                connect(m_selected_worker, SIGNAL(jobFinished(int,int)), this, SLOT(jobFinished(int,int)));
                connect(m_selected_worker, SIGNAL(jobErrored(int,int)), this, SLOT(jobErrored(int,int)));
                connect(m_selected_worker, SIGNAL(shotStarted(int,Shot*)), this, SLOT(shotStarted(int,Shot*)));
                connect(m_selected_worker, SIGNAL(shotFinished(int,int,Shot*)), this, SLOT(shotFinished(int,int,Shot*)));
                //connect(m_selected_worker, SIGNAL(shotErrored(int,int,Shot*)), this, SLOT(shotErrored(int,int,Shot*)));
                connect(m_selected_worker, SIGNAL(fileProduced(QString)), this, SLOT(newFile(QString)));

                if (dev) m_job_disk.insert(dev->getUuid(), m_selected_worker);
                else m_job_disk.insert("hdd", m_selected_worker);
                m_selected_worker->start();
                status = true;
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
    for (auto jj: std::as_const(m_trackedJobs))
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getState() >= JobUtils::JOB_STATE_DONE)
        {
            Device *d = j->getDevice();
            if (d) d->removeJob(j);

            m_trackedJobs.removeOne(jj);

            delete j;
        }
    }

    emit trackedJobsUpdated();
}

/* ************************************************************************** */

void JobManager::playPauseJob(int jobId)
{
    if (m_job_cpu && m_job_cpu->getCurrentJobId() == jobId)
    {
        m_job_cpu->playPauseWork();
    }
    if (m_job_web && m_job_web->getCurrentJobId() == jobId)
    {
        m_job_web->playPauseWork();
    }
}

void JobManager::stopJob(int jobId)
{
    if (m_job_cpu && m_job_cpu->getCurrentJobId() == jobId)
    {
        m_job_cpu->abortWork();
    }
    if (m_job_web && m_job_web->getCurrentJobId() == jobId)
    {
        m_job_web->abortWork();
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobManager::jobProgress(int jobId, float progress)
{
    for (auto jj: std::as_const(m_trackedJobs))
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
    for (auto jj: std::as_const(m_trackedJobs))
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
    for (auto jj: std::as_const(m_trackedJobs))
    {
        JobTracker *j = qobject_cast<JobTracker *>(jj);
        if (j && j->getId() == jobId)
        {
            j->setState(jobState);

            if (jobState == JobUtils::JOB_STATE_DONE)
                j->setProgress(100.0);

            Device *d = j->getDevice();
            if (d) d->removeJob(j);

            m_workingJobs--;
            emit trackedJobsUpdated();
        }
    }
}

void JobManager::jobAborted(int, int) // (int jobId, int jobState)
{
    //
}

void JobManager::jobErrored(int, int) // (int jobId, int jobState)
{
    //
}

/* ************************************************************************** */

void JobManager::shotStarted(int jobId, Shot *shot)
{
    if (!shot)
    {
        qWarning() << "shotStarted() without a valid Shot*";
        return;
    }

    for (auto jj: std::as_const(m_trackedJobs))
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

    for (auto jj: std::as_const(m_trackedJobs))
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
                    if (status > 0 && j->settings_offload.autoDelete)
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

                case JobUtils::JOB_FIRMWARE_UPDATE:
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
    for (auto md: *sm->getDirectoriesList())
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
    QString destDir;

    if (s)
    {
        if (md)
        {
            // Destination directory
            destDir = md->getPath();

            // Destination subdirectories
            if (s->isGoPro())
            {
                int h = md->getHierarchyMode();

                if (h == StorageUtils::HierarchyNone)
                {
                    //
                }
                else if (h == StorageUtils::HierarchyShot)
                {
                    if (s->getFileCount() > 1)
                    {
                        destDir += s->getName();
                        destDir += QDir::separator();
                    }
                }
                else if (h == StorageUtils::HierarchyDateShot)
                {
                    destDir += s->getDate().toString("yyyy-MM-dd");
                    destDir += QDir::separator();
                    if (s->getFileCount() > 1)
                    {
                        destDir += s->getName();
                        destDir += QDir::separator();
                    }
                }
                else if (h >= StorageUtils::HierarchyDateDeviceShot)
                {
                    destDir += s->getDate().toString("yyyy-MM-dd");
                    destDir += QDir::separator();
                    if (d)
                    {
                        destDir += d->getModel();
                        destDir += QDir::separator();
                    }
                    if (s->getFileCount() > 1)
                    {
                        destDir += s->getName();
                        destDir += QDir::separator();
                    }
                }
                else if (h >= StorageUtils::HierarchyYearDateDeviceShot)
                {
                    destDir += s->getDate().toString("yyyy");
                    destDir += QDir::separator();
                    destDir += s->getDate().toString("yyyy-MM-dd");
                    destDir += QDir::separator();
                    if (d)
                    {
                        destDir += d->getModel();
                        destDir += QDir::separator();
                    }
                    if (s->getFileCount() > 1)
                    {
                        destDir += s->getName();
                        destDir += QDir::separator();
                    }
                }
                else if (h >= StorageUtils::HierarchyCustom)
                {
                    QString c = md->getHierarchyCustom();

                    c.replace("$(DATE)", s->getDate().toString("yyyy-MM-dd"));
                    c.replace("$(YEAR)", s->getDate().toString("yyyy"));
                    c.replace("$(MONTH)", s->getDate().toString("MM"));
                    c.replace("$(DAY)", s->getDate().toString("dd"));
                    if (s->getFileCount() > 1)
                    {
                        c.replace("$(SHOT_NAME)", s->getName());
                    }
                    else
                    {
                        c.remove("$(SHOT_NAME)");
                    }
                    c.replace("$(CAMERA)", s->getCameraSource());

                    c.replace("//", "/");
                    if (!c.endsWith('/')) c.append('/');

                    destDir += c;
                }
            }
        }
        else
        {
            // Default destination directory
            destDir = getAutoDestinationString(s);
        }

        // Put chaptered videos in there own subdirectory
        if (s->getShotType() < ShotUtils::SHOT_PICTURE)
        {
            if (s->getChapterCount() > 1)
            {
                destDir += "chaptered_";
                destDir += QString::number(s->getShotId());
                destDir += QDir::separator();
            }
        }
        // Put multishot in there own subdirectory
        if (s->getShotType() > ShotUtils::SHOT_PICTURE)
        {
            if (s->getShotType() == ShotUtils::SHOT_PICTURE_BURST)
                destDir += "burst_";
            else if (s->getShotType() == ShotUtils::SHOT_PICTURE_TIMELAPSE)
                destDir += "timelapse_";
            else if (s->getShotType() == ShotUtils::SHOT_PICTURE_NIGHTLAPSE)
                destDir += "nightlapse_";
            else
                destDir += "multi_";

            destDir += QString::number(s->getShotId());
            destDir += QDir::separator();
        }

        // Check destDir
        QDir dd(destDir);
        if (!(dd.exists() || dd.mkpath(destDir)))
        {
            qWarning() << "Destination directory cannot be created! ABORT!";
            destDir.clear();
        }
    }

    return destDir;
}

/* ************************************************************************** */

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
                int h = md_current->getHierarchyMode();

                if (h == StorageUtils::HierarchyNone)
                {
                    hierarchyString = " FILES";
                }
                else if (h == StorageUtils::HierarchyShot)
                {
                    if (s)
                    {
                        if (s->getFileCount() > 1)
                        {
                            hierarchyString += s->getName();
                            hierarchyString += QDir::separator();
                        }
                    }
                    else
                    {
                        hierarchyString = " SHOT / FILES";
                    }
                }
                else if (h == StorageUtils::HierarchyDateShot)
                {
                    if (s)
                    {
                        hierarchyString += s->getDate().toString("yyyy-MM-dd");
                        hierarchyString += QDir::separator();
                        if (s->getFileCount() > 1)
                        {
                            hierarchyString += s->getName();
                            hierarchyString += QDir::separator();
                        }
                    }
                    else
                    {
                        hierarchyString = " date / SHOT / FILES";
                    }
                }
                else if (h == StorageUtils::HierarchyDateDeviceShot)
                {
                    if (s)
                    {
                        hierarchyString += s->getDate().toString("yyyy-MM-dd");
                        hierarchyString += QDir::separator();
                        hierarchyString += s->getCameraSource();
                        hierarchyString += QDir::separator();
                        if (s->getFileCount() > 1)
                        {
                            hierarchyString += s->getName();
                            hierarchyString += QDir::separator();
                        }
                    }
                    else
                    {
                        hierarchyString = " date / device / SHOT / FILES";
                    }
                }
                else if (h == StorageUtils::HierarchyYearDateDeviceShot)
                {
                    if (s)
                    {
                        hierarchyString += s->getDate().toString("yyyy");
                        hierarchyString += QDir::separator();
                        hierarchyString += s->getDate().toString("yyyy-MM-dd");
                        hierarchyString += QDir::separator();
                        hierarchyString += s->getCameraSource();
                        hierarchyString += QDir::separator();
                        if (s->getFileCount() > 1)
                        {
                            hierarchyString += s->getName();
                            hierarchyString += QDir::separator();
                        }
                    }
                    else
                    {
                        hierarchyString = " year / date / device / SHOT / FILES";
                    }
                }
                else if (h == StorageUtils::HierarchyCustom)
                {
                    QString c = md_current->getHierarchyCustom();

                    if (s)
                    {
                        c.replace("$(DATE)", s->getDate().toString("yyyy-MM-dd"));
                        c.replace("$(YEAR)", s->getDate().toString("yyyy"));
                        c.replace("$(MONTH)", s->getDate().toString("MM"));
                        c.replace("$(DAY)", s->getDate().toString("dd"));
                        if (s->getFileCount() > 1)
                        {
                            c.replace("$(SHOT_NAME)", s->getName());
                        }
                        else
                        {
                            c.remove("$(SHOT_NAME)");
                        }
                        c.replace("$(CAMERA)", s->getCameraSource());

                        c.replace("//", "/");
                        if (!c.endsWith('/')) c.append('/');

                        hierarchyString = c;
                    }
                    else
                    {
                        hierarchyString += " / ";
                        hierarchyString += c;
                        hierarchyString += " / FILES";
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
                int h = md_current->getHierarchyMode();

                if (h == StorageUtils::HierarchyNone)
                {
                    //
                }
                else if (h == StorageUtils::HierarchyShot)
                {
                    if (s->getFileCount() > 1)
                    {
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                }
                else if (h == StorageUtils::HierarchyDateShot)
                {
                    hierarchyString += s->getDate().toString("yyyy-MM-dd");
                    hierarchyString += QDir::separator();
                    if (s->getFileCount() > 1)
                    {
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                }
                else if (h == StorageUtils::HierarchyDateDeviceShot)
                {
                    hierarchyString += s->getDate().toString("yyyy-MM-dd");
                    hierarchyString += QDir::separator();
                    hierarchyString += s->getCameraSource();
                    hierarchyString += QDir::separator();
                    if (s->getFileCount() > 1)
                    {
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                }
                else if (h == StorageUtils::HierarchyYearDateDeviceShot)
                {
                    hierarchyString += s->getDate().toString("yyyy");
                    hierarchyString += QDir::separator();
                    hierarchyString += s->getDate().toString("yyyy-MM-dd");
                    hierarchyString += QDir::separator();
                    hierarchyString += s->getCameraSource();
                    hierarchyString += QDir::separator();
                    if (s->getFileCount() > 1)
                    {
                        hierarchyString += s->getName();
                        hierarchyString += QDir::separator();
                    }
                }
                else if (h == StorageUtils::HierarchyCustom)
                {
                    QString c = md_current->getHierarchyCustom();

                    c.replace("$(DATE)", s->getDate().toString("yyyy-MM-dd"));
                    c.replace("$(YEAR)", s->getDate().toString("yyyy"));
                    c.replace("$(MONTH)", s->getDate().toString("MM"));
                    c.replace("$(DAY)", s->getDate().toString("dd"));
                    if (s->getFileCount() > 1)
                    {
                        c.replace("$(SHOT_NAME)", s->getName());
                    }
                    else
                    {
                        c.remove("$(SHOT_NAME)");
                    }
                    c.replace("$(CAMERA)", s->getCameraSource());

                    c.replace("//", "/");
                    if (!c.endsWith('/')) c.append('/');

                    hierarchyString = c;
                }
                break;
            }
        }
    }

    return hierarchyString;
}

/* ************************************************************************** */
/* ************************************************************************** */
