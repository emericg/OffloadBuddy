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

    Q_PROPERTY(bool primary READ isPrimary NOTIFY directoryUpdated)

    Q_PROPERTY(bool enabled READ isEnabled NOTIFY enabledUpdated)
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableUpdated)
    Q_PROPERTY(bool scanning READ isScanning NOTIFY scanningUpdated)

    Q_PROPERTY(bool readOnly READ isReadOnly NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY storageUpdated)
    Q_PROPERTY(double storageLevel READ getSpaceUsed_percent NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY storageUpdated)

    QString m_path;
    int m_content_type = 0;
    int m_storage_type = 0;

    bool m_primary = false;
    bool m_enabled = false;
    bool m_available = false;
    bool m_scanning = false;

    QStorageInfo *m_storage = nullptr;
    QTimer m_refreshTimer;

Q_SIGNALS:
    void directoryUpdated();
    void enabledUpdated();
    void availableUpdated();
    void scanningUpdated();
    void storageUpdated();

private slots:
    void refreshMediaDirectory();

public:
    MediaDirectory(QObject *parent = nullptr);
    MediaDirectory(const QString &path, int content, bool primary = false, QObject *parent = nullptr);
    ~MediaDirectory();

public slots:
    QString getPath() { return m_path; }
    void setPath(const QString &path);

    int getContent() const { return m_content_type; }
    void setContent(int content);

    bool isPrimary() const { return m_primary; }

    bool isEnabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool isAvailable() const { return m_available; }
    bool isAvailableFor(unsigned shotType, int64_t shotSize);

    bool isScanning() const { return m_scanning; }
    void setScanning(bool scanning);

    bool isReadOnly();
    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    double getSpaceUsed_percent();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();
};

/* ************************************************************************** */
#endif // MEDIA_DIRECTORY_H
