/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "MediaDirectory.h"
#include "Shot.h"

#include <QStandardPaths>
#include <QStorageInfo>
#include <QDir>

#include <QSettings>
#include <QDebug>

#define MEDIA_DIRECTORIES_REFRESH_INTERVAL 30

/* ************************************************************************** */

/*!
 * \brief Used when there is no saved MediaDirectory.
 */
MediaDirectory::MediaDirectory()
{
    // Use default path:
    // Linux '/home/USERNAME/Videos/OffloadBuddy'
    // macOS '/Users/USERNAME/Movies/OffloadBuddy'
    // Windows 'C:/Users/USERNAME/Videos/OffloadBuddy'

    QString path = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    if (!path.endsWith('/')) path += '/';
    path += "OffloadBuddy/";
    QDir path_dir(path);

    if (!path_dir.exists())
    {
        path_dir.mkpath(path);
    }

    if (path_dir.exists())
    {
        setPath(path);
        setContent(CONTENT_ALL);

        m_refreshTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
        connect(&m_refreshTimer, &QTimer::timeout, this, &MediaDirectory::refreshMediaDirectory);
        m_refreshTimer.start();
    }
}

/*!
 * \brief Used when loading a saved MediaDirectory.
 *
 * Do not check if the path exists, we are allow to save paths that have been
 * disconnected since (ex: removable media).
 */
MediaDirectory::MediaDirectory(const QString &path, int content, bool primary)
{
    setPath(path);
    setContent(content);
    m_primary = primary;

    m_refreshTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
    connect(&m_refreshTimer, &QTimer::timeout, this, &MediaDirectory::refreshMediaDirectory);
    m_refreshTimer.start();
}

MediaDirectory::~MediaDirectory()
{
    delete m_storage;
}

/* ************************************************************************** */

/*!
 * \brief MediaDirectory::setPath
 * \param path: The path of this MediaDirectory
 *
 * We could 'force create' the directory here, but there are many cases were it
 * could lead to unintended behavior.
 * Ex: A user set its output directory to E:/Videos.
 * Next time the soft is opened, E:/ exists, but Videos doesn't anymore, because
 * E:/ was a removable media and it is not the same disk anymore. Do we want to take
 * the risk to inadvertantly use another disk or just let the user know that its
 * output directory is now invalid?
 */
void MediaDirectory::setPath(const QString &path)
{
    m_path = path;

    // Make sure the path is terminated with a separator.
    if (!m_path.endsWith('/')) m_path += '/';

    emit directoryUpdated();

    if (m_storage)
    {
        delete m_storage;
        m_storage = nullptr;
    }

    refreshMediaDirectory();
}

void MediaDirectory::setContent(int content)
{
    m_content_type = content;
}

bool MediaDirectory::isAvailableFor(unsigned shotType, int64_t shotSize)
{
    bool available = false;

    refreshMediaDirectory();

    if (m_available && m_storage && !m_storage->isReadOnly())
    {
        if (shotSize < getSpaceAvailable())
        {
            if ((shotType == Shared::SHOT_UNKNOWN && m_content_type == CONTENT_ALL) ||
                (shotType < Shared::SHOT_PICTURE && (m_content_type == CONTENT_VIDEOS || m_content_type == CONTENT_ALL)) ||
                (shotType >= Shared::SHOT_PICTURE && (m_content_type == CONTENT_PICTURES || m_content_type == CONTENT_ALL)))
            {
                available = true;
            }
        }
    }

    return available;
}

void MediaDirectory::setScanning(bool scanning)
{
    if (scanning != m_scanning)
    {
        m_scanning = scanning;
        emit scanningUpdated();
    }
}

/* ************************************************************************** */

void MediaDirectory::refreshMediaDirectory()
{
    if (m_storage)
    {
        // If there was a storage available, but it disappeared since, delete it
        if (m_storage->rootPath().isEmpty())
        {
            delete m_storage;
            m_storage = nullptr;
        }
        else
        {
            // If there is a storage available, refresh it
            m_storage->refresh();
            emit storageUpdated();
        }
    }

    // Otherwise, try to recreate one
    if (!m_storage)
    {
        m_storage = new QStorageInfo(m_path);
    }

    if (m_storage && m_storage->isValid() && m_storage->isReady())
    {
        //qDebug() << "refreshMediaDirectory(" << m_storage->rootPath() << ")";

        m_available = true;
        emit availableUpdated();
/*
        // basic checks // need at least 16MB
        if (m_storage->bytesAvailable() > 16*1024*1024 && !m_storage->isReadOnly())
        {
#ifdef __linux
            // Advanced permission checks
            QFileInfo fi(m_path);
            QFile::Permissions e = fi.permissions();
            if (!e.testFlag(QFileDevice::WriteUser))
            {
                qDebug() << "QFile::Permissions error:" << e << (unsigned)e;
                m_available = false;
                emit availableUpdated();
            }
            else
#endif // __linux
            {
                m_available = true;
                emit availableUpdated();
            }
        }
        else
        {
            qDebug() << "MediaDirectory(" << m_path << ") is not available: read only or full";
            m_available = false;
            emit availableUpdated();
        }
*/
    }
    else
    {
        //qDebug() << "MediaDirectory(" << m_path << ") is not available: invalid";

        m_available = false;
        emit availableUpdated();
    }
}

bool MediaDirectory::isReadOnly()
{
    if (m_storage)
        return m_storage->isReadOnly();

    return false;
}

int64_t MediaDirectory::getSpaceTotal()
{
    if (m_storage)
        return m_storage->bytesTotal();

    return 0;
}

int64_t MediaDirectory::getSpaceUsed()
{
    if (m_storage)
        return (m_storage->bytesTotal() - m_storage->bytesAvailable());

    return 0;
}

double MediaDirectory::getSpaceUsed_percent()
{
    if (m_storage)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(m_storage->bytesTotal());

    return 0.0;
}

int64_t MediaDirectory::getSpaceAvailable()
{
    if (m_storage)
        return m_storage->bytesAvailable();

    return 0;
}

int64_t MediaDirectory::getSpaceAvailable_withrefresh()
{
    refreshMediaDirectory();
    return getSpaceAvailable();
}

/* ************************************************************************** */
