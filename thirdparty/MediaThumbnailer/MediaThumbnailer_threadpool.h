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
