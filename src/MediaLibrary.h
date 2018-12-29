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

#ifndef LIBRARY_MANAGER_H
#define LIBRARY_MANAGER_H
/* ************************************************************************** */

#include "ShotProvider.h"

#include <QDebug>
#include <QObject>
#include <QVariant>
#include <QTimer>
#include <QList>

class MediaDirectory;

/* ************************************************************************** */

/*!
 * \brief The MediaLibrary class
 *
 * Handle all of your MediaDirectories and their files.
 */
class MediaLibrary: public ShotProvider
{
    Q_OBJECT

    Q_PROPERTY(int libraryState READ getLibraryState NOTIFY stateUpdated)

    deviceState_e m_libraryState = DEVICE_STATE_IDLE;

    void scanMediaDirectory(MediaDirectory *md);

Q_SIGNALS:
    void stateUpdated();

public:
    MediaLibrary();
    ~MediaLibrary();

public slots:
    void searchMediaDirectories();
    void searchMediaDirectory(const QString path);

    int getLibraryState() const { return m_libraryState; }
    void workerScanningStarted(QString s);
    void workerScanningFinished(QString s);
};

/* ************************************************************************** */
#endif // LIBRARY_MANAGER_H
