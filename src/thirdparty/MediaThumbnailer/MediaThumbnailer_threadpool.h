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
#include <QDebug>

#include <QQuickImageProvider>
#include <QQuickAsyncImageProvider>

class QQmlApplicationEngine;

/* ************************************************************************** */

class MediaThumbnailerRunner : public QObject, public QRunnable
{
    Q_OBJECT

    QString path;
    int timecode_s = 0;
    int width = 512;
    int height = 512;

    ThumbnailerBackend mediaThumbnailer;

signals:
    void done(QImage image);

public:
    MediaThumbnailerRunner(const QString &id, const QSize &requestedSize);

    void run() override;
};

/* ************************************************************************** */

class MediaThumbnailerResponse : public QQuickImageResponse
{
    QImage m_image;

public:
    MediaThumbnailerResponse(const QString &id, const QSize &requestedSize, QThreadPool *pool);

    void handleDone(QImage image);

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

    bool registerQml(QQmlApplicationEngine *engine);

    QQuickImageResponse *requestImageResponse(const QString &id, const QSize &requestedSize) override;
};

/* ************************************************************************** */
#endif // MEDIA_THUMBNAILER_THREADPOOL_H
