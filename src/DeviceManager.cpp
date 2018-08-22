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

#include "DeviceManager.h"
#include "Device.h"

#ifdef Q_OS_UNIX
#include <unistd.h>
#endif

#include <QFile>
#include <QDir>
#include <QThread>
#include <QDebug>

/* ************************************************************************** */

DeviceManager::DeviceManager()
{
#ifdef ENABLE_LIBMTP
    LIBMTP_Init();
#endif

    connect(&m_deviceScannerTimer, &QTimer::timeout, this, &DeviceManager::searchDevices);
    connect(&m_watcherFilesystem, &QFileSystemWatcher::directoryChanged, this, &DeviceManager::filesystemWatcherActivity);
}

DeviceManager::~DeviceManager()
{
    delete m_deviceScannerThread;
    delete m_deviceScanner;

    qDeleteAll(m_devices);
    m_devices.clear();
}

/* ************************************************************************** */
/* ************************************************************************** */

/*!
 * \brief Get the brand and model of a device from its MTP bus and device number.
 * \param busNum[in]: MTP bus number.
 * \param devNum[in]: MTP device number.
 * \param brand[out]: Device brand.
 * \param device[out]: Device model.
 * \return true if brand and device strings have been found.
 *
 * This function will only be used on linux.
 * This is used to match virtual filesystem with (at least) a brand and model.
 * Not much more can be found through libMTP if GVFS is already connected to the device.
 */
bool DeviceManager::getMtpDeviceName(const uint32_t busNum, const uint32_t devNum,
                                     QString &brand, QString &model)
{
    bool status = false;

#ifdef ENABLE_LIBMTP

    int numrawdevices;
    LIBMTP_raw_device_t *rawdevices;

    LIBMTP_error_number_t err = LIBMTP_Detect_Raw_Devices(&rawdevices, &numrawdevices);
    if (err == LIBMTP_ERROR_NONE)
    {
        for (int i = 0; i < numrawdevices; i++)
        {
            if (rawdevices[i].bus_location == busNum && rawdevices[i].devnum == devNum)
            {
                if (rawdevices[i].device_entry.vendor != nullptr ||
                    rawdevices[i].device_entry.product != nullptr)
                {
                    brand = rawdevices[i].device_entry.vendor;
                    model = rawdevices[i].device_entry.product;
                    status = true;
                    break;
                }
            }
        }
    }

    free(rawdevices);

#endif // ENABLE_LIBMTP

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceManager::searchDevices()
{
    //qDebug() << "DeviceManager::searchDevices()";

    if (m_deviceScanner == nullptr)
    {
        m_deviceScannerThread = new QThread();
        m_deviceScanner = new DeviceScanner();

        if (m_deviceScannerThread && m_deviceScanner)
        {
            m_deviceScanner->moveToThread(m_deviceScannerThread);

            connect(m_deviceScannerThread, SIGNAL(started()), m_deviceScanner, SLOT(searchDevices()));
            connect(this, SIGNAL(startDeviceScanning()), m_deviceScanner, SLOT(searchDevices()));

            connect(m_deviceScanner, SIGNAL(fsDeviceFound(QString, gopro_info_version *)), this, SLOT(addFsDevice(QString, gopro_info_version *)));
            connect(m_deviceScanner, SIGNAL(vfsDeviceFound(ofb_vfs_device *)), this, SLOT(addVfsDevice(ofb_vfs_device *)));
            connect(m_deviceScanner, SIGNAL(mtpDeviceFound(ofb_mtp_device *)), this, SLOT(addMtpDevice(ofb_mtp_device *)));

            connect(m_deviceScanner, SIGNAL(scanningStarted()), this, SLOT(workerScanningStarted()));
            connect(m_deviceScanner, SIGNAL(scanningFinished()), this, SLOT(workerScanningFinished()));
            //connect(m_deviceScanner, SIGNAL (scanningFinished()), m_deviceScanner, SLOT (deleteLater()));
            //connect(m_deviceScanner, SIGNAL(scanningFinished()), m_deviceScannerThread, SLOT(quit()));

            // automatically delete thread when its work is done
            //connect(m_deviceScannerThread, SIGNAL(finished()), m_deviceScannerThread, SLOT(deleteLater()));

            m_deviceScannerThread->start();
        }
    }
    else
    {
        emit startDeviceScanning();
    }
}

/* ************************************************************************** */

void DeviceManager::workerScanningStarted()
{
    //qDebug() << "DeviceManager::workerScanningStarted()";
}

void DeviceManager::workerScanningFinished()
{
    //qDebug() << "DeviceManager::workerScanningFinished()";

    // Restart device scanning timer
    m_deviceScannerTimer.setInterval(SCANNING_INTERVAL);
    m_deviceScannerTimer.setSingleShot(true);
    m_deviceScannerTimer.start();
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceManager::addFsDevice(QString path, gopro_info_version *infos)
{
    if (m_devices.size() >= MAX_DEVICES ||
        path.isEmpty() || !infos)
    {
        delete infos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;

    for (auto dd: m_devices)
    {
        d = qobject_cast<Device *>(dd);
        if (d)
        {
            if ((d->getPath(0) == path || d->getPath(1) == path) &&
                (d->getSerial() == infos->camera_serial_number))
            {
                deviceExists = true;
                break;
            }
            else if (d->getModel() == "FUSION" &&
                     d->getPath(0) != path &&
                     (d->getSerial() == infos->camera_serial_number))
            {
                // we only want to merge two SD cards from a same FUSION device
                deviceMerge = true;
                break;
            }
        }
    }

    if (deviceExists == false)
    {
        if (deviceMerge == true)
        {
            if (d)
            {
                qDebug() << ">>>> MERGING DEVICE";

                // fusioooooooon
                d->addStorage_filesystem(path);

                if (m_watcherFilesystem.addPath(path) == false)
                    qDebug() << "FILE WATCHER FAILZD";

                emit deviceListUpdated();
                emit devicesAdded();
            }
        }
        else
        {
            QString brand = "GoPro";
            d = new Device(DEVICE_FILESYSTEM,
                           brand, infos->camera_type,
                           infos->camera_serial_number,
                           infos->firmware_version);
            if (d)
            {
                if (d->addStorage_filesystem(path) == true)
                {
                    if (d->isValid())
                    {
                        m_devices.push_back(d);

                        if (m_watcherFilesystem.addPath(path) == false)
                            qDebug() << "FILE WATCHER FAILZD";

                        emit deviceListUpdated();
                        emit devicesAdded();
                    }
                    else
                    {
                        qDebug() << "> INVALID DEVICE";
                        delete d;
                    }
                }
                else
                {
                    qDebug() << "> INVALID DEVICE FILESYSTEM";
                    delete d;
                }
            }
        }
    }

    delete infos;
}

void DeviceManager::addVfsDevice(ofb_vfs_device *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES || !deviceInfos)
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;
/*
    for (auto dd: m_devices)
    {
        d = qobject_cast<Device*>(dd);
        if (d)
        {
            //if ((d->getPath(0) == path || d->getPath(1) == path) &&
            //    (d->getSerial() == infos->camera_serial_number))
            //{
            //    deviceExists = true;
            //    break;
            //}
        }
    }
*/
    if (deviceExists == false)
    {
        d = new Device(DEVICE_VIRTUAL_FILESYSTEM,
                       deviceInfos->brand, deviceInfos->model,
                       deviceInfos->firmware, deviceInfos->serial);

        for (auto fs: deviceInfos->paths)
        {
            d->addStorage_filesystem(fs);
        }

        if (d->isValid())
        {
            m_devices.push_back(d);

            emit deviceListUpdated();
            emit devicesAdded();
        }
    }

    delete deviceInfos;
}

void DeviceManager::addMtpDevice(ofb_mtp_device *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES ||
        !deviceInfos || !deviceInfos->device)
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;
/*
    for (auto dd: m_devices)
    {
        d = qobject_cast<Device*>(dd);
        if (d)
        {
            //
        }
    }
*/
    if (deviceExists == false)
    {
        d = new Device(DEVICE_MTP,
                       deviceInfos->brand, deviceInfos->model,
                       deviceInfos->firmware, deviceInfos->serial);

        d->setMtpInfos(deviceInfos->device, deviceInfos->battery,
                       deviceInfos->devBus, deviceInfos->devNum);
        d->addStorages_mtp(deviceInfos);

        if (d->isValid())
        {
            m_devices.push_back(d);

            emit deviceListUpdated();
            emit devicesAdded();
        }
    }

    delete deviceInfos;
}

/* ************************************************************************** */

void DeviceManager::removeDevice(const QString &path)
{
    if (path.isEmpty())
        return;

    QList<QObject *>::iterator it = m_devices.begin();
    while (it != m_devices.end())
    {
        Device *d = qobject_cast<Device*>(*it);
        if (d && (d->getPath(0) == path || d->getPath(1) == path))
        {
            it = m_devices.erase(it);
            m_watcherFilesystem.removePath(path);

            emit deviceRemoved(d);
            emit deviceListUpdated();

            return;
        }
        else
            ++it;
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceManager::filesystemWatcherActivity(const QString &path)
{
    if (path.isEmpty())
        return;

    qDebug() << "QFileSystemWatcher::directoryChanged()" << path;

    // FIXME virtual filesystem sometimes still exists after physical removal
    //QDir dir(path);
    //if (dir.exists() == false)
    {
        removeDevice(path);
    }
}

/* ************************************************************************** */
