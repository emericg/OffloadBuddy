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

#ifndef DEVICE_MANAGER_H
#define DEVICE_MANAGER_H
/* ************************************************************************** */

#include "Device.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QObject>
#include <QVariant>
#include <QList>

#include <QTimer>
#include <QStorageInfo>
#include <QFileSystemWatcher>

#define MAX_DEVICES         8
#define SCANNING_INTERVAL   10000

/* ************************************************************************** */

/*!
 * \brief The DeviceManager class
 */
class DeviceManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariant devicesList READ getDevices NOTIFY devicesUpdated)

    bool parseGoProVersionFile(const QString &path, gopro_info_version &infos);

    QList <QObject *> m_devices;

    QTimer m_updateTimer;

    QFileSystemWatcher m_watcherFilesystem;
    QList <std::pair<unsigned, unsigned>> m_watcherMtp;

Q_SIGNALS:
    void devicesAdded();
    void devicesUpdated();
    void devicesRemoved();
    void deviceRemoved(Device *devicePtr);

public:
    DeviceManager();
    ~DeviceManager();

public slots:
    bool searchDevices();
        bool scanFilesystems();
        bool scanVirtualFilesystems();
        bool scanMtpDevices();
        bool getMtpDevices(const uint32_t busNum, const uint32_t devNum,
                           QString &brand, QString &model);

    void addDevice(const QString &path, const gopro_info_version &infos);
    void removeDevice(const QString &path);
    void somethingsUp(const QString &path);

    QVariant getFirstDevice() const { if (m_devices.size() > 0) { return QVariant::fromValue(m_devices.at(0)); } return QVariant(); }
    QVariant getDevice(int index) const { if (index >= 0 && index < m_devices.size()) { return QVariant::fromValue(m_devices.at(index)); } return QVariant(); }
    QVariant getDevices() const { if (m_devices.size() > 0) { return QVariant::fromValue(m_devices); } return QVariant(); }
};

#endif // DEVICE_MANAGER_H
