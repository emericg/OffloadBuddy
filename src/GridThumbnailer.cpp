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
#endif // ENABLE_FFMPEG

#ifdef ENABLE_MINIVIDEO
#include "minivideo.h"
#endif

#include <QImageReader>
#include <QImage>
#include <QDebug>

#include <cmath>

/* ************************************************************************** */

GridThumbnailer::GridThumbnailer() :
    QQuickImageProvider(QQuickImageProvider::Image,
                        QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    fallback_video = QImage(":/resources/other/placeholder_video.svg").scaled(DEFAULT_THUMB_SIZE, DEFAULT_THUMB_SIZE, Qt::KeepAspectRatio);
    fallback_picture = QImage(":/resources/other/placeholder_picture.svg").scaled(DEFAULT_THUMB_SIZE, DEFAULT_THUMB_SIZE, Qt::KeepAspectRatio);
}

/* ************************************************************************** */
/* ************************************************************************** */

QImage GridThumbnailer::requestImage(const QString &id, QSize *size,
                                     const QSize &requestedSize)
{
    QImage thumb;

    QString path = id;
    int width = requestedSize.width() > 0 ? requestedSize.width() : DEFAULT_THUMB_SIZE;
    int height = requestedSize.height() > 0 ? requestedSize.height() : DEFAULT_THUMB_SIZE;

    int timecode_s = 0;
    if (id.lastIndexOf('@') > 0)
    {
        int timecode_pos = id.size() - id.lastIndexOf('@');
        timecode_s = id.right(timecode_pos - 1).toInt();
        path.chop(timecode_pos);
    }
/*
    qDebug() << "@ requestId: " << id;
    qDebug() << "@ requestPath: " << path;
    qDebug() << "@ requestedTimecode: " << timecode_s;
    qDebug() << "@ requestedSize: " << requestedSize;
*/
#if defined(ENABLE_FFMPEG)
    bool decoding_status = getImage_withFfmpeg(path, thumb, timecode_s, width, height);
#elif defined(ENABLE_MINIVIDEO)
    bool decoding_status = getImage_withMinivideo(path, thumb, timecode, width, height);
#else
    Q_UNUSED(width)
    Q_UNUSED(height)
    Q_UNUSED(timecode)
    bool decoding_status = false;
#endif

    // QImage fallback
    if (decoding_status == false)
    {
        QImageReader img_infos(path);

        // do we really have an image?
        if (img_infos.canRead())
        {
            // check size first, don't even try to thumbnail very big (>10K) pictures
            if (img_infos.size().rwidth() < 10000 && img_infos.size().rheight() < 10000)
            {
                decoding_status = thumb.load(path);
                thumb = thumb.scaled(width, height, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            }
        }
    }

    // Use our own static fallback pictures
    if (decoding_status == false)
    {
        if (size) *size = QSize(DEFAULT_THUMB_SIZE, DEFAULT_THUMB_SIZE);
        if (id.contains(".mp4") || id.contains(".m4v") || id.contains(".mov") || id.contains(".mkv") || id.contains(".webm"))
            return fallback_video;
        if (id.contains(".jpg") || id.contains(".jpeg") || id.contains(".png") || id.contains(".gpr") || id.contains(".tif") || id.contains(".tiff"))
            return fallback_picture;
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
    Q_UNUSED(id);
    Q_UNUSED(size);
    Q_UNUSED(requestedSize);

    return nullptr;
}

/* ************************************************************************** */
/* ************************************************************************** */

#if defined(ENABLE_MINIVIDEO)

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

            if (media && tid < media->tracks_video_count)
            {
                MediaStream_t *track = media->tracks_video[tid];
                if (track && sid < track->sample_count)
                {
                    // TODO seek
                    Q_UNUSED(timecode_s);

                    // TODO check if sid is a keyframe
                    //track->sample_type[sid] == sample_VIDEO_SYNC)

                    OutputSurface_t *out = minivideo_decode_frame(media, sid);
                    if (out)
                    {
                        status = true;
                        img = QImage(out->surface, out->width, out->height, QImage::Format_RGB888, &free).scaled(width*2, height);
                        minivideo_destroy_frame(&out);
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

// to work around av_err2str() in C++
#undef av_err2str
#ifdef _MSC_VER
#define av_err2str(errnum) av_make_error_string((char*)_alloca(AV_ERROR_MAX_STRING_SIZE), AV_ERROR_MAX_STRING_SIZE, errnum)
#else
#define av_err2str(errnum) av_make_error_string((char*)__builtin_alloca(AV_ERROR_MAX_STRING_SIZE), AV_ERROR_MAX_STRING_SIZE, errnum)
#endif

static bool ffmpeg_get_keyframes(const AVStream *stream, const int64_t target,
                                 int64_t &prev, int64_t &next)
{
    bool status = false;

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

    return status;
}

// align buffer sizes to multiples of 'roundTo'
static int roundTo(const int value, const int roundTo)
{
    return (value + (roundTo - 1)) & ~(roundTo - 1);
}

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
            double src_ar = (double)src_w / (double)src_h;
            enum AVPixelFormat src_pix_fmt = (AVPixelFormat)pFrame->format;

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
                    src_pix_fmt = (AVPixelFormat)pFrame->format;
                    break;
            }

            int dst_w = roundTo(std::round(width * src_ar), 8);
            int dst_h = height;
            int dstRange;
            enum AVPixelFormat dst_pix_fmt = AV_PIX_FMT_RGB24;

            /// SCALING (ffmpeg) ///////////////////////////////////////////////

            // create scaling context
            struct SwsContext *sws_ctx = sws_getContext(src_w, src_h, src_pix_fmt,
                                                        dst_w, dst_h, dst_pix_fmt,
                                                        SWS_BILINEAR,
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

bool GridThumbnailer::getImage_withFfmpeg(const QString &path, QImage &img,
                                          const int timecode_s,
                                          const int width, const int height)
{
    bool status = false;

    AVStream *pStreamContext = nullptr;
    AVCodec *pCodec = nullptr;
    AVCodecParameters *pCodecParameters =  nullptr;
    AVCodecContext *pCodecContext = nullptr;
    int video_stream_index = -1;

    AVFrame *pFrame = nullptr;
    AVPacket *pPacket = nullptr;
    int max_packets_to_process = 4;

    /// DEMUX //////////////////////////////////////////////////////////////////

    AVFormatContext *pFormatContext = avformat_alloc_context();
    if (!pFormatContext)
    {
        qDebug() << "ERROR could not allocate memory for Format Context";
        return status;
    }
    if (avformat_open_input(&pFormatContext, path.toLocal8Bit(), nullptr, nullptr) != 0)
    {
        qDebug() << "ERROR could not open the file:" << path;
        goto abort_stage1;
    }
    if (avformat_find_stream_info(pFormatContext,  nullptr) < 0)
    {
        qDebug() << "ERROR could not get the stream infos";
    }

    /// LOCATE VIDEO STREAM ////////////////////////////////////////////////////

    for (unsigned i = 0; i < pFormatContext->nb_streams; i++)
    {
        AVCodecParameters *pLocalCodecParameters = nullptr;
        pLocalCodecParameters = pFormatContext->streams[i]->codecpar;

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

        // when the stream is a video we store its index, codec parameters and codec
        if (pLocalCodecParameters->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            video_stream_index = (int)i;
            pCodec = pLocalCodec;
            pCodecParameters = pLocalCodecParameters;
            pStreamContext = pFormatContext->streams[i];
        }

        //qDebug() << "STREAM #" << i;
        //qDebug() << "Video Codec:" << QByteArray::fromHex(QString::number(pLocalCodecParameters->codec_tag, 16).toLocal8Bit());
        //qDebug() << "Video Codec: resolution" << pLocalCodecParameters->width << "x" << pLocalCodecParameters->height;
        //qDebug() << "Codec name:" << pLocalCodec->long_name << " ID:" << pLocalCodec->id;
        //qDebug() << "Bitrate:" << pCodecParameters->bit_rate;
    }

    /// ALLOCATIONS ////////////////////////////////////////////////////////////

    pCodecContext = avcodec_alloc_context3(pCodec);
    if (!pCodecContext)
    {
        qDebug() << "ERROR failed to allocated memory for AVCodecContext";
        goto abort_stage2;
    }
    if (avcodec_parameters_to_context(pCodecContext, pCodecParameters) < 0)
    {
        qDebug() << "ERROR failed to copy codec params to codec context";
        goto abort_stage2;
    }

    // SPEED FLAGS // "ain't nobody got time for that"
    pCodecContext->skip_loop_filter = AVDISCARD_ALL;
    pCodecContext->flags2 |= AV_CODEC_FLAG2_FAST;

    pCodecContext->thread_count = 4;
    pCodecContext->thread_type = FF_THREAD_SLICE;
    //pCodecContext->thread_type = FF_THREAD_FRAME | FF_THREAD_SLICE;

    if (avcodec_open2(pCodecContext, pCodec, nullptr) < 0)
    {
        qDebug() << "ERROR failed to open codec through avcodec_open2";
        goto abort_stage2;
    }
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
    if (strcmp(pFormatContext->iformat->name, "image2") != 0)
    {
        AVRational timebase_s = {1, 1};
        int64_t target_opt = av_rescale_q(timecode_s, timebase_s, pStreamContext->time_base);

        // Keyframe around optimal seek point
        int64_t prev_keyframe = -1;
        int64_t next_keyframe = -1;
        ffmpeg_get_keyframes(pStreamContext, target_opt, prev_keyframe, next_keyframe);

        int ret_seek = av_seek_frame(pFormatContext, video_stream_index, prev_keyframe, 0);
        if (ret_seek < 0)
        {
            qDebug() << "ERROR couldn't seek at" << timecode_s << "sec into the stream...";
        }
        else
        {
            avcodec_flush_buffers(pCodecContext);
        }
    }

    /// DECODE /////////////////////////////////////////////////////////////////

    // fill the Packet with data from the Stream
    while (av_read_frame(pFormatContext, pPacket) >= 0)
    {
        if (pPacket->stream_index == video_stream_index)
        {
            status = decode_packet(pPacket, pCodecContext, pFrame,
                                   img, width, height);

            // we have a picture!
            if (status == true)
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
    avcodec_free_context(&pCodecContext);

abort_stage1:
    avformat_close_input(&pFormatContext);
    avformat_free_context(pFormatContext);

    return status;
}

#endif // ENABLE_FFMPEG

/* ************************************************************************** */
