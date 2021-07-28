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
#include "StorageManager.h"
#include "Shot.h"

#include <limits>

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
MediaDirectory::MediaDirectory(QObject *parent)
    : QObject(parent)
{
    // Use default path:
    // Linux '/home/USERNAME/Videos/OffloadBuddy'
    // macOS '/Users/USERNAME/Movies/OffloadBuddy'
    // Windows 'C:/Users/USERNAME/Videos/OffloadBuddy'

    QString path = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    if (!path.endsWith('/')) path += '/';
    path += "OffloadBuddy/";

    QDir path_dir(path);
    if (!path_dir.exists()) path_dir.mkpath(path);

    if (path_dir.exists())
    {
        setPath(path);
        setContent(StorageUtils::ContentAll);
        m_enabled = true;
        m_primary = true;

        m_storage_refreshTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
        connect(&m_storage_refreshTimer, &QTimer::timeout, this, &MediaDirectory::refreshMediaDirectory);
        m_storage_refreshTimer.start();
    }
}

/*!
 * \brief Used when loading a saved MediaDirectory.
 *
 * Do not check if the path exists, we are allow to save paths that have been
 * disconnected since (ex: removable media).
 */
MediaDirectory::MediaDirectory(const QString &path, int content, int hierarchy,
                               bool enabled, bool primary, QObject *parent)
    : QObject(parent)
{
    setPath(path);

    m_content = content;
    m_hierarchy = hierarchy;
    m_enabled = enabled;
    m_primary = primary;

    m_storage_refreshTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
    connect(&m_storage_refreshTimer, &QTimer::timeout, this, &MediaDirectory::refreshMediaDirectory);
    m_storage_refreshTimer.start();
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
    if (m_path != path)
    {
        m_path = path;

        // Make sure the path is terminated with a separator.
        if (!m_path.endsWith('/')) m_path += '/';

        emit directoryUpdated();
        emit saveData();

        if (m_storage)
        {
            delete m_storage;
            m_storage = nullptr;
        }
        refreshMediaDirectory();
    }
}

void MediaDirectory::setContent(int content)
{
    if (m_content != content)
    {
        m_content = content;
        emit directoryUpdated();
        emit saveData();
    }
}

void MediaDirectory::setHierarchy(int hierarchy)
{
    if (m_hierarchy != hierarchy)
    {
        m_hierarchy = hierarchy;
        emit directoryUpdated();
        emit saveData();
    }
}

void MediaDirectory::setEnabled(bool enabled)
{
    if (m_enabled != enabled)
    {
        m_enabled = enabled;
        emit enabledUpdated();
        emit saveData();
    }
}

void MediaDirectory::setPrimary(bool primary)
{
    if (m_primary != primary)
    {
        m_primary = primary;
        emit primaryUpdated();
        emit saveData();
    }
}

void MediaDirectory::setScanning(bool scanning)
{
    if (scanning != m_scanning)
    {
        m_scanning = scanning;
        emit scanningUpdated();
        emit saveData();
    }
}

bool MediaDirectory::isAvailableFor(unsigned shotType, int64_t shotSize)
{
    bool available = false;

    refreshMediaDirectory();

    if (m_available && m_storage && !m_storage->isReadOnly())
    {
        if (shotSize < getSpaceAvailable())
        {
            if ((shotType == ShotUtils::SHOT_UNKNOWN && m_content == StorageUtils::ContentAll) ||
                (shotType < ShotUtils::SHOT_PICTURE && (m_content == StorageUtils::ContentAll || m_content == StorageUtils::ContentVideo)) ||
                (shotType >= ShotUtils::SHOT_PICTURE && (m_content == StorageUtils::ContentAll || m_content == StorageUtils::ContentPictures)))
            {
                available = true;
            }

            if (!m_storage_lfs && shotSize > std::numeric_limits<long long>::max())
            {
                available = false;
            }
        }
    }

    return available;
}

/* ************************************************************************** */

void MediaDirectory::refreshMediaDirectory()
{
    // We have a storage object
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

    // We don't have a storage object, try to create one
    if (!m_storage)
    {
        m_storage = new QStorageInfo(m_path);
        emit storageUpdated();
    }

    // Now update the 'm_available' state
    if (m_storage && m_storage->isValid() && m_storage->isReady())
    {
        //qDebug() << "refreshMediaDirectory(" << m_storage->rootPath() << ")";

        if (m_storage->fileSystemType() == "vfat" ||
            m_storage->fileSystemType() == "fat16" ||
            m_storage->fileSystemType() == "fat32")
        {
            // this storage only support 4GiB files
            m_storage_lfs = false;
            emit storageUpdated();
        }

        if (m_available == false)
        {
            m_available = true;
            emit availableUpdated();
        }
/*
        // Basic checks // need at least 8 MB
        if (!m_storage->isReadOnly() && m_storage->bytesAvailable() > 8*1024*1024)
        {
#if defined(Q_OS_LINUX)
            // Advanced permission checks
            QFileInfo fi(m_path);
            QFile::Permissions e = fi.permissions();
            if (!e.testFlag(QFileDevice::WriteUser))
            {
                qWarning() << "QFile::Permissions error:" << e << (unsigned)e;
                m_available = false;
                emit availableUpdated();
            }
            else
#endif // defined(Q_OS_LINUX)
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
        if (m_available == true)
        {
            qWarning() << "MediaDirectory(" << m_path << ") is not available: invalid or not ready";
            m_available = false;
            emit availableUpdated();
        }
    }
}

/* ************************************************************************** */

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

double MediaDirectory::getStorageLevel()
{
    if (m_storage)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(m_storage->bytesTotal());

    return 0.0;
}

/* ************************************************************************** */
