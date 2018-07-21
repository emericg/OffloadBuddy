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

#include <unistd.h>

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

    m_updateTimer.setInterval(SCANNING_TIMER);
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

                    deviceRootpath = storage.rootPath() + "/gvfs/" + subdir_device + "/GoPro MTP Client Disk Volume";
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

bool DeviceManager::scanMtpDevices()
{
    bool status = false;

#ifdef ENABLE_LIBMTP

    qDebug() << "Listing raw device(s)"; ///////////////////////////////////////

    LIBMTP_raw_device_t *rawdevices;
    int numrawdevices;
    LIBMTP_error_number_t err;

    err = LIBMTP_Detect_Raw_Devices(&rawdevices, &numrawdevices);
    switch(err)
    {
    case LIBMTP_ERROR_NO_DEVICE_ATTACHED:
        qDebug() << "Detect: No raw devices found.";
        status = true;
        break;
    case LIBMTP_ERROR_CONNECTING:
        qDebug() << "Detect: There has been an error connecting. Exiting";
        break;
    case LIBMTP_ERROR_MEMORY_ALLOCATION:
        qDebug() << "Detect: Encountered a Memory Allocation Error. Exiting";
        break;

    case LIBMTP_ERROR_NONE:
    {        
        qDebug() << "  Found %d device(s):" <<  numrawdevices;
        for (int i = 0; i < numrawdevices; i++)
        {
            if (rawdevices[i].device_entry.vendor != NULL ||
                rawdevices[i].device_entry.product != NULL)
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
        status = true;
    }
    break;

    case LIBMTP_ERROR_GENERAL:
    default:
        qDebug() << "Unknown connection error.";
        break;
    }

    qDebug() << "Attempting to connect device(s)"; /////////////////////////////

    for (int i = 0; i < numrawdevices; i++)
    {
        LIBMTP_mtpdevice_t *device;
        LIBMTP_devicestorage_t *storage;
        char *friendlyname;
        char *syncpartner;
        char *sectime;
        char *devcert;
        uint16_t *filetypes;
        uint16_t filetypes_len;
        uint8_t maxbattlevel;
        uint8_t currbattlevel;
        int ret;

        //device = LIBMTP_Open_Raw_Device_Uncached(&rawdevices[i]);
        device = LIBMTP_Open_Raw_Device(&rawdevices[i]);
        if (device == nullptr)
        {
            qDebug() << "Unable to open raw device #" << i;
            continue;
        }

        LIBMTP_Dump_Errorstack(device);
        LIBMTP_Clear_Errorstack(device);
        LIBMTP_Dump_Device_Info(device);

        qDebug() << "MTP-specific device properties:";

        // The friendly name
        friendlyname = LIBMTP_Get_Friendlyname(device);
        if (friendlyname == NULL)
        {
            qDebug() << "   Friendly name: (NULL)";
        }
        else
        {
            qDebug() << "   Friendly name:" << friendlyname;
            free(friendlyname);
        }
        syncpartner = LIBMTP_Get_Syncpartner(device);
        if (syncpartner == NULL)
        {
            qDebug() << "   Synchronization partner: (NULL)";
        }
        else
        {
            qDebug() << "   Synchronization partner:" << syncpartner;
            free(syncpartner);
        }

        // Some battery info
        ret = LIBMTP_Get_Batterylevel(device, &maxbattlevel, &currbattlevel);
        if (ret == 0)
        {
            qDebug() << "   Battery level" << currbattlevel << "of" << maxbattlevel \
                     << "(" << (int) ((float) currbattlevel/ (float) maxbattlevel * 100.0) << "%)";
        }
        else
        {
            // Silently ignore. Some devices does not support getting the battery level.
            LIBMTP_Clear_Errorstack(device);
        }

        ret = LIBMTP_Get_Supported_Filetypes(device, &filetypes, &filetypes_len);
        if (ret == 0)
        {
            qDebug() << "libmtp supported (playable) filetypes:";
            for (uint16_t j = 0; j < filetypes_len; j++)
            {
                qDebug() << "   " << QString::fromLocal8Bit(LIBMTP_Get_Filetype_Description((LIBMTP_filetype_t)filetypes[j]));
            }
        }
        else
        {
            LIBMTP_Dump_Errorstack(device);
            LIBMTP_Clear_Errorstack(device);
        }

        // TODO

        LIBMTP_Release_Device(device);
    } /* End For Loop */

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
    bool deviceExists = false;
    for (auto d: m_devices)
    {
        Device *dd = qobject_cast<Device*>(d);
        if (dd && dd->getRootPath() == path)
        {
            deviceExists = true;
            break;
        }
    }

    if (deviceExists == false)
    {
        Device *d = new Device(path, infos);
        if (d->isValid())
        {
            qDebug() << ">>>> ADDING DEVICE";

            m_devices.push_back(d);
            d->scanFiles();

            m_watcher.addPath(path);

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

void DeviceManager::removeDevice(const QString &path)
{
    QList<QObject *>::iterator it = m_devices.begin();
    while (it != m_devices.end())
    {
        Device *dd = qobject_cast<Device*>(*it);
        if (dd && dd->getRootPath() == path)
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

    QDir d(path);
    if (d.exists() == false)
    {
        removeDevice(path);
    }
}

/* ************************************************************************** */
