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
#include <QQueue>

class QProcess;
class Shot;
struct Job;

/* ************************************************************************** */

typedef struct commandWrapper
{
    Job *job = nullptr;
    unsigned job_element_index = -1;

    QString destFile;

    QString command;
    QStringList arguments;

} commandWrapper;

/*!
 * \brief The JobWorkerAsync class
 * Run async job and report progress
 */
class JobWorkerAsync: public QObject
{
    Q_OBJECT

    QQueue <commandWrapper *> m_ffmpegjobs;
    commandWrapper *m_ffmpegcurrent = nullptr;

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

    void work();

public slots:
    void queueWork(Job *job);

    void jobPlayPause();
    void jobAbort();

signals:
    void jobStarted(int);
    void jobProgress(int, float);
    void jobFinished(int, int);

    void jobAborted();
    void jobErrored();

    void shotStarted(int, Shot *);
    void shotFinished(int, Shot *);

    void fileProduced(QString);
};

/* ************************************************************************** */
#endif // JOB_WORKER_ASYNC_H
