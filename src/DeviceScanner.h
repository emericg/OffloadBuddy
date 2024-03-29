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

#ifndef DEVICE_SCANNER_H
#define DEVICE_SCANNER_H
/* ************************************************************************** */

#include "Shot.h"
#include "Device.h"

#include <QObject>
#include <QList>
#include <QString>
#include <QFileSystemWatcher>

/* ************************************************************************** */

/*!
 * \brief The DeviceScanner class
 */
class DeviceScanner: public QObject
{
    Q_OBJECT

    QFileSystemWatcher m_watcherFilesystem;
    QList <QString> m_watchedFilesystems;
    QList <QString> m_watchedVirtualFilesystems;
    QList <std::pair<unsigned, unsigned>> m_watchedMtpDevices;

    void scanFilesystems();
    void scanVirtualFilesystems();
    void scanMtpDevices();

public:
    DeviceScanner();
    ~DeviceScanner();

public slots:
    void searchDevices();

private slots:
    void removeFilesystem(const QString &path);
    void removeMtpDevice(const std::pair<unsigned, unsigned> device);

signals:
    void scanningStarted();
    void scanningFinished();

    void fsDeviceFound(QString, generic_device_infos *);
    void fsDeviceFound(QString, gopro_device_infos *);
    void fsDeviceFound(QString, insta360_device_infos *);
    void vfsDeviceFound(ofb_vfs_device *);
    void mtpDeviceFound(ofb_mtp_device *);

    void fsDeviceRemoved(const QString &);
    void mtpDeviceRemoved(const unsigned devBus, const unsigned devNum);
};

/* ************************************************************************** */
#endif // DEVICE_SCANNER_H
