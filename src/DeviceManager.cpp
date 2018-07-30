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
#include <QDebug>

/* ************************************************************************** */

DeviceManager::DeviceManager()
{
#ifdef ENABLE_LIBMTP
    LIBMTP_Init();
    qDebug() << "libmtp enabled, version:" << LIBMTP_VERSION_STRING;
#endif

    m_updateTimer.setInterval(SCANNING_INTERVAL);
    connect(&m_updateTimer, &QTimer::timeout, this, &DeviceManager::searchDevices);
    m_updateTimer.start();

    QObject::connect(&m_watcherFilesystem, &QFileSystemWatcher::directoryChanged, this, &DeviceManager::somethingsUp);
}

DeviceManager::~DeviceManager()
{
    qDeleteAll(m_devices);
    m_devices.clear();
}

/* ************************************************************************** */

bool DeviceManager::scanFilesystems()
{
    bool status = false;

    foreach (const QStorageInfo &storage, QStorageInfo::mountedVolumes())
    {
        //qDebug() << "> MOUNTPOINT(" << storage.fileSystemType() << ") > " << storage.rootPath();

        if (storage.fileSystemType() == "nfs" ||
            storage.fileSystemType() == "nfs4")
        {
            //qDebug() << "> skipping network filesystem";
            continue;
        }

        if (storage.fileSystemType() == "tmpfs")
        {
            //qDebug() << "> skipping virtual filesystem";
            continue;
        }

        // Path in watch list? bail early!
        if (m_watcherFilesystem.directories().contains(storage.rootPath()))
        {
            //qDebug() << "> skipping '" << storage.rootPath() << "', already handled";
            continue;
        }

        if (storage.isValid() && storage.isReady())
        {
            QString deviceRootpath = storage.rootPath();
            gopro_info_version deviceInfos;

            if (parseGoProVersionFile(deviceRootpath, deviceInfos))
            {
                addDevice(deviceRootpath, deviceInfos);
            }
            else
            {
                // TODO scan for other stuff than GoPro SD cards
            }
        }
        else
        {
            qDebug() << "* mountpoint invalid? '" << storage.displayName() << "'";
        }
    }

    return status;
}

bool DeviceManager::scanVirtualFilesystems()
{
    bool status = false;

#ifdef __linux
    foreach (const QStorageInfo &storage, QStorageInfo::mountedVolumes())
    {
        if (storage.fileSystemType() == "tmpfs")
        {
            //qDebug() << "> MOUNTPOINT(" << storage.fileSystemType() << ") > " << storage.rootPath();

            if (storage.rootPath() == "/run" ||
                storage.rootPath() == "/tmp")
            {
                //qDebug() << "> skipping OS internal filesystem";
                continue;
            }

            // Chances are, we now have a virtual MTP filesystem, so let's look for it
            // ex: /run/user/1000/gvfs/gphoto2:host=%5Busb%3A005%2C012%5D/
            // ex: /run/user/1000/gvfs/mtp:host=%5Busb%3A005%2C012%5D/
            // 0x2C: ','   0x3A: ':'   0x5B: '['   0x5D: ']'

            QDir gvfsDirectory(storage.rootPath() + "/gvfs");
            foreach (QString subdir_device, gvfsDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
            {
                qDebug() << "Scanning MTP subdir_device:" << subdir_device;

                int bus = -1, dev = -1;
                std::pair<uint32_t, uint32_t> currentMtpDevice;
                QString brand = "unknown", model = "device", firmware, serial;
                QString deviceRootpath = storage.rootPath();

                if (subdir_device.startsWith("mtp"))
                {
                    bus = subdir_device.mid(18,3).toInt();
                    dev = subdir_device.mid(24,3).toInt();
                }
                else if (subdir_device.startsWith("gphoto2"))
                {
                    bus = subdir_device.mid(22,3).toInt();
                    dev = subdir_device.mid(28,3).toInt();
                }
                if (bus >= 0 && dev >= 0)
                {
                    // Device in watch list? bail early!
                    currentMtpDevice = std::make_pair(bus, dev);
                    if (m_watcherMtp.contains(currentMtpDevice))
                    {
                        qDebug() << "> skipping device @ bus" << currentMtpDevice.first << ", dev" << currentMtpDevice.second << ", already handled";
                        continue;
                    }

                    getMtpDevices(static_cast<uint32_t>(bus), static_cast<uint32_t>(dev), brand, model);
                    //qDebug() << "MTP infos:" << bus << "/" << dev;
                    //qDebug() << "MTP infos:" << brand << "/" << model;
                }
                else
                {
                    // skip?
                    continue;
                }

                Device *d = new Device(brand, model, firmware, serial);

                // Then we usually have a subdirectory per MTP 'volume'
                // ex: one volume for the internal flash of a phone and one for its SD card
                QDir gvfsSubDirectory(gvfsDirectory.path() + "/" + subdir_device);
                foreach (QString subdir_volume, gvfsSubDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
                {
                    //qDebug() << "Scanning MTP subdir_volume:" << subdir_volume;
                    //qDebug() << "deviceRootpath:" << deviceRootpath;
                    deviceRootpath = gvfsSubDirectory.path() + "/" + subdir_volume;

                    QDir dcim(deviceRootpath + "/DCIM");
                    if (dcim.exists())
                    {
                        //qDebug() << "WE HAVE DCIM at ";
                        d->addStorage_filesystem(deviceRootpath);
                    }
                }

                QFile getstarted(deviceRootpath + "/Get_started_with_GoPro.url");
                QDir dcim(deviceRootpath + "/DCIM");
                if (getstarted.exists() && dcim.exists())
                {
                    //qDebug() << "WE HAVE Get_started_with_GoPro";
                    if (d->isValid())
                    {
                        m_watcherMtp.push_back(currentMtpDevice);
                        if (m_watcherFilesystem.addPath(deviceRootpath) == false)
                            qDebug() << "FILE WATCHER FAILZD";

                        m_devices.push_back(d);
                    }
                    else
                    {
                        delete d;
                    }
                }
                else
                {
                    // TODO scan for other stuff than GoPro devices
                    delete d;
                }
            }
        }
    }
#endif // __linux

    return status;
}

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
bool DeviceManager::getMtpDevices(const uint32_t busNum, const uint32_t devNum,
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

bool DeviceManager::scanMtpDevices()
{
    bool status = false;

#ifdef ENABLE_LIBMTP

    int numrawdevices;
    LIBMTP_raw_device_t *rawdevices;

    // use this to get *already* connected devices? ??
    //LIBMTP_Get_Connected_Devices(LIBMTP_mtpdevice_t **device_list)

    // check for devices that have disapeared
    //LIBMTP_Check_Specific_Device()
    //LIBMTP_Get_Connected_Devices(LIBMTP_mtpdevice_t **device_list)

    LIBMTP_error_number_t err = LIBMTP_Detect_Raw_Devices(&rawdevices, &numrawdevices);
    switch (err)
    {
    case LIBMTP_ERROR_NONE:
        status = true;
        //qDebug() << "MTP: Found %d device(s):" << numrawdevices;
        break;
    case LIBMTP_ERROR_NO_DEVICE_ATTACHED:
        status = true;
        break;

    case LIBMTP_ERROR_CONNECTING:
        qDebug() << "MTP: There has been a connection error!";
        break;
    case LIBMTP_ERROR_MEMORY_ALLOCATION:
        qDebug() << "MTP: Encountered a Memory Allocation Error!";
        break;
    case LIBMTP_ERROR_GENERAL:
    default:
        qDebug() << "MTP: Unknown connection error!";
        break;
    }

    for (int i = 0; i < numrawdevices; i++)
    {
        qDebug() << "> MTP DEVICE(" << rawdevices[i].device_entry.vendor << rawdevices[i].device_entry.product \
                 << ") [" << rawdevices[i].device_entry.vendor_id << ":" << rawdevices[i].device_entry.product_id \
                 << "] @ bus" << rawdevices[i].bus_location << ", dev" << rawdevices[i].devnum;

        // Device in watch list? bail early!
        auto currentMtpDevice = std::make_pair(rawdevices[i].bus_location, rawdevices[i].devnum);
        if (m_watcherMtp.contains(currentMtpDevice))
        {
            qDebug() << "> skipping device @ bus" << currentMtpDevice.first << ", dev" << currentMtpDevice.second << ", already handled";
            continue;
        }

        LIBMTP_mtpdevice_t *mtpDevice = LIBMTP_Open_Raw_Device_Uncached(&rawdevices[i]);
        if (mtpDevice == nullptr)
        {
            qDebug() << "MTP: Unable to open raw device #" << i;
            continue;
        }
/*
        LIBMTP_Dump_Errorstack(device);
        LIBMTP_Clear_Errorstack(device);
        LIBMTP_Dump_Device_Info(device);
*/
        // Device infos
        QString brand_qstr =  rawdevices[i].device_entry.vendor;
        QString model_qstr = rawdevices[i].device_entry.product;
        char *version = LIBMTP_Get_Deviceversion(mtpDevice);
        char *serial = LIBMTP_Get_Serialnumber(mtpDevice);
        QString serial_qstr = serial;
        QString firmware_qstr = version;

        // Create device
        Device *d = new Device(brand_qstr, model_qstr, serial_qstr, firmware_qstr);
        if (d)
        {
            if (d->addStorage_mtp(mtpDevice) == true)
            {
                if (d->isValid())
                {
                    m_watcherMtp.push_back(currentMtpDevice);
                    m_devices.push_back(d);

                    emit devicesUpdated();
                }
                else
                {
                    qDebug() << "> INVALID DEVICE";
                    delete d;
                }
            }
            else
            {
                qDebug() << "> INVALID DEVICE";
                delete d;
            }
        }
    }

    free(rawdevices);

#endif // ENABLE_LIBMTP

    return status;
}

bool DeviceManager::searchDevices()
{
    bool status = false;

    scanFilesystems();
    scanVirtualFilesystems();
    scanMtpDevices();

    if (m_devices.size() > 0)
        status = true;

    return status;
}

/*!
 * \brief parseGoProVersionFile
 * \param path[in]
 * \param infos[out]
 * \return
 */
bool DeviceManager::parseGoProVersionFile(const QString &path, gopro_info_version &infos)
{
    bool status = false;

    QFile versiontxt(path + "/MISC/version.txt");

    if (versiontxt.exists() &&
        versiontxt.size() > 0 &&
        versiontxt.open(QIODevice::ReadOnly))
    {
/*
        qDebug() << "> GOPRO SD CARD FOUND:";
        qDebug() << "- mountpoint:" << storage.displayName();
        qDebug() << "- type:" << storage.fileSystemType();
*/
        QTextStream in(&versiontxt);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            if (!line.isEmpty())
            {
                QStringList kv = line.split(':');
                if (kv.size() == 2)
                {
                    QString key = kv.at(0);
                    key.remove(0,1).chop(1);
                    QString value = kv.at(1);
                    value.remove(0,1).chop(2);
                    //qDebug() << "key:" << key << " / value:" << value;

                    if (key == "info version")
                        if (value != "1.0" && value != "1.1" &&  value != "2.0")
                            qWarning() << "SD Card version.txt is unsupported!";

                    if (key == "firmware version")
                        infos.firmware_version = value;

                    if (key == "camera type")
                        infos.camera_type = value;

                    if (key == "camera serial number")
                        infos.camera_serial_number = value;

                    if (key == "wifi mac")
                        infos.wifi_mac = value;
                    if (key == "wifi version")
                        infos.wifi_version = value;
                    if (key == "wifi bootloader version")
                        infos.wifi_bootloader_version = value;
                }
            }
        }

        if (!infos.camera_type.isEmpty() && !infos.camera_serial_number.isEmpty())
            status = true;
    }

    versiontxt.close();

    return status;
}

/* ************************************************************************** */

void DeviceManager::addDevice(const QString &path, const gopro_info_version &infos)
{
    if (path.isEmpty())
        return;
    if (m_devices.size() >= MAX_DEVICES)
        return;

    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;

    for (auto dd: m_devices)
    {
        d = qobject_cast<Device*>(dd);
        if (d)
        {
            if ((d->getPath(0) == path || d->getPath(1) == path) &&
                (d->getSerial() == infos.camera_serial_number))
            {
                deviceExists = true;
                break;
            }
            else if (d->getModel() == "FUSION" &&
                     d->getPath(0) != path &&
                     (d->getSerial() == infos.camera_serial_number))
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
            if (!d) return;
            qDebug() << ">>>> MERGING DEVICE";

            // fusioooooooon
            d->addStorage_filesystem(path);

            if (m_watcherFilesystem.addPath(path) == false)
                qDebug() << "FILE WATCHER FAILZD";

            emit devicesUpdated();
            emit devicesAdded();
        }
        else
        {
            QString brand = "GoPro";
            d = new Device(brand, infos.camera_type,
                           infos.camera_serial_number,
                           infos.firmware_version);
            if (d)
            {
                if (d->addStorage_filesystem(path) == true)
                {
                    if (d->isValid())
                    {
                        m_devices.push_back(d);

                        if (m_watcherFilesystem.addPath(path) == false)
                            qDebug() << "FILE WATCHER FAILZD";

                        emit devicesUpdated();
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
}

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

            emit devicesUpdated();
            emit devicesRemoved();
            emit deviceRemoved(d);

            return;
        }
        else
            ++it;
    }
}

void DeviceManager::somethingsUp(const QString &path)
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
