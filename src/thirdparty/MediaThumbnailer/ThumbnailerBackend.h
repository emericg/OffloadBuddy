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

#ifndef THUMBNAILER_BACKEND_H
#define THUMBNAILER_BACKEND_H
/* ************************************************************************** */

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
    ThumbnailerBackendInterface *m_backend = nullptr;

public:
    ThumbnailerBackend();
    virtual ~ThumbnailerBackend() = default;

    virtual bool getImage(const QString &path, QImage &image,
                  const int timecode_s, const int width, const int height)
    {
        if (m_backend) return m_backend->getImage(path, image, timecode_s, width, height);

        return false;
    }
};

/* ************************************************************************** */
#endif // THUMBNAILER_BACKEND_H
