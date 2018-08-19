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

#ifndef JOB_WORKER_H
#define JOB_WORKER_H
/* ************************************************************************** */

#include "Shot.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QObject>
#include <QString>
#include <QQueue>
#include <QThread>
#include <QMutex>

/* ************************************************************************** */

typedef enum JobType
{
    JOB_INVALID = 0,

    JOB_METADATAS,

    JOB_FORMAT,
    JOB_DELETE,
    JOB_COPY,

    JOB_MERGE,
    JOB_CLIP,
    JOB_TIMELAPSE_TO_VIDEO,
    JOB_REENCODE,
    JOB_STAB,

    JOB_FIRMWARE_DOWNLOAD,
    JOB_FIRMWARE_UPLOAD,

} JobType;

typedef enum JobState
{
    JOB_STATE_QUEUED = 0,
    JOB_STATE_WORKING,
    JOB_STATE_PAUSED,

    JOB_STATE_DONE = 8,
    JOB_STATE_ERRORED

} JobState;

/* ************************************************************************** */

typedef struct JobElement
{
    Shot *parent_shots;
    QString destination_dir;

    std::list <ofb_file> files;

} JobElement;

typedef struct Job
{
    int id = -1;
    JobType type = JOB_INVALID;

    std::list<JobElement *> elements;

    JobState state = JOB_STATE_QUEUED;
    float percent = 0.0;
    int totalFiles = 0;
    int64_t totalSize = 0;

} Job;

/* ************************************************************************** */
/* ************************************************************************** */

class JobWorker: public QObject
{
    Q_OBJECT

    bool working = false;
    QQueue <Job *> m_jobs;
    QMutex m_jobsMutex;

public:
    JobWorker();
    ~JobWorker();

public slots:
    void queueWork(Job *job);
    void work();

signals:
    void jobProgress(int, float);
    void jobStarted(int);
    void jobFinished(int, int);

    void shotStarted(int, Shot *);
    void shotFinished(int, Shot *);
};

/* ************************************************************************** */
#endif // JOB_WORKER_H
