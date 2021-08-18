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

#ifndef MEDIA_DIRECTORY_H
#define MEDIA_DIRECTORY_H
/* ************************************************************************** */

#include "StorageUtils.h"

#include <QObject>
#include <QVariant>
#include <QString>
#include <QList>
#include <QTimer>

class QStorageInfo;

/* ************************************************************************** */

/*!
 * \brief The MediaDirectory class
 *
 * Media directories are parts of the media library.
 * You can add or delete them from the settings screen.
 */
class MediaDirectory: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString directoryPath READ getPath WRITE setPath NOTIFY directoryUpdated)
    Q_PROPERTY(int directoryContent READ getContent WRITE setContent NOTIFY directoryUpdated)
    Q_PROPERTY(int directoryHierarchy READ getHierarchyMode WRITE setHierarchyMode NOTIFY directoryUpdated)
    Q_PROPERTY(QString directoryHierarchyCustom READ getHierarchyCustom WRITE setHierarchyCustom NOTIFY directoryUpdated)

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

    QString m_path;
    int m_content = StorageUtils::ContentAll;                   //!< see StorageUtils::StorageContent
    int m_hierarchy_mode = StorageUtils::HierarchyDateShot;     //!< see StorageUtils::StorageHierarchy
    QString m_hierarchy_custom;                                 //!< regex

    bool m_available = false;
    bool m_enabled = true;
    bool m_primary = false;
    bool m_scanning = false;

    int m_storage_type = 0;             //!< see StorageUtils::StorageType
    bool m_storage_lfs = true;
    QStorageInfo *m_storage = nullptr;
    QTimer m_storage_refreshTimer;
    const int m_storage_refreshInterval = 30;

Q_SIGNALS:
    void directoryUpdated(const QString &);
    void availableUpdated(const QString &, bool);
    void scanningUpdated(const QString &);
    void primaryUpdated(const QString &);
    void enabledUpdated(const QString &, bool);
    void storageUpdated();
    void saveData();

private slots:
    void refreshMediaDirectory();

public:
    MediaDirectory(QObject *parent = nullptr);
    MediaDirectory(const QString &path, int content,
                   int hierarchy_mode, const QString &hierarchy_custom,
                   bool enabled = true, bool primary = false, QObject *parent = nullptr);
    ~MediaDirectory();

    //

    QString getPath() { return m_path; }
    void setPath(const QString &path);

    bool isScanning() const { return m_scanning; }
    void setScanning(bool scanning);

    //

    int getContent() const { return m_content; }
    void setContent(int content);

    int getHierarchyMode() const { return m_hierarchy_mode; }
    void setHierarchyMode(int hierarchy);

    QString getHierarchyCustom() const { return m_hierarchy_custom; }
    void setHierarchyCustom(QString hierarchy);

    bool isPrimary() const { return m_primary; }
    void setPrimary(bool primary);

    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool isAvailable() const { return m_available; }
    bool isAvailableFor(unsigned shotType, int64_t shotSize);

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
#endif // MEDIA_DIRECTORY_H
