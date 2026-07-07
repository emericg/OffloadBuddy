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

#include "ThumbnailerBackend_minivideo.h"

#include <minivideo/minivideo.h>

#include <QImageReader>
#include <QImage>
#include <QDebug>
#include <cmath>

/* ************************************************************************** */

bool ThumbnailerBackend_minivideo::getImage(const QString &path, QImage &img,
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

/* ************************************************************************** */
