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

#ifndef JOB_UTILS_H
#define JOB_UTILS_H
/* ************************************************************************** */

#include <QObject>
#include <QMetaType>
#include <QQmlApplicationEngine>

class JobUtils: public QObject
{
    Q_OBJECT

public:
    static void registerQML()
    {
        qRegisterMetaType<JobUtils::JobType>("JobUtils::JobType");
        qRegisterMetaType<JobUtils::JobState>("JobUtils::JobState");

        qmlRegisterType<JobUtils>("JobUtils", 1, 0, "JobUtils");
    }

    enum JobType
    {
        JOB_INVALID = 0,

        JOB_OFFLOAD,
        JOB_MOVE,
        JOB_MERGE,

        JOB_CLIP,
        JOB_ENCODE,
        JOB_TELEMETRY,

        JOB_FIRMWARE_DOWNLOAD,
        JOB_FIRMWARE_UPLOAD,

        JOB_DELETE,
        JOB_FORMAT
    };
    Q_ENUM(JobType)

    enum JobState
    {
        JOB_STATE_QUEUED = 0,
        JOB_STATE_WORKING,
        JOB_STATE_PAUSED,

        JOB_STATE_DONE = 8,
        JOB_STATE_ERRORED,
        JOB_STATE_ABORTED
    };
    Q_ENUM(JobState)
};

/* ************************************************************************** */
#endif // JOB_UTILS_H
