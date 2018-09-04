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

#include "JobWorkerAsync.h"
#include "SettingsManager.h"

#include <QFileInfo>
#include <QFile>
#include <QDir>
#include <QMutexLocker>

#include <QDebug>

/* ************************************************************************** */

JobWorkerAsync::JobWorkerAsync()
{
    //
}

JobWorkerAsync::~JobWorkerAsync()
{
    jobAbort();
}

/* ************************************************************************** */

void JobWorkerAsync::jobAbort()
{
    if (m_childProcess)
    {
        m_childProcess->kill();
    }
}

void JobWorkerAsync::queueWork(Job *job)
{
    qDebug() << ">> queueWork()";

    QMutexLocker locker(& m_jobsMutex);
    m_jobs.enqueue(job);

    qDebug() << "<< queueWork()";
}

void JobWorkerAsync::work()
{
    qDebug() << "> JobSuperWorker::work()";

    m_jobsMutex.lock();
    while (!m_jobs.isEmpty())
    {
        m_current_job = m_jobs.dequeue();
        m_working = true;
        m_jobsMutex.unlock();

        if (m_current_job)
        {
            qDebug() << "> input file:" << m_current_job->elements.front()->files.front().filesystemPath;
            qDebug() << "> ouput file:" << m_current_job->elements.front()->destination_dir + m_current_job->elements.front()->files.front().name + "_reencoded.mp4";
        }
    }

    // FFMPEG binary
    QString program = "ffmpeg";
#ifdef Q_OS_WINDOWS
    {
        program = QDir::currentPath() + "/ffmpeg.exe";
    }
#endif

    // FFMPEG arguments
    QStringList arguments;
    arguments << "-y" /*<< "-loglevel" << "warning" << "-stats"*/;
    arguments << "-i" << m_current_job->elements.front()->files.front().filesystemPath;

    // H.264 video
    arguments << "-c:v" << "libx264";
    arguments << "-preset" << "slower" << "-tune" << "film";
    arguments << "-crf" << "24";
    // AAC audio copy
    arguments << "-c:a" << "copy";
/*
    // H.265 video
    arguments << "-c:v" << "libx265";
    arguments << "-crf" << "28" << "-preset" << "slow";
    // AAC audio copy
    arguments << "-c:a" << "copy";
*/
/*
    // VP9 video
    arguments << "-c:v" << "libvpx-vp9";
    arguments <<"-crf" << "40" << "-b:v" << "0" <<"-cpu-used" << "2";
    // Opus audio
    arguments << "-c:a" << "libopus";
    arguments << "-b:a" << "70K";
*/
    arguments << m_current_job->elements.front()->destination_dir + m_current_job->elements.front()->files.front().name + "_reencoded.mkv";

    if (m_childProcess == nullptr)
    {
        m_childProcess = new QProcess();
        connect(m_childProcess, SIGNAL(started()), this, SLOT(processStarted()));
        connect(m_childProcess, SIGNAL(finished(int)), this, SLOT(processFinished()));
        connect(m_childProcess, &QProcess::readyReadStandardOutput, this, &JobWorkerAsync::processOutput);
        connect(m_childProcess, &QProcess::readyReadStandardError, this, &JobWorkerAsync::processOutput);
        m_childProcess->start(program, arguments);
    }
}
/* ************************************************************************** */

void JobWorkerAsync::processStarted()
{
    qDebug() << "JobSuperWorker::processStarted()";
    emit jobStarted(m_current_job->id);
    emit shotStarted(m_current_job->id, m_current_job->elements.front()->parent_shots);
}

void JobWorkerAsync::processFinished()
{
    qDebug() << "JobSuperWorker::processFinished()";
    emit shotFinished(m_current_job->id, m_current_job->elements.front()->parent_shots);
    emit jobFinished(m_current_job->id, JOB_STATE_DONE);

    delete m_childProcess;
    m_childProcess = nullptr;
}

void JobWorkerAsync::processOutput()
{
    m_childProcess->waitForBytesWritten(1000);
    QString txt(m_childProcess->readAllStandardError());

    //qDebug() << "JobSuperWorker::processOutput(1)" << txt;
    //qDebug() << txt;

    if (m_duration.isNull())
    {
        if (txt.contains("Duration: "))
        {
            QString duration_qstr = txt.mid(txt.indexOf("Duration: ") + 10, 11);
            m_duration = QTime::fromString(duration_qstr, "hh:mm:ss.z");

            //qDebug() << "> duration (qstr:" << duration_qstr << ") [qtime:" << m_duration;
        }
    }
    else
    {
        if (txt.contains("time="))
        {
            QString progress_qstr = txt.mid(txt.indexOf("time=") + 5, 11);
            m_progress = QTime::fromString(progress_qstr, "hh:mm:ss.z");
            //qDebug() << "- progress (qstr:" << progress_qstr << ") [qtime:" << m_progress;
        }
    }

    if (m_duration.isValid() && m_progress.isValid())
    {
        float progress = QTime(0, 0, 0).msecsTo(m_progress) / static_cast<float>(QTime(0, 0, 0).msecsTo(m_duration));
        progress *= 100.f;

        //qDebug() << "- PROGRESS:" << progress;
        emit jobProgress(m_current_job->id, progress);
    }
}

/* ************************************************************************** */
