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

#ifndef JOB_SUPER_WORKER_H
#define JOB_SUPER_WORKER_H
/* ************************************************************************** */

#include "Shot.h"
#include "JobWorkerSync.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QObject>
#include <QString>
#include <QQueue>

#include <QProcess>
#include <QThread>
#include <QMutex>

/* ************************************************************************** */

/*!
 * \brief The JobWorkerAsync class
 * Run async job and report progress
 */
class JobWorkerAsync: public QObject
{
    Q_OBJECT

    bool m_working = false;
    QQueue <Job *> m_jobs;
    QMutex m_jobsMutex;
    Job *m_current_job = nullptr;

    QProcess *m_childProcess = nullptr;

    QTime m_duration;
    QTime m_progress;

private slots:
    void processStarted();
    void processFinished();
    void processOutput();

public:
    JobWorkerAsync();
    ~JobWorkerAsync();

    void queueWork(Job *job);
    void work();

public slots:
    void jobAbort();

signals:
    void jobStarted(int);
    void jobProgress(int, float);
    void jobFinished(int, int);

    void jobAborted();
    void jobErrored();

    void shotStarted(int, Shot *);
    void shotFinished(int, Shot *);
};

/* ************************************************************************** */
#endif // JOB_SUPER_WORKER_H
