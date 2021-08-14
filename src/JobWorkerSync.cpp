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

JobWorkerSync::JobWorkerSync()
{
    //
}

JobWorkerSync::~JobWorkerSync()
{
    if (m_thread) m_thread->terminate();
}

/* ************************************************************************** */
/* ************************************************************************** */

bool JobWorkerSync::start()
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

bool JobWorkerSync::stop()
{
    if (m_thread) m_thread->terminate();
    return true;
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerSync::queueWork(JobTracker *job)
{
    qDebug() << ">> JobWorkerSync::queueWork()";

    QMutexLocker locker(&m_jobsMutex);
    m_jobs.enqueue(job);

    qDebug() << "<< JobWorkerSync::queueWork()";
}

bool JobWorkerSync::isWorking()
{
    qDebug() << ">> JobWorkerSync::isWorking()";

    QMutexLocker locker(&m_jobsMutex);
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
        JobTracker *current_job = m_jobs.dequeue();
        m_working = true;
        m_jobsMutex.unlock();

        if (current_job)
        {
            emit jobStarted(current_job->getId());
            int index = -1;

            // HANDLE FIRMWARE UPDATE //////////////////////////////////////////

            if (current_job->getDevice())
            {
                FirmwareManager *fwm = FirmwareManager::getInstance();
                if (fwm)
                {
                    fwm->downloadFirmware(current_job->getDevice());
                }
            }
/*
            for (auto element: current_job->getElements())
            {
                emit shotStarted(current_job->getId(), element->parent_shot);
                int element_status = 1;

                index++;
                current_job->setElementsIndex(index);

                // HANDLE SHOTS ////////////////////////////////////////////////

                // TODO // so far we have no need for sync jobs on shots

                // Status

                emit shotFinished(current_job->getId(), element_status, element->parent_shot);
                emit jobProgress(current_job->getId(), progress);
            }
*/
            emit jobFinished(current_job->getId(), JobUtils::JOB_STATE_DONE);
        }
        m_jobsMutex.lock();
    }

    m_working = false;
    m_jobsMutex.unlock();

    qDebug() << "<< JobWorkerSync::work()";
}

/* ************************************************************************** */
