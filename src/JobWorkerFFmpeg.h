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

#ifndef JOB_WORKER_ASYNC_H
#define JOB_WORKER_ASYNC_H
/* ************************************************************************** */

#include <QObject>
#include <QString>
#include <QTime>
#include <QTemporaryFile>

#include <QQueue>

class QProcess;
class Shot;
class JobTracker;

/* ************************************************************************** */

typedef struct CommandWrapper
{
    JobTracker *job = nullptr;
    int job_element_index = -1;

    QTemporaryFile mergeFile;
    QString destFile;

    QString command;
    QStringList arguments;

} CommandWrapper;

/* ************************************************************************** */

/*!
 * \brief The JobWorkerFFmpeg class
 */
class JobWorkerFFmpeg: public QObject
{
    Q_OBJECT

    QQueue <CommandWrapper *> m_ffmpegJobs;
    CommandWrapper *m_ffmpegCurrent = nullptr;

    QProcess *m_childProcess = nullptr;

    QTime m_duration;
    QTime m_progress;

    int m_duration_frame = 0;
    int m_progress_frame = 0;

    void queueWork_encode(JobTracker *job);
    void queueWork_merge(JobTracker *job);

private slots:
    void processStarted();
    void processFinished();
    void processOutput();

public:
    JobWorkerFFmpeg();
    ~JobWorkerFFmpeg();

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
#endif // JOB_WORKER_ASYNC_H
