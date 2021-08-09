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
 * \date      2020
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#ifndef STORAGE_MANAGER_H
#define STORAGE_MANAGER_H
/* ************************************************************************** */

#include "MediaDirectory.h"

#include <QObject>
#include <QVariant>
#include <QString>
#include <QList>
#include <QTimer>

class QStorageInfo;

/* ************************************************************************** */

namespace StorageUtils
{
    Q_NAMESPACE

    enum StorageType
    {
        StorageUnknown = 0,
        StorageFilesystem,
        StorageVirtualFilesystem,
        StorageNetworkFilesystem,
        StorageMTP,
    };
    Q_ENUM_NS(StorageType)

    enum StorageContent
    {
        ContentAll = 0,
        ContentAudio,
        ContentVideo,
        ContentPictures,
    };
    Q_ENUM_NS(StorageContent)

    enum StorageHierarchy
    {
        HierarchyNone = 0,
        HierarchyShot,
        HierarchyDateShot,
        HierarchyDateDeviceShot,
    };
    Q_ENUM_NS(StorageHierarchy)

    enum DeviceType
    {
        DeviceUnknown = 0,
        DeviceActionCamera,
        DeviceCamera,
        DeviceMobile,
        DeviceComputer,
    };
    Q_ENUM_NS(DeviceType)
}

/*!
 * \brief The StorageManager class
 */
class StorageManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(uint contentHierarchy READ getContentHierarchy WRITE setContentHierarchy NOTIFY contentHierarchyChanged)
    Q_PROPERTY(uint directoriesCount READ getDirectoriesCount NOTIFY directoriesUpdated)
    Q_PROPERTY(QVariant directoriesList READ getDirectories NOTIFY directoriesUpdated)

    // Media directories
    static const int max_media_directories = 16;
    unsigned m_contentHierarchy = 0;
    QList <QObject *> m_mediaDirectories;

    // Saved settings
    bool readSettings();
    bool writeSettings();

    // Singleton
    static StorageManager *instance;
    StorageManager();
    ~StorageManager();

Q_SIGNALS:
    void contentHierarchyChanged();
    void directoriesUpdated();
    void directoryAdded(const QString &);
    void directoryRemoved(const QString &);

public slots:
    void directoryAvailabilityModified(const QString &, bool);
    void directoryModified();

public:
    static StorageManager *getInstance();

    void createDefaultDirectory();

    QVariant getDirectories() const { if (m_mediaDirectories.size() > 0) { return QVariant::fromValue(m_mediaDirectories); } return QVariant(); }
    unsigned getDirectoriesCount() const { return m_mediaDirectories.size(); }
    const QList <QObject *> *getDirectoriesList() const { return &m_mediaDirectories; }

    unsigned getContentHierarchy() const { return m_contentHierarchy; }
    void setContentHierarchy(unsigned value);

    Q_INVOKABLE void addDirectory(const QString &path);
    Q_INVOKABLE void removeDirectory(const QString &path);
};

/* ************************************************************************** */
#endif // STORAGE_MANAGER_H
