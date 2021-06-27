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

#ifndef MEDIA_THUMBNAILER_ASYNC_H
#define MEDIA_THUMBNAILER_ASYNC_H
/* ************************************************************************** */

#include "ThumbnailerBackend.h"

#include <QQuickImageProvider>

class QQmlApplicationEngine;

/* ************************************************************************** */

/*!
 * \brief The MediaThumbnailer class
 */
class MediaThumbnailer_async : public QQuickImageProvider
{
    const int DEFAULT_THUMB_SIZE = 512;

    ThumbnailerBackend mediaThumbnailer;

public:
    MediaThumbnailer_async();

    bool registerQml(QQmlApplicationEngine *engine);

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override;

    QPixmap requestPixmap(const QString &id, QSize *size,
                          const QSize &requestedSize) override;

    QQuickTextureFactory *requestTexture(const QString &id, QSize *size,
                                         const QSize &requestedSize) override;
};

/* ************************************************************************** */
#endif // MEDIA_THUMBNAILER_ASYNC_H
