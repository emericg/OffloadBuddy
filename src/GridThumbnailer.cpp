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

#include "GridThumbnailer.h"

#ifdef ENABLE_FFMPEG
#ifdef __cplusplus
extern "C"
{
    #include <libavcodec/avcodec.h>
    #include <libavformat/avformat.h>
    #include <libswscale/swscale.h>
    #include <libavutil/imgutils.h>
    #include <libavutil/parseutils.h>
}
#endif // __cplusplus

#include "utils/utils_maths.h"
#include "utils/utils_ffmpeg.h"
#endif // ENABLE_FFMPEG

#ifdef ENABLE_MINIVIDEO
#include "minivideo.h"
#endif

#include "SettingsManager.h"

#include <QImageReader>
#include <QImage>
#include <QDebug>

#include <cmath>

/* ************************************************************************** */

GridThumbnailer::GridThumbnailer() :
    QQuickImageProvider(QQuickImageProvider::Image,
                        QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

QImage GridThumbnailer::requestImage(const QString &id, QSize *size,
                                     const QSize &requestedSize)
{
    bool decoding_status = false;

    QString path = id;
    int target_width = requestedSize.width() > 0 ? requestedSize.width() : DEFAULT_THUMB_SIZE;
    int target_height = requestedSize.height() > 0 ? requestedSize.height() : DEFAULT_THUMB_SIZE;

    // Get timecode from string id, and remove it from string path
    int timecode_pos = id.lastIndexOf('@');
    int timecode_s = 0;
    if (timecode_pos)
    {
        bool timecode_validity = false;
        timecode_pos = id.size() - timecode_pos;
        timecode_s = id.rightRef(timecode_pos - 1).toInt(&timecode_validity);

        // Make sure we had a timecode and not a random '@' character
        if (timecode_validity)
            path.chop(timecode_pos);
    }
/*
    qDebug() << "@ requestId: " << id;
    qDebug() << "@ requestPath: " << path;
    qDebug() << "@ requestedTimecode: " << timecode_s;
    qDebug() << "@ requestedSize: " << requestedSize;
*/

    QImage thumb;

    // First, try QImageReader
    QImageReader img_infos(path);
    if (img_infos.canRead())
    {
        // check size first, don't even try to thumbnail very big (>10K) pictures
        if (img_infos.size().rwidth() > 0 && img_infos.size().rheight() > 0 &&
            img_infos.size().rwidth() < 10000 && img_infos.size().rheight() < 10000)
        {
            // load data into the QImage
            img_infos.setAutoTransform(true);
            decoding_status = img_infos.read(&thumb);

            // scale down (not up)
            if (target_width < img_infos.size().rwidth() && target_height < img_infos.size().rheight())
                thumb = thumb.scaled(target_width, target_height, Qt::KeepAspectRatio, Qt::SmoothTransformation);
        }
    }

    // Video file fallback
    if (!decoding_status)
    {
#if defined(ENABLE_FFMPEG)
        decoding_status = getImage_withFfmpeg(path, thumb, timecode_s, target_width, target_height);
#elif defined(ENABLE_MINIVIDEO)
        decoding_status = getImage_withMinivideo(path, thumb, timecode, target_width, target_height);
#endif
    }

    // Use our own static fallback pictures
    if (!decoding_status)
    {
        if (size) *size = QSize(DEFAULT_THUMB_SIZE, DEFAULT_THUMB_SIZE);
        //if (id.contains(".mp4") || id.contains(".m4v") || id.contains(".mov") || id.contains(".mkv") || id.contains(".webm"))
        //    return fallback_video;
        //if (id.contains(".jpg") || id.contains(".jpeg") || id.contains(".png") || id.contains(".gpr") || id.contains(".tif") || id.contains(".tiff"))
        //    return fallback_picture;
    }

    if (size) *size = QSize(thumb.width(), thumb.height());

    return thumb;
}

/* ************************************************************************** */

QPixmap GridThumbnailer::requestPixmap(const QString &id, QSize *size,
                                       const QSize &requestedSize)
{
    return QPixmap::fromImage(requestImage(id, size, requestedSize));
}

/* ************************************************************************** */

QQuickTextureFactory *GridThumbnailer::requestTexture(const QString &id, QSize *size,
                                                      const QSize &requestedSize)
{
    Q_UNUSED(id)
    Q_UNUSED(size)
    Q_UNUSED(requestedSize)

    return nullptr;
}

/* ************************************************************************** */
/* ************************************************************************** */

#ifdef ENABLE_MINIVIDEO

bool GridThumbnailer::getImage_withMinivideo(const QString &path, QImage &img,
                                             const int timecode_s,
                                             const int width, const int height)
{
    bool status = false;

    MediaFile_t *media = nullptr;
    if (minivideo_open(path.toLocal8Bit(), &media) > 0)
    {
        if (minivideo_parse(media, false, false) > 0)
        {
            unsigned tid = 0, sid = 0;

            if (media && media->tracks_video_count > tid)
            {
                MediaStream_t *track = media->tracks_video[tid];
                if (track && track->sample_count > tid)
                {
                    // TODO seek
                    Q_UNUSED(timecode_s)

                    // TODO make sure sid is a keyframe
                    //track->sample_type[sid] == sample_VIDEO_SYNC)

                    OutputSurface_t *out = minivideo_decode_frame(media, sid);
                    if (out)
                    {
                        img = QImage(out->surface, out->width, out->height,
                                     QImage::Format_RGB888, &free).scaled(width*2, height);
                        minivideo_destroy_frame(&out);

                        status = true;
                    }
                }
            }
        }

        minivideo_close(&media);
    }

    return status;
}

#endif // ENABLE_MINIVIDEO

/* ************************************************************************** */
/* ************************************************************************** */

#ifdef ENABLE_FFMPEG

bool decode_packet(AVPacket *pPacket, AVCodecContext *pCodecContext, AVFrame *pFrame,
                   QImage &img, const int width, const int height)
{
    //qDebug() << "decode_packet() AVPacket->pts:" << pPacket->pts;
    bool status = false;
    int retcode = 0;

    // Supply raw packet data as input to a decoder
    retcode = avcodec_send_packet(pCodecContext, pPacket);
    if (retcode < 0)
    {
        qDebug() << "ERROR while sending a packet to the decoder:" << av_err2str(retcode);
        return status;
    }

    while (retcode >= 0)
    {
        // Return decoded output data (into a frame) from a decoder
        retcode = avcodec_receive_frame(pCodecContext, pFrame);
        if (retcode == AVERROR(EAGAIN) || retcode == AVERROR_EOF)
            break;
        else if (retcode < 0)
        {
            qDebug() << "ERROR while receiving a frame from the decoder:" << av_err2str(retcode);
            return status;
        }

        if (retcode >= 0)
        {
/*
            qDebug() << "Frame #" << pCodecContext->frame_number << "FORMAT" << pFrame->format
                     << "(type=" << av_get_picture_type_char(pFrame->pict_type) << ", size=" << pFrame->pkt_size << "bytes)"
                     << "PTS" << pFrame->pts
                     << "key_frame" << pFrame->key_frame
                     << "[DTS" << pFrame->coded_picture_number << "]";
*/
            int src_w = pFrame->width;
            int src_h = pFrame->height;
            int srcRange = 0;
            double src_ar = static_cast<double>(src_w) / static_cast<double>(src_h);
            enum AVPixelFormat src_pix_fmt = static_cast<AVPixelFormat>(pFrame->format);

            // Remove the 'J' in deprecated pixel formats, which denotes full range
            switch (pFrame->format)
            {
                case AV_PIX_FMT_YUVJ420P:
                    src_pix_fmt = AV_PIX_FMT_YUV420P;
                    srcRange = 1;
                    break;
                case AV_PIX_FMT_YUVJ422P:
                    src_pix_fmt = AV_PIX_FMT_YUV422P;
                    srcRange = 1;
                    break;
                case AV_PIX_FMT_YUVJ444P:
                    src_pix_fmt = AV_PIX_FMT_YUV444P;
                    srcRange = 1;
                    break;
                case AV_PIX_FMT_YUVJ440P:
                    src_pix_fmt = AV_PIX_FMT_YUV440P;
                    srcRange = 1;
                    break;
                default:
                    src_pix_fmt = static_cast<AVPixelFormat>(pFrame->format);
                    break;
            }

            int dst_w = roundTo(static_cast<int>(std::round(width * src_ar)), 32);
            int dst_h = height;
            int dstRange;
            enum AVPixelFormat dst_pix_fmt = AV_PIX_FMT_RGB24;

            /// SCALING (ffmpeg) ///////////////////////////////////////////////

            int filtering_mode = SWS_FAST_BILINEAR;
            SettingsManager *sm = SettingsManager::getInstance();
            if (sm)
            {
                if (sm->getThumbQuality() == 0)
                    filtering_mode = SWS_FAST_BILINEAR;
                else if (sm->getThumbQuality() == 1)
                    filtering_mode = SWS_BILINEAR;
                else if (sm->getThumbQuality() == 2)
                    filtering_mode = SWS_BILINEAR; // SWS_BICUBIC ?
            }

            // create scaling context
            struct SwsContext *sws_ctx = sws_getContext(src_w, src_h, src_pix_fmt,
                                                        dst_w, dst_h, dst_pix_fmt,
                                                        filtering_mode,
                                                        nullptr, nullptr, nullptr);
            if (!sws_ctx)
            {
                qDebug() << "ERROR no scaler for convertion: fmt="
                         << av_get_pix_fmt_name(src_pix_fmt) << src_w << "x" << src_h
                         << " >>> fmt="
                         << av_get_pix_fmt_name(dst_pix_fmt) << dst_w << "x" << dst_h;
                return status;
            }

            int dummy[4];
            int brightness, contrast, saturation;
            sws_getColorspaceDetails(sws_ctx, (int**)&dummy, &srcRange,
                                     (int**)&dummy, &dstRange,
                                     &brightness, &contrast, &saturation);

            const int *coefs = sws_getCoefficients(SWS_CS_DEFAULT);

            srcRange = 1; // FIXME // this marks that values are according to yuv'J'

            sws_setColorspaceDetails(sws_ctx, coefs, srcRange, coefs, dstRange,
                                     brightness, contrast, saturation);

            uint8_t *dst_data[4];
            int dst_linesize[4];
            if ((retcode = av_image_alloc(dst_data, dst_linesize,
                                          dst_w, dst_h, dst_pix_fmt, 1)) < 0)
            {
                qDebug() << "ERROR Could not allocate destination image";
                return status;
            }

            sws_scale(sws_ctx, (const uint8_t * const*)(pFrame->data),
                      (const int*)pFrame->linesize, 0, src_h,
                      dst_data, dst_linesize);

            // !!! copy
            img = QImage(dst_data[0], dst_w, dst_h, QImage::Format_RGB888).copy();

            av_freep(dst_data);
            av_frame_unref(pFrame);
            sws_freeContext(sws_ctx);

            status = true;
        }
    }

    return status;
}

/* ************************************************************************** */

bool GridThumbnailer::getImage_withFfmpeg(const QString &path, QImage &img,
                                          const int timecode_s,
                                          const int width, const int height)
{
    bool status = false;

    AVStream *videoStreamContext = nullptr;
    AVCodec *videoCodec = nullptr;
    AVCodecParameters *videoCodecParameters =  nullptr;
    AVCodecContext *videoCodecContext = nullptr;
    int videoStreamIndex = -1;

    AVFrame *pFrame = nullptr;
    AVPacket *pPacket = nullptr;
    int max_packets_to_process = 4;

    /// DEMUX //////////////////////////////////////////////////////////////////

    AVFormatContext *demuxContext = avformat_alloc_context();
    if (!demuxContext)
    {
        qDebug() << "ERROR could not allocate memory for Format Context";
        return status;
    }
    if (avformat_open_input(&demuxContext, path.toLocal8Bit(), nullptr, nullptr) != 0)
    {
        qDebug() << "ERROR could not open the file:" << path;
        goto abort_stage1;
    }
    if (avformat_find_stream_info(demuxContext,  nullptr) < 0)
    {
        qDebug() << "ERROR could not get the streams infos";
    }

    /// LOCATE VIDEO STREAM ////////////////////////////////////////////////////

    for (unsigned i = 0; i < demuxContext->nb_streams; i++)
    {
        AVCodecParameters *pLocalCodecParameters = nullptr;
        pLocalCodecParameters = demuxContext->streams[i]->codecpar;

        if (!pLocalCodecParameters)
            continue;
        if (pLocalCodecParameters->codec_type != AVMEDIA_TYPE_VIDEO)
            continue;

        // finds the registered decoder for a codec ID
        AVCodec *pLocalCodec = avcodec_find_decoder(pLocalCodecParameters->codec_id);
        if (pLocalCodec == nullptr)
        {
            qDebug() << "ERROR unsupported codec!" << QByteArray::fromHex(QString::number(pLocalCodecParameters->codec_tag, 16).toLocal8Bit());
            goto abort_stage1;
        }

        // when the stream is a video, we store its index, codec parameters and codec
        if (pLocalCodecParameters->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            videoStreamIndex = static_cast<int>(i);
            videoCodec = pLocalCodec;
            videoCodecParameters = pLocalCodecParameters;
            videoStreamContext = demuxContext->streams[i];
        }

        //qDebug() << "STREAM #" << i;
        //qDebug() << "Video Codec:" << QByteArray::fromHex(QString::number(pLocalCodecParameters->codec_tag, 16).toLocal8Bit());
        //qDebug() << "Video Codec: resolution" << pLocalCodecParameters->width << "x" << pLocalCodecParameters->height;
        //qDebug() << "Codec name:" << pLocalCodec->long_name << " ID:" << pLocalCodec->id;
        //qDebug() << "Bitrate:" << pCodecParameters->bit_rate;
    }

    /// CONTEXES ALLOCATIONS ///////////////////////////////////////////////////

    videoCodecContext = avcodec_alloc_context3(videoCodec);
    if (!videoCodecContext)
    {
        qDebug() << "ERROR failed to allocated memory for AVCodecContext";
        goto abort_stage2;
    }
    if (avcodec_parameters_to_context(videoCodecContext, videoCodecParameters) < 0)
    {
        qDebug() << "ERROR failed to copy codec params to codec context";
        goto abort_stage2;
    }

    // SPEED FLAGS // "ain't nobody got time for that"
    videoCodecContext->skip_loop_filter = AVDISCARD_ALL;
    videoCodecContext->flags2 |= AV_CODEC_FLAG2_FAST;

    videoCodecContext->thread_count = 1;
    videoCodecContext->thread_type = FF_THREAD_FRAME;
    //videoCodecContext->thread_type = FF_THREAD_FRAME | FF_THREAD_SLICE;

    if (avcodec_open2(videoCodecContext, videoCodec, nullptr) < 0)
    {
        qDebug() << "ERROR failed to open codec through avcodec_open2";
        goto abort_stage2;
    }

    /// FRAMES ALLOCATIONS /////////////////////////////////////////////////////

    pFrame = av_frame_alloc();
    if (!pFrame)
    {
        qDebug() << "ERROR failed to allocated memory for AVFrame";
        goto abort_stage3;
    }
    pPacket = av_packet_alloc();
    if (!pPacket)
    {
        qDebug() << "ERROR failed to allocated memory for AVPacket";
        goto abort_stage3;
    }

    /// SEEK ///////////////////////////////////////////////////////////////////

    // do not try to seek on images...
    if (strcmp(demuxContext->iformat->name, "image2") != 0)
    {
        AVRational timebase_s = {1, 1};
        int64_t target_opt = av_rescale_q(timecode_s, timebase_s, videoStreamContext->time_base);

        // Keyframe around optimal seek point
        int64_t prev_keyframe = -1;
        int64_t next_keyframe = -1;
        ffmpeg_get_keyframes(videoStreamContext, target_opt, prev_keyframe, next_keyframe);

        int ret_seek = av_seek_frame(demuxContext, videoStreamIndex, prev_keyframe, 0);
        if (ret_seek < 0)
        {
            qDebug() << "ERROR couldn't seek at" << timecode_s << "sec into the stream...";
        }
        else
        {
            avcodec_flush_buffers(videoCodecContext);
        }
    }

    /// DECODE /////////////////////////////////////////////////////////////////

    // fill the Packet with data from the Stream
    while (av_read_frame(demuxContext, pPacket) >= 0)
    {
        if (pPacket->stream_index == videoStreamIndex)
        {
            status = decode_packet(pPacket, videoCodecContext, pFrame,
                                   img, width, height);

            // we have a picture!
            if (status)
                break;

            // stop it, otherwise we'll be saving hundreds of frames
            if (--max_packets_to_process <= 0)
                break;
        }
        av_packet_unref(pPacket);
    }

    /// CLEANUPS ///////////////////////////////////////////////////////////////

abort_stage3:
    av_packet_free(&pPacket);
    av_frame_free(&pFrame);

abort_stage2:
    avcodec_free_context(&videoCodecContext);

abort_stage1:
    avformat_close_input(&demuxContext);
    avformat_free_context(demuxContext);

    return status;
}

#endif // ENABLE_FFMPEG

/* ************************************************************************** */
