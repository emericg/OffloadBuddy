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

#ifndef DEVICE_STORAGE_H
#define DEVICE_STORAGE_H
/* ************************************************************************** */

#include "StorageUtils.h"

#include <QObject>
#include <QVariant>
#include <QString>
#include <QList>
#include <QTimer>

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#else
typedef void LIBMTP_mtpdevice_t;
typedef void LIBMTP_devicestorage_t;
#endif // ENABLE_LIBMTP

class QStorageInfo;

/* ************************************************************************** */

/*!
 * \brief The DeviceStorage class
 *
 * Media storage for physical devices (cameras and stuff).
 */
class DeviceStorage: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString directoryPath READ getDevicePath WRITE setDevicePath NOTIFY directoryUpdated)

    Q_PROPERTY(bool available READ isAvailable NOTIFY availableUpdated)
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledUpdated)
    Q_PROPERTY(bool primary READ isPrimary WRITE setPrimary NOTIFY primaryUpdated)
    Q_PROPERTY(bool scanning READ isScanning NOTIFY scanningUpdated)

    Q_PROPERTY(bool readOnly READ isReadOnly NOTIFY storageUpdated)
    Q_PROPERTY(bool largeFileSupport READ hasLFS NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY storageUpdated)
    Q_PROPERTY(double storageLevel READ getStorageLevel NOTIFY storageUpdated)

    bool m_available = false;
    bool m_enabled = true;
    bool m_primary = false;
    bool m_scanning = false;

    int m_storage_type = 0;             //!< see StorageUtils::StorageType
    bool m_storage_lfs = true;

    // Filesystem storage
    QString m_fs_path;
    QStorageInfo *m_fs_storage = nullptr;
    QTimer m_storage_refreshTimer;
    const int m_storage_refreshInterval = 30;

    // MTP storage
    unsigned m_dcim_id = 0;
    LIBMTP_mtpdevice_t *m_mtp_device = nullptr;
    LIBMTP_devicestorage_t *m_mtp_storage = nullptr;

    void refreshMediaStorage_fs();
    void refreshMediaStorage_mtp();

Q_SIGNALS:
    void directoryUpdated();
    void availableUpdated();
    void scanningUpdated();
    void primaryUpdated();
    void enabledUpdated();
    void storageUpdated();

public slots:
    void refreshMediaStorage();

public:
    DeviceStorage(const QString &path,
                  bool primary = false, QObject *parent = nullptr);
    DeviceStorage(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage,
                  bool primary = false, QObject *parent = nullptr);
    ~DeviceStorage();

    //

    void setDeviceMtp(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage);

    QString getDevicePath();
    void setDevicePath(const QString &path);

    bool isScanning() const { return m_scanning; }
    void setScanning(bool scanning);

    //

    bool isPrimary() const { return m_primary; }
    void setPrimary(bool primary);

    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool isAvailable() const { return m_available; }

    //

    bool isReadOnly();
    bool hasLFS() const { return m_storage_lfs; }

    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();
    double getStorageLevel();
};

/* ************************************************************************** */
#endif // DEVICE_STORAGE_H
