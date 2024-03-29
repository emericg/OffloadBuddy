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

#ifndef JOB_WORKER_SYNC_H
#define JOB_WORKER_SYNC_H
/* ************************************************************************** */

#include <QObject>
#include <QQueue>
#include <QMutex>

class QThread;
class Shot;
class JobTracker;

/* ************************************************************************** */

/*!
 * \brief The JobWorkerASync class
 */
class JobWorkerASync: public QObject
{
    Q_OBJECT

    QQueue <JobTracker *> m_jobs;
    JobTracker *m_jobCurrent = nullptr;

private slots:
    void asyncJobStarted();
    void asyncJobFinished();
    void asyncJobProgress(float);

public:
    JobWorkerASync();
    ~JobWorkerASync();

    void work();
    bool isWorking();
    int getCurrentJobId();

public slots:
    void queueWork(JobTracker *job);
    void playPauseWork();
    void abortWork();

signals:
    void jobStarted(int);
    void jobProgress(int, float);
    void jobFinished(int, int);
    void jobAborted(int, int);
    void jobErrored(int, int);

    void shotStarted(int, Shot *);
    void shotFinished(int, int, Shot *);
    void shotErrored(int, int, Shot *);

    void fileProduced(QString);
};

/* ************************************************************************** */
#endif // JOB_WORKER_SYNC_H
