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

#include "JobWorkerFFmpeg.h"
#include "JobManager.h"
#include "Shot.h"
#include "utils_app.h"
#include "utils_maths.h"
#include "utils_screen.h"

#include <QProcess>
#include <QFileInfo>
#include <QImageReader>
#include <QFile>
#include <QDir>
#include <QDebug>

#if defined(Q_OS_LINUX) || defined(Q_OS_MACOS)
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
/* ************************************************************************** */

JobWorkerFFmpeg::JobWorkerFFmpeg()
{
    //
}

JobWorkerFFmpeg::~JobWorkerFFmpeg()
{
    while (!m_ffmpegJobs.isEmpty())
    {
        CommandWrapper *wrap = m_ffmpegJobs.dequeue();
        delete wrap;
    }

    abortWork();
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerFFmpeg::playPauseWork()
{
#if defined(Q_OS_LINUX) || defined(Q_OS_MACOS)

    if (m_childProcess && m_ffmpegCurrent && m_ffmpegCurrent->job)
    {
        qDebug() << ">> JobWorkerFFmpeg::playPauseWork()";

        if (m_ffmpegCurrent->job->getState() == JobUtils::JOB_STATE_WORKING)
        {
            kill(m_childProcess->processId(), SIGSTOP); // suspend
            m_ffmpegCurrent->job->setState(JobUtils::JOB_STATE_PAUSED);
        }
        else if (m_ffmpegCurrent->job->getState() == JobUtils::JOB_STATE_PAUSED)
        {
            kill(m_childProcess->processId(), SIGCONT); // resume
            m_ffmpegCurrent->job->setState(JobUtils::JOB_STATE_WORKING);
        }
    }

#endif // Q_OS_LINUX || Q_OS_MACOS
}

/* ************************************************************************** */

void JobWorkerFFmpeg::abortWork()
{
    qDebug() << ">> JobWorkerFFmpeg::abortWork()";

    if (m_childProcess)
    {
        m_childProcess->write("q\n");

        m_ffmpegCurrent->job->setState(JobUtils::JOB_STATE_ABORTED);

        if (!m_childProcess->waitForFinished(2000))
        {
            qDebug() << "jobAbort() current process won't die...";
            m_childProcess->kill();
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerFFmpeg::queueWork(JobTracker *job)
{
    qDebug() << ">> JobWorkerFFmpeg::queueWork()";

    if (job)
    {
        if (job->getType() == JobUtils::JOB_ENCODE)
        {
            queueWork_encode(job);
        }
        else if (job->getType() == JobUtils::JOB_MERGE)
        {
            queueWork_merge(job);
        }
    }
}

/* ************************************************************************** */

void JobWorkerFFmpeg::queueWork_merge(JobTracker *job)
{
    qDebug() << ">> JobWorkerFFmpeg::queueWork_merge()";

    if (job)
    {
        for (int i = 0; i < job->getElementsCount(); i++)
        {
            JobElement *element = job->getElement(i);

            // Make sure the shot has at least two files to merge...
            if (element->parent_shot->getFileCount() < 2)
            {
                job->setState(JobUtils::JOB_STATE_ERRORED);
                continue;
            }

            // telemetry extraction ////////////////////////////////////////////

            element->parent_shot->parseTelemetry();
            element->parent_shot->exportGps(element->destination_folder, 0,
                                            job->settings_telemetry.gps_frequency,
                                            job->settings_telemetry.EGM96);
            element->parent_shot->exportTelemetry(element->destination_folder, 0,
                                                  job->settings_telemetry.telemetry_frequency,
                                                  job->settings_telemetry.gps_frequency,
                                                  job->settings_telemetry.EGM96);

            // ffmpeg job //////////////////////////////////////////////////////

            CommandWrapper *ptiwrap = new CommandWrapper;
            ptiwrap->job = job;
            ptiwrap->job->setElementsIndex(i);
            ptiwrap->job_element_index = i;

            UtilsApp *app = UtilsApp::getInstance();
            ptiwrap->command = app->getAppPath() + "/ffmpeg";

            // No ffmpeg bundled? Just try to use ffmpeg from the system...
            if (!QFileInfo::exists(ptiwrap->command)) ptiwrap->command = "ffmpeg";

#if defined(Q_OS_WINDOWS)
            ptiwrap->command += ".exe";
#endif

            // ffmpeg arguments ////////////////////////////////////////////////

            // Create merge file
            if (ptiwrap->mergeFile.open())
            {
                QTextStream exportStream(&ptiwrap->mergeFile);

                for (unsigned i = 0; i < element->files.size(); i++)
                {
                    exportStream << "file '" << element->files.at(i).filesystemPath << "'\n";
                }

                ptiwrap->mergeFile.close();
            }

            // Create job
            ptiwrap->arguments << "-f" << "concat";
            ptiwrap->arguments << "-safe" << "0";
            ptiwrap->arguments << "-i" << ptiwrap->mergeFile.fileName();
            ptiwrap->arguments << "-c" << "copy";
            ptiwrap->arguments << "-y";

            QString file_folder = element->destination_folder;
            QString file_name;
            QString file_name_suffix = "_merged";
            QString file_extension = "mp4";

            if (!element->destination_file.isEmpty()) file_name = element->destination_file;
            else file_name = element->files.front().name + file_name_suffix;

            ptiwrap->destFile = file_folder + file_name + "." + file_extension;
            ptiwrap->arguments << ptiwrap->destFile;

            // Dispatch job
            m_ffmpegJobs.push_back(ptiwrap);

            // Recap ///////////////////////////////////////////////////////////
/*
            // Recap encoding arguments:
            qDebug() << "MERGE JOB:";
            qDebug() << ">" << ptiwrap->mergeFile.fileName();
            qDebug() << ">" << ptiwrap->command;
            qDebug() << ">" << ptiwrap->arguments;
*/
        }
    }
}

/* ************************************************************************** */

void JobWorkerFFmpeg::queueWork_encode(JobTracker *job)
{
    qDebug() << ">> JobWorkerFFmpeg::queueWork_encode()";

    if (job)
    {
        for (int i = 0; i < job->getElementsCount(); i++)
        {
            JobElement *element = job->getElement(i);
            if (element->parent_shot->getShotType() <= ShotUtils::SHOT_PICTURE &&
                element->files.size() != 1)
            {
                qDebug() << "This async job element got" << element->files.size() << "file(s), should not happen...";
                //continue;
            }

            // telemetry extraction ////////////////////////////////////////////

            if (job->settings_encode.extractTelemetry)
            {
                // "auto" telemetry extraction
                element->parent_shot->parseTelemetry();
                element->parent_shot->exportGps(element->destination_folder, 0,
                                                job->settings_telemetry.gps_frequency,
                                                job->settings_telemetry.EGM96);
                element->parent_shot->exportTelemetry(element->destination_folder, 0,
                                                      job->settings_telemetry.telemetry_frequency,
                                                      job->settings_telemetry.gps_frequency,
                                                      job->settings_telemetry.EGM96);
            }

            // ffmpeg job ////////////////////////=/////////////////////////////

            CommandWrapper *ptiwrap = new CommandWrapper;
            ptiwrap->job = job;
            ptiwrap->job->setElementsIndex(i);
            ptiwrap->job_element_index = i;

            QString codec = job->settings_encode.video_codec;
            if (element->parent_shot->getShotType() == ShotUtils::SHOT_PICTURE || job->settings_encode.mode == "screenshot")
            {
                codec = job->settings_encode.image_codec;
            }

            QString file_folder = element->destination_folder;
            QString file_name;
            QString file_name_suffix = (codec == "copy") ? "_clipped" : "_reencoded";
            QString file_extension;

            QString video_filters;
            QString audio_filters;

            // ffmpeg binary ///////////////////////////////////////////////////

            UtilsApp *app = UtilsApp::getInstance();
            ptiwrap->command = app->getAppPath() + "/ffmpeg";

            // No ffmpeg bundled? Just try to use ffmpeg from the system...
            if (!QFileInfo::exists(ptiwrap->command)) ptiwrap->command = "ffmpeg";

#if defined(Q_OS_WINDOWS)
            ptiwrap->command += ".exe";
#endif

            // ffmpeg arguments ////////////////////////////////////////////////

            ptiwrap->arguments << "-y";
            //ptiwrap->arguments << "-loglevel" << "warning" << "-stats";
            //ptiwrap->arguments << "-noautorotate";

            //// INPUTS

            if (element->parent_shot->getShotType() >= ShotUtils::SHOT_PICTURE_MULTI)
            {
                // timelapse to video
                ptiwrap->arguments << "-r" << QString::number(job->settings_encode.timelapse_fps);

                ptiwrap->arguments << "-start_number" << element->files.at(0).name.mid(1, -1);
                QString replacestr = "/" + element->files.at(0).name;
                ptiwrap->arguments << "-i" << element->files.at(0).filesystemPath.replace(replacestr, "/G%07d");

                //ptiwrap->arguments << "-pattern_type" << "glob" << "-i" << element->files.at(0).directory + "/*." + timelapse_src_ext;

                m_duration_frame = job->getFilesCount();
            }
            else
            {
                ptiwrap->arguments << "-i" << element->files.at(0).filesystemPath;
            }

            //// CODECS

            if (codec == "copy")
            {
                ptiwrap->arguments << "-codec" << "copy";
            }

            if (codec == "H.264")
            {
                file_extension = "mp4";

                // H.264 video
                ptiwrap->arguments << "-c:v" << "libx264";
                ptiwrap->arguments << "-pix_fmt" << "yuv420p";

                if (job->settings_encode.encoding_speed == 3)
                    ptiwrap->arguments << "-preset" << "faster";
                else if (job->settings_encode.encoding_speed == 1)
                    ptiwrap->arguments << "-preset" << "slower";
                else
                    ptiwrap->arguments << "-preset" << "medium";

                ptiwrap->arguments << "-tune" << "film";

                // CRF scale range is 0–51
                // (0 is lossless, 23 is default, 51 is worst) // sane range is 17–28
                int crf = mapNumber(job->settings_encode.encoding_quality, 50, 100, 28, 17);
                ptiwrap->arguments << "-crf" << QString::number(crf);

                // Audio copy
                ptiwrap->arguments << "-c:a" << "copy";
            }

            if (codec == "H.265")
            {
                file_extension = "mp4";

                // H.265 video
                ptiwrap->arguments << "-c:v" << "libx265";
                ptiwrap->arguments << "-pix_fmt" << "yuv420p";

                if (job->settings_encode.encoding_speed == 3)
                    ptiwrap->arguments << "-preset" << "faster";
                else if (job->settings_encode.encoding_speed == 1)
                    ptiwrap->arguments << "-preset" << "slower";
                else
                    ptiwrap->arguments << "-preset" << "medium";

                // CRF scale range is 0–51
                // (0 is lossless, 28 is default, 51 is worst) // sane range is 20–33
                int crf = mapNumber(job->settings_encode.encoding_quality, 50, 100, 33, 20);
                ptiwrap->arguments << "-crf" << QString::number(crf);

                // Audio copy
                ptiwrap->arguments << "-c:a" << "copy";
            }

            if (codec == "VP9")
            {
                file_extension = "mkv";

                if (job->settings_encode.encoding_speed == 3)
                    ptiwrap->arguments << "-deadline" << "realtime";
                else if (job->settings_encode.encoding_speed == 1)
                    ptiwrap->arguments << "-deadline" << "best";
                else
                    ptiwrap->arguments << "-deadline" << "good";

                // CRF scale range is 0–63
                // (0 is lossless, 23 is default, 63 is worst) // sane range is 24–48
                int crf = mapNumber(job->settings_encode.encoding_quality, 50, 100, 48, 24);

                // VP9 video
                ptiwrap->arguments << "-c:v" << "libvpx-vp9";
                ptiwrap->arguments << "-pix_fmt" << "yuv420p";
                ptiwrap->arguments << "-crf" << QString::number(crf) << "-b:v" << "0";
                ptiwrap->arguments << "-cpu-used" << "2";
                ptiwrap->arguments << "-threads" << "16";
                ptiwrap->arguments << "-row-mt" << "1";
                ptiwrap->arguments << "-tile-columns" << "2";
                ptiwrap->arguments << "-tile-rows" << "0";
                ptiwrap->arguments << "-frame-parallel" << "0";

                // Opus audio
                ptiwrap->arguments << "-c:a" << "libopus";
                ptiwrap->arguments << "-b:a" << "96K";
            }

            if (codec == "AV1")
            {
                file_extension = "mkv";

                // libaom-av1 // libsvtav1 // librav1e

                // CRF scale range is 0–63. Lower values mean better quality and greater file size.
                // 0 means lossless. A CRF value of 23 yields a quality level corresponding to CRF 19 for
                // x264 (​source), which would be considered visually lossless.
                int crf = mapNumber(job->settings_encode.encoding_quality, 50, 100, 48, 26);

                if (job->settings_encode.encoding_speed == 3)
                    ptiwrap->arguments << "-deadline" << "realtime";
                else if (job->settings_encode.encoding_speed == 1)
                    ptiwrap->arguments << "-deadline" << "best";
                else
                    ptiwrap->arguments << "-deadline" << "good";

                // AV1 video
                ptiwrap->arguments << "-c:v" << "libaom-av1";
                ptiwrap->arguments << "-pix_fmt" << "yuv420p";
                ptiwrap->arguments << "-crf" << QString::number(crf) << "-b:v" << "0";
                ptiwrap->arguments << "-cpu-used" << "4";
                ptiwrap->arguments << "-threads" << "16";
                ptiwrap->arguments << "-row-mt" << "1";
                ptiwrap->arguments << "-tiles" << "4x2";
                ptiwrap->arguments << "-frame-parallel" << "0";

                // Opus audio
                ptiwrap->arguments << "-c:a" << "libopus";
                ptiwrap->arguments << "-b:a" << "96K";
            }

            if (codec == "GIF")
            {
                file_extension = "gif";
            }

            if (codec == "PNG")
            {
                file_extension = "png";
            }
            if (codec == "JPEG")
            {
                file_extension = "jpg";

                // qscale range is 2–31
                int qscale = mapNumber(job->settings_encode.encoding_quality, 0, 100, 10, 1);

                ptiwrap->arguments << "-q:v" << QString::number(qscale);
                //ptiwrap->arguments << "-pix_fmt" << "yuv420p";
            }
            if (codec == "WEBP")
            {
                file_extension = "webp";

                // quality range is 0-100, default is 75
                int quality = job->settings_encode.encoding_quality;
                ptiwrap->arguments << "-quality" << QString::number(quality);
                ptiwrap->arguments << "-preset" << "photo";
                 // 0 faster but worst // 6 slower but better
                ptiwrap->arguments << "-compression_level" << QString::number(6);
            }

            //// PARAMS

            if (codec == "GIF")
            {
                ptiwrap->arguments << "-r" << QString::number(job->settings_encode.fps);

                // Using simple filter:
                //if (!video_filters.isEmpty()) video_filters += ",";
                //video_filters += "scale=-1:400:sws_dither=ed"; // sws_dither=[none,auto,bayer,ed,a_dither,x_dither]

                // Using complex filter
                video_filters = "[0:v]trim="+ getFFmpegDurationStringEscaped(job->settings_encode.startMs) + ":" + getFFmpegDurationStringEscaped(job->settings_encode.startMs + job->settings_encode.durationMs) + ",setpts=PTS-STARTPTS[0v];";
                if (job->settings_encode.gif_effect == "forwardbackward")
                {
                    video_filters += "[0v]crop=" + job->settings_encode.crop + ",scale=" + job->settings_encode.scale + ":sws_dither=ed,split=2[v1][2v];" \
                                     "[2v]reverse,fifo[v2];[v1][v2]concat=n=2:v=1[out]";
                }
                else if (job->settings_encode.gif_effect == "backwardforward")
                {
                    video_filters += "[0v]crop=" + job->settings_encode.crop + ",scale=" + job->settings_encode.scale + ":sws_dither=ed,split=2[v1][2v];" \
                                     "[2v]reverse,fifo[v2];[v2][v1]concat=n=2:v=1[out]";
                }
                else if (job->settings_encode.gif_effect == "backward")
                {
                    video_filters += "[0v]crop=" + job->settings_encode.crop + ",scale=" + job->settings_encode.scale + ":sws_dither=ed[2v];" \
                                     "[2v]reverse,fifo[out]";
                }
                else // forward
                {
                    video_filters += "[0v]crop=" + job->settings_encode.crop + ",scale=" + job->settings_encode.scale + ":sws_dither=ed[out]";
                }
                ptiwrap->arguments << "-filter_complex" << video_filters << "-map" << "[out]";
            }
            else
            {
                // Change output framerate
                if (job->settings_encode.fps > 0 && codec != "GIF")
                {
                    ptiwrap->arguments << "-r" << QString::number(job->settings_encode.fps);
                }

                // Clip duration
                if (job->settings_encode.durationMs > 0)
                {
                    ptiwrap->arguments << "-ss" << getFFmpegDurationString(job->settings_encode.startMs);
                    ptiwrap->arguments << "-t" << getFFmpegDurationString(job->settings_encode.durationMs);
                }

                // Screenshot?
                if (job->settings_encode.mode == "screenshot")
                {
                    ptiwrap->arguments << "-ss" << getFFmpegDurationString(job->settings_encode.startMs);
                    ptiwrap->arguments << "-frames:v" << "1";
                    file_name_suffix = "_screen" + QString::number(job->settings_encode.startMs / 1000);
                }

                // Filters
                {
                    // Transformations (from GUI)
                    if (job->settings_encode.transform > 1)
                    {
                        // EXIF from job->settings_encode.transform:
                        // 1 = Horizontal (default)
                        // 2 = Mirror
                        // 3 = Rotate 180
                        // 4 = Flip
                        // 5 = Flip and rotate 90 CW
                        // 6 = Rotate 90 CW // Rotate 270 CCW
                        // 7 = Mirror and rotate 90 CW
                        // 8 = Rotate 270 CW // Rotate 90 CCW

                        // ffmpeg transpose filter:
                        // http://ffmpeg.org/ffmpeg-all.html#transpose-1
                        // 0 = 90CounterCLockwise and Vertical Flip (default)
                        // 1 = 90Clockwise
                        // 2 = 90CounterClockwise
                        // 3 = 90Clockwise and Vertical Flip
                        // -vf "transpose=2,transpose=2" for 180 degrees.

                        // ffmpeg metadata:
                        //-noautorotate // force the use of metadata instead of proper geometry rotation
                        //-metadata:s:v rotate="" // force the metadata rotation value

                        QString rf = "";
                        if (job->settings_encode.transform == QImageIOHandler::TransformationMirror)
                            rf = "hflip";
                        else if (job->settings_encode.transform == QImageIOHandler::TransformationRotate180)
                            rf = "transpose=2,transpose=2"; // 180°
                        else if (job->settings_encode.transform == QImageIOHandler::TransformationFlip)
                            rf = "vflip";
                        else if (job->settings_encode.transform == QImageIOHandler::TransformationFlipAndRotate90)
                            rf = "hflip,transpose=2";
                        else if (job->settings_encode.transform == QImageIOHandler::TransformationRotate90)
                            rf = "transpose=1"; // 90°
                        else if (job->settings_encode.transform == QImageIOHandler::TransformationMirrorAndRotate90)
                            rf = "hflip,transpose=1";
                        else if (job->settings_encode.transform == QImageIOHandler::TransformationRotate270)
                            rf = "transpose=2"; // 270°

                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += rf;
                    }
                    // Transformations (from shot)
                    if (job->settings_encode.mode == "batch")
                    {
                        int transformation = element->parent_shot->getTransformation();
                        if (transformation > 0)
                        {
                            QString rf = "";
                            if (transformation == QImageIOHandler::TransformationMirror)
                                rf = "hflip";
                            else if (transformation == QImageIOHandler::TransformationRotate180)
                                rf = "transpose=2,transpose=2"; // 180°
                            else if (transformation == QImageIOHandler::TransformationFlip)
                                rf = "vflip";
                            else if (transformation == QImageIOHandler::TransformationFlipAndRotate90)
                                rf = "hflip,transpose=2";
                            else if (transformation == QImageIOHandler::TransformationRotate90)
                                rf = "transpose=1"; // 90°
                            else if (transformation == QImageIOHandler::TransformationMirrorAndRotate90)
                                rf = "hflip,transpose=1";
                            else if (transformation == QImageIOHandler::TransformationRotate270)
                                rf = "transpose=2"; // 270°

                            if (!video_filters.isEmpty()) video_filters += ",";
                            video_filters += rf;
                        }
                    }

                    // Crop // -filter:v "crop=out_w:out_h:x:y"
                    if (!job->settings_encode.crop.isEmpty())
                    {
                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += "crop=" + job->settings_encode.crop;
                    }

                    // Scaling
                    if (!job->settings_encode.scale.isEmpty())
                    {
                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += "scale=" + job->settings_encode.scale;
                    }
                    if (job->settings_encode.resolution > 0)
                    {
                        //if (!video_filters.isEmpty()) video_filters += ",";
                        //video_filters += "scale=" + QString::number(job->settings_encode.resolution) + ":-1";
                    }

                    // Timelapse
                    if (job->settings_encode.timelapse_fps > 0)
                    {
                        if (element->parent_shot->getShotType() < ShotUtils::SHOT_PICTURE)
                        {
                            // video to video timelapse
                            if (!video_filters.isEmpty()) video_filters += ",";
                            video_filters += "select='not(mod(n," + QString::number(job->settings_encode.timelapse_fps) + "))',setpts=N/FRAME_RATE/TB";
                            //video_filters += "setpts=" + QString::number(0.5) + "*PTS";

                            ptiwrap->arguments << "-r" << QString::number(job->settings_encode.fps);
                        }
                        else
                        {
                            // timelapse to video timelapse
                            ptiwrap->arguments << "-r" << QString::number(job->settings_encode.timelapse_fps);
                        }

                        ptiwrap->arguments << "-an";
                    }

                    // Defisheye filter
                    if (!job->settings_encode.defisheye.isEmpty())
                    {
                        if (!video_filters.isEmpty()) video_filters += ",";

                        // (using lenscorrection)
                        // - https://gopro.com/help/articles/Question_Answer/HERO3-Black-Edition-Field-of-View-FOV-Information
                        // - https://gopro.com/help/articles/Question_Answer/HERO4-Field-of-View-FOV-Information"
                        // - https://gopro.com/help/articles/Question_Answer/HERO4-Field-of-View-FOV-Information
                        // - https://gopro.com/help/articles/Question_Answer/HERO5-Black-Field-of-View-FOV-Information
                        // - https://gopro.com/help/articles/Question_Answer/HERO6-Black-Field-of-View-FOV-Information
                        // - https://gopro.com/help/articles/Question_Answer/HERO7-Field-of-View-FOV-Information
                        // - https://community.gopro.com/t5/en/HERO8-Black-Digital-Lenses-formerly-known-as-FOV/ta-p/398868
                        // - https://community.gopro.com/t5/en/HERO9-Black-Digital-Lenses-FOV-Information/ta-p/712624
                        //video_filters += "lenscorrection=cx=0.5:cy=0.5:k1=-0.193:k2=-0.022";

                        // (using lensfun)
                        //video_filters += "lensfun=make=GoPro:model=HERO5 Black:lens_model=fixed lens:mode=geometry:target_geometry=rectilinear:interpolation=lanczos";

                        // (using v360)
                        video_filters += "v360=input=sg:ih_fov=122.6:iv_fov=94.4:output=flat:d_fov=120:interp=spline16:w=4000:h=3000";
                    }

                    // Deshake filter
                    if (job->settings_encode.deshake)
                    {
                        if (!video_filters.isEmpty()) video_filters += ",";
                        video_filters += "deshake";
                    }

                    // Fade in/out filter
                    // video_filters += "fade=t=in:st=0:d=0.5"

                    // Zoom and pan filter
                    // TODO

                    // Apply filters
                    if (!video_filters.isEmpty()) ptiwrap->arguments << "-vf" << video_filters;
                    if (!audio_filters.isEmpty()) ptiwrap->arguments << "-af" << audio_filters;
                }
            }

            // Keep (some) metadata?
            ptiwrap->arguments << "-map_metadata" << "0";

            if (!element->destination_file.isEmpty()) file_name = element->destination_file;
            else file_name = element->files.front().name + file_name_suffix;

            // Re-encoding
            ptiwrap->destFile = file_folder + file_name + "." + file_extension;
            ptiwrap->arguments << ptiwrap->destFile;

            // Dispatch job
            m_ffmpegJobs.push_back(ptiwrap);

            // Recap ///////////////////////////////////////////////////////////

            // Recap encoding arguments:
            qDebug() << "ENCODING JOB:";
            qDebug() << ">" << ptiwrap->command;
            qDebug() << ">" << ptiwrap->arguments;
        }
/*
        // Recap settings:
        qDebug() << "ENCODING SETTINGS:";
        qDebug() << "* codec (video):" << job->settings_encode.video_codec;
        qDebug() << "* codec (image):" << job->settings_encode.image_codec;
        qDebug() << "* encoding quality:" << job->settings_encode.encoding_quality;
        qDebug() << "* encoding speed:" << job->settings_encode.encoding_speed;
        qDebug() << "* fps:" << job->settings_encode.fps;
        qDebug() << "* resolution:" << job->settings_encode.resolution;
        qDebug() << "* transform:" << job->settings_encode.transform;
        qDebug() << "* scale:" << job->settings_encode.scale;
        qDebug() << "* crop:" << job->settings_encode.crop;
        qDebug() << "* start (ms)   :" << job->settings_encode.startMs;
        qDebug() << "* duration (ms):" << job->settings_encode.durationMs;
*/
    }

    qDebug() << "<< JobWorkerFFmpeg::queueWork()";
}

/* ************************************************************************** */

int JobWorkerFFmpeg::getCurrentJobId()
{
    if (m_ffmpegCurrent)
    {
        return m_ffmpegCurrent->job->getId();
    }

    return -1;
}

bool JobWorkerFFmpeg::isWorking()
{
    return (m_childProcess && m_ffmpegCurrent);
}

/* ************************************************************************** */

void JobWorkerFFmpeg::work()
{
    if (m_childProcess == nullptr && !m_ffmpegJobs.isEmpty())
    {
        qDebug() << ">> JobWorkerFFmpeg::work()";

        m_ffmpegCurrent = m_ffmpegJobs.dequeue();
        if (m_ffmpegCurrent)
        {
            m_childProcess = new QProcess();
            connect(m_childProcess, SIGNAL(started()), this, SLOT(processStarted()));
            connect(m_childProcess, SIGNAL(finished(int)), this, SLOT(processFinished()));
            connect(m_childProcess, &QProcess::readyReadStandardOutput, this, &JobWorkerFFmpeg::processOutput);
            connect(m_childProcess, &QProcess::readyReadStandardError, this, &JobWorkerFFmpeg::processOutput);

            m_childProcess->start(m_ffmpegCurrent->command, m_ffmpegCurrent->arguments);
        }

        qDebug() << "<< JobWorkerFFmpeg::work()";
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void JobWorkerFFmpeg::processStarted()
{
    if (m_childProcess && m_ffmpegCurrent)
    {
        qDebug() << "JobWorkerFFmpeg::processStarted()";
        m_ffmpegCurrent->job->setState(JobUtils::JOB_STATE_WORKING);

        UtilsScreen *scr = UtilsScreen::getInstance();
        scr->keepScreenOn(true, "OffloadBuddy", tr("Encoding media"));

        Q_EMIT jobStarted(m_ffmpegCurrent->job->getId());
        Q_EMIT shotStarted(m_ffmpegCurrent->job->getId(), m_ffmpegCurrent->job->getElement(m_ffmpegCurrent->job_element_index)->parent_shot);
    }
}

/* ************************************************************************** */

void JobWorkerFFmpeg::processFinished()
{
    if (m_childProcess && m_ffmpegCurrent)
    {
        int exitStatus = m_childProcess->exitStatus();
        int exitCode = m_childProcess->exitCode();

        //qDebug() << "JobWorkerFFmpeg::processFinished(" << exitStatus << "/" << exitCode << ")" << m_ffmpegCurrent->destFile;

        UtilsScreen *scr = UtilsScreen::getInstance();
        scr->keepScreenOn(false);

        JobUtils::JobState js = static_cast<JobUtils::JobState>(m_ffmpegCurrent->job->getState());
        if (js != JobUtils::JOB_STATE_ABORTED)
        {
            if (exitStatus == QProcess::NormalExit)
            {
                if (exitCode == 0)
                {
                    // Still, make sure that the output file exists
                    if (QFile::exists(m_ffmpegCurrent->destFile))
                    {
                        js = JobUtils::JOB_STATE_DONE;
                    }
                    else
                    {
                        js = JobUtils::JOB_STATE_ERRORED;
                    }
                }
                else
                {
                    js = JobUtils::JOB_STATE_ERRORED;
                }
            }
            else if (exitStatus == QProcess::CrashExit)
            {
                js = JobUtils::JOB_STATE_ERRORED;
            }
        }

        if (m_ffmpegCurrent->job &&
            m_ffmpegCurrent->job->getElementsCount() > m_ffmpegCurrent->job_element_index)
        {
            m_ffmpegCurrent->job->setDestinationFile(m_ffmpegCurrent->destFile);

            Q_EMIT fileProduced(m_ffmpegCurrent->job->getDestinationFile());
            Q_EMIT shotFinished(m_ffmpegCurrent->job->getId(), 0, m_ffmpegCurrent->job->getElement(m_ffmpegCurrent->job_element_index)->parent_shot);
            Q_EMIT jobFinished(m_ffmpegCurrent->job->getId(), js);
        }

        m_childProcess->waitForFinished();
        m_childProcess->deleteLater();
        m_childProcess = nullptr;
        m_duration = QTime();
        m_progress = QTime();
        m_duration_frame = 0;
        m_progress_frame = 0;

        delete m_ffmpegCurrent;
        m_ffmpegCurrent = nullptr;
    }

    work(); // next job?
}

/* ************************************************************************** */

void JobWorkerFFmpeg::processOutput()
{
    if (m_childProcess)
    {
        m_childProcess->waitForBytesWritten(128);
        QString txt(m_childProcess->readAllStandardError());

        //qDebug() << "JobWorkerFFmpeg::processOutput()" << txt;

        if (m_duration.isNull() || !m_duration.isValid())
        {
            if (txt.contains("Duration: "))
            {
                QString duration_qstr = txt.mid(txt.indexOf("Duration: ") + 10, 11);
                m_duration = QTime::fromString(duration_qstr, "hh:mm:ss.z");
                //qDebug() << "> duration (qstr:" << duration_qstr << ") [qtime:" << m_duration;
            }
            else
            {
                if (m_ffmpegCurrent && m_ffmpegCurrent->job)
                {
                    // fallback, use duration from the shot
                    m_duration = QTime(0, 0, 0).addMSecs(m_ffmpegCurrent->job->getElement(m_ffmpegCurrent->job_element_index)->parent_shot->getDuration());
                }
            }
        }
        else
        {
            if (txt.contains("frame="))
            {
                QString progress_qstr = txt.mid(txt.indexOf("frame=") + 6, 6);
                m_progress_frame = progress_qstr.toInt();
                //qDebug() << "- progress (QString:" << progress_qstr << ") [int:" << m_progress_frame;
            }
            if (txt.contains("time="))
            {
                QString progress_qstr = txt.mid(txt.indexOf("time=") + 5, 11);
                m_progress = QTime::fromString(progress_qstr, "hh:mm:ss.z");
                //qDebug() << "- progress (QString:" << progress_qstr << ") [QTime:" << m_progress;
            }
        }

        float progress = 0.f;
        {
            if (m_duration_frame > 0 && m_progress_frame > 0)
            {
                progress = m_progress_frame / static_cast<float>(m_duration_frame);
            }
            else if (m_duration.isValid() && m_progress.isValid())
            {
                progress = QTime(0, 0, 0).msecsTo(m_progress) / static_cast<float>(QTime(0, 0, 0).msecsTo(m_duration));
            }

            progress *= 100.f;
            //qDebug() << "- ENCODING PROGRESS:" << progress << "%";

            if (m_ffmpegCurrent && m_ffmpegCurrent->job)
            {
                Q_EMIT jobProgress(m_ffmpegCurrent->job->getId(), progress);
            }
        }
    }
}

/* ************************************************************************** */
