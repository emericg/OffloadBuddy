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
#include "MediaThumbnailer_utils.h"

#include <QQmlEngine>
#include <QImageReader>
#include <QImage>
#include <QDebug>

/* ************************************************************************** */
/* ************************************************************************** */

MediaThumbnailer_threadpool::MediaThumbnailer_threadpool(int threadCount) : QQuickAsyncImageProvider()
{
    if (threadCount > 0)
    {
        pool.setMaxThreadCount(threadCount);
        pool.setThreadPriority(QThread::LowestPriority);
        pool.setObjectName("MediaThumbnailer");
    }
}

/* ************************************************************************** */

MediaThumbnailer_threadpool *MediaThumbnailer_threadpool::registerToEngine(QQmlEngine *engine, int threadCount)
{
    if (!engine) return nullptr;

    auto *provider = new MediaThumbnailer_threadpool(threadCount);
    engine->addImageProvider("MediaThumbnailer", provider);

    return provider;
}

/* ************************************************************************** */

bool MediaThumbnailer_threadpool::registerQml(QQmlEngine *engine)
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
    : m_cancelled(new QAtomicInt(0))
{
    auto runnable = new MediaThumbnailerRunner(id, requestedSize, m_cancelled);
    connect(runnable, &MediaThumbnailerRunner::done, this, &MediaThumbnailerResponse::handleDone);
    pool->start(runnable);
}

/* ************************************************************************** */

void MediaThumbnailerResponse::cancel()
{
    // Signal the runner to bail out
    m_cancelled->storeRelaxed(1);
}

/* ************************************************************************** */

void MediaThumbnailerResponse::handleDone(const QImage &image)
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

MediaThumbnailerRunner::MediaThumbnailerRunner(const QString &id, const QSize &requestedSize,
                                               const QSharedPointer<QAtomicInt> &cancelled)
    : m_cancelled(cancelled)
{
    //QThread::currentThread()->setPriority(QThread::LowestPriority);

    width = requestedSize.width() > 0 ? requestedSize.width() : DEFAULT_THUMB_SIZE;
    height = requestedSize.height() > 0 ? requestedSize.height() : DEFAULT_THUMB_SIZE;

    // Parse the request id into a path and an (optional) timecode
    const MediaThumbnailerUtils::ParsedRequest req = MediaThumbnailerUtils::parseRequestId(id);
    path = req.path;
    timecode_s = req.timecode_s;
/*
    // RECAP
    qDebug() << "@ requestId: " << id;
    qDebug() << "@ requestPath: " << path;
    qDebug() << "@ requestedTimecode: " << timecode_s << "s";
    qDebug() << "@ requestedSize: " << requestedSize;
    qDebug() << "@ width/height: " << width << "/" << height;
*/
}

/* ************************************************************************** */

void MediaThumbnailerRunner::run()
{
    QImage thumb;

    // Response already cancelled? Skip all decoding and return an empty image!
    if (m_cancelled->loadRelaxed())
    {
        emit done(thumb);
        return;
    }

    bool decoding_status = false;

    // Image thumbnail?
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

    // Media thumbnail? (re-check cancellation before starting)
    if (decoding_status == false && !m_cancelled->loadRelaxed())
    {
        mediaThumbnailer.getImage(path, thumb, timecode_s, width, height);
    }

    emit done(thumb);
}

/* ************************************************************************** */
/* ************************************************************************** */
