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

#ifndef MEDIA_THUMBNAILER_UTILS_H
#define MEDIA_THUMBNAILER_UTILS_H
/* ************************************************************************** */

#include <QString>
#include <QSize>

#include <cmath>

/* ************************************************************************** */

namespace MediaThumbnailerUtils {

//! A thumbnail request id parsed into a filesystem path and a timecode.
struct ParsedRequest
{
    QString path;
    int timecode_s = 0;
};

/*!
 * \brief Parse a thumbnail request id of the form "[file:///]<path>[@<seconds>]".
 * \param id: The request id, as passed to the QQuickImageProvider.
 * \return A ParsedRequest.
 */
inline ParsedRequest parseRequestId(const QString &id)
{
    ParsedRequest req;
    req.path = id;

    // Make sure we have a regular path and not an URL
    if (req.path.startsWith("file:///")) req.path.remove(0, 8);

    // Get the timecode from the id ("<path>@<seconds>") and strip it from the path
    const int at_pos = id.lastIndexOf('@');
    if (at_pos > 0)
    {
        // Length of "@<seconds>"
        const int suffix_len = id.size() - at_pos;

        bool timecode_validity = false;
        const int timecode = id.right(suffix_len - 1).toInt(&timecode_validity);

        // Make sure we had a valid timecode and not a random '@' character
        if (timecode_validity)
        {
            req.timecode_s = timecode;
            req.path.chop(suffix_len);
        }
    }

    return req;
}

/*!
 * \brief Compute an aspect-ratio-preserving thumbnail size fitted to a target width.
 * \param sourceSize: The natural size of the source image.
 * \param targetWidth: The requested thumbnail width.
 * \param targetHeight: Fallback size used when sourceSize is invalid.
 * \return The scaled size to hand to QImageReader::setScaledSize().
 */
inline QSize thumbnailScaledSize(const QSize &sourceSize, int targetWidth, int targetHeight)
{
    if (sourceSize.width() <= 0 || sourceSize.height() <= 0)
    {
        return QSize(targetWidth, targetHeight);
    }

    const float ar = sourceSize.width() / static_cast<float>(sourceSize.height());
    return QSize(targetWidth, static_cast<int>(std::round(targetWidth / ar)));
}

} // namespace MediaThumbnailerUtils

/* ************************************************************************** */
#endif // MEDIA_THUMBNAILER_UTILS_H
