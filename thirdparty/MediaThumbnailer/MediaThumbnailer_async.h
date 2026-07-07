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

#ifndef MEDIA_THUMBNAILER_ASYNC_H
#define MEDIA_THUMBNAILER_ASYNC_H
/* ************************************************************************** */

#include "ThumbnailerBackend.h"

#include <QQuickImageProvider>

class QQmlEngine;

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

    /*!
     * \brief Create the provider and register it to a QML engine under the "MediaThumbnailer" scheme.
     * \param engine: The QML engine of your application.
     * \return Pointer to the QQuickAsyncImageProvider created.
     *
     * The engine takes ownership of the returned provider and deletes it on teardown (do not delete it yourself).
     */
    static MediaThumbnailer_async *registerToEngine(QQmlEngine *engine);

    bool registerQml(QQmlEngine *engine);

    QImage requestImage(const QString &id, QSize *size,
                        const QSize &requestedSize) override;

    QPixmap requestPixmap(const QString &id, QSize *size,
                          const QSize &requestedSize) override;

    QQuickTextureFactory *requestTexture(const QString &id, QSize *size,
                                         const QSize &requestedSize) override;
};

/* ************************************************************************** */
#endif // MEDIA_THUMBNAILER_ASYNC_H
