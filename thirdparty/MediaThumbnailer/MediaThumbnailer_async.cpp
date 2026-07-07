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

#include "MediaThumbnailer_async.h"
#include "MediaThumbnailer_utils.h"

#include <QQmlEngine>
#include <QImageReader>
#include <QImage>
#include <QDebug>

/* ************************************************************************** */

MediaThumbnailer_async::MediaThumbnailer_async() :
    QQuickImageProvider(QQuickImageProvider::Image, QQmlImageProviderBase::ForceAsynchronousImageLoading)
{
    //
}

/* ************************************************************************** */

MediaThumbnailer_async *MediaThumbnailer_async::registerToEngine(QQmlEngine *engine)
{
    if (!engine) return nullptr;

    auto *provider = new MediaThumbnailer_async();
    engine->addImageProvider("MediaThumbnailer", provider);

    return provider;
}

/* ************************************************************************** */

bool MediaThumbnailer_async::registerQml(QQmlEngine *engine)
{
    bool status = false;

    if (engine)
    {
        // Register MediaThumbnailer_async as an ImageProvider
        engine->addImageProvider("MediaThumbnailer", this);

        status = true;
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

QImage MediaThumbnailer_async::requestImage(const QString &id, QSize *size,
                                            const QSize &requestedSize)
{
    bool decoding_status = false;

    QImage thumb;
    int width = requestedSize.width() > 0 ? requestedSize.width() : DEFAULT_THUMB_SIZE;
    int height = requestedSize.height() > 0 ? requestedSize.height() : DEFAULT_THUMB_SIZE;

    // Parse the request id into a path and an (optional) timecode
    const MediaThumbnailerUtils::ParsedRequest req = MediaThumbnailerUtils::parseRequestId(id);
    const QString &path = req.path;
    const int timecode_s = req.timecode_s;
/*
    // RECAP
    qDebug() << "@ requestId: " << id;
    qDebug() << "@ requestPath: " << path;
    qDebug() << "@ requestedTimecode: " << timecode_s << "s";
    qDebug() << "@ requestedSize: " << requestedSize;
    qDebug() << "@ width/height: " << width << "/" << height;
*/
    // Imge thumbnail?
    QImageReader img_infos(path);
    if (img_infos.canRead())
    {
        // check size first, don't even try to thumbnail very big (>8K) pictures
        if (img_infos.size().rwidth() < 8192 && img_infos.size().rheight() < 8192)
        {
            img_infos.setScaledSize(MediaThumbnailerUtils::thumbnailScaledSize(img_infos.size(), width, height));
            img_infos.setAutoTransform(true);
            decoding_status = img_infos.read(&thumb);
        }
    }

    // Media thumbnail
    if (decoding_status == false)
    {
        decoding_status = mediaThumbnailer.getImage(path, thumb, timecode_s, width, height);
    }

    if (size) *size = QSize(thumb.width(), thumb.height());
    return thumb;
}

/* ************************************************************************** */

QPixmap MediaThumbnailer_async::requestPixmap(const QString &id, QSize *size,
                                              const QSize &requestedSize)
{
    return QPixmap::fromImage(requestImage(id, size, requestedSize));
}

/* ************************************************************************** */

QQuickTextureFactory *MediaThumbnailer_async::requestTexture(const QString &id, QSize *size,
                                                             const QSize &requestedSize)
{
    return QQuickTextureFactory::textureFactoryForImage(requestImage(id, size, requestedSize));
}

/* ************************************************************************** */
