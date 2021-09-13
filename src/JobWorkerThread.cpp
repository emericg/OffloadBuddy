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

#include "JobWorkerThread.h"
#include "JobManager.h"
#include "SettingsManager.h"
#include "FirmwareManager.h"
#include "Shot.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStorageInfo>
#include <QThread>
#include <QMutexLocker>
#include <QDebug>

/* ************************************************************************** */

JobWorkerThread::JobWorkerThread()
{
    //
}

JobWorkerThread::~JobWorkerThread()
{
    if (m_thread) m_thread->terminate();
}

/* ************************************************************************** */
/* ************************************************************************** */

bool JobWorkerThread::start()
{
    m_thread = new QThread();
    if (m_thread)
    {
        connect(m_thread, &QThread::finished, m_thread, &QObject::deleteLater);
        moveToThread(m_thread);
        m_thread->start();

        return true;
    }

    return false;
}

bool JobWorkerThread::stop()
{
    if (m_thread) m_thread->terminate();
    return true;
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerThread::queueWork(JobTracker *job)
{
    qDebug() << ">> JobWorkerThread::queueWork()";

    QMutexLocker locker(&m_jobsMutex);
    m_jobs.enqueue(job);

    //emit startWorking();

    qDebug() << "<< JobWorkerThread::queueWork()";
}

bool JobWorkerThread::isWorking()
{
    qDebug() << ">> JobWorkerThread::isWorking()";

    QMutexLocker locker(&m_jobsMutex);
    return m_working;
}

void JobWorkerThread::work()
{
    qDebug() << ">> JobWorkerThread::work()";

    float progress = 0.f;
    int64_t stuff_done = 0;

    m_jobsMutex.lock();
    while (!m_jobs.isEmpty())
    {
        JobTracker *current_job = m_jobs.dequeue();
        m_working = true;
        m_jobsMutex.unlock();

        if (current_job)
        {
            emit jobStarted(current_job->getId());
            int index = -1;

            for (auto element: current_job->getElements())
            {
                emit shotStarted(current_job->getId(), element->parent_shot);
                int element_status = 1;

                index++;
                current_job->setElementsIndex(index);

                // HANDLE TELEMETRY ////////////////////////////////////////////

                if (current_job->getType() == JobUtils::JOB_TELEMETRY)
                {
                    work_telemetry(element, &current_job->settings_telemetry);
/*
                    if (element->parent_shot)
                    {
                        element->parent_shot->parseTelemetry();

                        if (!current_job->settings_telemetry.gps_format.isEmpty())
                        {
                            element->parent_shot->exportGps(element->destination_dir, 0,
                                                            current_job->settings_telemetry.gps_frequency,
                                                            current_job->settings_telemetry.EGM96);
                        }
                        if (!current_job->settings_telemetry.telemetry_format.isEmpty())
                        {
                            element->parent_shot->exportTelemetry(element->destination_dir, 0,
                                                                  current_job->settings_telemetry.telemetry_frequency,
                                                                  current_job->settings_telemetry.gps_frequency,
                                                                  current_job->settings_telemetry.EGM96);
                        }
                    }
*/
                }

                if (current_job->getType() == JobUtils::JOB_OFFLOAD && current_job->settings_offload.extractTelemetry)
                {
                    // "auto" telemetry extraction
                    element->parent_shot->parseTelemetry();
                    element->parent_shot->exportGps(element->destination_dir, 0,
                                            current_job->settings_telemetry.gps_frequency,
                                            current_job->settings_telemetry.EGM96);
                    element->parent_shot->exportTelemetry(element->destination_dir, 0,
                                            current_job->settings_telemetry.telemetry_frequency,
                                            current_job->settings_telemetry.gps_frequency,
                                            current_job->settings_telemetry.EGM96);
                }

                // HANDLE OFFLOADS /////////////////////////////////////////////

                if (current_job->getType() == JobUtils::JOB_MOVE ||
                    current_job->getType() == JobUtils::JOB_OFFLOAD)
                {
                    for (auto const &file: element->files)
                    {
                        if (!file.filesystemPath.isEmpty())
                        {
                            //qDebug() << "JobWorkerThread  >  FS copying:" << file->filesystemPath;
                            //qDebug() << "       to  > " << element->destination_dir;

                            QFileInfo fi_src(file.filesystemPath);
                            QString destFile = element->destination_dir + fi_src.baseName() + "." + fi_src.suffix();
                            QFileInfo fi_dst(destFile);

                            if (!fi_dst.exists() ||
                                (fi_dst.exists() && fi_dst.size() != fi_src.size()))
                            {
                                bool success = false;

                                if (QStorageInfo(fi_src.dir()).rootPath() == QStorageInfo(fi_dst.dir()).rootPath())
                                {
                                    // Source and dest are on the same filesystem
                                    // attempting a simple rename instead of copy

                                    success = QFile::rename(file.filesystemPath, destFile);
                                    if (success)
                                    {
                                        //qDebug() << "RENAMED: " << destFile;
                                        stuff_done += fi_src.size();
                                        emit fileProduced(destFile);
                                    }
                                    else
                                    {
                                        // TODO handle errors
                                        qWarning() << "Couldn't rename file: " << destFile;
                                    }
                                }

                                if (!success)
                                {
                                    success = QFile::copy(file.filesystemPath, destFile);
                                    if (success)
                                    {
                                        //qDebug() << "COPIED: " << destFile;
                                        stuff_done += fi_src.size();
                                        emit fileProduced(destFile);
                                    }
                                    else
                                    {
                                        // TODO handle errors
                                        qWarning() << "Couldn't copy file: " << destFile;
                                    }
                                }

                                if (!success) element_status = 0;
                            }
                            else
                            {
                                //qDebug() << "No need to copy file: " << destFile;
                                stuff_done += fi_src.size();
                                element_status = 0;
                            }
                        }
#ifdef ENABLE_LIBMTP
                        else if (file.mtpDevice && file.mtpObjectId)
                        {
                            //qDebug() << "JobWorkerThread  >  MTP copying:" << file->mtpObjectId;
                            //qDebug() << "       to  > " << element->destination_dir;

                            QString destFile = element->destination_dir + file.name + "." + file.extension;
                            QFileInfo fi_dst(destFile);

                            if (!fi_dst.exists() ||
                                (fi_dst.exists() && fi_dst.size() != static_cast<qint64>(file.size)))
                            {
                                int err = LIBMTP_Get_File_To_File(file.mtpDevice, file.mtpObjectId, destFile.toLocal8Bit(), nullptr, nullptr);
                                if (err)
                                {
                                    // TODO handle errors
                                    qDebug() << "Couldn't copy file: " << destFile;
                                }
                                else
                                {
                                    //qDebug() << "COPIED: " << destFile;
                                    stuff_done += file.size;
                                    emit fileProduced(destFile);
                                }
                            }
                            else
                            {
                                qDebug() << "No need to copy file: " << destFile;
                                stuff_done += file.size;
                            }
                        }
#endif // ENABLE_LIBMTP
                    }

                    progress = (stuff_done / static_cast<float>(current_job->getFilesSize())) * 100.f;
                    //qDebug() << "progress: " << progress << "(" << current_job->totalSize << "/" << stuff_done << ")";
                }

                // HANDLE DELETION /////////////////////////////////////////////

                if (current_job->getType() == JobUtils::JOB_DELETE)
                {
                    for (auto const &file: element->files)
                    {
                        // TODO check if device is RO?

                        if (!file.filesystemPath.isEmpty())
                        {
                            //qDebug() << "JobWorkerThread  >  deleting:" << file.filesystemPath;

                            bool status = false;
#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
                            if (current_job->settings_delete.moveToTrash)
                                status = QFile::moveToTrash(file.filesystemPath); // Qt 5.15
                            else
#endif
                                status = QFile::remove(file.filesystemPath);

                            if (status)
                            {
                                stuff_done++;
                            }
                            else
                            {
                                // TODO handle errors
                                qDebug() << "Couldn't delete file: " << file.filesystemPath;
                            }
                        }
#ifdef ENABLE_LIBMTP
                        else if (file.mtpDevice && file.mtpObjectId)
                        {
                            //qDebug() << "JobWorkerThread  >  deleting:" << file.name;

                            int err = LIBMTP_Delete_Object(file.mtpDevice, file.mtpObjectId);
                            if (err)
                            {
                                // TODO handle errors
                                qDebug() << "Couldn't delete file: " << file.name;
                            }
                            else
                            {
                                stuff_done++;
                            }
                        }
#endif // ENABLE_LIBMTP
                    }

                    progress = ((stuff_done) / static_cast<float>(current_job->getFilesCount())) * 100.f;
                    //qDebug() << "progress: " << progress << "(" << current_job->totalFiles << "/" << stuff_done << ")";
                }

                // Status

                emit shotFinished(current_job->getId(), element_status, element->parent_shot);
                emit jobProgress(current_job->getId(), progress);
            }

            emit jobFinished(current_job->getId(), JobUtils::JOB_STATE_DONE);
        }
        m_jobsMutex.lock();
    }

    m_working = false;
    m_jobsMutex.unlock();

    qDebug() << "<< JobWorkerThread::work()";
}

/* ************************************************************************** */

void JobWorkerThread::work_telemetry(JobElement *element, JobSettingsTelemetry *settings)
{
    if (element->parent_shot)
    {
        element->parent_shot->parseTelemetry();

        if (!settings->gps_format.isEmpty())
        {
            element->parent_shot->exportGps(element->destination_dir, 0,
                                            settings->gps_frequency,
                                            settings->EGM96);
        }
        if (!settings->telemetry_format.isEmpty())
        {
            element->parent_shot->exportTelemetry(element->destination_dir, 0,
                                                  settings->telemetry_frequency,
                                                  settings->gps_frequency,
                                                  settings->EGM96);
        }
    }
}

void JobWorkerThread::work_offload()
{
    //
}

void JobWorkerThread::work_delete()
{
    //
}

/* ************************************************************************** */
