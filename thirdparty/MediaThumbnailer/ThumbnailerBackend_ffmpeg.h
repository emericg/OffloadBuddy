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

#ifndef THUMBNAILER_BACKEND_FFMPEG_H
#define THUMBNAILER_BACKEND_FFMPEG_H
/* ************************************************************************** */

#include "ThumbnailerBackend.h"

/* ************************************************************************** */

class ThumbnailerBackend_ffmpeg : public ThumbnailerBackendInterface
{
public:
    ThumbnailerBackend_ffmpeg() = default;
    ~ThumbnailerBackend_ffmpeg() = default;

    bool getImage(const QString &path, QImage &img,
                  const int timecode_s,
                  const int width, const int height);
};

/* ************************************************************************** */
#endif // THUMBNAILER_BACKEND_FFMPEG_H
