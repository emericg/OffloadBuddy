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

#ifndef LIBRARY_MANAGER_H
#define LIBRARY_MANAGER_H
/* ************************************************************************** */

#include "ShotProvider.h"
#include "DeviceUtils.h"

#include <QObject>
#include <QVariant>
#include <QList>
#include <QStringList>

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
    int m_libraryScan = 0;

    void scanMediaDirectory(MediaDirectory *md);

    int getLibraryState() const { return m_libraryState; }

Q_SIGNALS:
    void stateUpdated();

public slots:
    void workerScanningStarted(const QString &path);
    void workerScanningFinished(const QString &path);

public:
    MediaLibrary();
    ~MediaLibrary();

    void invalidate();

    Q_INVOKABLE void searchMediaDirectories();
    Q_INVOKABLE void searchMediaDirectory(const QString &path);
    Q_INVOKABLE void cleanMediaDirectory(const QString &path);

    // Get uuids/names/paths from grid indexes
    Q_INVOKABLE QStringList getSelectedShotsUuids(const QVariant &indexes);
    Q_INVOKABLE QStringList getSelectedShotsNames(const QVariant &indexes);
    Q_INVOKABLE QStringList getSelectedShotsFilepaths(const QVariant &indexes);

    // Submit jobs
    Q_INVOKABLE void moveSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void moveSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void mergeSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void mergeSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void deleteSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void deleteSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void reencodeSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void reencodeSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void extractTelemetrySelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void extractTelemetrySelection(const QVariant &uuids, const QVariant &settings);
};

/* ************************************************************************** */
#endif // LIBRARY_MANAGER_H
