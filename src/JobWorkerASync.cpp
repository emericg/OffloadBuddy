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

#include "JobWorkerASync.h"
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

JobWorkerASync::JobWorkerASync()
{
    //
}

JobWorkerASync::~JobWorkerASync()
{
    while (!m_jobs.isEmpty())
    {
        JobTracker *job = m_jobs.dequeue();
        delete job;
    }

    abortWork();
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerASync::playPauseWork()
{
    qDebug() << ">> JobWorkerASync::playPauseWork()";
}

/* ************************************************************************** */

void JobWorkerASync::abortWork()
{
    qDebug() << ">> JobWorkerASync::abortWork()";

    if (m_jobCurrent->getType() == JobUtils::JOB_FIRMWARE_UPDATE)
    {
        if (m_jobCurrent->getDevice())
        {
            FirmwareManager *fwm = FirmwareManager::getInstance();
            if (fwm)
            {
                fwm->stopUpgrade(m_jobCurrent->getDevice());
            }
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

bool JobWorkerASync::isWorking()
{
    return (m_jobCurrent);
}

int JobWorkerASync::getCurrentJobId()
{
    if (m_jobCurrent)
    {
        return m_jobCurrent->getId();
    }

    return -1;
}

void JobWorkerASync::queueWork(JobTracker *job)
{
    qDebug() << ">> JobWorkerASync::queueWork()";

    m_jobs.enqueue(job);

    qDebug() << "<< JobWorkerASync::queueWork()";
}

/* ************************************************************************** */

void JobWorkerASync::work()
{
    if (m_jobCurrent == nullptr && !m_jobs.isEmpty())
    {
        qDebug() << ">> JobWorkerASync::work()";

        m_jobCurrent = m_jobs.dequeue();
        if (m_jobCurrent)
        {
            // HANDLE FIRMWARE UPDATE //////////////////////////////////////////

            if (m_jobCurrent->getType() == JobUtils::JOB_FIRMWARE_UPDATE)
            {
                if (m_jobCurrent->getDevice())
                {
                    FirmwareManager *fwm = FirmwareManager::getInstance();
                    if (fwm)
                    {
                        connect(fwm, SIGNAL(fwDlProgress(float)), this, SLOT(asyncJobProgress(float)));
                        connect(fwm, SIGNAL(fwUpgradeErrored()), this, SLOT(asyncJobFinished()));
                        connect(fwm, SIGNAL(fwUpgradeFinished()), this, SLOT(asyncJobFinished()));

                        fwm->startUpgrade(m_jobCurrent->getDevice());
                    }
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
            emit jobStarted(m_jobCurrent->getId());
        }

        qDebug() << "<< JobWorkerASync::work()";
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerASync::asyncJobStarted()
{
    //qDebug() << "JobWorkerASync::asyncJobStarted()";

    if (m_jobCurrent)
    {
        emit jobStarted(m_jobCurrent->getId());
    }
}

void JobWorkerASync::asyncJobFinished()
{
    //qDebug() << "JobWorkerASync::asyncJobFinished()";

    if (m_jobCurrent)
    {
        emit jobFinished(m_jobCurrent->getId(), JobUtils::JOB_STATE_DONE);
        delete m_jobCurrent;
        m_jobCurrent = nullptr;
    }

    work(); // next job?
}

/* ************************************************************************** */

void JobWorkerASync::asyncJobProgress(float progress)
{
    //qDebug() << "JobWorkerASync::asyncJobProgress(" << progress << ")";

    if (m_jobCurrent)
    {
        emit jobProgress(m_jobCurrent->getId(), progress);
    }
}

/* ************************************************************************** */
