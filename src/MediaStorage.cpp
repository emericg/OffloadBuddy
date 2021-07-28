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
 * \date      2021
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "MediaStorage.h"
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
 * \brief Used when creating a MediaStorage from a filesystem path.
 *
 * Do not check if the path exists, we are allow to save paths that have been
 * disconnected since (ex: removable media, disconnected network storage).
 */
MediaStorage::MediaStorage(const QString &path, bool primary, QObject *parent)
    : QObject(parent)
{
    m_storage_type = StorageUtils::StorageFilesystem;

    setDevicePath(path);

    m_content = 0;
    m_hierarchy = 0;
    m_enabled = true;
    m_primary = primary;

    m_storage_refreshTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
    connect(&m_storage_refreshTimer, &QTimer::timeout, this, &MediaStorage::refreshMediaStorage);
    m_storage_refreshTimer.start();
}

/*!
 * \brief Used when creating a MediaStorage from a MTP device.
 */
MediaStorage::MediaStorage(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage,
                           bool primary, QObject *parent)
    : QObject(parent)
{
    m_storage_type = StorageUtils::StorageMtp;

    setDeviceMtp(device, storage);

    m_content = 0;
    m_hierarchy = 0;
    m_enabled = true;
    m_primary = primary;

    m_storage_refreshTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
    connect(&m_storage_refreshTimer, &QTimer::timeout, this, &MediaStorage::refreshMediaStorage);
    m_storage_refreshTimer.start();
}

MediaStorage::~MediaStorage()
{
    delete m_fs_storage;

    // cleanup MTP cleanup handled by Device class
}

/* ************************************************************************** */

/*!
 * \brief MediaStorage::setDevicePath
 * \param path: The path of this MediaStorage
 *
 * We could 'force create' the directory here, but there are many cases were it
 * could lead to unintended behavior.
 * Ex: A user set its output directory to E:/Videos.
 * Next time the soft is opened, E:/ exists, but Videos doesn't anymore, because
 * E:/ was a removable media and it is not the same disk anymore. Do we want to take
 * the risk to inadvertantly use another disk or just let the user know that its
 * output directory is now invalid?
 */
void MediaStorage::setDevicePath(const QString &path)
{
    if (m_fs_path != path)
    {
        m_fs_path = path;

        // Make sure the path is terminated with a separator.
        if (!m_fs_path.endsWith('/')) m_fs_path += '/';

        emit directoryUpdated();
        emit saveData();

        if (m_fs_storage)
        {
            delete m_fs_storage;
            m_fs_storage = nullptr;
        }
        refreshMediaStorage();
    }
}

QString MediaStorage::getDevicePath()
{
    if (m_storage_type == StorageUtils::StorageFilesystem)
    {
        return m_fs_path;
    }

#ifdef ENABLE_LIBMTP
    if (m_storage_type == StorageUtils::StorageMtp)
    {
        return m_mtp_storage->VolumeIdentifier;
    }
#endif // ENABLE_LIBMTP

    return QString();
}

void MediaStorage::setDeviceMtp(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage)
{
    if (device && storage)
    {
        m_mtp_device = device;
        m_mtp_storage = storage;
    }
}

/* ************************************************************************** */

void MediaStorage::setContent(int content)
{
    if (m_content != content)
    {
        m_content = content;
        emit directoryUpdated();
        emit saveData();
    }
}

void MediaStorage::setHierarchy(int hierarchy)
{
    if (m_hierarchy != hierarchy)
    {
        m_hierarchy = hierarchy;
        emit directoryUpdated();
        emit saveData();
    }
}

void MediaStorage::setEnabled(bool enabled)
{
    if (m_enabled != enabled)
    {
        m_enabled = enabled;
        emit enabledUpdated();
        emit saveData();
    }
}

void MediaStorage::setPrimary(bool primary)
{
    if (m_primary != primary)
    {
        m_primary = primary;
        emit primaryUpdated();
        emit saveData();
    }
}

void MediaStorage::setScanning(bool scanning)
{
    if (scanning != m_scanning)
    {
        m_scanning = scanning;
        emit scanningUpdated();
        emit saveData();
    }
}

bool MediaStorage::isAvailableFor(unsigned shotType, int64_t shotSize)
{
    bool available = false;

    refreshMediaStorage();

    if (m_available && m_fs_storage && !m_fs_storage->isReadOnly())
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

void MediaStorage::refreshMediaStorage()
{
    refreshMediaStorage_fs();
    refreshMediaStorage_mtp();
}

void MediaStorage::refreshMediaStorage_mtp()
{
#ifdef ENABLE_LIBMTP
    // TODO? or space related values kept up to date by the lib?
#endif // ENABLE_LIBMTP
}

void MediaStorage::refreshMediaStorage_fs()
{
    // We have a storage object
    if (m_fs_storage)
    {
        // If there was a storage available, but it disappeared since, delete it
        if (m_fs_storage->rootPath().isEmpty())
        {
            delete m_fs_storage;
            m_fs_storage = nullptr;
        }
        else
        {
            // If there is a storage available, refresh it
            m_fs_storage->refresh();
            emit storageUpdated();
        }
    }

    // We don't have a storage object, try to create one
    if (!m_fs_storage)
    {
        m_fs_storage = new QStorageInfo(m_fs_path);
        emit storageUpdated();
    }

    // Now update the 'm_available' state
    if (m_fs_storage && m_fs_storage->isValid() && m_fs_storage->isReady())
    {
        //qDebug() << "refreshMediaStorage(" << m_fs_storage->rootPath() << ")";

        if (m_fs_storage->fileSystemType() == "vfat" ||
            m_fs_storage->fileSystemType() == "fat16" ||
            m_fs_storage->fileSystemType() == "fat32")
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
        if (!m_fs_storage->isReadOnly() && m_fs_storage->bytesAvailable() > 8*1024*1024)
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
            qDebug() << "MediaStorage(" << m_path << ") is not available: read only or full";
            m_available = false;
            emit availableUpdated();
        }
*/
    }
    else
    {
        if (m_available == true)
        {
            qWarning() << "MediaStorage(" << m_fs_path << ") is not available: invalid or not ready";
            m_available = false;
            emit availableUpdated();
        }
    }
}

/* ************************************************************************** */

bool MediaStorage::isReadOnly()
{
    if (m_storage_type == StorageUtils::StorageFilesystem)
    {
        if (m_fs_storage)
            return m_fs_storage->isReadOnly();
    }

#ifdef ENABLE_LIBMTP
    if (m_storage_type == StorageUtils::StorageMtp)
    {
        // TODO
    }
#endif // ENABLE_LIBMTP

    return false;
}

int64_t MediaStorage::getSpaceTotal()
{
    if (m_storage_type == StorageUtils::StorageFilesystem)
    {
        if (m_fs_storage)
            return m_fs_storage->bytesTotal();
    }

#ifdef ENABLE_LIBMTP
    if (m_storage_type == StorageUtils::StorageMtp)
    {
        if (m_mtp_storage)
            return m_mtp_storage->MaxCapacity;
    }
#endif // ENABLE_LIBMTP

    return 0;
}

int64_t MediaStorage::getSpaceUsed()
{
    if (m_storage_type == StorageUtils::StorageFilesystem)
    {
        if (m_fs_storage)
            return (m_fs_storage->bytesTotal() - m_fs_storage->bytesAvailable());
    }

#ifdef ENABLE_LIBMTP
    if (m_storage_type == StorageUtils::StorageMtp)
    {
        if (m_mtp_storage)
            return (m_mtp_storage->MaxCapacity - m_mtp_storage->FreeSpaceInBytes);
    }
#endif // ENABLE_LIBMTP

    return 0;
}

int64_t MediaStorage::getSpaceAvailable()
{
    if (m_storage_type == StorageUtils::StorageFilesystem)
    {
        if (m_fs_storage)
            return m_fs_storage->bytesAvailable();
    }

#ifdef ENABLE_LIBMTP
    if (m_storage_type == StorageUtils::StorageMtp)
    {
        if (m_mtp_storage)
            return m_mtp_storage->FreeSpaceInBytes;
    }
#endif // ENABLE_LIBMTP

    return 0;
}

int64_t MediaStorage::getSpaceAvailable_withrefresh()
{
    refreshMediaStorage();
    return getSpaceAvailable();
}

double MediaStorage::getStorageLevel()
{
    if (m_storage_type == StorageUtils::StorageFilesystem)
    {
        if (m_fs_storage)
            return static_cast<double>(getSpaceUsed()) / static_cast<double>(m_fs_storage->bytesTotal());
    }

    return 0.0;
}

/* ************************************************************************** */
