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

#include "MediaThumbnailer_threadpool.h"

#include <QQmlApplicationEngine>
#include <QImageReader>
#include <QImage>
#include <QDebug>

/* ************************************************************************** */

MediaThumbnailer_threadpool::MediaThumbnailer_threadpool(int threadCount) : QQuickAsyncImageProvider()
{
    if (threadCount > 0)
    {
        pool.setMaxThreadCount(threadCount);
    }
}

/* ************************************************************************** */

bool MediaThumbnailer_threadpool::registerQml(QQmlApplicationEngine *engine)
{
    bool status = false;

    if (engine)
    {
        // Register MediaThumbnailer_threadpool as an ImageProvider
        engine->addImageProvider("MediaThumbnailer", this);

        status = true;
    }

    return status;
}

/* ************************************************************************** */

QQuickImageResponse *MediaThumbnailer_threadpool::requestImageResponse(const QString &id, const QSize &requestedSize)
{
    //qDebug() << "Active threads: " << pool.activeThreadCount();

    MediaThumbnailerResponse *response = new MediaThumbnailerResponse(id, requestedSize, &pool);
    return response;
}

/* ************************************************************************** */
/* ************************************************************************** */

MediaThumbnailerResponse::MediaThumbnailerResponse(const QString &id, const QSize &requestedSize, QThreadPool *pool)
{
    auto runnable = new MediaThumbnailerRunner(id, requestedSize);
    connect(runnable, &MediaThumbnailerRunner::done, this, &MediaThumbnailerResponse::handleDone);
    pool->start(runnable);
}

/* ************************************************************************** */

void MediaThumbnailerResponse::handleDone(QImage image)
{
    m_image = image;
    emit finished();
}

/* ************************************************************************** */

QQuickTextureFactory *MediaThumbnailerResponse::textureFactory() const
{
    return QQuickTextureFactory::textureFactoryForImage(m_image);
}

/* ************************************************************************** */
/* ************************************************************************** */

MediaThumbnailerRunner::MediaThumbnailerRunner(const QString &id, const QSize &requestedSize)
{
    QThread::currentThread()->setPriority(QThread::LowestPriority);

    if (requestedSize.width() > 0) width = requestedSize.width();
    if (requestedSize.height() > 0) height = requestedSize.height();

    // Make sure we have a regular path and not an URL
    path = id;
    if (path.startsWith("file:///")) path.remove(0, 8);

    // Get timecode from string id, and remove it from string path
    int timecode_pos = id.lastIndexOf('@');
    if (timecode_pos)
    {
        bool timecode_validity = false;
        timecode_pos = id.size() - timecode_pos;
        timecode_s = id.rightRef(timecode_pos - 1).toInt(&timecode_validity);

        // Make sure we had a timecode and not a random '@' character
        if (timecode_validity) path.chop(timecode_pos);
    }
/*
    // RECAP
    qDebug() << "@ requestId: " << id;
    qDebug() << "@ requestPath: " << path;
    qDebug() << "@ requestedTimecode: " << timecode_s << "s";
    qDebug() << "@ requestedSize: " << requestedSize;
*/
}

/* ************************************************************************** */

void MediaThumbnailerRunner::run()
{
    bool decoding_status = false;

    QImage image;

    // Media thumbnail
    decoding_status = mediaThumbnailer.getImage(path, image, timecode_s, width, height);

    // QImage fallback
    if (decoding_status == false)
    {
        QImageReader img_infos(path);
        if (img_infos.canRead())
        {
            // check size first, don't even try to thumbnail very big (>8K) pictures
            if (img_infos.size().rwidth() < 8192 && img_infos.size().rheight() < 8192)
            {
                image.load(path);
                image = image.scaled(512, 512, Qt::KeepAspectRatio, Qt::SmoothTransformation);
            }
        }
    }

    emit done(image);
}

/* ************************************************************************** */
/* ************************************************************************** */
