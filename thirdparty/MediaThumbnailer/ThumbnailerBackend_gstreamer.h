/*!
 * Copyright (c) 2021 Emeric Grange - All Rights Reserved
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef THUMBNAILER_BACKEND_GSTREAMER_H
#define THUMBNAILER_BACKEND_GSTREAMER_H
/* ************************************************************************** */

#include "ThumbnailerBackend.h"

#include <gst/gst.h>

/* ************************************************************************** */

class ThumbnailerBackend_gstreamer: public ThumbnailerBackendInterface
{
    typedef enum {
        GST_VIDEO_SCALE_NEAREST,
        GST_VIDEO_SCALE_BILINEAR,
        GST_VIDEO_SCALE_4TAP,
        GST_VIDEO_SCALE_LANCZOS,

        GST_VIDEO_SCALE_BILINEAR2,
        GST_VIDEO_SCALE_SINC,
        GST_VIDEO_SCALE_HERMITE,
        GST_VIDEO_SCALE_SPLINE,
        GST_VIDEO_SCALE_CATROM,
        GST_VIDEO_SCALE_MITCHELL
    } GstVideoScaleMethod;

    typedef enum {
        GST_AUTOPLUG_SELECT_TRY,
        GST_AUTOPLUG_SELECT_EXPOSE,
        GST_AUTOPLUG_SELECT_SKIP
    } GstAutoplugSelectResult;

    typedef struct {
        float f;
        int num;
        int den;
    } framerate_info_t;

    static const int maxVideoTracks = 1;

    // GStreamer message bus
    GstBus *m_gstBus = nullptr;

    // GStreamer pipeline
    GstState m_currentPipelineState = GST_STATE_NULL;
    GstElement *m_gstPipeline = nullptr;
    GstElement *m_gstSource = nullptr, *m_gstDecodeBin = nullptr;

    GstElement *m_gstVideoBin = nullptr;
    GstElement *m_gstVideoConv = nullptr, *m_gstVideoScale = nullptr, *m_gstVideoFilter = nullptr, *m_gstVideoSink = nullptr;

    bool loadMedia(const QString &path, int width, int height);
    void destroyPipeline();

    void play_internal();
    void pause_internal();
    void stop_internal();
    bool seek_internal(int64_t time_ns);

    bool getVideoSample(QImage &img);

    // Callbacks
    static void cb_on_pad_added(GstElement *decodebin, GstPad *pad, gpointer data);
    static void cb_no_more_pads(GstElement *decodebin, gpointer data);
    static void cb_message_eos(GstBus *bus, GstMessage *message, gpointer data);
    static void cb_message_error(GstBus *bus, GstMessage *message, gpointer data);
    static void cb_message_warning(GstBus *bus, GstMessage *message, gpointer data);
    static gboolean cb_autoplug_continue(GstElement *bin, GstPad *pad, GstCaps *caps, gpointer user_data);
    static GstAutoplugSelectResult cb_autoplug_select(GstElement *decodebin, GstPad *pad, GstCaps *caps, GstElementFactory *factory, gpointer user_data);

    void on_pad_added(GstElement *decodebin, GstPad *pad, gpointer data);
    void no_more_pads(GstElement *decodebin, gpointer data);
    gboolean autoplug_continue(GstElement *bin, GstPad *pad, GstCaps *caps);
    GstAutoplugSelectResult autoplug_select(GstElement *decodebin, GstPad *pad, GstCaps *caps, GstElementFactory *factory);
    void message_eos();
    void message_err(GstMessage *message);

    // VIDEO
    uint32_t m_videoTrackCount = 0;
    // input description
    uint32_t m_videoCodec = 0;
    uint32_t m_videoFrameCount = 0;
    framerate_info_t m_videoFrameRate = {0.0, 0, 0};
    uint32_t m_videoWidth = 0;
    uint32_t m_videoHeight = 0;
    // output description
    bool m_videoCapsFilterInstalled = false;
    unsigned m_videoOutputFormat = 0;
    uint32_t m_videoOutputWidth = 0;
    uint32_t m_videoOutputHeight = 0;
    // video buffers
    GstSample *m_gstSample = nullptr;
    GstBuffer *m_gstBuffer = nullptr;
    GstMapInfo m_gstmapinfo;

    bool setVideoOutputFormat(unsigned format, int width, int height);

public:
    ThumbnailerBackend_gstreamer() = default;
    ~ThumbnailerBackend_gstreamer();

    bool getImage(const QString &path, QImage &img,
                  const int timecode_s,
                  const int width, const int height);
};

/* ************************************************************************** */
#endif // THUMBNAILER_BACKEND_GSTREAMER_H
