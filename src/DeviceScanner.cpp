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

#include <QStorageInfo>

#include <QFile>
#include <QDir>
#include <QDebug>

/* ************************************************************************** */

DeviceScanner::DeviceScanner()
{
    //
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
            if (goproDeviceInfos)
            {
                if (parseGoProVersionFile(deviceRootpath, *goproDeviceInfos))
                {
                    // Send device infos to the DeviceManager
                    emit fsDeviceFound(deviceRootpath, goproDeviceInfos);
                    m_watchedFilesystems.push_back(deviceRootpath);
                }
                else
                {
                    delete goproDeviceInfos;
                }
            }

            generic_device_infos *genericDeviceInfos = new generic_device_infos;
            if (genericDeviceInfos)
            {
                if (parseGenericDCIM(deviceRootpath, *genericDeviceInfos))
                {
                    emit fsDeviceFound(deviceRootpath, genericDeviceInfos);
                    m_watchedFilesystems.push_back(deviceRootpath);
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
}

/* ************************************************************************** */

void DeviceScanner::scanVirtualFilesystems()
{
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
                //qDebug() << "Scanning MTP subdir_device:" << subdir_device;

                ofb_vfs_device *deviceInfos = new ofb_vfs_device;
                if (deviceInfos)
                {
                    int bus = -1, dev = -1;
                    std::pair<uint32_t, uint32_t> currentMtpDevice;
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
                        currentMtpDevice = std::make_pair(bus, dev);
                        deviceInfos->devBus = static_cast<uint32_t>(bus);
                        deviceInfos->devNum = static_cast<uint32_t>(dev);

                        // Device in watch list? bail early!
                        if (m_watchedMtpDevices.contains(currentMtpDevice))
                        {
                            //qDebug() << "> skipping device @ bus" << currentMtpDevice.first << ", dev" << currentMtpDevice.second << ", already handled";
                            delete deviceInfos;
                            continue;
                        }

                        DeviceManager::getMtpDeviceName(deviceInfos->devBus, deviceInfos->devNum,
                                                        deviceInfos->brand, deviceInfos->model);
                        //qDebug() << "MTP infos:" << bus << "/" << dev;
                        //qDebug() << "MTP infos:" << brand << "/" << model;
                    }
                    else
                    {
                        // Probably not handled by libMTP...

                        // skip?
                        delete deviceInfos;
                        continue;
                    }

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
                            deviceInfos->paths.push_back(deviceRootpath);
                        }
                    }
/*
                    QFile getstarted(deviceInfos->paths.at(0) + "/Get_started_with_GoPro.url");
                    if (getstarted.exists())
                    {
                        qDebug() << "WE HAVE A GOPRO";
                    }
*/
                    if (deviceInfos->paths.size() > 0)
                    {
                        // Send device infos to the DeviceManager
                        emit vfsDeviceFound(deviceInfos);
                        m_watchedMtpDevices.push_back(currentMtpDevice);
                    }
                    else
                    {
                        delete deviceInfos;
                    }
                }
            }
        }
    }

#endif // __linux
}

/* ************************************************************************** */

void DeviceScanner::scanMtpDevices()
{
#ifdef ENABLE_LIBMTP

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

    for (int i = 0; i < numrawdevices; i++)
    {
/*
        qDebug() << "> MTP DEVICE(" << rawdevices[i].device_entry.vendor << rawdevices[i].device_entry.product \
                 << ") [" << rawdevices[i].device_entry.vendor_id << ":" << rawdevices[i].device_entry.product_id \
                 << "] @ bus" << rawdevices[i].bus_location << ", dev" << rawdevices[i].devnum;
*/
        // Device in watch list? bail early!
        auto currentMtpDevice = std::make_pair(rawdevices[i].bus_location, rawdevices[i].devnum);
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

#endif // ENABLE_LIBMTP
}

/* ************************************************************************** */
