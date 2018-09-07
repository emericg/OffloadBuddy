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

#include "DeviceScanner.h"
#include "DeviceManager.h"
#include "GoProFileModel.h"
#include "GenericFileModel.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QDir>
#include <QFile>
#include <QStorageInfo>
#include <QDebug>

/* ************************************************************************** */

DeviceScanner::DeviceScanner()
{
    connect(&m_watcherFilesystem, &QFileSystemWatcher::directoryChanged, this, &DeviceScanner::removeFilesystem);
}

DeviceScanner::~DeviceScanner()
{
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceScanner::searchDevices()
{
    emit scanningStarted();

    scanFilesystems();
    scanVirtualFilesystems();
    scanMtpDevices();

    emit scanningFinished();
}

/* ************************************************************************** */

void DeviceScanner::scanFilesystems()
{
    QStringList connectedFilesystems;

    // Check if we have new device(s)
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

        if (storage.rootPath() == "/" ||
            storage.rootPath() == "/home" ||
            storage.rootPath().startsWith("/boot") ||
            storage.rootPath().startsWith("/Users/"))
        {
            //qDebug() << "> skipping OS internal filesystem";
            continue;
        }

        connectedFilesystems.push_back(storage.rootPath());

        // Path already in "watched" list? bail early!
        if (m_watchedFilesystems.contains(storage.rootPath()))
        {
            //qDebug() << "> skipping '" << storage.rootPath() << "', already handled";
            continue;
        }

        if (storage.isValid() && storage.isReady())
        {
            QString deviceRootpath = storage.rootPath();
            bool found = false;

            gopro_device_infos *goproDeviceInfos = new gopro_device_infos;
            if (goproDeviceInfos && found == false)
            {
                if (parseGoProVersionFile(deviceRootpath, *goproDeviceInfos))
                {
                    found = true;

                    // Send device infos to the DeviceManager
                    emit fsDeviceFound(deviceRootpath, goproDeviceInfos);

                    // Watch this path
                    m_watchedFilesystems.push_back(deviceRootpath);
                    if (m_watcherFilesystem.addPath(deviceRootpath) == false)
                        qDebug() << "FILE WATCHER FAILZD for " << deviceRootpath;
                }
                else
                {
                    delete goproDeviceInfos;
                }
            }

            generic_device_infos *genericDeviceInfos = new generic_device_infos;
            if (genericDeviceInfos && found == false)
            {
                if (parseGenericDCIM(deviceRootpath, *genericDeviceInfos))
                {
                    found = true;

                    // Send device infos to the DeviceManager
                    emit fsDeviceFound(deviceRootpath, genericDeviceInfos);

                    // Watch this path
                    m_watchedFilesystems.push_back(deviceRootpath);
                    if (m_watcherFilesystem.addPath(deviceRootpath) == false)
                        qDebug() << "FILE WATCHER FAILZD for " << deviceRootpath;
                }
                else
                {
                    delete genericDeviceInfos;
                }
            }
        }
        else
        {
            qDebug() << "* mountpoint invalid? '" << storage.displayName() << "'";
        }
    }

    // Check if we lost some device(s) since last scan
    for (auto storage: m_watchedFilesystems)
    {
        if (connectedFilesystems.contains(storage) == false)
        {
            //qDebug() << storage << "has gone missing, removing device...";
            removeFilesystem(storage);
        }
    }
}

/* ************************************************************************** */

void DeviceScanner::scanVirtualFilesystems()
{
#ifdef __linux
    QStringList connectedVirtualFilesystems;

    // Check if we have new device(s)
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
                QString virtual_mountpoint = storage.rootPath() + "/gvfs/" + subdir_device;

                //qDebug() << "> VIRTUAL MOUNTPOINT(" << storage.fileSystemType() << ") > " << virtual_mountpoint;

                connectedVirtualFilesystems.push_back(storage.rootPath() + "/gvfs/" + subdir_device);

                ofb_vfs_device *deviceInfos = new ofb_vfs_device;
                if (deviceInfos)
                {
                    int bus = -1, dev = -1;
                    std::pair<uint32_t, uint32_t> currentMtpDevice;

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
                        currentMtpDevice = std::make_pair(bus, dev);
                        deviceInfos->devBus = static_cast<uint32_t>(bus);
                        deviceInfos->devNum = static_cast<uint32_t>(dev);

                        // Device in watch list? bail early!
                        // FIXME m_watchedMtpDevices is never cleaned but bus ids are dynamic anyway
                        if (m_watchedMtpDevices.contains(currentMtpDevice))
                        {
                            //qDebug() << "> skipping device @ bus" << currentMtpDevice.first << ", dev" << currentMtpDevice.second << ", already handled";
                            delete deviceInfos;
                            continue;
                        }

                        DeviceManager::getMtpDeviceName(deviceInfos->devBus, deviceInfos->devNum,
                                                        deviceInfos->brand, deviceInfos->model);
                        //qDebug() << "MTP infos:" << deviceInfos->devBus << "/" << deviceInfos->devNum;
                        //qDebug() << "MTP infos:" << deviceInfos->brand << "/" << deviceInfos->model;
                    }
                    else
                    {
                        // Probably not handled by libMTP...
                        //qDebug() << "> skipping device: not handled";

                        // skip?
                        delete deviceInfos;
                        continue;
                    }

                    // Then we usually have a subdirectory per MTP 'volume'
                    // ex: one volume for the internal flash of a phone and one for its SD card
                    QDir gvfsSubDirectory(virtual_mountpoint);
                    foreach (QString subdir_volume, gvfsSubDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
                    {
                        //qDebug() << "Scanning MTP subdir_volume:" << subdir_volume;
                        //qDebug() << "deviceRootpath:" << deviceRootpath;
                        QString devicePath = virtual_mountpoint + "/" + subdir_volume;

                        QDir dcim(devicePath + "/DCIM");
                        if (dcim.exists() && dcim.isReadable())
                        {
                            //qDebug() << "WE HAVE a DCIM directory on" << devicePath;
                            deviceInfos->paths.push_back(devicePath);
                        }
                    }

                    if (deviceInfos->paths.size() > 0)
                    {
                        // Send device infos to the DeviceManager
                        emit vfsDeviceFound(deviceInfos);
                        m_watchedMtpDevices.push_back(currentMtpDevice);
                        m_watchedVirtualFilesystems.push_back(deviceInfos->paths.front());
                    }
                    else
                    {
                        delete deviceInfos;
                    }
                }
            }
        }
    }

    // Check if we lost some device(s) since last scan
    for (auto watchedFs: m_watchedVirtualFilesystems)
    {
        bool connected = false;

        for (auto connectedFs: connectedVirtualFilesystems)
        {
            if (connectedFs.startsWith(watchedFs))
            {
                connected = true;
            }
        }

        if (connected == false)
        {
            //qDebug() << watchedFs << "has gone missing, removing device...";
            removeFilesystem(watchedFs);
        }
    }

#endif // __linux
}

/* ************************************************************************** */

void DeviceScanner::scanMtpDevices()
{
#ifdef ENABLE_LIBMTP

    QList <std::pair<unsigned, unsigned>> connectedMtpDevices;

    int numrawdevices = 0;
    LIBMTP_raw_device_t *rawdevices = nullptr;

    // use this to get *already* connected devices? ??
    //LIBMTP_Get_Connected_Devices(LIBMTP_mtpdevice_t **device_list)

    // check for devices that have disapeared
    //LIBMTP_Check_Specific_Device()
    //LIBMTP_Get_Connected_Devices(LIBMTP_mtpdevice_t **device_list)

    LIBMTP_error_number_t err = LIBMTP_Detect_Raw_Devices(&rawdevices, &numrawdevices);
    switch (err)
    {
    case LIBMTP_ERROR_NONE:
        //qDebug() << "MTP: Found %d device(s):" << numrawdevices;
        break;
    case LIBMTP_ERROR_NO_DEVICE_ATTACHED:
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

    // Check if we have new device(s)
    for (int i = 0; i < numrawdevices; i++)
    {
/*
        qDebug() << "> MTP DEVICE(" << rawdevices[i].device_entry.vendor << rawdevices[i].device_entry.product \
                 << ") [" << rawdevices[i].device_entry.vendor_id << ":" << rawdevices[i].device_entry.product_id \
                 << "] @ bus" << rawdevices[i].bus_location << ", dev" << rawdevices[i].devnum;
*/
        // Device in watch list? bail early!
        auto currentMtpDevice = std::make_pair(rawdevices[i].bus_location, rawdevices[i].devnum);
        connectedMtpDevices.push_back(currentMtpDevice);
        if (m_watchedMtpDevices.contains(currentMtpDevice))
        {
            //qDebug() << "> skipping device @ bus" << currentMtpDevice.first << ", dev" << currentMtpDevice.second << ", already handled";
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
        ofb_mtp_device *deviceInfos = new ofb_mtp_device;
        if (deviceInfos)
        {
            // Device infos
            char *deviceversion = LIBMTP_Get_Deviceversion(mtpDevice);
            char *serialnumber = LIBMTP_Get_Serialnumber(mtpDevice);

            deviceInfos->brand =  rawdevices[i].device_entry.vendor;
            deviceInfos->model = rawdevices[i].device_entry.product;
            deviceInfos->serial = serialnumber;
            deviceInfos->firmware = deviceversion;

            deviceInfos->devBus = rawdevices[i].bus_location;
            deviceInfos->devNum = rawdevices[i].devnum;
            deviceInfos->device = mtpDevice;

            // Battery infos
            uint8_t maxbattlevel, currbattlevel;
            int ret = LIBMTP_Get_Batterylevel(mtpDevice, &maxbattlevel, &currbattlevel);
            if (ret == 0 && maxbattlevel > 0)
            {
                deviceInfos->battery = (static_cast<double>(currbattlevel) / static_cast<double>(maxbattlevel)) * 100.0;
                //qDebug() << "MTP Battery level:" << deviceInfos->battery << "%";
            }
            else
            {
                // Silently ignore. Some devices does not support getting the battery level.
                LIBMTP_Clear_Errorstack(mtpDevice);
            }

            // Storage infos
            for (LIBMTP_devicestorage_t *storage = mtpDevice->storage;
                 storage != nullptr;
                 storage = storage->next)
            {
                //storage->AccessCapability // 0x0000 read/write
                //storage->FreeSpaceInBytes
                //storage->MaxCapacity

                // Get file listing for the root directory only, search for a DCIM directory
                LIBMTP_file_t *files = LIBMTP_Get_Files_And_Folders(mtpDevice, storage->id, LIBMTP_FILES_AND_FOLDERS_ROOT);
                if (files != nullptr)
                {
                    LIBMTP_file_t *file = files;
                    LIBMTP_file_t *tmp;
                    while (file != nullptr)
                    {
                        //qDebug() << "-" << file->filename;

                        if (strcmp(file->filename, "DCIM"))
                        {
                            StorageMtp *s = new StorageMtp;
                            s->m_device = mtpDevice;
                            s->m_storage = storage;
                            s->m_dcim_id = file->item_id;
                            s->m_writable = (storage->AccessCapability == 0) ? true : false;
/*
                            qDebug() << "MTP storage:";
                            qDebug() << "-" << s->m_device;
                            qDebug() << "-" << s->m_storage;
                            qDebug() << "-" << s->m_storage->id;
*/
                            deviceInfos->storages.push_back(s);
                        }

                        tmp = file;
                        file = file->next;
                        LIBMTP_destroy_file_t(tmp);
                    }
                }
            }

            if (deviceInfos->storages.size() > 0)
            {
                // Send device infos to the DeviceManager
                emit mtpDeviceFound(deviceInfos);
                m_watchedMtpDevices.push_back(currentMtpDevice);
            }
            else
            {
                LIBMTP_Release_Device(mtpDevice);
                delete deviceInfos;
            }
        }
    }

    free(rawdevices);

    // Check if we lost some device(s) since last scan
    for (auto watchedDevice: m_watchedMtpDevices)
    {
        if (connectedMtpDevices.contains(watchedDevice) == false)
        {
            //qDebug() << "Device @ bus" << watchedDevice.first << ", dev" << watchedDevice.second << "has gone missing, removing device...";
            removeMtpDevice(watchedDevice);
        }
    }

#endif // ENABLE_LIBMTP
}

/* ************************************************************************** */

void DeviceScanner::removeFilesystem(const QString &path)
{
    if (path.isEmpty())
        return;

    //qDebug() << "DeviceScanner::removeFilesystem()" << path;

    QDir dir(path);
    if (dir.exists() == true)
    {
        // FIXME virtual filesystem sometimes still exists after physical removal
        qDebug() << "DeviceScanner::removeFilesystem()" << path << "but associated directory STILL exists";
    }

    {
        m_watcherFilesystem.removePath(path);
        m_watchedFilesystems.removeOne(path);
        m_watchedVirtualFilesystems.removeOne(path);

        Q_EMIT fsDeviceRemoved(path);
    }
}

void DeviceScanner::removeMtpDevice(std::pair<unsigned, unsigned> device)
{
    m_watchedMtpDevices.removeOne(device);

    Q_EMIT mtpDeviceRemoved(device.first, device.second);
}

/* ************************************************************************** */
