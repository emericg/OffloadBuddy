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

    QObject::connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, &DeviceManager::somethingsUp);
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
/*
        qDebug() << "> MOUNTPOINT:";
        qDebug() << "- mountpoint:" << storage.rootPath();
        qDebug() << "- type:" << storage.fileSystemType();
*/
        if (storage.fileSystemType() == "nfs" ||
            storage.fileSystemType() == "nfs4" /*||
            storage.fileSystemType() == "tmpfs"*/)
        {
            //qDebug() << "> skipping network filesystem";
            continue;
        }

        // Path in QFileSystemWatcher? bail early
        if (m_watcher.directories().contains(storage.rootPath()))
        {
            //qDebug() << "> skipping '" << storage.rootPath() << "', already handled";
            continue;
        }

        if (storage.isValid() && storage.isReady())
        {
            QString deviceRootpath = storage.rootPath();
            gopro_version_20 deviceInfos;

#ifdef __linux
            if (storage.fileSystemType() == "tmpfs")
            {
                QDir gvfsDirectory(storage.rootPath() + "/gvfs");
                foreach (QString subdir_device, gvfsDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
                {
                    qDebug() << "Scanning MTP subdir:" << subdir_device;

                    // detect every other cameras / phones devces
                    QDir gvfsSubDirectory(gvfsDirectory.path() + "/" + subdir_device);
                    foreach (QString subsubdir, gvfsSubDirectory.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
                    {
                        qDebug() << "Scanning MTP subsubdir:" << subsubdir;

                        deviceRootpath = gvfsSubDirectory.path() + "/" + subsubdir;
                        QDir dcim(deviceRootpath + "/DCIM");
                        if (dcim.exists())
                        {
                            addDevice(deviceRootpath);
                        }
                    }

                    deviceRootpath = gvfsDirectory.path() + "/" + subdir_device + "/GoPro MTP Client Disk Volume";
                    QFile getstarted(deviceRootpath + "/Get_started_with_GoPro.url");
                    QDir dcim(deviceRootpath + "/DCIM");
                    if (getstarted.exists() && dcim.exists())
                    {
                        addDevice(deviceRootpath);
                    }
                }
            }
            else
#endif // __linux
            {
                if (parseGoProVersionFile(deviceRootpath, deviceInfos))
                {
                    addDevice(deviceRootpath, &deviceInfos);
                }
            }
        }
        else
        {
            qDebug() << "* mountpoint invalid? '" << storage.displayName() << "'";
        }
    }

    return status;
}

bool DeviceManager::getMtpDevices(const uint32_t busNum, const uint32_t devNum,
                                  QString &brand, QString &device)
{
#ifdef ENABLE_LIBMTP

    int numrawdevices;
    LIBMTP_raw_device_t *rawdevices;
    LIBMTP_error_number_t err;

    err = LIBMTP_Detect_Raw_Devices(&rawdevices, &numrawdevices);
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
                    device = rawdevices[i].device_entry.product;
                    return true;
                }
            }
        }
    }

    free(rawdevices);

#endif // ENABLE_LIBMTP

    return false;
}

bool DeviceManager::scanMtpDevices()
{
    bool status = false;

#ifdef ENABLE_LIBMTP

    LIBMTP_raw_device_t *rawdevices = nullptr;
    int numrawdevices = 0;

    LIBMTP_error_number_t err = LIBMTP_Detect_Raw_Devices(&rawdevices, &numrawdevices);
    switch (err)
    {
    case LIBMTP_ERROR_NO_DEVICE_ATTACHED:
        qDebug() << "MTP: No raw devices found.";
        status = true;
        break;
    case LIBMTP_ERROR_CONNECTING:
        qDebug() << "MTP: There has been an error connecting. Exiting";
        break;
    case LIBMTP_ERROR_MEMORY_ALLOCATION:
        qDebug() << "MTP: Encountered a Memory Allocation Error. Exiting";
        break;

    case LIBMTP_ERROR_NONE:
    {
        qDebug() << "MTP: Found %d device(s):" <<  numrawdevices;
        status = true;

        for (int i = 0; i < numrawdevices; i++)
        {
            if (rawdevices[i].device_entry.vendor != nullptr ||
                rawdevices[i].device_entry.product != nullptr)
            {
                qDebug() << "  MTP:" << rawdevices[i].device_entry.vendor << rawdevices[i].device_entry.product \
                         << ":" << rawdevices[i].device_entry.vendor_id \
                         << "(" << rawdevices[i].device_entry.vendor_id << ":" << rawdevices[i].device_entry.product_id \
                         << ") @ bus" << rawdevices[i].bus_location << ", dev" << rawdevices[i].devnum;
            }
            else
            {
/*
                qDebug() << "  %04x:%04x @ bus %d, dev %d\n",
                rawdevices[i].device_entry.vendor_id,
                rawdevices[i].device_entry.product_id,
                rawdevices[i].bus_location,
                rawdevices[i].devnum);
*/
            }
        }
    } break;

    case LIBMTP_ERROR_GENERAL:
    default:
        qDebug() << "MTP: Unknown connection error.";
        break;
    }

    for (int i = 0; i < numrawdevices; i++)
    {
        LIBMTP_mtpdevice_t *device = LIBMTP_Open_Raw_Device_Uncached(&rawdevices[i]);
        if (device == nullptr)
        {
            qDebug() << "MTP: Unable to open raw device #" << i;
            continue;
        }
/*
        LIBMTP_Dump_Errorstack(device);
        LIBMTP_Clear_Errorstack(device);
        LIBMTP_Dump_Device_Info(device);
*/
        // Synchronization partner
        char *syncpartner = LIBMTP_Get_Syncpartner(device);
        if (syncpartner != nullptr)
        {
            qDebug() << "   Synchronization partner:" << syncpartner;
            free(syncpartner);
        }

        // Device infos
        char *version = LIBMTP_Get_Deviceversion(device);
        char *serial = LIBMTP_Get_Serialnumber(device);
        rawdevices[i].device_entry.vendor;
        rawdevices[i].device_entry.product;

        // Battery infos
        uint8_t maxbattlevel, currbattlevel;
        int ret = LIBMTP_Get_Batterylevel(device, &maxbattlevel, &currbattlevel);
        if (ret == 0)
        {
            qDebug() << "MTP Battery level" << currbattlevel << "of" << maxbattlevel \
                     << "(" << ((double)currbattlevel/ (double)maxbattlevel * 100.0) << "%)";
        }
        else
        {
            // Silently ignore. Some devices does not support getting the battery level.
            LIBMTP_Clear_Errorstack(device);
        }

        // Storage infos
        for (LIBMTP_devicestorage_t *storage = device->storage; storage != nullptr; storage = storage->next)
        {
            //storage->AccessCapability // 0x0000 read/write
            //storage->FreeSpaceInBytes
            //storage->MaxCapacity

            // Get file listing for the root directory, no other dirs
            LIBMTP_file_t *files = LIBMTP_Get_Files_And_Folders(device, storage->id, LIBMTP_FILES_AND_FOLDERS_ROOT);
            if (files != nullptr)
            {
                qDebug() << "MTP FILES:";

                LIBMTP_file_t *file, *tmp;
                file = files;
                while (file != nullptr)
                {
                    qDebug() << "-" << file->filename;

                    if (!strcmp(file->filename, "WMPInfo.xml") ||
                        !strcmp(file->filename, "WMPinfo.xml") ||
                        !strcmp(file->filename, "default-capabilities.xml"))
                    {
                        if (file->item_id != 0)
                        {
                        }
                    }

                    tmp = file;
                    file = file->next;
                    LIBMTP_destroy_file_t(tmp);
                }
            }
        }

        LIBMTP_Release_Device(device);
    }

    free(rawdevices);

#endif // ENABLE_LIBMTP

    return status;
}

bool DeviceManager::searchDevices()
{
    bool status = false;

    scanFilesystems();
    scanMtpDevices();

    return status;
}

bool DeviceManager::parseGoProVersionFile(const QString &path, gopro_version_20 &infos)
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
                        if (value != "2.0")
                            qWarning() << "SD Card version.txt is unsupported!";

                    if (key == "firmware version")
                        infos.firmware_version = value;

                    if (key == "camera type")
                        infos.camera_type = value;

                    if (key == "camera serial number")
                        infos.camera_serial_number = value;

                    if (key == "wifi mac")
                        infos.wifi_mac = value;
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

void DeviceManager::addDevice(const QString &path, const gopro_version_20 *infos)
{
    Device *d = nullptr;
    bool deviceExists = false;
    bool deviceMerge = false;

    if (m_devices.size() >= MAX_DEVICES)
        return;

    for (auto dd: m_devices)
    {
        d = qobject_cast<Device*>(dd);
        if (d)
        {
            if ((d->getRootPath() == path || d->getSecondayRootPath() == path) &&
                (!infos || (infos && d->getSerial() == infos->camera_serial_number)))
            {
                deviceExists = true;
                break;
            }
            else if (d->getModel() == "FUSION" &&
                     d->getRootPath() != path &&
                     (!infos || (infos && d->getSerial() == infos->camera_serial_number)))
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
            qDebug() << ">>>> MERGING DEVICE";

            // fusioooooooon
            d->addSecondaryDevice(path);
            d->scanSecondaryDevice();

            if (m_watcher.addPath(path) == false)
                qDebug() << "FILE WATCHER FAILZD";

            emit devicesUpdated();
            emit devicesAdded();
        }
        else
        {
            d = new Device(path, infos);
            if (d->isValid())
            {
                qDebug() << ">>>> ADDING DEVICE";

                m_devices.push_back(d);
                d->scanFiles();

                if (m_watcher.addPath(path) == false)
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
    }
}

void DeviceManager::removeDevice(const QString &path)
{
    QList<QObject *>::iterator it = m_devices.begin();
    while (it != m_devices.end())
    {
        Device *d = qobject_cast<Device*>(*it);
        if (d && (d->getRootPath() == path || d->getSecondayRootPath() == path))
            it = m_devices.erase(it);
        else
            ++it;
    }

    m_watcher.removePath(path);

    emit devicesUpdated();
    emit devicesRemoved();
}

void DeviceManager::somethingsUp(const QString &path)
{
    qDebug() << "QFileSystemWatcher::directoryChanged()" << path;

    QDir dir(path);
    if (dir.exists() == false)
    {
        removeDevice(path);
    }
}

/* ************************************************************************** */
