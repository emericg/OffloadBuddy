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
 * \date      2021
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "Job.h"

#include <QUrl>
#include <QFileInfo>
#include <QDesktopServices>

/* ************************************************************************** */

JobTracker::JobTracker(int job_id, int job_type, QObject *parent) : QObject(parent)
{
    m_id = job_id;
    m_type = static_cast<JobUtils::JobType>(job_type);
}

JobTracker::~JobTracker()
{
    //
}

/* ************************************************************************** */

QString JobTracker::getTypeString() const
{
    if (m_type == JobUtils::JOB_FORMAT) return tr("FORMAT");
    else if (m_type == JobUtils::JOB_DELETE) return tr("DELETION");
    else if (m_type == JobUtils::JOB_OFFLOAD) return tr("OFFLOADING");
    else if (m_type == JobUtils::JOB_MOVE) return tr("MOVE");
    else if (m_type == JobUtils::JOB_CLIP) return tr("CLIP");
    else if (m_type == JobUtils::JOB_ENCODE) return tr("ENCODING");
    else if (m_type == JobUtils::JOB_TELEMETRY) return tr("TELEMETRY EXTRACTION");
    else if (m_type == JobUtils::JOB_FIRMWARE_DOWNLOAD) return tr("DOWNLOADING");
    else if (m_type == JobUtils::JOB_FIRMWARE_UPLOAD) return tr("FIRMWARE");
    else return tr("UNKNOWN");
}

QString JobTracker::getStateString() const
{
    if (m_state == JobUtils::JOB_STATE_QUEUED) return tr("QUEUED");
    else if (m_state == JobUtils::JOB_STATE_WORKING) return tr("WORKING");
    else if (m_state == JobUtils::JOB_STATE_PAUSED) return tr("PAUSED");
    else if (m_state == JobUtils::JOB_STATE_DONE) return tr("DONE");
    else if (m_state == JobUtils::JOB_STATE_ERRORED) return tr("ERRORED");
    else if (m_state == JobUtils::JOB_STATE_ABORTED) return tr("ABORTED");
    else return tr("UNKNOWN");
}

/* ************************************************************************** */

void JobTracker::openDestination() const
{
    QFileInfo d(m_destination);
    if (!m_destination.isEmpty() && d.exists())
    {
        QDesktopServices::openUrl(QUrl::fromLocalFile(m_destination));
    }
}
/* ************************************************************************** */
