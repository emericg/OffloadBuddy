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
#include "DeviceScanner.h"
#include "GoProFileModel.h"
#include "JobManager.h"
#include "FileScanner.h"

#include <QStorageInfo>
#include <QFile>
#include <QDir>
#include <QThread>
#include <QDebug>

/* ************************************************************************** */

Device::Device(const QString &brand, const QString &model,
               const QString &serial, const QString &version)
{
    m_brand = brand;
    m_model = model;
    m_serial = serial;
    m_firmware = version;

    m_shotModel = new ShotModel;

    m_updateStorageTimer.setInterval(5 * 1000);
    connect(&m_updateStorageTimer, &QTimer::timeout, this, &Device::refreshStorageInfos);
    m_updateStorageTimer.start();
}

Device::~Device()
{
    delete m_shotModel;

    qDeleteAll(m_filesystemStorages);
    m_filesystemStorages.clear();

#ifdef ENABLE_LIBMTP
    qDeleteAll(m_mtpStorages);
    m_mtpStorages.clear();

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

double Device::getSpaceUsed_percent()
{
    if (getSpaceTotal() > 0)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(getSpaceTotal());

    return 0.0;
}

int64_t Device::getSpaceAvailable_withrefresh()
{
    refreshStorageInfos();
    return getSpaceAvailable();
}

/* ************************************************************************** */
/* ************************************************************************** */

bool Device::addStorages_filesystem(ofb_fs_device *device)
{
    bool status = false;

    qDebug() << "addStorages_filesystem" << device->storages.size();

    return status;
}

bool Device::addStorages_mtp(ofb_mtp_device *device)
{
    bool status = true;

    qDebug() << "addStorages_mtp" << device->storages.size();

    for (auto st: device->storages)
    {
        m_mtpStorages.push_back(st);

        if (status == true)
        {
            QThread *thread = new QThread();
            FileScanner *fs = new FileScanner();

            if (thread && fs)
            {
                fs->chooseMtpStorage(st);
                fs->moveToThread(thread);

                connect(thread, SIGNAL(started()), fs, SLOT(scanMtpDevice()));
                connect(fs, SIGNAL(fileFound(ofb_file *, ofb_shot *)), m_shotModel, SLOT(addFile(ofb_file *, ofb_shot *)));
                connect(fs, SIGNAL(scanningFinished(QString)), this, SLOT(workerScanningFinished(QString)));

                // automatically delete thread and everything when the work is done
                connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
                connect(fs, SIGNAL (scanningFinished(QString)), fs, SLOT (deleteLater()));
                connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

                thread->start();
            }

            // FIXME scan first storage only! Can't do them all at once, needs to be serialized
            break;
        }
    }

    return status;
}

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
        QThread *thread = new QThread();
        FileScanner *fs = new FileScanner();

        if (thread && fs)
        {
            fs->chooseFilesystem(path);
            fs->moveToThread(thread);

            connect(thread, SIGNAL(started()), fs, SLOT(scanFilesystem()));
            connect(fs, SIGNAL(fileFound(ofb_file *, ofb_shot *)), m_shotModel, SLOT(addFile(ofb_file *, ofb_shot *)));
            connect(fs, SIGNAL(scanningFinished(QString)), this, SLOT(workerScanningFinished(QString)));

            // automatically delete thread and everything when the work is done
            connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
            connect(fs, SIGNAL (scanningFinished(QString)), fs, SLOT (deleteLater()));
            connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

            thread->start();
        }
    }

    return status;
}

bool Device::addStorage_mtp(LIBMTP_mtpdevice_t *mtpDevice)
{
    bool status = false;

#ifdef ENABLE_LIBMTP
    if (mtpDevice)
    {
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
        //status = scanMtpDevices();
    }

    return status;
}

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
        if (m_mtpStorages.size() > 0)
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

void Device::getMtpIds(int &devBus, int &devNum) const
{
/*
    if (m_mtpStorages.size() > 0)
    {
        StorageMtp *s = m_mtpStorages.at(0);
        //
    }
*/
}

/* ************************************************************************** */

void Device::workerFoundShot(Shot *s)
{
    qDebug() << "> Device::workerFoundShot";

    m_shotModel->addShot(s);
}

void Device::workerScanningStarted(QString s)
{
    //qDebug() << "> Device::workerScanningStarted(" << s << ")";
    m_deviceState = DEVICE_STATE_SCANNING;
    emit stateUpdated();
}

void Device::workerScanningFinished(QString s)
{
    //qDebug() << "> Device::workerScanningFinished(" << s << ")";
    m_deviceState = DEVICE_STATE_IDLE;
    emit stateUpdated();
}

/* ************************************************************************** */

void Device::refreshBatteryInfos()
{
    //qDebug() << "refreshBatteryInfos()";
    // TODO
}

void Device::refreshStorageInfos()
{
    //qDebug() << "refreshStorageInfos(" << m_storage->rootPath() << ")";

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

void Device::addShot(Shot *shot)
{
    if (m_shotModel)
    {
        m_shotModel->addShot(shot);
    }
}

void Device::deleteShot(Shot *shot)
{
    if (m_shotModel)
    {
        m_shotModel->removeShot(shot);
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::offloadAll()
{
    //qDebug() << "offloadAll()";
    //qDebug() << "(a) shots count: " << m_shotModel->getShotCount();

    JobManager *jm = JobManager::getInstance();

    QList<Shot *> shots;
    m_shotModel->getShots(shots);

    for (auto shot: shots)
    {
        jm->addJob(JOB_COPY, this, shot);
    }
}

void Device::deleteAll()
{
    //qDebug() << "deleteAll()";
    //qDebug() << "(a) shots count: " << m_shotModel->getShotCount();

    JobManager *jm = JobManager::getInstance();

    QList<Shot *> shots;
    m_shotModel->getShots(shots);

    for (auto shot: shots)
    {
        jm->addJob(JOB_DELETE, this, shot);
    }
}

/* ************************************************************************** */
