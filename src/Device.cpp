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

#include "Device.h"
#include "DeviceScanner.h"
#include "FileScanner.h"
#include "JobManager.h"
#include "StorageManager.h"

#include <QMap>
#include <QJSValue>
#include <QVariant>

#include <QStorageInfo>
#include <QFile>
#include <QDir>
#include <QUuid>
#include <QThread>
#include <QJSValue>
#include <QDebug>

/* ************************************************************************** */

Device::Device(const deviceType_e type, const deviceStorage_e storage,
               const QString &brand, const QString &model,
               const QString &serial, const QString &version)
{
    m_deviceType = type;
    m_deviceStorage = storage;

    m_brand = brand;
    m_model = model;
    m_serial = serial;
    m_firmware = version;

    m_uuid = QUuid::createUuid().toString();

    connect(&m_updateStorageTimer, &QTimer::timeout, this, &Device::refreshStorageInfos);
    m_updateStorageTimer.setInterval(10 * 1000);
    m_updateStorageTimer.start();

    if (m_deviceStorage == STORAGE_MTP)
    {
        connect(&m_updateBatteryTimer, &QTimer::timeout, this, &Device::refreshBatteryInfos);
        m_updateBatteryTimer.setInterval(60 * 1000);
        m_updateBatteryTimer.start();
    }
}

Device::~Device()
{
    qDeleteAll(m_filesystemStorages);
    m_filesystemStorages.clear();

#ifdef ENABLE_LIBMTP
    qDeleteAll(m_mtpStorages);
    m_mtpStorages.clear();

    qDeleteAll(m_mtpDevices);
    m_mtpDevices.clear();
#endif // ENABLE_LIBMTP
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::setName(const QString &name)
{
    m_model = name;
    emit deviceUpdated();
}

bool Device::isValid()
{
    bool status = true;

    if (m_brand.isEmpty() && m_model.isEmpty())
        status = false;

    if (m_filesystemStorages.empty() && m_mtpStorages.empty())
        status = false;

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool Device::addStorages_filesystem(ofb_fs_device *device)
{
    //qDebug() << "addStorages_filesystem" << device->storages.size();
    bool status = false;

    if (!device)
        return status;

    return status;
}

/* ************************************************************************** */

bool Device::addStorages_mtp(ofb_mtp_device *device)
{
    //qDebug() << "addStorages_mtp" << device->storages.size();
    bool status = false;

    if (!device)
        return status;

    m_deviceStorage = STORAGE_MTP;

    // Device
    if (!m_mtpDevices.contains(device))
    {
        m_mtpDevices.push_back(device);
        emit deviceUpdated();
    }

    // Storage
    for (auto st: qAsConst(device->storages))
    {
        m_mtpStorages.push_back(st);
        emit storageUpdated();
        status = true;

        // Start initial scan
        QThread *thread = new QThread();
        FileScanner *fs = new FileScanner();

        if (thread && fs)
        {
            fs->chooseMtpStorage(st);
            fs->moveToThread(thread);

            connect(thread, SIGNAL(started()), fs, SLOT(scanMtpDevice()));
            connect(fs, SIGNAL(fileFound(ofb_file *, ofb_shot *)), m_shotModel, SLOT(addFile(ofb_file *, ofb_shot *)));
            connect(fs, SIGNAL(scanningStarted(QString)), this, SLOT(workerScanningStarted(QString)));
            connect(fs, SIGNAL(scanningFinished(QString)), this, SLOT(workerScanningFinished(QString)));

            // automatically delete thread and everything when the work is done
            connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
            connect(fs, SIGNAL(scanningFinished(QString)), fs, SLOT (deleteLater()));
            connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

            thread->start();
        }
    }

    return status;
}

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
                // Basic checks // need at least 8 MB
                if (!storage->m_storage.isReadOnly() && storage->m_storage.bytesAvailable() > 8*1024*1024)
                {
#if defined(Q_OS_LINUX)
/*
                    // Advanced permission checks
                    QFileInfo fi(storage->m_path);
                    QFile::Permissions  e = fi.permissions();
                    if (!e.testFlag(QFileDevice::WriteUser))
                    {
                        qDebug() << "PERMS error on device:" << e << (unsigned)e;
                    }
*/
#endif // defined(Q_OS_LINUX)
                }

                m_filesystemStorages.push_back(storage);
                m_deviceStorage = STORAGE_FILESYSTEM;
                status = true;

                emit storageUpdated();
            }
            else
            {
                qDebug() << "* device storage invalid? '" << storage->m_storage.displayName() << "'";
                delete storage;
                storage = nullptr;
            }
        }
    }

    // Start initial scan
    if (status)
    {
        QThread *thread = new QThread();
        FileScanner *fs = new FileScanner();

        if (thread && fs)
        {
            fs->chooseFilesystem(path);
            fs->moveToThread(thread);

            connect(thread, SIGNAL(started()), fs, SLOT(scanFilesystemDCIM()));
            connect(fs, SIGNAL(fileFound(ofb_file *, ofb_shot *)), m_shotModel, SLOT(addFile(ofb_file *, ofb_shot *)));
            connect(fs, SIGNAL(scanningStarted(QString)), this, SLOT(workerScanningStarted(QString)));
            connect(fs, SIGNAL(scanningFinished(QString)), this, SLOT(workerScanningFinished(QString)));

            // automatically delete thread and everything when the work is done
            connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
            connect(fs, SIGNAL(scanningFinished(QString)), fs, SLOT (deleteLater()));
            connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

            thread->start();
        }
    }

    return status;
}

/* ************************************************************************** */

void Device::workerScanningStarted(const QString &path)
{
    //qDebug() << "> Device::workerScanningStarted(" << path << ")";
    Q_UNUSED(path)

    m_deviceState = DEVICE_STATE_SCANNING;
    emit stateUpdated();
}

void Device::workerScanningFinished(const QString &path)
{
    //qDebug() << "> Device::workerScanningFinished(" << path << ")";
    Q_UNUSED(path)

    m_deviceState = DEVICE_STATE_IDLE;
    emit stateUpdated();
}

/* ************************************************************************** */
/* ************************************************************************** */

QString Device::getPath(const int index) const
{
    if (index >= 0)
    {
        if (!m_filesystemStorages.empty())
        {
            if (m_filesystemStorages.size() > index)
            {
                return m_filesystemStorages.at(index)->m_path;
            }
        }
#ifdef ENABLE_LIBMTP
        if (!m_mtpStorages.empty())
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

QStringList Device::getPathList() const
{
    QStringList paths;

    for (auto st: m_filesystemStorages)
    {
        if (st) paths += st->m_path;
    }
#ifdef ENABLE_LIBMTP
/*
    for (auto st: m_mtpStorages)
    {
        if (st) st->m_storage->VolumeIdentifier;
    }
*/
#endif // ENABLE_LIBMTP

    return paths;
}

/* ************************************************************************** */
/* ************************************************************************** */

int Device::getMtpDeviceCount() const
{
    return m_mtpDevices.size();
}

void Device::getMtpIds(unsigned &devBus, unsigned &devNum, const int index) const
{
    if (!m_mtpDevices.isEmpty() && index < m_mtpDevices.size() && m_mtpDevices.at(index))
    {
        devBus = m_mtpDevices.at(index)->devBus;
        devNum = m_mtpDevices.at(index)->devNum;
    }
    else
    {
        devBus = 0;
        devNum = 0;
    }
}

std::pair<unsigned, unsigned> Device::getMtpIds(const int index) const
{
    if (!m_mtpDevices.isEmpty() && index < m_mtpDevices.size() && m_mtpDevices.at(index))
    {
        return std::make_pair(m_mtpDevices.at(index)->devBus, m_mtpDevices.at(index)->devNum);
    }

    return std::make_pair(0, 0);
}

int Device::getMtpBatteryCount() const
{
    int batteries = 0;

    for (auto d: m_mtpDevices)
    {
        if (d && d->battery > 0.f)
            batteries++;
    }

    return batteries;
}

float Device::getMtpBatteryLevel(const int index) const
{
    float level = -1.f;

    if (index == 0)
    {
        int total = 0;
        for (auto d: m_mtpDevices)
        {
            if (d && d->battery > 0.f)
            {
                level += d->battery / 100.f;
                total++;
            }
        }
        if (total > 0)
            level /= static_cast<float>(total);
    }
    else if (index <= getMtpBatteryCount())
    {
        auto d = m_mtpDevices.at(index);
        if (d) level = d->battery / 100.f;
    }

    return level;
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::refreshBatteryInfos()
{
    //qDebug() << "refreshBatteryInfos()";

#ifdef ENABLE_LIBMTP
    for (auto d: qAsConst(m_mtpDevices))
    {
        if (d && d->device)
        {
            uint8_t maxbattlevel, currbattlevel;
            int ret = LIBMTP_Get_Batterylevel(d->device, &maxbattlevel, &currbattlevel);
            if (ret == 0 && maxbattlevel > 0)
            {
                d->battery = (static_cast<float>(currbattlevel) / static_cast<float>(maxbattlevel)) * 100.f;
                //qDebug() << "MTP Battery level:" << d->battery << "%";
                emit batteryUpdated();
            }
            else
            {
                // Silently ignore. Some devices does not support getting the battery level.
                LIBMTP_Clear_Errorstack(d->device);
            }
        }
    }
#endif // ENABLE_LIBMTP
}

void Device::refreshStorageInfos()
{
    //qDebug() << "refreshStorageInfos(" << m_storage->rootPath() << ")";

    for (auto storage: qAsConst(m_filesystemStorages))
    {
        if (storage &&
            storage->m_storage.isValid() && storage->m_storage.isReady())
        {
            storage->m_storage.refresh();

            // Check if writable and some space is available
            if (!storage->m_storage.isReadOnly() &&
                storage->m_storage.bytesAvailable() > 8*1024*1024)
            {
                //
            }
        }
    }

#ifdef ENABLE_LIBMTP
    for (auto storage: qAsConst(m_mtpStorages))
    {
        if (storage)
        {
            // TODO? or space related values kept up to date by the lib?
        }
    }
#endif // ENABLE_LIBMTP

    emit storageUpdated();
}

/* ************************************************************************** */
/* ************************************************************************** */

int Device::getStorageCount() const
{
    int count = m_filesystemStorages.size();

#ifdef ENABLE_LIBMTP
    count += m_mtpStorages.size();
#endif

    return count;
}

float Device::getStorageLevel(const int index)
{
    float level = 0;

    if (index == 0)
    {
        if (getSpaceTotal() > 0)
            level = static_cast<float>(getSpaceUsed()) / static_cast<float>(getSpaceTotal());
    }
    else
    {
        int64_t su = 0, sf = 0;
        int i = (index - 1);

        if (m_filesystemStorages.size() > i)
        {
            auto st = m_filesystemStorages.at(i);
            su += (st->m_storage.bytesTotal() - st->m_storage.bytesAvailable());
            sf += st->m_storage.bytesTotal();
        }
#ifdef ENABLE_LIBMTP
        else if (m_mtpStorages.size() > i)
        {
            auto st = m_mtpStorages.at(i);
            su += st->m_storage->MaxCapacity - st->m_storage->FreeSpaceInBytes;
            sf += st->m_storage->MaxCapacity;
        }
#endif // ENABLE_LIBMTP

        level = static_cast<float>(su) / static_cast<float>(sf);
    }

    return level;
}

bool Device::isReadOnly() const
{
    bool ro = false;

    for (auto st: m_filesystemStorages)
    {
        if (st)
            ro |= st->m_storage.isReadOnly();
    }

    return ro;
}

int64_t Device::getSpaceTotal()
{
    int64_t s = 0;

    for (auto st: qAsConst(m_filesystemStorages))
    {
        if (st)
            s += st->m_storage.bytesTotal();
    }
#ifdef ENABLE_LIBMTP
    for (auto st: qAsConst(m_mtpStorages))
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

    for (auto st: qAsConst(m_filesystemStorages))
    {
        if (st)
            s += (st->m_storage.bytesTotal() - st->m_storage.bytesAvailable());
    }
#ifdef ENABLE_LIBMTP
    for (auto st: qAsConst(m_mtpStorages))
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

    for (auto st: qAsConst(m_filesystemStorages))
    {
        if (st)
            s += st->m_storage.bytesAvailable();
    }
#ifdef ENABLE_LIBMTP
    for (auto st: qAsConst(m_mtpStorages))
    {
        if (st)
            s += st->m_storage->FreeSpaceInBytes;
    }
#endif // ENABLE_LIBMTP

    return s;
}

int64_t Device::getSpaceAvailable_withrefresh()
{
    refreshStorageInfos();
    return getSpaceAvailable();
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::offloadAll(const QString &path, const QVariant &values)
{
    //qDebug() << "offloadAll()";
    //qDebug() << "(a) shots count: " << m_shotModel->getShotCount();

    JobManager *jm = JobManager::getInstance();
    StorageManager *sm = StorageManager::getInstance();

    QList<Shot *> shots;
    m_shotModel->getShots(shots);

    // MediaDirectory
    MediaDirectory *md = nullptr;
    if (!path.isEmpty())
    {
        QString selectedPath = path;
        if (sm)
        {
            const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
            for (auto d: *mediaDirectories)
            {
                MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
                if (dd && dd->getPath() == selectedPath)
                {
                    md = dd;
                }
            }
        }
    }

    if (jm && !shots.empty())
    {
        //if (sm->getAutoMerge())
        //    jm->addJobs(JOB_MERGE, this, shots, md);
        //else
            jm->addJobs(JOB_COPY, this, nullptr, shots, md);
    }
}

void Device::deleteAll()
{
    //qDebug() << "deleteAll()";
    //qDebug() << "(a) shots count: " << m_shotModel->getShotCount();

    JobManager *jm = JobManager::getInstance();

    QList<Shot *> shots;
    m_shotModel->getShots(shots);

    if (jm && !shots.empty())
        jm->addJobs(JOB_DELETE, this, nullptr, shots);
}

/* ************************************************************************** */
/* ************************************************************************** */

QStringList Device::getSelectedShotsUuids(const QVariant &indexes)
{
    qDebug() << "Device::getSelectedShotsUuids(" << indexes << ")";
    QStringList selectedUuids;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedUuids += shot->getUuid();
        //qDebug() << "MediaLibrary::getSelectedShotsUuids(" <<  shot->getUuid();
    }

    return selectedUuids;
}

/* ************************************************************************** */

QStringList Device::getSelectedShotsNames(const QVariant &indexes)
{
    //qDebug() << "Device::getSelectedShotsNames(" << indexes << ")";
    QStringList selectedUuids;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedUuids += shot->getName();
        //qDebug() << "MediaLibrary::getSelectedShotsNames(" <<  shot->getUuid();
    }

    return selectedUuids;
}

/* ************************************************************************** */

QStringList Device::getSelectedFilesPaths(const QVariant &indexes)
{
    //qDebug() << "Device::getSelectedFilesPaths(" << indexes << ")";

    QStringList selectedPaths;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedPaths += shot->getFilesStringList();
        //qDebug() << "MediaLibrary::listSelected(" <<  shot->getFilesQStringList();
    }

    return selectedPaths;
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::offloadSelected(const QString &shot_uuid, const QVariant &values)
{
    qDebug() << "offloadCopySelected(" << shot_uuid << ")";

    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    if (jm && shot)
        jm->addJob(JOB_COPY, this, nullptr, shot);
}

void Device::offloadMergeSelected(const QString &shot_uuid)
{
    qDebug() << "offloadMergeSelected(" << shot_uuid << ")";

    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);
    if (jm && shot) jm->addJob(JOB_COPY, this, nullptr, shot);
}

void Device::reencodeSelected(const QString &shot_uuid, const QVariant &values)
{
    qDebug() << "Device::reencodeSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(values).toVariant();
    if (variant.type() != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Job settings
    JobEncodeSettings sett;

    if (variantMap.contains("codec"))
        sett.codec = variantMap.value("codec").toString();

    if (variantMap.contains("quality"))
        sett.encoding_quality = variantMap.value("quality").toInt();
    if (variantMap.contains("speed"))
        sett.encoding_speed = variantMap.value("speed").toInt();

    if (variantMap.contains("resolution"))
        sett.resolution = variantMap.value("resolution").toInt();

    if (variantMap.contains("scale"))
        sett.scale = variantMap.value("scale").toString();

    if (variantMap.contains("transform"))
        sett.transform = variantMap.value("transform").toInt();

    if (variantMap.contains("crop"))
        sett.crop = variantMap.value("crop").toString();

    if (variantMap.contains("fps"))
        sett.fps = variantMap.value("fps").toFloat();

    if (variantMap.contains("gif_effect"))
        sett.gif_effect = variantMap.value("gif_effect").toString();

    if (variantMap.contains("timelapse_fps"))
        sett.timelapse_fps = variantMap.value("timelapse_fps").toInt();

    if (variantMap.contains("defisheye"))
        sett.defisheye = variantMap.value("defisheye").toString();
    if (variantMap.contains("deshake"))
        sett.deshake = variantMap.value("deshake").toBool();

    if (variantMap.contains("screenshot"))
        sett.screenshot = variantMap.value("screenshot").toBool();

    if (variantMap.contains("clipStartMs"))
        sett.startMs = variantMap.value("clipStartMs").toInt();
    if (variantMap.contains("clipDurationMs"))
        sett.durationMs = variantMap.value("clipDurationMs").toInt();

    // MediaDirectory
    MediaDirectory *md = nullptr;
    if (variantMap.contains("path"))
    {
        QString selectedPath = variantMap.value("path").toString();
        StorageManager *sm = StorageManager::getInstance();
        if (sm)
        {
            const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
            for (auto d: *mediaDirectories)
            {
                MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
                if (dd && dd->getPath() == selectedPath)
                {
                    md = dd;
                }
            }
        }
    }

    // Job
    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);
    if (jm && shot) jm->addJob(JOB_REENCODE, this, nullptr, shot, md, &sett);
}

void Device::deleteSelected(const QString &shot_uuid)
{
    qDebug() << "Device::deleteSelected(" << shot_uuid << ")";

    JobManager *jm = JobManager::getInstance();
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);
    if (jm && shot) jm->addJob(JOB_DELETE, this, nullptr, shot);
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::deleteSelection(const QVariant &indexes)
{
    qDebug() << "deleteSelection(" << indexes << ")";

    QStringList selectedUuids = getSelectedShotsUuids(indexes);
    QList<Shot *> list;

    for (const auto &u: qAsConst(selectedUuids))
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JOB_DELETE, this, nullptr, list);
}

void Device::offloadCopySelection(const QVariant &indexes)
{
    qDebug() << "offloadCopySelection(" << indexes << ")";

    QStringList selectedUuids = getSelectedShotsUuids(indexes);
    QList<Shot *> list;

    for (const auto &u: qAsConst(selectedUuids))
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JOB_COPY, this, nullptr, list);
}

void Device::offloadMergeSelection(const QVariant &indexes)
{
    qDebug() << "offloadMergeSelection(" << indexes << ")";

    QStringList selectedUuids = getSelectedShotsUuids(indexes);
    QList<Shot *> list;

    for (const auto &u: qAsConst(selectedUuids))
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JOB_COPY, this, nullptr, list);
}

/* ************************************************************************** */
