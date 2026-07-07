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

#ifndef THUMBNAILER_BACKEND_H
#define THUMBNAILER_BACKEND_H
/* ************************************************************************** */

#include <memory>

#include <QString>
#include <QImage>

/* ************************************************************************** */

class ThumbnailerBackendInterface
{
public:
    virtual ~ThumbnailerBackendInterface() = default;

    virtual bool getImage(const QString &path, QImage &img,
                          const int timecode_s,
                          const int width, const int height) = 0;
};

/* ************************************************************************** */

/*!
 * \brief The ThumbnailerBackend class
 */
class ThumbnailerBackend : public ThumbnailerBackendInterface
{
protected:
    std::unique_ptr<ThumbnailerBackendInterface> m_backend;

public:
    ThumbnailerBackend();
    virtual ~ThumbnailerBackend() = default;

    virtual bool getImage(const QString &path, QImage &image,
                  const int timecode_s, const int width, const int height) override
    {
        if (m_backend) return m_backend->getImage(path, image, timecode_s, width, height);

        return false;
    }
};

/* ************************************************************************** */
#endif // THUMBNAILER_BACKEND_H
