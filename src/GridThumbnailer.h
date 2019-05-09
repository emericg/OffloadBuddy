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

#ifndef GRID_THUMBNAILER_H
#define GRID_THUMBNAILER_H
/* ************************************************************************** */

#include <QQuickAsyncImageProvider>

/* ************************************************************************** */

/*!
 * \brief The GridThumbnailer class
 */
class GridThumbnailer : public QQuickImageProvider
{
    const int DEFAULT_THUMB_SIZE = 512;

#ifdef ENABLE_FFMPEG
    bool getImage_withFfmpeg(const QString &path, QImage &img,
                             const int timecode_s,
                             const int width, const int height);
#endif
#ifdef ENABLE_MINIVIDEO
    bool getImage_withMinivideo(const QString &path, QImage &img,
                                const int timecode_s,
                                const int width, const int height);
#endif

public:
    GridThumbnailer();

    QImage requestImage(const QString &id, QSize *size,
                        const QSize& requestedSize) override;

    QPixmap requestPixmap(const QString &id, QSize *size,
                          const QSize &requestedSize) override;

    QQuickTextureFactory *requestTexture(const QString &id, QSize *size,
                                         const QSize &requestedSize) override;
};

/* ************************************************************************** */
#endif // GRID_THUMBNAILER_H
