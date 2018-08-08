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

#ifndef DEVICE_SCANNER
#define DEVICE_SCANNER
/* ************************************************************************** */

#include "Shot.h"
#include "Device.h"

#include <QObject>
#include <QList>
#include <QString>

/* ************************************************************************** */

class DeviceScanner: public QObject
{
    Q_OBJECT

    QList <QString> m_watchedFilesystems;
    QList <std::pair<unsigned, unsigned>> m_watchedMtpDevices;

    void scanFilesystems();
    void scanVirtualFilesystems();
    void scanMtpDevices();

public:
    DeviceScanner();
    ~DeviceScanner();

public slots:
    void searchDevices();

signals:
    void scanningStarted();
    void scanningFinished();

    void fsDeviceFound(QString, gopro_info_version *);
    void vfsDeviceFound(ofb_vfs_device *);
    void mtpDeviceFound(ofb_mtp_device *);

    void fsDeviceRemoved(QString);
    void vfsDeviceRemoved(QString, std::pair<unsigned, unsigned>);
    void mtpDeviceRemoved(std::pair<unsigned, unsigned>);
};

/* ************************************************************************** */
#endif // DEVICE_SCANNER
