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

#include "DeviceManager.h"
#include "Device.h"

#ifdef Q_OS_UNIX
#include <unistd.h>
#endif

#include <QFile>
#include <QDir>
#include <QThread>
#include <QDebug>

#define MAX_DEVICES         8
#define SCANNING_INTERVAL  10 // seconds

/* ************************************************************************** */

DeviceManager *DeviceManager::instance = nullptr;

DeviceManager *DeviceManager::getInstance()
{
    if (instance == nullptr)
    {
        instance = new DeviceManager();
    }

    return instance;
}

DeviceManager::DeviceManager()
{
#ifdef ENABLE_LIBMTP
    LIBMTP_Init();
#endif

    connect(&m_deviceScannerTimer, &QTimer::timeout, this, &DeviceManager::searchDevices);
}

DeviceManager::~DeviceManager()
{
    delete m_deviceScanner;
    delete m_deviceScannerThread;

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
 * This function will only be used on Linux platforms.
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

/*!
 * \brief Get the brand and model of a device from its device path string.
 * \param stringId[in]: device path string.
 * \param brand[out]: Device brand.
 * \param device[out]: Device model.
 * \return true if brand and device strings have been found.
 *
 * This function will only be used on libMTP supported platforms.
 * This is used to match virtual filesystem with (at least) a brand and model.
 * Not much more can be found through libMTP if GVFS is already connected to the device.
 */
bool DeviceManager::getMtpDeviceName(const QString &stringId,
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
            if (rawdevices[i].device_entry.vendor != nullptr ||
                rawdevices[i].device_entry.product != nullptr)
            {
                bool accepted = false;

                if (numrawdevices == 1)
                    accepted = true;
                else
                {
                    QString v(rawdevices[i].device_entry.vendor);
                    QString p(rawdevices[i].device_entry.product);

                    QStringList mtp_string_parts = stringId.split("_");

                    for (auto const &part: std::as_const(mtp_string_parts))
                    {
                        // FUSION hack
                        if (p.contains("Fusion", Qt::CaseInsensitive))
                        {
                            if (stringId.contains("frnt") && p.contains("front"))
                                accepted = true;
                            else if (stringId.contains("back") && p.contains("back"))
                                accepted = true;
                        }
                        else if (v.contains(part) || p.contains(v))
                            accepted = true;
                    }
                }

                if (accepted)
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

            connect(m_deviceScanner, SIGNAL(fsDeviceFound(QString,generic_device_infos*)), this, SLOT(addFsDeviceGeneric(QString,generic_device_infos*)));
            connect(m_deviceScanner, SIGNAL(fsDeviceFound(QString,gopro_device_infos*)), this, SLOT(addFsDeviceGoPro(QString,gopro_device_infos*)));
            connect(m_deviceScanner, SIGNAL(fsDeviceFound(QString,insta360_device_infos*)), this, SLOT(addFsDeviceInsta360(QString,insta360_device_infos*)));
            connect(m_deviceScanner, SIGNAL(vfsDeviceFound(ofb_vfs_device*)), this, SLOT(addVfsDevice(ofb_vfs_device*)));
            connect(m_deviceScanner, SIGNAL(mtpDeviceFound(ofb_mtp_device*)), this, SLOT(addMtpDevice(ofb_mtp_device*)));

            connect(m_deviceScanner, SIGNAL(fsDeviceRemoved(QString)), this, SLOT(removeFsDevice(QString)));
            connect(m_deviceScanner, SIGNAL(mtpDeviceRemoved(uint,uint)), this, SLOT(removeMtpDevice(uint,uint)));

            connect(m_deviceScanner, SIGNAL(scanningStarted()), this, SLOT(workerScanningStarted()));
            connect(m_deviceScanner, SIGNAL(scanningFinished()), this, SLOT(workerScanningFinished()));

            // we just keep the scanner always on now...
            //connect(m_deviceScanner, SIGNAL(scanningFinished()), m_deviceScanner, SLOT (deleteLater()));
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
    // We use single shot timer restarted after each scan because we don't want
    // a scanning started while the previous one is still running (ex: blocked
    // more than SCANNING_INTERVAL on a buggy unresponding MTP device...)
    m_deviceScannerTimer.setInterval(SCANNING_INTERVAL * 1000);
    m_deviceScannerTimer.setSingleShot(true);
    m_deviceScannerTimer.start();
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceManager::addFsDeviceGeneric(const QString &path, generic_device_infos *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES || path.isEmpty() || !deviceInfos)
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;

    for (auto dd: std::as_const(m_devices))
    {
        d = qobject_cast<Device *>(dd);
        if (d && (d->getPath(0) == path || d->getPath(1) == path))
        {
            deviceExists = true;
            break;
        }
    }

    if (!deviceExists)
    {
        d = new Device(deviceInfos->device_type,
                       StorageUtils::StorageFilesystem,
                       deviceInfos->device_brand,
                       deviceInfos->device_model,
                       "", "");
        if (d)
        {
            if (d->addStorage_filesystem(path))
            {
                if (d->isValid())
                {
                    m_devices.push_back(d);

                    emit deviceListUpdated();
                    emit devicesAdded();
                }
                else
                {
                    qWarning() << "> INVALID DEVICE";
                    delete d;
                }
            }
            else
            {
                qWarning() << "> INVALID DEVICE FILESYSTEM";
                delete d;
            }
        }
    }

    delete deviceInfos;
}

void DeviceManager::addFsDeviceGoPro(const QString &path, gopro_device_infos *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES || path.isEmpty() || !deviceInfos)
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;

    for (auto dd: std::as_const(m_devices))
    {
        d = qobject_cast<Device *>(dd);
        if (d)
        {
            if ((d->getPath(0) == path || d->getPath(1) == path) &&
                (d->getSerial() == deviceInfos->camera_serial_number))
            {
                deviceExists = true;
                break;
            }
            else if (d->getModel().contains("Fusion", Qt::CaseInsensitive) &&
                     d->getPath(0) != path &&
                     (d->getSerial() == deviceInfos->camera_serial_number))
            {
                // FUSION hack
                // we only want to merge two SD cards from a same FUSION device
                deviceMerge = true;
                break;
            }
        }
    }

    if (!deviceExists)
    {
        if (deviceMerge)
        {
            qDebug() << ">>>> Fusioooooooon";

            d->addStorage_filesystem(path);
            emit deviceListUpdated();
            //emit devicesAdded();
        }
        else
        {
            QString brand = "GoPro";
            QString fw = deviceInfos->firmware_version.left(6);

            d = new Device(DeviceUtils::DeviceActionCamera,
                           StorageUtils::StorageFilesystem,
                           brand, deviceInfos->camera_type,
                           deviceInfos->camera_serial_number, fw);
            if (d)
            {
                if (d->addStorage_filesystem(path))
                {
                    if (d->isValid())
                    {
                        m_devices.push_back(d);

                        emit deviceListUpdated();
                        emit devicesAdded();
                    }
                    else
                    {
                        qWarning() << "> INVALID (FS) DEVICE";
                        delete d;
                    }
                }
                else
                {
                    qWarning() << "> INVALID DEVICE FILESYSTEM";
                    delete d;
                }
            }
        }
    }

    delete deviceInfos;
}

void DeviceManager::addFsDeviceInsta360(const QString &path, insta360_device_infos *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES || path.isEmpty() || !deviceInfos)
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;

    for (auto dd: std::as_const(m_devices))
    {
        d = qobject_cast<Device *>(dd);
        if (d)
        {
            if ((d->getPath(0) == path || d->getPath(1) == path) &&
                (d->getSerial() == deviceInfos->camera_serial_number))
            {
                deviceExists = true;
                break;
            }
        }
    }

    if (!deviceExists)
    {
        QString brand = "Insta360";
        QString model;

        if (deviceInfos->camera_string.contains("OneR"))
            model = "One R";
        else if (deviceInfos->camera_string.contains("OneX2"))
            model = "One X2";
        else if (deviceInfos->camera_string.contains("OneX"))
            model = "One X";
        else if (deviceInfos->camera_string.contains("GO2"))
            model = "GO2";
        else if (deviceInfos->camera_string.contains("GO"))
            model = "GO";
        else
        {
            model = deviceInfos->camera_string;
            model.remove(brand);
            if (model.startsWith(' ')) model.remove(0, 1);
        }

        d = new Device(DeviceUtils::DeviceActionCamera,
                       StorageUtils::StorageFilesystem,
                       brand, model,
                       deviceInfos->camera_serial_number,
                       deviceInfos->camera_firmware);
        if (d)
        {
            if (d->addStorage_filesystem(path))
            {
                if (d->isValid())
                {
                    m_devices.push_back(d);

                    emit deviceListUpdated();
                    emit devicesAdded();
                }
                else
                {
                    qWarning() << "> INVALID (FS) DEVICE";
                    delete d;
                }
            }
            else
            {
                qWarning() << "> INVALID DEVICE FILESYSTEM";
                delete d;
            }
        }
    }

    delete deviceInfos;
}

void DeviceManager::addVfsDevice(ofb_vfs_device *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES || !deviceInfos || deviceInfos->paths.empty())
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;

    for (auto dd: std::as_const(m_devices))
    {
        d = qobject_cast<Device*>(dd);
        if (d)
        {
            // TODO // Search for duplicate device
            //if (d->getPathList().contains(infos->paths))
            //    deviceExists = true;

            // FUSION hack
            // search for another FUSION device
            // TODO // handle more than one fusion
            if (deviceInfos->model.contains("Fusion", Qt::CaseInsensitive) &&
                d->getModel().contains("Fusion", Qt::CaseInsensitive) &&
                d->getStorageCount() < 2)
            {
                deviceMerge = true;
                break;
            }
        }
    }

    if (!deviceExists)
    {
        if (deviceMerge)
        {
            qDebug() << ">>>> Fusioooooooon";

            for (auto const &fs: std::as_const(deviceInfos->paths))
            {
                d->setName("Fusion");
                d->addStorage_filesystem(fs);
            }
            emit deviceListUpdated();
            //emit devicesAdded();
        }
        else
        {
            d = new Device(DeviceUtils::DeviceUnknown,
                           StorageUtils::StorageVirtualFilesystem,
                           deviceInfos->brand, deviceInfos->model,
                           deviceInfos->firmware, deviceInfos->serial);

            for (auto const &fs: std::as_const(deviceInfos->paths))
            {
                d->addStorage_filesystem(fs);
            }

            if (d->isValid())
            {
                m_devices.push_back(d);

                emit deviceListUpdated();
                emit devicesAdded();
            }
            else
            {
                qWarning() << "> INVALID (VFS) DEVICE";
                delete d;
            }
        }
    }

    delete deviceInfos;
}

void DeviceManager::addMtpDevice(ofb_mtp_device *deviceInfos)
{
    if (m_devices.size() >= MAX_DEVICES || !deviceInfos || !deviceInfos->device)
    {
        delete deviceInfos;
        return;
    }

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;

    for (auto dd: std::as_const(m_devices))
    {
        d = qobject_cast<Device*>(dd);
        if (d)
        {
            // TODO // Search for duplicate device

            // FUSION hack
            // Search for another FUSION device
            // TODO // Handle more than one fusion
            if (deviceInfos->model.contains("Fusion", Qt::CaseInsensitive) &&
                d->getModel().contains("Fusion", Qt::CaseInsensitive) &&
                d->getStorageCount() < 2)
            {
                qDebug() << "?? Fusioooooooon" << deviceInfos->model << d->getModel() << d->getStorageCount();

                deviceMerge = true;
                break;
            }
        }
    }

    if (!deviceExists)
    {
        if (deviceMerge)
        {
            qDebug() << ">>>> Fusioooooooon";

            d->setName("Fusion");
            d->addStorages_mtp(deviceInfos);
            emit deviceListUpdated();
            //emit devicesAdded();
        }
        else
        {
            d = new Device(DeviceUtils::DeviceUnknown,
                           StorageUtils::StorageMTP,
                           deviceInfos->brand, deviceInfos->model,
                           deviceInfos->firmware, deviceInfos->serial);

            d->addStorages_mtp(deviceInfos);

            if (d->isValid())
            {
                m_devices.push_back(d);

                emit deviceListUpdated();
                emit devicesAdded();
            }
            else
            {
                qWarning() << "> INVALID (MTP) DEVICE";
                delete d;
            }
        }
    }
}

/* ************************************************************************** */

void DeviceManager::removeFsDevice(const QString &path)
{
    if (path.isEmpty()) return;

    QList<QObject *>::iterator it = m_devices.begin();
    while (it != m_devices.end())
    {
        Device *d = qobject_cast<Device*>(*it);
        if (d)
        {
            if (d->getPath(0) == path || d->getPath(1) == path)
            {
                it = m_devices.erase(it);

                emit deviceRemoved(d);
                emit deviceListUpdated();

                return;
            }
        }

        ++it;
    }
}

void DeviceManager::removeMtpDevice(const unsigned devBus, const unsigned devNum)
{
    QList<QObject *>::iterator it = m_devices.begin();
    while (it != m_devices.end())
    {
        Device *d = qobject_cast<Device*>(*it);
        if (d)
        {
            std::pair<unsigned, unsigned> dIds = d->getMtpIds();

            if (dIds.first == devBus && dIds.second == devNum)
            {
                it = m_devices.erase(it);

                emit deviceRemoved(d);
                emit deviceListUpdated();

                return;
            }
        }

        ++it;
    }
}

/* ************************************************************************** */
