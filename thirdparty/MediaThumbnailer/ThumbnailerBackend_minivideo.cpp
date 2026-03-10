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
