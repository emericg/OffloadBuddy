/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2018 Emeric Grange - All Rights Reserved
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

#ifndef LIBRARY_DIRECTORY_H
#define LIBRARY_DIRECTORY_H
/* ************************************************************************** */

#include <QObject>
#include <QVariant>
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
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableUpdated)

    Q_PROPERTY(bool readOnly READ isReadOnly NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY spaceUpdated)
    Q_PROPERTY(double spaceUsedPercent READ getSpaceUsed_percent NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY spaceUpdated)

    QString m_path;
    int m_content_type = 0;
    int m_storage_type = 0;

    QStorageInfo *m_storage = nullptr;
    bool m_available = false;
    QTimer m_updateTimer;

Q_SIGNALS:
    void directoryUpdated();
    void availableUpdated();
    void spaceUpdated();

private slots:
    void refreshMediaDirectory();

public:
    MediaDirectory();
    MediaDirectory(QString &path, int content);
    ~MediaDirectory();

public slots:
    QString getPath() { return m_path; }
    void setPath(QString path);
    int getContent() { return m_content_type; }
    void setContent(int content);

    bool isAvailable() { return m_available; }
    bool isAvailableFor(unsigned shotType, int64_t shotSize);

    //
    bool isReadOnly();
    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    double getSpaceUsed_percent();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();
};

/* ************************************************************************** */
#endif // LIBRARY_DIRECTORY_H
