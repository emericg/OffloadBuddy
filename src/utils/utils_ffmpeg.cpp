/*!
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

#include "utils_ffmpeg.h"

#ifdef __cplusplus
extern "C"
{
#include <libavcodec/avcodec.h>
#include <libavcodec/avfft.h>
#include <libavformat/avformat.h>
#include <libavformat/avio.h>
#include <libswscale/swscale.h>

#include <libavutil/opt.h>
#include <libavutil/common.h>
#include <libavutil/channel_layout.h>
#include <libavutil/imgutils.h>
#include <libavutil/mathematics.h>
#include <libavutil/samplefmt.h>
#include <libavutil/time.h>
#include <libavutil/opt.h>
#include <libavutil/pixdesc.h>
#include <libavutil/file.h>

// hwaccel
//#include "libavcodec/vdpau.h"
//#include "libavutil/hwcontext.h"
//#include "libavutil/hwcontext_vdpau.h"
}
#endif // __cplusplus

#include <QString>
#include <QDebug>

/* ************************************************************************** */

void ffmpeg_version()
{
    qDebug() << "- libavformat version:" << LIBAVFORMAT_VERSION_MAJOR
                                         << LIBAVFORMAT_VERSION_MINOR
                                         << LIBAVFORMAT_VERSION_MICRO;

    qDebug() << "- libavcodec version:" << LIBAVCODEC_VERSION_MAJOR
                                        << LIBAVCODEC_VERSION_MINOR
                                        << LIBAVCODEC_VERSION_MICRO;

    qDebug() << "- libavutil version:" << LIBAVUTIL_VERSION_MAJOR
                                       << LIBAVUTIL_VERSION_MINOR
                                       << LIBAVUTIL_VERSION_MICRO;
}

void ffmpeg_list_decoders(bool hw_only)
{
#if (LIBAVCODEC_VERSION_MAJOR >= 58)
    const AVCodec *codec = nullptr;
    void *opaque = nullptr;

    while ((codec = av_codec_iterate(&opaque)))
    {
        if (codec->hw_configs)
            qDebug() << "DECODER:  (HW) " << codec->name;
        else if (!hw_only)
            qDebug() << "DECODER:" << codec->name;
    }
#endif
}

void ffmpeg_list_encoders(bool hw_only)
{
#if (LIBAVCODEC_VERSION_MAJOR >= 58)
    const AVCodec *codec = nullptr;
    void *opaque = nullptr;

    // FIXME no way to query HW encoders only...
    hw_only = false;

    while ((codec = av_codec_iterate(&opaque)))
    {
        if (codec->encode2)
        {
            if (codec->hw_configs)
                qDebug() << "ENCODER:  (HW) " << codec->name;
            else if (!hw_only)
                qDebug() << "ENCODER:" << codec->name;
        }
    }
#endif
}

/* ************************************************************************** */

bool ffmpeg_get_keyframes(const AVStream *stream, const int64_t target,
                          int64_t &prev, int64_t &next)
{
    bool status = false;
/*
    if (stream && stream->nb_index_entries > 1)
    {
        for (int i = 0; i < stream->nb_index_entries; i++)
        {
            if ((stream->index_entries[i].flags & AVINDEX_KEYFRAME) == 1)
            {
                if (next < 0 && stream->index_entries[i].timestamp > target)
                {
                    next = stream->index_entries[i].timestamp;
                    status = true;
                    break;
                }

                if (stream->index_entries[i].timestamp > prev)
                {
                    prev = stream->index_entries[i].timestamp;
                }
            }
        }
    }
*/
    return status;
}

/* ************************************************************************** */
