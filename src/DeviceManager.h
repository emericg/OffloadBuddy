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

#ifndef DEVICE_MANAGER_H
#define DEVICE_MANAGER_H
/* ************************************************************************** */

#include "Device.h"
#include "DeviceScanner.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QObject>
#include <QVariant>
#include <QList>

#include <QTimer>
#include <QStorageInfo>
#include <QFileSystemWatcher>

/* ************************************************************************** */

/*!
 * \brief The DeviceManager class
 */
class DeviceManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariant devicesList READ getDevices NOTIFY deviceListUpdated)

    QList <QObject *> m_devices;

    DeviceScanner *m_deviceScanner = nullptr;
    QThread *m_deviceScannerThread = nullptr;
    QTimer m_deviceScannerTimer;

Q_SIGNALS:
    void devicesAdded();
    void deviceListUpdated();
    void deviceRemoved(Device *devicePtr);
    void startDeviceScanning();

private slots:
    void workerScanningStarted();
    void workerScanningFinished();

public:
    DeviceManager();
    ~DeviceManager();

    static bool getMtpDeviceName(const uint32_t busNum, const uint32_t devNum,
                                 QString &brand, QString &model);
    static bool getMtpDeviceName(const QString &stringId,
                                 QString &brand, QString &model);

public slots:
    void searchDevices();

    void addFsDeviceGoPro(const QString &path, gopro_device_infos *deviceInfos);
    void addFsDeviceGeneric(const QString &path, generic_device_infos *deviceInfos);
    void addVfsDevice(ofb_vfs_device *deviceInfos);
    void addMtpDevice(ofb_mtp_device *deviceInfos);

    void removeFsDevice(const QString &path);
    void removeMtpDevice(const unsigned devBus, const unsigned devNum);

    QVariant getFirstDevice() const { if (m_devices.size() > 0) { return QVariant::fromValue(m_devices.at(0)); } return QVariant(); }
    QVariant getDevice(int index) const { if (index >= 0 && index < m_devices.size()) { return QVariant::fromValue(m_devices.at(index)); } return QVariant(); }
    QVariant getDevices() const { if (m_devices.size() > 0) { return QVariant::fromValue(m_devices); } return QVariant(); }
};

#endif // DEVICE_MANAGER_H
