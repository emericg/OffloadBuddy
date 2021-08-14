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

#ifndef DEVICE_H
#define DEVICE_H
/* ************************************************************************** */

#include "DeviceUtils.h"
#include "ShotProvider.h"
#include "MediaStorage.h"
#include "Job.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#else
typedef void LIBMTP_mtpdevice_t;
typedef void LIBMTP_devicestorage_t;
#endif // ENABLE_LIBMTP

#include <QObject>
#include <QVariant>
#include <QList>
#include <QStringList>
#include <QTimer>
#include <QStorageInfo>

/* ************************************************************************** */

/*!
 * \brief The Device class
 *
 * A device object represent a physicaly connected MTP device like a camera or
 * a connected SD card from such a device.
 */
class Device: public ShotProvider
{
    Q_OBJECT

    Q_PROPERTY(int deviceState READ getDeviceState NOTIFY stateUpdated)
    Q_PROPERTY(int deviceType READ getDeviceType NOTIFY deviceUpdated)
    Q_PROPERTY(int deviceStorage READ getDeviceStorage NOTIFY deviceUpdated)
    Q_PROPERTY(int deviceModel READ getDeviceModel NOTIFY deviceUpdated)

    Q_PROPERTY(QString uuid READ getUuid NOTIFY deviceUpdated)

    Q_PROPERTY(QString brand READ getBrand NOTIFY deviceUpdated)
    Q_PROPERTY(QString model READ getModel NOTIFY deviceUpdated)
    Q_PROPERTY(QString serial READ getSerial NOTIFY deviceUpdated)
    Q_PROPERTY(QString firmware READ getFirmware NOTIFY deviceUpdated)

    Q_PROPERTY(float batteryLevel READ getMtpBatteryLevel NOTIFY batteryUpdated)
    Q_PROPERTY(float storageLevel READ getStorageLevel NOTIFY storageUpdated)

    Q_PROPERTY(uint storageCount READ getStoragesCount NOTIFY storageUpdated)
    Q_PROPERTY(QVariant storageList READ getStorages NOTIFY storageUpdated)

    Q_PROPERTY(bool readOnly READ isReadOnly NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY storageUpdated)

    Q_PROPERTY(int jobsCount READ getJobsCount NOTIFY jobsUpdated)
    Q_PROPERTY(QVariant jobsList READ getJobs NOTIFY jobsUpdated)

    deviceType_e m_deviceType = DEVICE_UNKNOWN;
    deviceModel_e m_deviceModel = MODEL_UNKNOWN;
    deviceStorage_e m_deviceStorage = STORAGE_FILESYSTEM;
    deviceState_e m_deviceState = DEVICE_STATE_IDLE;

    QString m_uuid;             //!< Device unique identifier, generated at object creation

    // Generic infos
    QString m_brand = "Unknown";//!< Device brand
    QString m_model = "device"; //!< Device model
    QString m_stringId;         //!< A backup string that describe the device in case neither brand/model can be identified
    QString m_serial;
    QString m_firmware;

    // MTP infos
    QList <ofb_mtp_device *> m_mtpDevices;
    QTimer m_updateBatteryTimer;

    // Storage(s)
    QList <QObject *> m_mediaStorages;

    // Jobs
    QList <QObject *> m_trackedJobs;

Q_SIGNALS:
    void deviceUpdated();
    void stateUpdated();
    void batteryUpdated();
    void storageUpdated();
    void jobsUpdated();

private slots:
    void refreshBatteryInfos();
    void refreshStorageInfos();

public slots:
    void workerScanningStarted(const QString &path);
    void workerScanningFinished(const QString &path);

public:
    Device(const deviceType_e type, const deviceStorage_e storage,
           const QString &brand, const QString &model,
           const QString &serial, const QString &version);
    ~Device();

    bool isValid();

    void setName(const QString &name);
    QString getUuid() const { return m_uuid; }

    //
    int getDeviceState() const { return m_deviceState; }
    int getDeviceModel() const { return m_deviceModel; }
    int getDeviceType() const { return m_deviceType; }
    int getDeviceStorage() const { return m_deviceStorage; }
    QString getBrand() const { return m_brand; }
    QString getModel() const { return m_model; }
    QString getSerial() const { return m_serial; }
    QString getFirmware() const { return m_firmware; }

    // Storage
    QVariant getStorages() const { if (m_mediaStorages.size() > 0) { return QVariant::fromValue(m_mediaStorages); } return QVariant(); }
    unsigned getStoragesCount() const { return m_mediaStorages.size(); }
    const QList <QObject *> *getDirectoriesList() const { return &m_mediaStorages; }

    bool addStorage_filesystem(const QString &path);
    bool addStorage_mtp(LIBMTP_mtpdevice_t *m_mtpDevice); // TODO

    bool addStorages_filesystem(ofb_fs_device *device); // TODO
    bool addStorages_mtp(ofb_mtp_device *device);

    Q_INVOKABLE int getStorageCount() const;
    Q_INVOKABLE float getStorageLevel(const int index = 0);

    bool isReadOnly() const;
    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();

    // FS specifics
    QString getPath(const int index = 0) const;
    QStringList getPathList() const;

    // MTP specifics
    int getMtpDeviceCount() const;
    void getMtpIds(unsigned &devBus, unsigned &devNum, const int index = 0) const;
    std::pair<unsigned, unsigned> getMtpIds(const int index = 0) const;

    int getMtpBatteryCount() const;
    float getMtpBatteryLevel(const int index = 0) const;

    // Get UUIDs/names/paths from grid indexes
    Q_INVOKABLE QStringList getSelectedShotsUuids(const QVariant &indexes);
    Q_INVOKABLE QStringList getSelectedShotsNames(const QVariant &indexes);
    Q_INVOKABLE QStringList getSelectedShotsFilepaths(const QVariant &indexes);

    // Submit jobs
    Q_INVOKABLE void offloadSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void offloadSelection(const QVariant &uuids, const QVariant &settings);
    Q_INVOKABLE void offloadAll(const QVariant &settings);

    Q_INVOKABLE void deleteSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void deleteSelection(const QVariant &uuids, const QVariant &settings);
    Q_INVOKABLE void deleteAll(const QVariant &settings);

    Q_INVOKABLE void reencodeSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void reencodeSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void extractTelemetrySelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void extractTelemetrySelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void firmwareUpdate();

    // Track jobs
    void addJob(JobTracker *j);
    void removeJob(JobTracker *j);
    int getJobsCount() const { return m_trackedJobs.size(); }
    QVariant getJobs() const;
};

/* ************************************************************************** */
#endif // DEVICE_H
