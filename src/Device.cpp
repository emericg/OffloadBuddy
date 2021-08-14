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
#include "SettingsManager.h"

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

    if (m_deviceStorage == STORAGE_MTP)
    {
        connect(&m_updateBatteryTimer, &QTimer::timeout, this, &Device::refreshBatteryInfos);
        m_updateBatteryTimer.setInterval(60 * 1000);
        m_updateBatteryTimer.start();
    }

    if (m_shotFilter)
    {
        SettingsManager *st = SettingsManager::getInstance();
        int sortRoleSettings = st->getDeviceSortRole();
        int sortRole = ShotModel::DateRole;

        switch (sortRoleSettings)
        {
            case SettingsUtils::OrderByCamera:
                sortRole = ShotModel::CameraRole;
                break;
            case SettingsUtils::OrderByGps:
                sortRole = ShotModel::GpsRole;
                break;
            case SettingsUtils::OrderBySize:
                sortRole = ShotModel::SizeRole;
                break;
            case SettingsUtils::OrderByFilePath:
                sortRole = ShotModel::PathRole;
                break;
            case SettingsUtils::OrderByName:
                sortRole = ShotModel::NameRole;
                break;
            case SettingsUtils::OrderByShotType:
                sortRole = ShotModel::ShotTypeRole;
                break;
            case SettingsUtils::OrderByDuration:
                sortRole = ShotModel::DurationRole;
                break;
            default:
            case SettingsUtils::OrderByDate:
                sortRole = ShotModel::DateRole;
                break;
        }

        m_sortOrder = (Qt::SortOrder)st->getDeviceSortOrder();
        m_shotFilter->setSortRole(sortRole);
        m_shotFilter->sort(0, m_sortOrder);
    }
}

Device::~Device()
{
    qDeleteAll(m_mediaStorages);
    m_mediaStorages.clear();

#ifdef ENABLE_LIBMTP
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

    if (m_mediaStorages.empty())
        status = false;

    return status;
}

/* ************************************************************************** */
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
        MediaStorage *storage = new MediaStorage(device->device, st->m_storage, false, this);
        if (storage)
        {
            m_mediaStorages.push_back(storage);
            status = true;

            emit storageUpdated();
        }

        // Start initial scan
        QThread *thread = new QThread();
        FileScanner *fs = new FileScanner();

        if (thread && fs)
        {
            fs->chooseMtpStorage(st);
            fs->moveToThread(thread);

            connect(thread, SIGNAL(started()), fs, SLOT(scanMtpDevice()));
            connect(fs, SIGNAL(fileFound(ofb_file*,ofb_shot*)), m_shotModel, SLOT(addFile(ofb_file*,ofb_shot*)));
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
        MediaStorage *storage = new MediaStorage(path, false, this);
        if (storage)
        {
            m_mediaStorages.push_back(storage);
            status = true;

            emit storageUpdated();
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
            connect(fs, SIGNAL(fileFound(ofb_file*,ofb_shot*)), m_shotModel, SLOT(addFile(ofb_file*,ofb_shot*)));
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
/*
    // Update sort
    // This may still be needed for things like timelapses, where Shots are
    // not yet complete when they are added to the ShotModel
    if (m_shotFilter)
    {
        m_shotFilter->sort(0, m_sortOrder);
        m_shotFilter->invalidate();
    }
*/
    m_deviceState = DEVICE_STATE_IDLE;
    emit stateUpdated();
}

/* ************************************************************************** */
/* ************************************************************************** */

QString Device::getPath(const int index) const
{
    if (index >= 0)
    {
        if (m_mediaStorages.size() > index)
        {
            return static_cast<MediaStorage *>(m_mediaStorages.at(index))->getDevicePath();
        }
    }

    return QString();
}

QStringList Device::getPathList() const
{
    QStringList paths;

    for (auto st: m_mediaStorages)
    {
        if (st)
        {
            paths += static_cast<MediaStorage *>(st)->getDevicePath();
        }
    }

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

    for (auto st: qAsConst(m_mediaStorages))
    {
        if (st)
        {
            static_cast<MediaStorage *>(st)->refreshMediaStorage();
        }
    }

    emit storageUpdated();
}

/* ************************************************************************** */
/* ************************************************************************** */

int Device::getStorageCount() const
{
    return m_mediaStorages.count();
}

float Device::getStorageLevel(const int index)
{
    float level = 0;

    {
        int64_t su = 0, st = 0;

        if (m_mediaStorages.size() > index)
        {
            su += static_cast<MediaStorage *>(m_mediaStorages.at(index))->getSpaceUsed();
            st += static_cast<MediaStorage *>(m_mediaStorages.at(index))->getSpaceTotal();
        }

        level = static_cast<float>(su) / static_cast<float>(st);
    }

    return level;
}

bool Device::isReadOnly() const
{
    bool ro = false;
    for (auto st: qAsConst(m_mediaStorages))
    {
        if (st)
        {
            ro |= static_cast<MediaStorage *>(st)->isReadOnly();
        }
    }

    return ro;
}

int64_t Device::getSpaceTotal()
{
    int64_t s = 0;

    for (auto st: qAsConst(m_mediaStorages))
    {
        if (st)
        {
            s += static_cast<MediaStorage *>(st)->getSpaceTotal();
        }
    }

    return s;
}

int64_t Device::getSpaceUsed()
{
    int64_t s = 0;

    for (auto st: qAsConst(m_mediaStorages))
    {
        if (st)
        {
            s += static_cast<MediaStorage *>(st)->getSpaceUsed();
        }
    }

    return s;
}

int64_t Device::getSpaceAvailable()
{
    int64_t s = 0;

    for (auto st: qAsConst(m_mediaStorages))
    {
        if (st)
        {
            s += static_cast<MediaStorage *>(st)->getSpaceAvailable();
        }
    }

    return s;
}

int64_t Device::getSpaceAvailable_withrefresh()
{
    int64_t s = 0;

    for (auto st: qAsConst(m_mediaStorages))
    {
        if (st)
        {
            static_cast<MediaStorage *>(st)->refreshMediaStorage();
            s += static_cast<MediaStorage *>(st)->getSpaceAvailable();
        }
    }

    return s;
}

/* ************************************************************************** */
/* ************************************************************************** */

QStringList Device::getSelectedShotsUuids(const QVariant &indexes)
{
    //qDebug() << "Device::getSelectedShotsUuids(" << indexes << ")";
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
    QStringList selectedNames;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedNames += shot->getName();
        //qDebug() << "MediaLibrary::getSelectedShotsNames(" <<  shot->getUuid();
    }

    return selectedNames;
}

/* ************************************************************************** */

QStringList Device::getSelectedShotsFilepaths(const QVariant &indexes)
{
    //qDebug() << "Device::getSelectedShotsFilepaths(" << indexes << ")";
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

void Device::offloadSelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "Device::offloadCopySelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shot
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsOffload set;
    {
        if (variantMap.contains("ignoreJunk"))
            set.ignoreJunk = variantMap.value("ignoreJunk").toBool();

        if (variantMap.contains("ignoreAudio"))
            set.ignoreAudio = variantMap.value("ignoreAudio").toBool();

        if (variantMap.contains("extractTelemetry"))
            set.extractTelemetry = variantMap.value("extractTelemetry").toBool();

        if (variantMap.contains("mergeChapters"))
            set.mergeChapters = variantMap.value("mergeChapters").toBool();

        if (variantMap.contains("autoDelete"))
            set.autoDelete = variantMap.value("autoDelete").toBool();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (set.mergeChapters && shot->getChapterCount() > 1)
    {
        if (jm && shot) jm->addJob(JobUtils::JOB_MERGE, this, nullptr, shot,
                                   &dst, nullptr, &set);
    }
    else
    {
        if (jm && shot) jm->addJob(JobUtils::JOB_OFFLOAD, this, nullptr, shot,
                                   &dst, nullptr, &set);
    }
}

/* ************************************************************************** */

void Device::offloadSelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "Device::offloadSelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsOffload set;
    {
        if (variantMap.contains("ignoreJunk"))
            set.ignoreJunk = variantMap.value("ignoreJunk").toBool();

        if (variantMap.contains("ignoreAudio"))
            set.ignoreAudio = variantMap.value("ignoreAudio").toBool();

        if (variantMap.contains("extractTelemetry"))
            set.extractTelemetry = variantMap.value("extractTelemetry").toBool();

        if (variantMap.contains("mergeChapters"))
            set.mergeChapters = variantMap.value("mergeChapters").toBool();

        if (variantMap.contains("autoDelete"))
            set.autoDelete = variantMap.value("autoDelete").toBool();
    }

    // Get shots
    QList <Shot *> list_merge;
    QList <Shot *> list_offload;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        Shot *s = m_shotModel->getShotWithUuid(u);
        if (set.mergeChapters && s->getChapterCount() > 1)
        {
            list_merge.push_back(s);
        }
        else
        {
            list_offload.push_back(s);
        }
    }


    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm)
    {
        if (!list_merge.empty())
        {
            jm->addJobs(JobUtils::JOB_MERGE, this, nullptr, list_merge,
                        &dst, nullptr, &set);
        }
        if (!list_offload.empty())
        {
            jm->addJobs(JobUtils::JOB_OFFLOAD, this, nullptr, list_offload,
                        &dst, nullptr, &set);
        }
    }
}

/* ************************************************************************** */

void Device::offloadAll(const QVariant &settings)
{
    qDebug() << "Device::offloadAll()";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsOffload set;
    {
        if (variantMap.contains("ignoreJunk"))
            set.ignoreJunk = variantMap.value("ignoreJunk").toBool();

        if (variantMap.contains("ignoreAudio"))
            set.ignoreAudio = variantMap.value("ignoreAudio").toBool();

        if (variantMap.contains("extractTelemetry"))
            set.extractTelemetry = variantMap.value("extractTelemetry").toBool();

        if (variantMap.contains("mergeChapters"))
            set.mergeChapters = variantMap.value("mergeChapters").toBool();

        if (variantMap.contains("autoDelete"))
            set.autoDelete = variantMap.value("autoDelete").toBool();
    }

    // Get shots
    QList <Shot *> shots;
    m_shotModel->getShots(shots);

    QList <Shot *> list_merge;
    QList <Shot *> list_offload;
    for (const auto &s: qAsConst(shots))
    {
        if (set.mergeChapters && s->getChapterCount() > 1)
        {
            list_merge.push_back(s);
        }
        else
        {
            list_offload.push_back(s);
        }
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm)
    {
        if (!list_merge.empty())
        {
            jm->addJobs(JobUtils::JOB_MERGE, this, nullptr, list_merge,
                        &dst, nullptr, &set);
        }
        if (!list_offload.empty())
        {
            jm->addJobs(JobUtils::JOB_OFFLOAD, this, nullptr, list_offload,
                        &dst, nullptr, &set);
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::deleteSelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "Device::deleteSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shot
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get settings
    JobSettingsDelete set;
    {
        if (variantMap.contains("moveToTrash"))
            set.moveToTrash = variantMap.value("moveToTrash").toBool();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_DELETE, this, nullptr, shot,
                               nullptr, &set, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */

void Device::deleteSelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "Device::deleteSelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> list;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    // Get settings
    JobSettingsDelete set;
    {
        if (variantMap.contains("moveToTrash"))
            set.moveToTrash = variantMap.value("moveToTrash").toBool();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JobUtils::JOB_DELETE, this, nullptr, list,
                                         nullptr, &set, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */

void Device::deleteAll(const QVariant &settings)
{
    qDebug() << "Device::deleteAll()";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> shots;
    m_shotModel->getShots(shots);

    // Get settings
    JobSettingsDelete set;
    {
        if (variantMap.contains("moveToTrash"))
            set.moveToTrash = variantMap.value("moveToTrash").toBool();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !shots.empty()) jm->addJobs(JobUtils::JOB_DELETE, this, nullptr, shots,
                                          nullptr, &set, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::reencodeSelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "Device::reencodeSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsEncode set;
    {
        if (variantMap.contains("mode"))
            set.mode = variantMap.value("mode").toString();

        if (variantMap.contains("video_codec"))
            set.video_codec = variantMap.value("video_codec").toString();
        if (variantMap.contains("image_codec"))
            set.image_codec = variantMap.value("image_codec").toString();

        if (variantMap.contains("quality"))
            set.encoding_quality = variantMap.value("quality").toInt();
        if (variantMap.contains("speed"))
            set.encoding_speed = variantMap.value("speed").toInt();

        if (variantMap.contains("resolution"))
            set.resolution = variantMap.value("resolution").toInt();

        if (variantMap.contains("scale"))
            set.scale = variantMap.value("scale").toString();

        if (variantMap.contains("transform"))
            set.transform = variantMap.value("transform").toInt();

        if (variantMap.contains("crop"))
            set.crop = variantMap.value("crop").toString();

        if (variantMap.contains("fps"))
            set.fps = variantMap.value("fps").toFloat();

        if (variantMap.contains("gif_effect"))
            set.gif_effect = variantMap.value("gif_effect").toString();

        if (variantMap.contains("timelapse_fps"))
            set.timelapse_fps = variantMap.value("timelapse_fps").toInt();

        if (variantMap.contains("defisheye"))
            set.defisheye = variantMap.value("defisheye").toString();
        if (variantMap.contains("deshake"))
            set.deshake = variantMap.value("deshake").toBool();

        if (variantMap.contains("clipStartMs"))
            set.startMs = variantMap.value("clipStartMs").toInt();
        if (variantMap.contains("clipDurationMs"))
            set.durationMs = variantMap.value("clipDurationMs").toInt();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_ENCODE, this, nullptr, shot,
                               &dst, nullptr, nullptr, nullptr, &set);
}

/* ************************************************************************** */

void Device::reencodeSelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "Device::reencodeSelection(" << uuids << ")";

    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        reencodeSelected(u, settings);
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::extractTelemetrySelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "Device::extractTelemetrySelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shot
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsTelemetry set;
    {
        if (variantMap.contains("telemetry_format"))
            set.telemetry_format = variantMap.value("telemetry_format").toString();

        if (variantMap.contains("telemetry_frequency"))
            set.telemetry_frequency = variantMap.value("telemetry_frequency").toInt();

        if (variantMap.contains("gps_format"))
            set.gps_format = variantMap.value("gps_format").toString();

        if (variantMap.contains("gps_frequency"))
            set.gps_frequency = variantMap.value("gps_frequency").toInt();

        if (variantMap.contains("egm96_correction"))
            set.EGM96 = variantMap.value("egm96_correction").toBool();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_TELEMETRY, this, nullptr, shot,
                               &dst, nullptr, nullptr, &set, nullptr);
}

void Device::extractTelemetrySelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "Device::extractTelemetrySelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> list;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsTelemetry set;
    {
        if (variantMap.contains("telemetry_format"))
            set.telemetry_format = variantMap.value("telemetry_format").toString();

        if (variantMap.contains("telemetry_frequency"))
            set.telemetry_frequency = variantMap.value("telemetry_frequency").toInt();

        if (variantMap.contains("gps_format"))
            set.gps_format = variantMap.value("gps_format").toString();

        if (variantMap.contains("gps_frequency"))
            set.gps_frequency = variantMap.value("gps_frequency").toInt();

        if (variantMap.contains("egm96_correction"))
            set.EGM96 = variantMap.value("egm96_correction").toBool();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JobUtils::JOB_TELEMETRY, this, nullptr, list,
                                         &dst, nullptr, nullptr, &set, nullptr);
}

/* ************************************************************************** */
/* ************************************************************************** */

void Device::firmwareUpdate()
{
    qDebug() << "Device::firmwareUpdate(" << m_uuid << ")";

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm) jm->addJob(JobUtils::JOB_FIRMWARE_UPDATE, this, nullptr, nullptr);
}

/* ************************************************************************** */
/* ************************************************************************** */

// Track jobs
void Device::addJob(JobTracker *j)
{
    if (j)
    {
        if (j->getType() == JobUtils::JOB_OFFLOAD || j->getType() == JobUtils::JOB_ENCODE)
        {
            m_trackedJobs.push_back(j);
            Q_EMIT jobsUpdated();
        }
    }
}

void Device::removeJob(JobTracker *j)
{
    m_trackedJobs.removeOne(j);
    Q_EMIT jobsUpdated();
}

QVariant Device::getJobs() const
{
    if (m_trackedJobs.size() > 0)
    {
        return QVariant::fromValue(m_trackedJobs);
    }

    return QVariant();
}

/* ************************************************************************** */
/* ************************************************************************** */
