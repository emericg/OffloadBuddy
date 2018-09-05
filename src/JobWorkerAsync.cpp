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
#include <QDebug>

#ifdef Q_OS_LINUX
#include <signal.h>
#endif

/* ************************************************************************** */

JobWorkerAsync::JobWorkerAsync()
{
    //
}

JobWorkerAsync::~JobWorkerAsync()
{
    do {
        commandWrapper *wrap = m_ffmpegjobs.dequeue();
        delete wrap;
    } while (!m_ffmpegjobs.isEmpty());

    jobAbort();
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerAsync::jobPlayPause()
{
    if (m_childProcess)
    {
#ifdef Q_OS_LINUX
        //kill(m_childProcess->pid(), SIGSTOP); // suspend
        //kill(m_childProcess->pid(), SIGCONT); // resume
#endif
    }
}

void JobWorkerAsync::jobAbort()
{
    if (m_childProcess)
    {
        //m_childProcess->write("q\n");
        //if (!m_childProcess->waitForFinished(4000))
        {
            m_childProcess->kill();
            if (!m_childProcess->waitForFinished(4000))
            {
                qDebug() << "jobAbort() current process won't die...";
            }
        }
    }
}

/* ************************************************************************** */

void JobWorkerAsync::queueWork(Job *job)
{
    if (job)
    {
        for (unsigned i = 0; i < job->elements.size(); i++)
        {
            JobElement *element = job->elements.at(i);
            if (element->files.size() != 1)
            {
                qDebug() << "This async job element got more (or less actually) than 1 file, it should not happen...";
                continue;
            }

            commandWrapper *ptiwrap = new commandWrapper;

            ptiwrap->job = job;
            ptiwrap->job_element_index = i;

            // FFMPEG binary
            ptiwrap->command = "ffmpeg";
#ifdef Q_OS_WINDOWS
            ptiwrap->command = QDir::currentPath() + "/ffmpeg.exe";
#endif
            // FFMPEG arguments
            ptiwrap->arguments << "-y" /*<< "-loglevel" << "warning" << "-stats"*/;
            ptiwrap->arguments << "-i" << element->files.at(0).filesystemPath;

            // H.264 video
            ptiwrap->arguments << "-c:v" << "libx264";
            ptiwrap->arguments << "-preset" << "slower" << "-tune" << "film";
            ptiwrap->arguments << "-crf" << "24";
            // AAC audio copy
            ptiwrap->arguments << "-c:a" << "copy";
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
            ptiwrap->arguments << element->destination_dir + element->files.front().name + "_reencoded.mkv";

            m_ffmpegjobs.push_front(ptiwrap);
        }
    }
}

void JobWorkerAsync::work()
{
    if (m_childProcess == nullptr)
    {
        qDebug() << "> JobSuperWorker::work()";

        if (!m_ffmpegjobs.isEmpty())
        {
            m_ffmpegcurrent = m_ffmpegjobs.dequeue();
            if (m_ffmpegcurrent)
            {
                m_childProcess = new QProcess();
                connect(m_childProcess, SIGNAL(started()), this, SLOT(processStarted()));
                connect(m_childProcess, SIGNAL(finished(int)), this, SLOT(processFinished()));
                connect(m_childProcess, &QProcess::readyReadStandardOutput, this, &JobWorkerAsync::processOutput);
                connect(m_childProcess, &QProcess::readyReadStandardError, this, &JobWorkerAsync::processOutput);

                m_childProcess->start(m_ffmpegcurrent->command, m_ffmpegcurrent->arguments);
            }
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerAsync::processStarted()
{
    if (m_childProcess && m_ffmpegcurrent)
    {
        qDebug() << "JobSuperWorker::processStarted()";

        emit jobStarted(m_ffmpegcurrent->job->id);
        emit shotStarted(m_ffmpegcurrent->job->id, m_ffmpegcurrent->job->elements.at(m_ffmpegcurrent->job_element_index)->parent_shots);
    }
}

void JobWorkerAsync::processFinished()
{
    if (m_childProcess && m_ffmpegcurrent)
    {
        qDebug() << "JobSuperWorker::processFinished()";

        JobState js = JOB_STATE_DONE;
        if (m_childProcess->exitStatus() == QProcess::CrashExit)
            js = JOB_STATE_ERRORED;

        if (m_ffmpegcurrent->job &&
            m_ffmpegcurrent->job->elements.size() > m_ffmpegcurrent->job_element_index)
        {
            emit shotFinished(m_ffmpegcurrent->job->id, m_ffmpegcurrent->job->elements.at(m_ffmpegcurrent->job_element_index)->parent_shots);
            emit jobFinished(m_ffmpegcurrent->job->id, js);
        }

        delete m_childProcess;
        m_childProcess = nullptr;
        m_duration = QTime();
        m_progress = QTime();

        delete m_ffmpegcurrent;
        m_ffmpegcurrent = nullptr;
    }

    work();
}

void JobWorkerAsync::processOutput()
{
    if (m_childProcess)
    {
        m_childProcess->waitForBytesWritten(500);
        QString txt(m_childProcess->readAllStandardError());

        //qDebug() << "JobSuperWorker::processOutput()" << txt;

        if (m_duration.isNull() || !m_duration.isValid())
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
            emit jobProgress(m_ffmpegcurrent->job->id, progress);
        }
    }
}

/* ************************************************************************** */
