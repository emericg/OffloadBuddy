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

#include "JobWorkerAsync.h"
#include "JobManager.h"
#include "Shot.h"
#include "utils/utils_app.h"

#include <QProcess>
#include <QFileInfo>
#include <QFile>
#include <QDir>
#include <QDebug>

#ifdef Q_OS_LINUX
#include <signal.h>
#endif

/* ************************************************************************** */

QString getFFmpegDurationString(const int64_t duration_ms)
{
    QString duration_qstr;

    if (duration_ms > 0)
    {
        int64_t hours = duration_ms / 3600000;
        int64_t minutes = (duration_ms - (hours * 3600000)) / 60000;
        int64_t seconds = (duration_ms - (hours * 3600000) - (minutes * 60000)) / 1000;
        int64_t ms = (duration_ms - (hours * 3600000) - (minutes * 60000)) - (seconds * 1000);

        duration_qstr += QString::number(hours).rightJustified(2, '0');
        duration_qstr += ":";
        duration_qstr += QString::number(minutes).rightJustified(2, '0');
        duration_qstr += ":";
        duration_qstr += QString::number(seconds).rightJustified(2, '0');
        duration_qstr += ".";
        duration_qstr += QString::number(ms);
    }
    else
    {
        duration_qstr = "00:00:00";
    }

    //qDebug() << "getFFmpegDurationString(" << duration_ms << ") >" << duration_qstr;

    return duration_qstr;
}

QString getFFmpegDurationStringEscaped(const int64_t duration_ms)
{
    QString duration_qstr;

    if (duration_ms > 0)
    {
        int64_t hours = duration_ms / 3600000;
        int64_t minutes = (duration_ms - (hours * 3600000)) / 60000;
        int64_t seconds = (duration_ms - (hours * 3600000) - (minutes * 60000)) / 1000;
        int64_t ms = (duration_ms - (hours * 3600000) - (minutes * 60000)) - (seconds * 1000);

        duration_qstr += "'";
        duration_qstr += QString::number(hours).rightJustified(2, '0');
        duration_qstr += "\\:";
        duration_qstr += QString::number(minutes).rightJustified(2, '0');
        duration_qstr += "\\:";
        duration_qstr += QString::number(seconds).rightJustified(2, '0');
        duration_qstr += ".";
        duration_qstr += QString::number(ms);
        duration_qstr += "'";
    }
    else
    {
        duration_qstr = "'00\\:00\\:00'";
    }

    //qDebug() << "getFFmpegDurationStringEscaped(" << duration_ms << ") >" << duration_qstr;

    return duration_qstr;
}

/* ************************************************************************** */

JobWorkerAsync::JobWorkerAsync()
{
    //
}

JobWorkerAsync::~JobWorkerAsync()
{
    while (!m_ffmpegjobs.isEmpty())
    {
        commandWrapper *wrap = m_ffmpegjobs.dequeue();
        delete wrap;
    }

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
    qDebug() << ">> JobWorkerAsync::jobAbort()";

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
    qDebug() << ">> JobWorkerAsync::queueWork()";

    if (job)
    {
        for (unsigned i = 0; i < job->elements.size(); i++)
        {
            JobElement *element = job->elements.at(i);
            if (element->parent_shots->getShotType() <= Shared::SHOT_PICTURE &&
                element->files.size() != 1)
            {
                qDebug() << "This async job element got" << element->files.size() << "file(s), should not happen...";
                continue;
            }

            commandWrapper *ptiwrap = new commandWrapper;

            ptiwrap->job = job;
            ptiwrap->job_element_index = i;

            QString reencode_or_clipped = (job->settings.codec == "copy") ? "_clipped" : "_reencoded";
            QString file_extension = "mp4";
            QString video_filters;
            QString audio_filters;

            // ffmpeg binary ///////////////////////////////////////////////////

            UtilsApp *app = UtilsApp::getInstance();
            ptiwrap->command = app->getAppPath() + "/ffmpeg";
            // No ffmpeg bundled? Just try to use ffmpeg from the system...
            if (!QFileInfo::exists(ptiwrap->command)) ptiwrap->command = "ffmpeg";
#ifdef Q_OS_WIN
            // Windows?
            ptiwrap->command += ".exe";
#endif

            // ffmpeg arguments ////////////////////////////////////////////////

            ptiwrap->arguments << "-y";
            //ptiwrap->arguments << "-loglevel" << "warning" << "-stats";

            //// INPUTS

            if (element->parent_shots->getShotType() > Shared::SHOT_PICTURE)
            {
                // timelapse to video
                ptiwrap->arguments << "-r" << QString::number(job->settings.timelapse_fps);
                ptiwrap->arguments << "-start_number" << element->files.at(0).name.mid(1, -1);
                QString replacestr = "/" + element->files.at(0).name + "." + element->files.at(0).extension.toUpper();
                ptiwrap->arguments << "-i" << element->files.at(0).filesystemPath.replace(replacestr, "/G%07d.JPG");
            }
            else
            {
                ptiwrap->arguments << "-i" << element->files.at(0).filesystemPath;
            }

            //// CODECS

            if (job->settings.codec == "copy")
            {
                ptiwrap->arguments << "-codec" << "copy";
            }

            if (job->settings.codec == "H.264")
            {
                file_extension = "mp4";

                // H.264 video
                ptiwrap->arguments << "-c:v" << "libx264";

                if (job->settings.encoding_speed == 0)
                    ptiwrap->arguments << "-preset" << "faster";
                else if (job->settings.encoding_speed == 2)
                    ptiwrap->arguments << "-preset" << "slower";
                else
                    ptiwrap->arguments << "-preset" << "medium";

                ptiwrap->arguments << "-tune" << "film";

                // CRF scale range is 0–51
                // (0 is lossless, 23 is default, 51 is worst) // sane range is 17–28
                int crf = 21 - job->settings.encoding_quality;
                ptiwrap->arguments << "-crf" << QString::number(crf);

                // AAC audio copy
                ptiwrap->arguments << "-c:a" << "copy";
            }

            if (job->settings.codec == "H.265")
            {
                file_extension = "mp4";

                // H.265 video
                ptiwrap->arguments << "-c:v" << "libx265";

                if (job->settings.encoding_speed == 0)
                    ptiwrap->arguments << "-preset" << "faster";
                else if (job->settings.encoding_speed == 2)
                    ptiwrap->arguments << "-preset" << "slower";
                else
                    ptiwrap->arguments << "-preset" << "medium";

                int crf = 28 - job->settings.encoding_quality;
                ptiwrap->arguments << "-crf" << QString::number(crf);

                // AAC audio copy
                ptiwrap->arguments << "-c:a" << "copy";
            }

            if (job->settings.codec == "VP9")
            {
                file_extension = "mkv";

                // CRF scale range is 0–63
                // (0 is lossless, 23 is default, 63 is worst) // sane range is 15–35
                int crf = 35 - job->settings.encoding_quality;

                // VP9 video
                ptiwrap->arguments << "-c:v" << "libvpx-vp9";
                ptiwrap->arguments <<"-crf" << QString::number(crf) << "-b:v" << "0" <<"-cpu-used" << "2";
                // Opus audio
                ptiwrap->arguments << "-c:a" << "libopus";
                ptiwrap->arguments << "-b:a" << "70K";
            }

            if (job->settings.codec == "GIF")
            {
                file_extension = "gif";
            }

            if (job->settings.codec == "PNG")
            {
                file_extension = "png";
            }
            if (job->settings.codec == "JPEG")
            {
                file_extension = "jpg";

                int qscale = 5 - job->settings.encoding_quality;
                ptiwrap->arguments << "-q:v" << QString::number(qscale);
            }
            if (job->settings.codec == "WEBP")
            {
                file_extension = "webp";

                int qscale = 75 + (job->settings.encoding_quality * 4);
                ptiwrap->arguments << "-quality" << QString::number(qscale);
                ptiwrap->arguments << "-preset" << "photo";
                ptiwrap->arguments << "-compression_level" << QString::number(6);
            }

            //// PARAMS

            if (job->settings.codec == "GIF")
            {
                ptiwrap->arguments << "-r" << QString::number(job->settings.fps);

                // Using simple filter:
                //if (!video_filters.isEmpty()) video_filters += ",";
                //video_filters += "scale=-1:400:sws_dither=ed"; // sws_dither=[none,auto,bayer,ed,a_dither,x_dither]

                // Using complex filter
                video_filters = "[0:v]trim="+ getFFmpegDurationStringEscaped(job->settings.startMs) + ":" + getFFmpegDurationStringEscaped(job->settings.startMs + job->settings.durationMs) + ",setpts=PTS-STARTPTS[0v];";
                if (job->settings.gif_effect == "forwardbackward")
                {
                    video_filters += "[0v]crop=" + job->settings.crop + ",scale=" + job->settings.scale + ":sws_dither=ed,split=2[v1][2v];" \
                                     "[2v]reverse,fifo[v2];[v1][v2]concat=n=2:v=1[out]";
                }
                else if (job->settings.gif_effect == "backward")
                {
                    video_filters += "[0v]crop=" + job->settings.crop + ",scale=" + job->settings.scale + ":sws_dither=ed[2v];" \
                                     "[2v]reverse,fifo[out]";
                }
                else // forward
                {
                    video_filters += "[0v]crop=" + job->settings.crop + ",scale=" + job->settings.scale + ":sws_dither=ed[out]";
                }
                ptiwrap->arguments << "-filter_complex" << video_filters << "-map" << "[out]";
            }
            else
            {
                // Change output framerate
                if (job->settings.fps > 0 && job->settings.codec != "GIF")
                {
                    ptiwrap->arguments << "-r" << QString::number(job->settings.fps);
                }

                // Clip duration
                if (job->settings.durationMs > 0)
                {
                    ptiwrap->arguments << "-ss" << getFFmpegDurationString(job->settings.startMs);
                    ptiwrap->arguments << "-t" << getFFmpegDurationString(job->settings.durationMs);
                }

                // Filters
                {
                    // Transformations
                    if (job->settings.transform > 1)
                    {
                        // job->settings.transform
                        //1 = Horizontal (normal)
                        //2 = Mirror horizontal
                        //3 = Rotate 180
                        //4 = Mirror vertical
                        //5 = Mirror horizontal and rotate 270 CW
                        //6 = Rotate 90 CW
                        //7 = Mirror horizontal and rotate 90 CW
                        //8 = Rotate 270 CW

                        // ffmpeg transpose filter // http://ffmpeg.org/ffmpeg-all.html#transpose-1
                        //0 = 90CounterCLockwise and Vertical Flip (default)
                        //1 = 90Clockwise
                        //2 = 90CounterClockwise
                        //3 = 90Clockwise and Vertical Flip
                        //-vf "transpose=2,transpose=2" for 180 degrees.

                        // ffmpeg metadata
                        //-metadata:s:v rotate=""
                        //-noautorotate

                        QString rf = "";
                        if (job->settings.transform == 2)
                            rf = "hflip";
                        else if (job->settings.transform == 3)
                            rf = "transpose=2,transpose=2"; // 180°
                        else if (job->settings.transform == 4)
                            rf = "vflip";
                        else if (job->settings.transform == 5)
                            rf = "hflip,transpose=2";
                        else if (job->settings.transform == 6)
                            rf = "transpose=1"; // 90°
                        else if (job->settings.transform == 7)
                            rf = "hflip,transpose=1";
                        else if (job->settings.transform == 8)
                            rf = "transpose=2"; // 270°

                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += rf;
                    }

                    // Crop // -filter:v "crop=out_w:out_h:x:y"
                    if (!job->settings.crop.isEmpty())
                    {
                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += "crop=" + job->settings.crop;
                    }

                    // Scaling
                    if (!job->settings.scale.isEmpty())
                    {
                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += "scale=" + job->settings.scale;
                    }
                    if (job->settings.resolution > 0)
                    {
                        //if (!video_filters.isEmpty()) video_filters += ",";
                        //video_filters += "scale=" + QString::number(job->settings.resolution) + ":-1";
                    }

                    // Timelapse
                    if (job->settings.timelapse_fps > 0)
                    {
                        if (element->parent_shots->getShotType() < Shared::SHOT_PICTURE)
                        {
                            // video to video timelapse
                            if (!video_filters.isEmpty()) video_filters += ",";
                            video_filters += "select='not(mod(n," + QString::number(job->settings.timelapse_fps) + "))',setpts=N/FRAME_RATE/TB";
                            //video_filters += "setpts=" + QString::number(0.5) + "*PTS";

                            ptiwrap->arguments << "-r" << QString::number(job->settings.fps);
                        }
                        else
                        {
                            // timelapse to video timelapse
                            ptiwrap->arguments << "-r" << QString::number(job->settings.timelapse_fps);
                        }

                        ptiwrap->arguments << "-an";
                    }

                    // Defisheye filter
                    // HERO4? lenscorrection=k1=-0.6:k2=0.55
                    // ? lenscorrection=k1=-0.56:k2=0.3
                    //ptiwrap->arguments << "-vf" << "lenscorrection=k1=-0.6:k2=0.55";

                    // Apply filters
                    if (!video_filters.isEmpty()) ptiwrap->arguments << "-vf" << video_filters;
                    if (!audio_filters.isEmpty()) ptiwrap->arguments << "-af" << audio_filters;
                }
            }

            // Keep (some) metadata?
            ptiwrap->arguments << "-map_metadata" << "0";

            // Re-encoding
            ptiwrap->destFile = element->destination_dir + element->files.front().name + reencode_or_clipped + "." + file_extension;
            ptiwrap->arguments << ptiwrap->destFile;

            m_ffmpegjobs.push_back(ptiwrap);

            // Recap encoding arguments:
            qDebug() << "ENCODING JOB:";
            qDebug() << ">" << ptiwrap->command;
            qDebug() << ">" << ptiwrap->arguments;
        }
/*
        // Recap settings:
        qDebug() << "ENCODING SETTINGS:";
        qDebug() << "* codec:" << job->settings.codec;
        qDebug() << "* encoding quality:" << job->settings.encoding_quality;
        qDebug() << "* encoding speed:" << job->settings.encoding_speed;
        qDebug() << "* fps:" << job->settings.fps;
        qDebug() << "* resolution:" << job->settings.resolution;
        qDebug() << "* transform:" << job->settings.transform;
        qDebug() << "* scale:" << job->settings.scale;
        qDebug() << "* crop:" << job->settings.crop;
        qDebug() << "* start (ms)   :" << job->settings.startMs;
        qDebug() << "* duration (ms):" << job->settings.durationMs;
*/
    }

    qDebug() << ">> JobWorkerAsync::queueWork()";
}

void JobWorkerAsync::work()
{
    qDebug() << ">> JobWorkerAsync::work()";

    if (m_childProcess == nullptr)
    {
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

    qDebug() << "<< JobWorkerAsync::work()";
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerAsync::processStarted()
{
    if (m_childProcess && m_ffmpegcurrent)
    {
        qDebug() << "JobWorkerAsync::processStarted()";

        emit jobStarted(m_ffmpegcurrent->job->id);
        emit shotStarted(m_ffmpegcurrent->job->id, m_ffmpegcurrent->job->elements.at(m_ffmpegcurrent->job_element_index)->parent_shots);
    }
}

void JobWorkerAsync::processFinished()
{
    if (m_childProcess && m_ffmpegcurrent)
    {
        qDebug() << "JobWorkerAsync::processFinished()";

        JobState js = JOB_STATE_DONE;
        if (m_childProcess->exitStatus() == QProcess::CrashExit)
            js = JOB_STATE_ERRORED;

        if (m_ffmpegcurrent->job &&
            m_ffmpegcurrent->job->elements.size() > m_ffmpegcurrent->job_element_index)
        {
            emit fileProduced(m_ffmpegcurrent->destFile);
            emit shotFinished(m_ffmpegcurrent->job->id, m_ffmpegcurrent->job->elements.at(m_ffmpegcurrent->job_element_index)->parent_shots);
            emit jobFinished(m_ffmpegcurrent->job->id, js);
        }

        m_childProcess->waitForFinished();
        m_childProcess->deleteLater();
        //delete m_childProcess;
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
        m_childProcess->waitForBytesWritten(128);
        QString txt(m_childProcess->readAllStandardError());

        //qDebug() << "JobWorkerAsync::processOutput()" << txt;

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
