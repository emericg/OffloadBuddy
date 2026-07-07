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

#ifndef MEDIA_THUMBNAILER_THREADPOOL_H
#define MEDIA_THUMBNAILER_THREADPOOL_H
/* ************************************************************************** */

#include "ThumbnailerBackend.h"

#include <QImage>
#include <QThreadPool>
#include <QAtomicInt>
#include <QSharedPointer>
#include <QDebug>

#include <QQuickImageProvider>
#include <QQuickAsyncImageProvider>

class QQmlEngine;

/* ************************************************************************** */

class MediaThumbnailerRunner : public QObject, public QRunnable
{
    Q_OBJECT

    const int DEFAULT_THUMB_SIZE = 512;

    QString path;
    int timecode_s = 0;
    int width = DEFAULT_THUMB_SIZE;
    int height = DEFAULT_THUMB_SIZE;

    ThumbnailerBackend mediaThumbnailer;

    //! Shared with the owning response so cancel() can be observed from the pool thread
    QSharedPointer<QAtomicInt> m_cancelled;

signals:
    void done(const QImage &image);

public:
    MediaThumbnailerRunner(const QString &id, const QSize &requestedSize,
                           const QSharedPointer<QAtomicInt> &cancelled);

    void run() override;
};

/* ************************************************************************** */

class MediaThumbnailerResponse : public QQuickImageResponse
{
    QImage m_image;

    //! Shared with the runner; raised by cancel() to skip pending/ongoing decoding
    QSharedPointer<QAtomicInt> m_cancelled;

public:
    MediaThumbnailerResponse(const QString &id, const QSize &requestedSize, QThreadPool *pool);

    void handleDone(const QImage &image);

    void cancel() override;

    QQuickTextureFactory *textureFactory() const override;
};

/* ************************************************************************** */

/*!
 * \brief The MediaThumbnailer_threadpool class
 */
class MediaThumbnailer_threadpool : public QQuickAsyncImageProvider
{
    QThreadPool pool;

public:
    MediaThumbnailer_threadpool(int threadCount = -1);

    /*!
     * \brief Create the provider and register it to a QML engine under the "MediaThumbnailer" scheme.
     * \param engine: The QML engine of your application.
     * \param threadCount: Number of thread the threadpool is allowed to use.
     * \return Pointer to the QQuickAsyncImageProvider created.
     *
     * The engine takes ownership of the returned provider and deletes it on teardown (do not delete it yourself).
     */
    static MediaThumbnailer_threadpool *registerToEngine(QQmlEngine *engine, int threadCount = -1);

    bool registerQml(QQmlEngine *engine);

    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;
};

/* ************************************************************************** */
#endif // MEDIA_THUMBNAILER_THREADPOOL_H
