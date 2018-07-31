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

#include "Device.h"
#include "GoProFileModel.h"
#include "JobManager.h"

#include <QStorageInfo>
#include <QFile>
#include <QDir>
#include <QDebug>

#ifndef LIBMTP_FILES_AND_FOLDERS_ROOT
// Hack for older versions of libmtp (<=1.10?)
#define LIBMTP_FILES_AND_FOLDERS_ROOT 0xffffffff
#endif

/* ************************************************************************** */

Device::Device(const QString &brand, const QString &model,
               const QString &serial, const QString &version)
{
    m_brand = brand;
    m_model = model;
    m_serial = serial;
    m_firmware = version;

    m_shotModel = new ShotModel;

    m_updateTimer.setInterval(5 * 1000);
    connect(&m_updateTimer, &QTimer::timeout, this, &Device::refreshDevice);
    m_updateTimer.start();
}

Device::~Device()
{
    delete m_shotModel;

    qDeleteAll(m_filesystemStorages);
    m_filesystemStorages.clear();

    qDeleteAll(m_mtpStorages);
    m_mtpStorages.clear();

#ifdef ENABLE_LIBMTP
    if (m_mtpDevice)
        LIBMTP_Release_Device(m_mtpDevice);
#endif // ENABLE_LIBMTP
}

/* ************************************************************************** */
/* ************************************************************************** */

bool Device::isValid()
{
    bool status = true;

    if (m_brand.isEmpty() || m_model.isEmpty())
        status = false;

    if (m_filesystemStorages.size() == 0 && m_mtpStorages.size() == 0)
        status = false;

    return status;
}

/* ************************************************************************** */

bool Device::scanFilesystem(const QString &path)
{
    QString dcim_path = path + QDir::separator() + "DCIM";

    emit scanningStarted();
    m_deviceState = DEVICE_STATE_SCANNING;

    qDebug() << "> SCANNING STARTED (filesystem)";
    qDebug() << "  * DCIM:" << dcim_path;

    QDir dcim;
    dcim.setPath(dcim_path);
    foreach (QString subdir_name, dcim.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
    {
        qDebug() << "  * Scanning subdir:" << subdir_name;

        // ex:  100GOPRO
        //      100ANDRO
        //      1000GP
        //      100GBACK

        QDir subdir;
        subdir.setPath(dcim_path + QDir::separator() + subdir_name);

        foreach (QString file_name, subdir.entryList(QDir::Files| QDir::NoDotAndDotDot))
        {
            QFileInfo fi(dcim_path + QDir::separator() + subdir_name + QDir::separator() + file_name);
            if (fi.exists() && fi.isReadable())
            {
                ofb_file *f = new ofb_file;
                {
                    f->name = fi.baseName();
                    f->extension = fi.suffix().toLower();
                    f->size = static_cast<uint64_t>(fi.size());
                    f->creation_date = fi.birthTime();
                    f->modification_date = fi.lastModified();

                    f->filesystemPath = fi.filePath();
                }

                Shared::ShotType file_type = Shared::SHOT_UNKNOWN;
                int file_number = 0;
                int group_number = 0;
                int camera_id = 0; // for multi camera system

                getGoProShotInfos(f->name, f->extension,
                                  file_type, file_number, group_number, camera_id);

                int file_id = (file_type == Shared::SHOT_VIDEO) ? file_number : group_number;
                Shot *s = findShot(file_type, file_id, camera_id);
                if (s)
                {
                    //qWarning() << "Adding file:" << file_name << "to an existing shot";
                    s->addFile(f);
                }
                else
                {
                    //qWarning() << "file:" << file_name << "is a new shot";
                    Shot *s = new Shot(file_type);
                    if (s)
                    {
                        s->addFile(f);
                        s->setFileId(file_id);
                        s->setCameraId(camera_id);
                        if (s->isValid())
                        {
                            m_shotModel->addShot(s);
                        }
                    }
                }
/*
            qDebug() << "    * " << file_path;
            qDebug() << "    - " << file_name;
            qDebug() << "    - " << file_ext;
            qDebug() << "    - " << file_type;
            qDebug() << "    - " << group_number;
            qDebug() << "    - " << file_number;
*/
            }
        }
    }

    qDebug() << "  -" << m_shotModel->getShotList()->size() << "shots found";
    qDebug() << "> SCANNING FINISHED";

    emit scanningFinished();
    m_deviceState = DEVICE_STATE_IDLE;

    return true;
}

bool Device::scanMtpDevices()
{
    bool status = true;

#ifdef ENABLE_LIBMTP

    emit scanningStarted();
    m_deviceState = DEVICE_STATE_SCANNING;

    qDebug() << "> SCANNING STARTED (MTP device)";

    for (auto st: m_mtpStorages)
    {
        //qDebug() << "DCIM:" << dcim_path;

        mtpFileRec(st->m_device, st->m_storage->id, LIBMTP_FILES_AND_FOLDERS_ROOT);
    }

    qDebug() << "  -" << m_shotModel->getShotList()->size() << "shots found";
    qDebug() << "> SCANNING FINISHED";

    emit scanningFinished();
    m_deviceState = DEVICE_STATE_IDLE;

#endif // ENABLE_LIBMTP

    return status;
}

Shot * Device::findShot(Shared::ShotType type, int file_id, int camera_id) const
{
    if (m_shotModel->getShotList()->size() > 0 && file_id > 0)
    {
        for (int i = m_shotModel->getShotList()->size()-1; i >= 0; i--)
        {
            Shot *search = qobject_cast<Shot*>(m_shotModel->getShotList()->at(i));
            if (search && search->getType() == type)
            {
                if (search->getFileId() == file_id &&
                    search->getCameraId() == camera_id)
                {
                    return search;
                }
            }
        }

        //qDebug() << "No shot found for id" << file_id;
    }

    return nullptr;
}

/* ************************************************************************** */

double Device::getSpaceUsed_percent()
{
    if (getSpaceTotal() > 0)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(getSpaceTotal());

    return 0.0;
}

int64_t Device::getSpaceAvailable_withrefresh()
{
    refreshDevice();
    return getSpaceAvailable();
}

/* ************************************************************************** */
/* ************************************************************************** */

bool Device::addStorage_filesystem(const QString &path)
{
    bool status = false;

    if (!path.isEmpty())
    {
        StorageFilesystem *storage = new StorageFilesystem;
        if (storage)
        {
            storage->m_path = path;
            storage->m_storage.setPath(path);

            if (storage->m_storage.isValid() && storage->m_storage.isReady())
            {
                // basic checks
                if (storage->m_storage.bytesAvailable() > 128*1024*1024 &&
                    storage->m_storage.isReadOnly() == false)
                {
                    storage->m_writable = true;
#if __linux
/*
                    // adanced permission checks
                    QFileInfo fi(storage->m_path);
                    QFile::Permissions  e = fi.permissions();
                    if (!e.testFlag(QFileDevice::WriteUser))
                    {
                        m_writable = false;
                        qDebug() << "PERMS error on device:" << e << (unsigned)e;
                    }
*/
#endif // __linux
                }

                m_filesystemStorages.push_back(storage);
                m_deviceType = DEVICE_FILESYSTEM;
                status = true;
            }
            else
            {
                qDebug() << "* device storage invalid? '" << storage->m_storage.displayName() << "'";
                delete storage;
                storage = nullptr;
            }
        }
    }

    if (status == true)
    {
        status = scanFilesystem(path);
    }

    return status;
}

bool Device::addStorage_mtp(LIBMTP_mtpdevice_t *mtpDevice)
{
    bool status = false;

#ifdef ENABLE_LIBMTP
    if (mtpDevice)
    {
        // Battery infos
        uint8_t maxbattlevel, currbattlevel;
        int ret = LIBMTP_Get_Batterylevel(mtpDevice, &maxbattlevel, &currbattlevel);
        if (ret == 0)
        {
            if (maxbattlevel > 0)
                m_battery = (static_cast<double>(currbattlevel)/ static_cast<double>(maxbattlevel)) * 100.0;
            qDebug() << "MTP Battery level:" << m_battery << "%)";
        }
        else
        {
            // Silently ignore. Some devices does not support getting the battery level.
            LIBMTP_Clear_Errorstack(mtpDevice);
        }
/*
        // Synchronization partner
        char *syncpartner = LIBMTP_Get_Syncpartner(device);
        if (syncpartner != nullptr)
        {
            qDebug() << "   Synchronization partner:" << syncpartner;
            free(syncpartner);
        }
*/
        // Storage infos
        for (LIBMTP_devicestorage_t *storage = mtpDevice->storage;
             storage != nullptr;
             storage = storage->next)
        {
            //storage->AccessCapability // 0x0000 read/write
            //storage->FreeSpaceInBytes
            //storage->MaxCapacity

            // Get file listing for the root directory only
            LIBMTP_file_t *files = LIBMTP_Get_Files_And_Folders(mtpDevice, storage->id, LIBMTP_FILES_AND_FOLDERS_ROOT);
            if (files != nullptr)
            {
                qDebug() << "MTP FILES:";

                LIBMTP_file_t *file = files;
                LIBMTP_file_t *tmp;
                while (file != nullptr)
                {
                    qDebug() << "-" << file->filename;

                    if (strcmp(file->filename, "DCIM"))
                    {
                        StorageMtp *s = new StorageMtp;
                        s->m_device = mtpDevice;
                        s->m_storage = storage;
                        s->m_dcim_id = file->item_id;
                        s->m_writable = (storage->AccessCapability == 0) ? true : false;

                        m_mtpStorages.push_back(s);
                        m_deviceType = DEVICE_MTP;
                        m_deviceModel = DEVICE_CAMERA;
                        status = true;
                    }
                    else if (strcmp(file->filename, "Android"))
                        m_deviceModel = DEVICE_PHONE;
                    else if (strcmp(file->filename, "Get_started_with_GoPro.url"))
                        m_deviceModel = DEVICE_GOPRO;

                    tmp = file;
                    file = file->next;
                    LIBMTP_destroy_file_t(tmp);
                }
            }
        }
    }
#endif // ENABLE_LIBMTP

    if (status == true)
    {
        status = scanMtpDevices();
    }

    return status;
}

#ifdef ENABLE_LIBMTP
void Device::mtpFileRec(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf)
{
    LIBMTP_file_t *mtpFiles;

    // Get file listing
    mtpFiles = LIBMTP_Get_Files_And_Folders(device, storageid, leaf);

    if (mtpFiles == nullptr)
    {
        LIBMTP_Dump_Errorstack(device);
        LIBMTP_Clear_Errorstack(device);
    }
    else
    {
        LIBMTP_file_t *mtpFile, *tmp;
        mtpFile = mtpFiles;

        while (mtpFile != nullptr)
        {
            if (mtpFile->filetype == LIBMTP_FILETYPE_FOLDER)
            {
                mtpFileRec(device, storageid, mtpFile->item_id);
            }
            else //if (file->filetype == LIBMTP_FILETYPE_ALBUM)
            {
                //qDebug() << "-" << file->filename << "(" << file->filesize;
                QString file_name = mtpFile->filename;
                QString file_ext = file_name.right(3).toLower();

                ofb_file *f = new ofb_file;
                {
                    f->name = mtpFile->filename;
                    f->extension = file_name.right(3).toLower();
                    f->size = mtpFile->filesize;
                    f->creation_date = f->modification_date = QDateTime::fromTime_t(mtpFile->modificationdate);

                    f->mtpDevice = device;
                    //f->mtpStorage = mtpFile->storage_id;
                    f->mtpObjectId = mtpFile->item_id;
                }

                Shared::ShotType file_type = Shared::SHOT_UNKNOWN;
                int file_number = 0;
                int group_number = 0;
                int camera_id = 0; // for multi camera system

                getGoProShotInfos(file_name, file_ext,
                                  file_type, file_number, group_number, camera_id);

                int shot_id = (file_type == Shared::SHOT_VIDEO) ? file_number : group_number;
                Shot *s = findShot(file_type, shot_id, camera_id);
                if (s)
                {
                    //qWarning() << "Adding file:" << file_name << "to an existing shot";
                    s->addFile(f);
                }
                else
                {
                    //qWarning() << "file:" << file_name << "is a new shot";
                    Shot *s = new Shot(file_type);
                    if (s)
                    {
                        s->addFile(f);
                        s->setFileId(shot_id);
                        s->setCameraId(camera_id);
                        if (s->isValid())
                        {
                            m_shotModel->addShot(s);
                        }
                    }
                }
/*
                qDebug() << "* " << file_path;
                qDebug() << "- " << file_name;
                qDebug() << "- " << file_ext;
                qDebug() << "- " << file_type;
                qDebug() << "- " << group_number;
                qDebug() << "- " << file_number;
*/
            }

            tmp = mtpFile;
            mtpFile = mtpFile->next;
            LIBMTP_destroy_file_t(tmp);
        }
    }
}
#endif // ENABLE_LIBMTP

/* ************************************************************************** */

QString Device::getPath(int index) const
{
    if (index >= 0)
    {
        if (m_filesystemStorages.size() > 0)
        {
            if (m_filesystemStorages.size() > index)
            {
                return m_filesystemStorages.at(index)->m_path;
            }
        }
#ifdef ENABLE_LIBMTP
        else if (m_mtpStorages.size() > 0)
        {
            if (m_mtpStorages.size() > index)
            {
                // TODO
                //return m_devicestorage.at(index)->m_path;
            }
        }
#endif // ENABLE_LIBMTP
    }

    return QString();
}

void Device::refreshDevice()
{
    //qDebug() << "refreshDevice(" << m_storage->rootPath() << ")";

    for (auto storage: m_filesystemStorages)
    {
        if (storage &&
            storage->m_storage.isValid() && storage->m_storage.isReady())
        {
            storage->m_storage.refresh();

            // Check if writable and some space is available // for firmware upates
            if (storage->m_storage.isReadOnly() == false &&
                storage->m_storage.bytesAvailable() > 128*1024*1024)
            {
                storage->m_writable = true;
            }
            else
            {
                storage->m_writable = false;
            }
        }
    }

#ifdef ENABLE_LIBMTP
    for (auto storage: m_mtpStorages)
    {
        if (storage)
        {
            // TODO?
        }
    }

#endif // ENABLE_LIBMTP

    emit spaceUpdated();
}

int64_t Device::getSpaceTotal()
{
    int64_t s = 0;

    for (auto st: m_filesystemStorages)
    {
        if (st)
            s += st->m_storage.bytesTotal();
    }
#ifdef ENABLE_LIBMTP
    for (auto st: m_mtpStorages)
    {
        if (st)
            s += st->m_storage->MaxCapacity;
    }
#endif // ENABLE_LIBMTP

    return s;
}

int64_t Device::getSpaceUsed()
{
    int64_t s = 0;

    for (auto st: m_filesystemStorages)
    {
        if (st)
            s += (st->m_storage.bytesTotal() - st->m_storage.bytesAvailable());
    }
#ifdef ENABLE_LIBMTP
    for (auto st: m_mtpStorages)
    {
        if (st)
            s += st->m_storage->MaxCapacity - st->m_storage->FreeSpaceInBytes;
    }
#endif // ENABLE_LIBMTP

    return s;
}

int64_t Device::getSpaceAvailable()
{
    int64_t s = 0;

    for (auto st: m_filesystemStorages)
    {
        if (st)
            s += st->m_storage.bytesAvailable();
    }
#ifdef ENABLE_LIBMTP
    for (auto st: m_mtpStorages)
    {
        if (st)
            s += st->m_storage->FreeSpaceInBytes;
    }
#endif // ENABLE_LIBMTP

    return s;
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::offloadAll()
{
    qDebug() << "offloadAll()";
}

void Device::deleteAll()
{
    qDebug() << "deleteAll()";
}

/* ************************************************************************** */
