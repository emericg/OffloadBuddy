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

#include "Shot.h"
#include "ShotModel.h"
#include "ShotFilter.h"

#include <QDebug>
#include <QObject>
#include <QVariant>
#include <QTimer>
#include <QList>

class MediaDirectory;

/* ************************************************************************** */

/*!
 * \brief The ShotProvider class
 */
class ShotProvider: public QObject
{
    Q_OBJECT

protected:
    Q_PROPERTY(ShotModel *shotModel READ getShotModel NOTIFY shotModelUpdated)
    Q_PROPERTY(ShotFilter *shotFilter READ getShotFilter NOTIFY shotModelUpdated)

    // Shot(s)
    ShotModel *m_shotModel = nullptr;
    ShotFilter *m_shotFilter = nullptr;
    Shot *findShot(Shared::ShotType type, int file_id, int camera_id) const;

Q_SIGNALS:
    void shotModelUpdated();
    void shotsUpdated();

public:
    ShotProvider()
    {
        m_shotModel = new ShotModel;
        m_shotFilter = new ShotFilter;

        m_shotFilter->setSourceModel(m_shotModel);
        m_shotFilter->setSortRole(ShotModel::DateRole);
        m_shotFilter->sort(0, Qt::AscendingOrder);
    }

    virtual ~ShotProvider()
    {
        delete m_shotModel;
        delete m_shotFilter;
    }

    //
    void addShot(Shot *shot);
    void deleteShot(Shot *shot);

    //
    ShotModel *getShotModel() const { return m_shotModel; }
    ShotFilter *getShotFilter() const { return m_shotFilter; }

public slots:
    //QVariant getShot(const int index) const { return QVariant::fromValue(m_shotModel->getShotAt(index)); }
    QVariant getShot(const QString name) const { return QVariant::fromValue(m_shotModel->getShotAt(name)); }
};

/* ************************************************************************** */

/*!
 * \brief The MediaLibrary class
 */
class MediaLibrary: public ShotProvider
{
    Q_OBJECT

    Q_PROPERTY(int libraryState READ getLibraryState NOTIFY stateUpdated)

    deviceState_e m_libraryState = DEVICE_STATE_IDLE;

    // Storage(s)
    QTimer m_updateStorageTimer;
    QList <MediaDirectory *> m_mediaDirectories;

Q_SIGNALS:
    void stateUpdated();

public:
    MediaLibrary();
    ~MediaLibrary();

    void searchMediaDirectories();

public slots:
    //
    int getLibraryState() const { return m_libraryState; }
    void workerScanningStarted(QString s);
    void workerScanningFinished(QString s);
};

#endif // LIBRARY_MANAGER_H
