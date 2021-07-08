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

    QString m_path;
    int m_content_type = 0; // see Utils::ContentTypes (dSphere)
    int m_content_hierarchy = 0; // (not implemented)

    bool m_primary = false;
    bool m_enabled = true;
    bool m_available = false;
    bool m_scanning = false;

    int m_storage_type = 0; // (not implemented)
    bool m_storage_lfs = true;
    QStorageInfo *m_storage = nullptr;
    QTimer m_storage_refreshTimer;

Q_SIGNALS:
    void directoryUpdated();
    void availableUpdated();
    void scanningUpdated();
    void primaryUpdated();
    void enabledUpdated();
    void storageUpdated();
    void saveData();

private slots:
    void refreshMediaDirectory();

public:
    MediaDirectory(QObject *parent = nullptr);
    MediaDirectory(const QString &path, int content, int hierarchy,
                   bool enabled = true, bool primary = false, QObject *parent = nullptr);
    ~MediaDirectory();

    //

    QString getPath() { return m_path; }
    void setPath(const QString &path);

    int getContent() const { return m_content_type; }
    void setContent(int content);

    int getHierarchy() const { return m_content_hierarchy; }
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
#endif // MEDIA_DIRECTORY_H
