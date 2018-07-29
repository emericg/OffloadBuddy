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
            storage.fileSystemType() == "nfs4" /*||
            storage.fileSystemType() == "tmpfs"*/)
        {
            //qDebug() << "> skipping network filesystem";
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
                    device = rawdevices[i].device_entry.product;
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
        auto cur = std::make_pair(rawdevices[i].bus_location, rawdevices[i].devnum);
        if (m_watcherMtp.contains(cur))
        {
            qDebug() << "> skipping device @ bus" << rawdevices[i].bus_location << ", dev" << rawdevices[i].devnum << ", already handled";
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
                    m_watcherMtp.push_back(cur);
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
                (!infos || (infos && d->getSerial() == infos->camera_serial_number)))
            {
                deviceExists = true;
                break;
            }
            else if (d->getModel() == "FUSION" &&
                     d->getPath(0) != path &&
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
            d = new Device(brand, infos->camera_type,
                           infos->camera_serial_number, infos->firmware_version);

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
