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
 * \date      2026
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
