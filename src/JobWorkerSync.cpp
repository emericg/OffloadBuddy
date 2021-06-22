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

#include "JobWorkerSync.h"
#include "JobManager.h"
#include "SettingsManager.h"
#include "Shot.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QFileInfo>
#include <QFile>
#include <QThread>
#include <QMutexLocker>
#include <QDebug>

/* ************************************************************************** */

JobWorkerSync::JobWorkerSync()
{
    //
}

JobWorkerSync::~JobWorkerSync()
{
    delete thread;
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerSync::queueWork(Job *job)
{
    qDebug() << ">> JobWorkerSync::queueWork()";

    QMutexLocker locker(& m_jobsMutex);
    m_jobs.enqueue(job);

    qDebug() << "<< JobWorkerSync::queueWork()";
}

bool JobWorkerSync::isWorking()
{
    qDebug() << ">> JobWorkerSync::isWorking()";

    QMutexLocker locker(& m_jobsMutex);
    return m_working;
}


void JobWorkerSync::work()
{
    qDebug() << ">> JobWorkerSync::work()";

    float progress = 0.f;
    int64_t stuff_done = 0;

    m_jobsMutex.lock();
    while (!m_jobs.isEmpty())
    {
        Job *current_job = m_jobs.dequeue();
        m_working = true;
        m_jobsMutex.unlock();

        if (current_job)
        {
            emit jobStarted(current_job->id);

            for (auto element: current_job->elements)
            {
                emit shotStarted(current_job->id, element->parent_shots);

                // HANDLE DELETION /////////////////////////////////////////////
                if (current_job->type == JOB_DELETE)
                {
                    for (auto const &file: element->files)
                    {
                        // TODO check if device is RO?

                        if (!file.filesystemPath.isEmpty())
                        {
                            //qDebug() << "JobWorkerSync  >  deleting:" << file.filesystemPath;

                            //if (QFile::moveToTrash(file.filesystemPath)) // Qt 5.15
                            if (QFile::remove(file.filesystemPath))
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
                            //qDebug() << "JobWorkerSync  >  deleting:" << file.name;

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

                    progress = ((stuff_done) / static_cast<float>(current_job->totalFiles)) * 100.f;
                    //qDebug() << "progress: " << progress << "(" << current_job->totalFiles << "/" << stuff_done << ")";
                }

                // HANDLE COPY /////////////////////////////////////////////////
                if (current_job->type == JOB_COPY)
                {
                    for (auto const &file: element->files)
                    {
                        if (!file.filesystemPath.isEmpty())
                        {
                            //qDebug() << "JobWorkerSync  >  FS copying:" << file->filesystemPath;
                            //qDebug() << "       to  > " << element->destination_dir;

                            QFileInfo fi_src(file.filesystemPath);
                            QString destFile = element->destination_dir + fi_src.baseName() + "." + fi_src.suffix();
                            QFileInfo fi_dst(destFile);

                            if (!fi_dst.exists() ||
                                (fi_dst.exists() && fi_dst.size() != fi_src.size()))
                            {
                                bool success = QFile::copy(file.filesystemPath, destFile);
                                if (success)
                                {
                                    //qDebug() << "COPIED: " << destFile;
                                    stuff_done += fi_src.size();

                                    emit fileProduced(destFile);
                                }
                                else
                                {
                                    // TODO handle errors
                                    qDebug() << "Couldn't copy file: " << destFile;
                                }
                            }
                            else
                            {
                                //qDebug() << "No need to copy file: " << destFile;
                                stuff_done += fi_src.size();
                            }
                        }
#ifdef ENABLE_LIBMTP
                        else if (file.mtpDevice && file.mtpObjectId)
                        {
                            //qDebug() << "JobWorkerSync  >  MTP copying:" << file->mtpObjectId;
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

                    progress = ((stuff_done) / static_cast<float>(current_job->totalSize)) * 100.f;
                    //qDebug() << "progress: " << progress << "(" << current_job->totalSize << "/" << stuff_done << ")";
                }

                emit shotFinished(current_job->id, element->parent_shots);
                emit jobProgress(current_job->id, progress);
            }

            emit jobFinished(current_job->id, JOB_STATE_DONE);
            delete current_job;
        }
        m_jobsMutex.lock();
    }

    m_working = false;
    m_jobsMutex.unlock();

    qDebug() << "<< JobWorkerSync::work()";
}

/* ************************************************************************** */
