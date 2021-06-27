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

#include "ShotProvider.h"
#include "utils/utils_enums.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#ifndef LIBMTP_FILES_AND_FOLDERS_ROOT
// Hack for older versions of libmtp (<=1.10?)
#define LIBMTP_FILES_AND_FOLDERS_ROOT 0xffffffff
#endif
#else
typedef void LIBMTP_mtpdevice_t;
typedef void LIBMTP_devicestorage_t;
#endif // ENABLE_LIBMTP

#include <QObject>
#include <QVariant>
#include <QList>
#include <QStringList>

#include <QStorageInfo>
#include <QTimer>

/* ************************************************************************** */

typedef struct generic_device_infos
{
    deviceType_e device_type;
    QString device_brand;
    QString device_model;

} generic_device_infos;

typedef struct gopro_device_infos
{
    deviceStorage_e device_type;

    // Fields from version.txt "info_version 1.0"
    QString camera_type;            // ex: "HERO6 Black", "FUSION", "Hero3-Black Edition", "HD2"
    QString firmware_version;       // ex: "HD6.01.02.01.00"

    // Fields from version.txt "info_version 1.1"
    QString wifi_mac;               // ex: "0441693db024"
    QString wifi_version;           // ex: "3.4.2.9"
    QString wifi_bootloader_version;// ex: "0.2.2"

    // Fields from version.txt "info_version 2.0"
    QString camera_serial_number;   // ex: "C3221324521518"

} gopro_device_infos;

/* ************************************************************************** */

class StorageFilesystem
{
public:
    QString m_path;
    QStorageInfo m_storage;
    bool m_writable = false;
};

class StorageMtp
{
public:
    unsigned m_dcim_id = 0;
    LIBMTP_mtpdevice_t *m_device = nullptr;
    LIBMTP_devicestorage_t *m_storage = nullptr;
    bool m_writable = false;
};

/* ************************************************************************** */

struct ofb_fs_device
{
    QString brand = "Unknown";
    QString model = "device";
    QString stringId;
    QString serial;
    QString firmware;

    QStringList paths;
    QList <StorageFilesystem *> storages;
};

struct ofb_vfs_device
{
    QString brand = "Unknown";
    QString model = "device";
    QString stringId;
    QString serial;
    QString firmware;

    uint32_t devBus = 0;
    uint32_t devNum = 0;

    QStringList paths;
    QList <StorageFilesystem *> storages;
};

struct ofb_mtp_device
{
    QString brand = "Unknown";
    QString model = "device";
    QString stringId;
    QString serial;
    QString firmware;

    uint32_t devBus = 0;
    uint32_t devNum = 0;

    float battery = 0.0;

    LIBMTP_mtpdevice_t *device = nullptr;

    QList <StorageMtp *> storages;
};

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

    Q_PROPERTY(bool readOnly READ isReadOnly NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY storageUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY storageUpdated)

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
    QTimer m_updateStorageTimer;
    QList <StorageFilesystem *> m_filesystemStorages;
    QList <StorageMtp *> m_mtpStorages;

Q_SIGNALS:
    void deviceUpdated();
    void stateUpdated();
    void batteryUpdated();
    void storageUpdated();

private slots:
    void refreshBatteryInfos();
    void refreshStorageInfos();

public slots:
    //
    void workerScanningStarted(const QString &path);
    void workerScanningFinished(const QString &path);

public:
    Device(const deviceType_e type, const deviceStorage_e storage,
           const QString &brand, const QString &model,
           const QString &serial, const QString &version);
    ~Device();

    void setName(const QString &name);
    bool isValid();

    bool addStorage_filesystem(const QString &path);
    bool addStorage_mtp(LIBMTP_mtpdevice_t *m_mtpDevice); // TODO

    bool addStorages_filesystem(ofb_fs_device *device); // TODO
    bool addStorages_mtp(ofb_mtp_device *device);

    //
    int getDeviceState() const { return m_deviceState; }
    int getDeviceModel() const { return m_deviceModel; }
    int getDeviceType() const { return m_deviceType; }
    int getDeviceStorage() const { return m_deviceStorage; }
    QString getBrand() const { return m_brand; }
    QString getModel() const { return m_model; }
    QString getSerial() const { return m_serial; }
    QString getFirmware() const { return m_firmware; }

    QString getUuid() const { return m_uuid; }

    //
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

    // Get uuids/names/paths from grid indexes
    Q_INVOKABLE QStringList getSelectedShotsUuids(const QVariant &indexes);
    Q_INVOKABLE QStringList getSelectedShotsNames(const QVariant &indexes);
    Q_INVOKABLE QStringList getSelectedFilesPaths(const QVariant &indexes);

    // Submit jobs
    Q_INVOKABLE void offloadAll(const QVariant &settings);
    Q_INVOKABLE void offloadSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void offloadSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void deleteAll(const QVariant &settings);
    Q_INVOKABLE void deleteSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void deleteSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void moveSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void moveSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void reencodeSelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void reencodeSelection(const QVariant &uuids, const QVariant &settings);

    Q_INVOKABLE void extractTelemetrySelected(const QString &shot_uuid, const QVariant &settings);
    Q_INVOKABLE void extractTelemetrySelection(const QVariant &uuids, const QVariant &settings);
};

/* ************************************************************************** */
#endif // DEVICE_H
