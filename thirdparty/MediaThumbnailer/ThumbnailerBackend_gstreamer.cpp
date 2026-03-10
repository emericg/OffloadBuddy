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

#include "ThumbnailerBackend_gstreamer.h"

#include <gst/gst.h>
#include <gst/app/gstappsink.h>

#include <minivideo/minivideo_fourcc.h>

#include <QDebug>

/* ************************************************************************** */

bool ThumbnailerBackend_gstreamer::loadMedia(const QString &path, int width, int height)
{
    //qDebug() << "ThumbnailerBackend_gstreamer::openMedia(" << path << ")";
    bool status = true;

    // Make sure the pipeline is clean
    destroyPipeline();

    // Create a pipeline
    m_gstPipeline = gst_pipeline_new("GStreamerThumbnailer");

    // Add a message handler to this pipeline
    m_gstBus = gst_pipeline_get_bus(GST_PIPELINE(m_gstPipeline));
    if (m_gstBus)
    {
        // connect every message to a custom callback
        gst_bus_add_signal_watch(m_gstBus);
        gst_bus_enable_sync_message_emission(m_gstBus);
        g_signal_connect(m_gstBus, "message::eos", G_CALLBACK(cb_message_eos), this);
        g_signal_connect(m_gstBus, "message::warning", G_CALLBACK(cb_message_warning), this);
        g_signal_connect(m_gstBus, "message::error", G_CALLBACK(cb_message_error), this);
        gst_object_unref(m_gstBus);
    }

    // Set the source file
    m_gstSource = gst_element_factory_make("filesrc", "source");
    g_object_set(G_OBJECT(m_gstSource), "location", path.toUtf8().constData(), NULL);

    // Use a 'decodebin' "autoplugger"
    m_gstDecodeBin = gst_element_factory_make("decodebin", "decoder");
    // handle streams
    g_signal_connect(m_gstDecodeBin, "pad-added", G_CALLBACK(cb_on_pad_added), this);
    g_signal_connect(m_gstDecodeBin, "no-more-pads", G_CALLBACK(cb_no_more_pads), this);
    // always handle continue callback to select the tracks we need
    g_signal_connect(m_gstDecodeBin, "autoplug-continue", G_CALLBACK(cb_autoplug_continue), this);
    // we always ignore the second video track to avoid to allocate a video decoder
    g_signal_connect(m_gstDecodeBin, "autoplug-select", G_CALLBACK(cb_autoplug_select), this);

    if (!m_gstPipeline || !m_gstSource || !m_gstDecodeBin)
    {
        if (!m_gstPipeline) qWarning() << "GST pipeline could not be created.";
        if (!m_gstSource) qWarning() << "GST source could not be created.";
        if (!m_gstDecodeBin) qWarning() << "GST decoder could not be created.";

        return status;
    }

    // We add our elements (source and decoder) into the pipeline and link them
    gst_bin_add_many(GST_BIN(m_gstPipeline), m_gstSource, m_gstDecodeBin, NULL);
    if (gst_element_link(m_gstSource, m_gstDecodeBin) == TRUE)
    {
        gboolean gst_status;

        /// VIDEO PIPELINE(s) //////////////////////////////////////////////////

        int vid = 0;
        QString binname = "videobin" + QString::number(vid);
        QString convname = "vconv" + QString::number(vid);
        QString scalename = "vscale" + QString::number(vid);
        QString filtername = "vfilter" + QString::number(vid);
        QString sinkname = "vsink" + QString::number(vid);
        QString ghostpadname = "videobinghostpad" + QString::number(vid);

        m_gstVideoBin = gst_bin_new(binname.toUtf8());
        m_gstVideoConv = gst_element_factory_make("videoconvert", convname.toUtf8());
        m_gstVideoScale = gst_element_factory_make("videoscale", scalename.toUtf8());
        m_gstVideoFilter = gst_element_factory_make("capsfilter", filtername.toUtf8());
        m_gstVideoSink = gst_element_factory_make("appsink", sinkname.toUtf8());

        if (m_gstVideoConv && m_gstVideoScale && m_gstVideoFilter && m_gstVideoSink)
        {
            // Scaling algorithm
            g_object_set(G_OBJECT(m_gstVideoScale), "method", GST_VIDEO_SCALE_BILINEAR2, NULL);

            // Set the vsink to hold x decoded buffer, then pause the decoding process
            // (and not just dropping frames while continuing the playback)
            g_object_set(G_OBJECT(m_gstVideoSink), "max-buffers", 1, NULL);
            g_object_set(G_OBJECT(m_gstVideoSink), "drop", FALSE, NULL);
            // Async sink
            g_object_set(G_OBJECT(m_gstVideoSink), "async", TRUE, NULL);
            g_object_set(G_OBJECT(m_gstVideoSink), "sync", FALSE, NULL);

            // Add our elements to the videoBin
            gst_bin_add_many(GST_BIN(m_gstVideoBin), m_gstVideoConv, m_gstVideoScale, m_gstVideoFilter, m_gstVideoSink, NULL);

            // Link elements between them
            gst_status = gst_element_link_many(m_gstVideoConv, m_gstVideoScale, m_gstVideoFilter, m_gstVideoSink, NULL);

            // Add a "ghost" sink pad for our videoBin, connected to its first element
            GstPad *videobinghostpad = gst_element_get_static_pad(m_gstVideoConv, "sink");
            gst_status = gst_element_add_pad(m_gstVideoBin, gst_ghost_pad_new(ghostpadname.toUtf8(), videobinghostpad));
            gst_object_unref(videobinghostpad);

            // Add our bin to the global pipeline (padadded() callback will link them if needed)
            gst_status = gst_bin_add(GST_BIN(m_gstPipeline), m_gstVideoBin);

            setVideoOutputFormat(fourcc_be("RGBA"), width, height);
        }
        else
        {
            qWarning() << "Error while building VIDEO #" << vid << "pipeline...";
            status = false;
        }
    }

    return status;
}

/* ************************************************************************** */

void ThumbnailerBackend_gstreamer::destroyPipeline()
{
    //qDebug() << "ThumbnailerBackend_gstreamer::destroyPipeline()";

    if (m_gstSample)
    {
        gst_buffer_unmap(m_gstBuffer, &m_gstmapinfo);
        m_gstBuffer = nullptr;
        gst_sample_unref(m_gstSample);
        m_gstSample = nullptr;
    }

    if (m_gstPipeline)
    {
        gst_element_set_state(m_gstPipeline, GST_STATE_NULL);
        gst_object_unref(GST_OBJECT(m_gstPipeline));
        m_gstPipeline = nullptr;
   }

    m_videoTrackCount = 0;
    m_videoCodec = 0;
    m_videoFrameCount = 0;
    m_videoFrameRate = {0.0, 0, 0};
    m_videoWidth = 0;
    m_videoHeight = 0;
    m_videoCapsFilterInstalled = false;
    m_videoOutputFormat = 0;
    m_videoOutputWidth = 0;
    m_videoOutputHeight = 0;
}

/* ************************************************************************** */
/* ************************************************************************** */

void ThumbnailerBackend_gstreamer::play_internal()
{
    gst_element_set_state(m_gstPipeline, GST_STATE_PLAYING);
    gst_element_get_state(m_gstPipeline, &m_currentPipelineState, NULL, GST_SECOND);
}

void ThumbnailerBackend_gstreamer::pause_internal()
{
    gst_element_set_state(m_gstPipeline, GST_STATE_PAUSED);
    gst_element_get_state(m_gstPipeline, &m_currentPipelineState, NULL, GST_SECOND);
}

void ThumbnailerBackend_gstreamer::stop_internal()
{
    gst_element_set_state(m_gstPipeline, GST_STATE_NULL);
    gst_element_get_state(m_gstPipeline, &m_currentPipelineState, NULL, GST_SECOND);
}

/* ************************************************************************** */

bool ThumbnailerBackend_gstreamer::seek_internal(int64_t nsec)
{
    bool status = false;

    if (m_currentPipelineState == GST_STATE_PLAYING || m_currentPipelineState == GST_STATE_PAUSED)
    {
        gint64 seekpos = (gint64)nsec;
        GstSeekFlags flags = (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT | GST_SEEK_FLAG_KEY_UNIT);

        if (gst_element_seek_simple(m_gstPipeline, GST_FORMAT_TIME, flags, seekpos) == TRUE)
        {
            status = true;
        }
        else
        {
            qWarning() << "ThumbnailerBackend_gstreamer::seekToNs(" << nsec << ") FAILED";
        }
    }
    else
    {
        qWarning() << "ThumbnailerBackend_gstreamer::seekToNs(" << nsec << ") impossible, stream is not running";
    }

    return status;
}

/* ************************************************************************** */

void ThumbnailerBackend_gstreamer::cb_message_eos(GstBus *bus, GstMessage *message, gpointer data)
{
    Q_UNUSED(bus)
    Q_UNUSED(message)
    ((ThumbnailerBackend_gstreamer*)data)->message_eos();
}

void ThumbnailerBackend_gstreamer::cb_message_error(GstBus *bus, GstMessage *message, gpointer data)
{
    Q_UNUSED(bus)
    ((ThumbnailerBackend_gstreamer*)data)->message_err(message);
}

void ThumbnailerBackend_gstreamer::cb_message_warning(GstBus *bus, GstMessage *message, gpointer data)
{
    Q_UNUSED(bus)
    ((ThumbnailerBackend_gstreamer*)data)->message_err(message);
}

void ThumbnailerBackend_gstreamer::cb_on_pad_added(GstElement *decodebin, GstPad *pad, gpointer data)
{
    ((ThumbnailerBackend_gstreamer*)data)->on_pad_added(decodebin, pad, data);
}

void ThumbnailerBackend_gstreamer::cb_no_more_pads(GstElement *decodebin, gpointer data)
{
    ((ThumbnailerBackend_gstreamer*)data)->no_more_pads(decodebin, data);
}

gboolean ThumbnailerBackend_gstreamer::cb_autoplug_continue(GstElement *bin, GstPad *pad, GstCaps *caps, gpointer user_data)
{
    return ((ThumbnailerBackend_gstreamer*)user_data)->autoplug_continue(bin, pad, caps);
}

ThumbnailerBackend_gstreamer::GstAutoplugSelectResult
ThumbnailerBackend_gstreamer::cb_autoplug_select(GstElement *decodebin, GstPad *pad, GstCaps *caps, GstElementFactory *factory, gpointer user_data)
{
    return ((ThumbnailerBackend_gstreamer*)user_data)->autoplug_select(decodebin, pad, caps, factory);
}

/* ************************************************************************** */

void ThumbnailerBackend_gstreamer::on_pad_added(GstElement *decodebin, GstPad *pad, gpointer data)
{
    //qDebug() << "ThumbnailerBackend_gstreamer::on_pad_added()";

    Q_UNUSED(decodebin)
    Q_UNUSED(data)

    gchar *pad_name = gst_pad_get_name(pad);

    // Check pad type (audio or video)
    GstCaps *pad_current_caps = gst_pad_get_current_caps(pad);
    GstStructure *caps_struct = gst_caps_get_structure(pad_current_caps, 0);

    if (g_strrstr(gst_structure_get_name(caps_struct), "video"))
    {
        if (m_videoTrackCount >= maxVideoTracks)
        {
            qWarning() << "=" << pad_name << "cannot be linked, no video slots left";
            goto cleanup;
        }

        QString ghostpadnb = "videobinghostpad" + QString::number(m_videoTrackCount);
        GstPad *videopad = gst_element_get_static_pad(m_gstVideoBin, ghostpadnb.toUtf8());

        // Connect pad to its appropriate video sink
        if (videopad)
        {
            if (GST_PAD_IS_LINKED(videopad))
            {
                qWarning() << "=" << pad_name << "cannot be linked, we already have video";
            }
            else
            {
                if (gst_pad_link(pad, videopad) == GST_PAD_LINK_OK)
                {
                    //qDebug() << "=" << pad_name << "video pad has been LINKED";
                }
                else
                {
                    qWarning() << "=" << pad_name << "video pad link ERROR !!!";
                }
            }
            g_object_unref(videopad);

            m_videoTrackCount++;
        }
        else
        {
            qWarning() << "=" << pad_name << "video pad cannot be linked: no pad available...";
        }
    }

cleanup:
    gst_caps_unref(pad_current_caps);
    g_free(pad_name);
}

void ThumbnailerBackend_gstreamer::no_more_pads(GstElement *decodebin, gpointer data)
{
    //qDebug() << "ThumbnailerBackend_gstreamer::no_more_pads()";

    Q_UNUSED(decodebin)
    Q_UNUSED(data)

    QString ghostpadnb = "videobinghostpad" + QString::number(0);
    GstPad *videopad = gst_element_get_static_pad(m_gstVideoBin, ghostpadnb.toUtf8());
    if (videopad)
    {
        if (!GST_PAD_IS_LINKED(videopad))
        {
            // this also frees the video bin
            gst_element_set_state(m_gstVideoBin, GST_STATE_NULL);
            gst_bin_remove(GST_BIN(m_gstPipeline), m_gstVideoBin);
            m_gstVideoBin = nullptr;
            m_gstVideoConv = nullptr;
            m_gstVideoScale = nullptr;
            m_gstVideoFilter = nullptr;
            m_gstVideoSink = nullptr;
        }
        g_object_unref(videopad);
    }
}

gboolean ThumbnailerBackend_gstreamer::autoplug_continue(GstElement *bin, GstPad *pad, GstCaps *caps)
{
    Q_UNUSED(bin)
    Q_UNUSED(pad)

    GstStructure *caps_struct = gst_caps_get_structure(caps, 0);

    //const gchar *type = gst_structure_get_name(caps_struct);
    //gchar *caps_str = gst_caps_to_string(caps);
    //qDebug() << "ThumbnailerBackend_gstreamer::autoplug_continue() type:" << type << " / caps:" << caps_str;

    if (g_strrstr(gst_structure_get_name(caps_struct), "audio"))
    {
        return FALSE;
    }

    return TRUE;
}

ThumbnailerBackend_gstreamer::GstAutoplugSelectResult
ThumbnailerBackend_gstreamer::autoplug_select(GstElement *bin, GstPad *pad, GstCaps *caps, GstElementFactory *factory)
{
    Q_UNUSED(bin)
    Q_UNUSED(pad)
    Q_UNUSED(caps)
    Q_UNUSED(factory)

    //GstStructure *caps_struct = gst_caps_get_structure(caps, 0);

    //const gchar *type = gst_structure_get_name(caps_struct);
    //gchar *caps_str = gst_caps_to_string(caps);
    //qDebug() << "ThumbnailerBackend_gstreamer::autoplug_select() type:" << type << " / caps:" << caps_str;

    //const gchar *mimeType = gst_structure_get_name(caps_struct);
    //const gchar *format = gst_structure_get_string(caps_struct, "stream-format");

    return GST_AUTOPLUG_SELECT_TRY;
}

/* ************************************************************************** */

void ThumbnailerBackend_gstreamer::message_eos()
{
    //qDebug() << "ThumbnailerBackend_gstreamer::message_eos()";
}

void ThumbnailerBackend_gstreamer::message_err(GstMessage *msg)
{
    //qDebug() << "ThumbnailerBackend_gstreamer::message_err()";

    switch (GST_MESSAGE_TYPE(msg))
    {
    case GST_MESSAGE_ERROR: {
        GError *error;
        gchar  *debug;
        gst_message_parse_error(msg, &error, &debug);
        qWarning() << ">>> BUS >>> error:" << error->message;
        g_error_free(error);
        g_free(debug);
    } break;

    case GST_MESSAGE_WARNING: {
        GError *warning;
        gchar  *debug;
        gst_message_parse_warning(msg, &warning, &debug);
        qWarning() << ">>> BUS >>> warning: " << warning->message;
        g_error_free(warning);
        g_free(debug);
    } break;

    case GST_MESSAGE_INFO: {
        GError *info;
        gchar  *debug;
        gst_message_parse_info(msg, &info, &debug);
        qDebug() << ">>> BUS >>> info: " << info->message;
        g_error_free(info);
        g_free(debug);
    } break;

    default:
        break;
    }
}

/* ************************************************************************** */

bool ThumbnailerBackend_gstreamer::setVideoOutputFormat(unsigned format, int width, int height)
{
    //qDebug() << "ThumbnailerBackend_gstreamer::setVideoOutputFormat(" << format << "," << width << "x" << height << ")";
    bool status = false;

    // Apply buffer format filter (to all available tracks)
    if (m_gstVideoFilter)
    {
        std::string fcc = getFccString_be(format);
        const gchar *format_str = fcc.c_str();
        GstCaps *video_caps = gst_caps_new_simple("video/x-raw",
                                                  "format", G_TYPE_STRING, format_str,
                                                  "width", G_TYPE_INT, width,
                                                  "height", G_TYPE_INT, height,
                                                  NULL);

        g_object_set(m_gstVideoFilter, "caps", video_caps, NULL);
        gst_caps_unref(video_caps);

        m_videoOutputFormat = format;
        m_videoOutputWidth = width;
        m_videoOutputHeight = height;

        m_videoCapsFilterInstalled = true;
        status = true;
    }

    if (status != true)
    {
        qWarning() << "ThumbnailerBackend_gstreamer::setVideoOutputFormat(" << format << ") FAILED";
    }

    return status;
}

/* ************************************************************************** */

bool ThumbnailerBackend_gstreamer::getVideoSample(QImage &img)
{
    bool status = false;

    if (m_currentPipelineState != GST_STATE_PLAYING || !m_gstVideoSink)
    {
        qDebug() << "getVideoSample() video track is not PLAYING";
        return status;
    }

    if (gst_app_sink_is_eos((GstAppSink*)m_gstVideoSink) == TRUE)
    {
        pause_internal();

        gint64 len;
        gst_element_query_duration(m_gstPipeline, GST_FORMAT_TIME, &len);
        len /= 1000000;

        qDebug() << "getVideoSample() video track is EOS";
        return status;
    }

    if (m_gstSample)
    {
        gst_buffer_unmap(m_gstBuffer, &m_gstmapinfo);
        m_gstBuffer = nullptr;
        gst_sample_unref(m_gstSample);
        m_gstSample = nullptr;
    }

    // Get new sample
    m_gstSample = gst_app_sink_try_pull_sample((GstAppSink*)m_gstVideoSink, GST_SECOND);

    if (m_gstSample)
    {
        m_gstBuffer = gst_sample_get_buffer(m_gstSample);

        //qDebug() << "+ buffer pts " << GST_BUFFER_DTS_OR_PTS(buffer);
        //g_print ("+ buffer timecode %" GST_TIME_FORMAT "\n", GST_TIME_ARGS(GST_BUFFER_DTS_OR_PTS(buffer)));

        if (m_gstBuffer)
        {
            if (m_videoOutputWidth && m_videoOutputHeight &&
                gst_buffer_map(m_gstBuffer, &m_gstmapinfo, GST_MAP_READ) == TRUE)
            {
                // QImage wrap
                img = QImage(m_gstmapinfo.data,
                             m_videoOutputWidth, m_videoOutputHeight,
                             QImage::Format_RGBA8888);

                status = true;
            }
            else
            {
                qWarning() << "getVideoSample() could not get map video buffer";
            }
        }
        else
        {
            qWarning() << "getVideoSample() no video buffer";
        }
    }
    else
    {
        qWarning() << "getVideoSample() no video sample";
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool ThumbnailerBackend_gstreamer::getImage(const QString &path, QImage &img,
                                            const int timecode_s,
                                            const int width, const int height)
{
    bool status = false;

    if (gst_init_check(nullptr, nullptr, nullptr))
    {
        loadMedia(path, width, height);

        pause_internal();

        int64_t time_ns = timecode_s;
        time_ns *= 1000000000;
        if (seek_internal(time_ns) == true)
        {
            play_internal();

            if (getVideoSample(img))
            {
                status = true;
            }
        }
    }

    return status;
}

/* ************************************************************************** */
