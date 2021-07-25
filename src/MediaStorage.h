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

#ifndef MEDIA_STORAGE_H
#define MEDIA_STORAGE_H
/* ************************************************************************** */

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
 * \brief The MediaStorage class
 *
 * Media storage for physical devices (cameras and stuff).
 */
class MediaStorage: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString directoryPath READ getDevicePath WRITE setDevicePath NOTIFY directoryUpdated)
    Q_PROPERTY(int directoryContent READ getContent WRITE setContent NOTIFY directoryUpdated)
    Q_PROPERTY(int directoryHierarchy READ getHierarchy WRITE setHierarchy NOTIFY directoryUpdated)

    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledUpdated)
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableUpdated)
    Q_PROPERTY(bool primary READ isPrimary NOTIFY primaryUpdated)
    Q_PROPERTY(bool scanning READ isScanning NOTIFY scanningUpdated)
    Q_PROPERTY(bool readOnly READ isReadOnly NOTIFY storageUpdated)
    Q_PROPERTY(bool largeFileSupport READ hasLFS NOTIFY storageUpdated)

    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY storageUpdated)
    Q_PROPERTY(double storageLevel READ getStorageLevel NOTIFY storageUpdated)

    int m_content = 0;                  // see StorageUtils::StorageContent
    int m_hierarchy = 0;                // see StorageUtils::StorageHierarchy

    bool m_primary = false;
    bool m_enabled = true;
    bool m_available = false;
    bool m_scanning = false;

    int m_storage_type = 0;             // see StorageUtils::StorageType
    bool m_storage_lfs = true;

    QTimer m_storage_refreshTimer;

    // Filesystem storage
    QString m_fs_path;
    QStorageInfo *m_fs_storage = nullptr;

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
    void saveData();

public slots:
    void refreshMediaStorage();

public:
    MediaStorage(const QString &path,
                 bool primary = false, QObject *parent = nullptr);
    MediaStorage(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage,
                 bool primary = false, QObject *parent = nullptr);
    ~MediaStorage();

    //

    void setDeviceMtp(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage);

    QString getDevicePath();
    void setDevicePath(const QString &path);

    //

    int getContent() const { return m_content; }
    void setContent(int content);

    int getHierarchy() const { return m_hierarchy; }
    void setHierarchy(int hierarchy);

    //

    bool isPrimary() const { return m_primary; }
    void setPrimary(bool primary);

    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool isAvailable() const { return m_available; }
    bool isAvailableFor(unsigned shotType, int64_t shotSize);

    bool isScanning() const { return m_scanning; }
    void setScanning(bool scanning);

    bool isReadOnly();
    bool hasLFS() const { return m_storage_lfs; }

    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();
    double getStorageLevel();
};

/* ************************************************************************** */
#endif // MEDIA_STORAGE_H
