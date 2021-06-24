/*!
 * COPYRIGHT (C) 2021 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2021
 */

#include "ThumbnailerBackend_ffmpeg.h"

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

#include <QImageReader>
#include <QImage>
#include <QDebug>

#include <cmath>

/* ************************************************************************** */

#undef av_err2str
#if defined(_MSC_VER)
//! to work around av_err2str() in C++
#define av_err2str(errnum) av_make_error_string(static_cast<char*>(_alloca(AV_ERROR_MAX_STRING_SIZE)), AV_ERROR_MAX_STRING_SIZE, errnum)
#else
#define av_err2str(errnum) av_make_error_string(static_cast<char*>(__builtin_alloca(AV_ERROR_MAX_STRING_SIZE)), AV_ERROR_MAX_STRING_SIZE, errnum)
#endif

/* ************************************************************************** */

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

            int dst_w = ((static_cast<int>(std::round(width * src_ar)) + (31)) & ~(31));
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

/* ************************************************************************** */

bool ThumbnailerBackend_ffmpeg::getImage(const QString &path, QImage &img,
                                         const int timecode_s,
                                         const int width, const int height)
{
    bool status = false;

    AVStream *videoStreamContext = nullptr;
    AVCodec *videoCodec = nullptr;
    AVCodecParameters *videoCodecParameters = nullptr;
    AVCodecContext *videoCodecContext = nullptr;
    int videoStreamIndex = -1;

    AVFrame *pFrame = nullptr;
    AVPacket *pPacket = nullptr;
    int max_packets_to_process = 16;

    /// DEMUX //////////////////////////////////////////////////////////////////

    AVFormatContext *demuxContext = avformat_alloc_context();
    if (!demuxContext)
    {
        qDebug() << "ERROR could not allocate memory for Format Context";
        return status;
    }
    if (avformat_open_input(&demuxContext, path.toUtf8(), nullptr, nullptr) != 0)
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
            qDebug() << "ERROR unsupported codec!" << QByteArray::fromHex(QString::number(pLocalCodecParameters->codec_tag, 16).toUtf8());
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
    }

    /// CONTEXES ALLOCATIONS ///////////////////////////////////////////////////

    if (!videoCodec)
    {
        qDebug() << "ERROR failed to allocate videoCodec, no video track?";
        goto abort_stage2;
    }
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
    videoCodecContext->flags2 = AV_CODEC_FLAG2_FAST;
    videoCodecContext->thread_count = 2;
    videoCodecContext->thread_type = FF_THREAD_SLICE;

    if (avcodec_open2(videoCodecContext, videoCodec, nullptr) < 0)
    {
        qDebug() << "ERROR failed to open codec through avcodec_open2";
        goto abort_stage2;
    }

    videoCodecContext->hwaccel = nullptr;

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
        //int64_t prev_keyframe = -1, next_keyframe = -1;
        //ffmpeg_get_keyframes(videoStreamContext, target_opt, prev_keyframe, next_keyframe);

        int ret_seek = av_seek_frame(demuxContext, videoStreamIndex, target_opt, AVSEEK_FLAG_BACKWARD);
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

/* ************************************************************************** */
