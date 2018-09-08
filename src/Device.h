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

#ifndef DEVICE_H
#define DEVICE_H
/* ************************************************************************** */

#include "Shot.h"
#include "ShotModel.h"
#include "ShotFilter.h"

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

#include <QStorageInfo>
#include <QTimer>

/* ************************************************************************** */

typedef enum deviceType_e
{
    DEVICE_UNKNOWN = 0,

    DEVICE_COMPUTER,
    DEVICE_SMARTPHONE,
    DEVICE_CAMERA,
    DEVICE_ACTIONCAM,

} deviceType_e;

typedef enum deviceModel_e
{
    MODEL_UNKNOWN = 0,

    DEVICE_GOPRO = 128,
        DEVICE_HERO2,
        DEVICE_HERO3_WHITE,
        DEVICE_HERO3_SILVER,
        DEVICE_HERO3_BLACK,
        DEVICE_HERO3p_WHITE,
        DEVICE_HERO3p_SILVER,
        DEVICE_HERO3p_BLACK,
        DEVICE_HERO,
        DEVICE_HEROp,
        DEVICE_HEROpLCD,
        DEVICE_HERO4_SILVER,
        DEVICE_HERO4_BLACK,
        DEVICE_HERO4_SESSION,
        DEVICE_HERO5_SESSION,
        DEVICE_HERO5_WHITE,
        DEVICE_HERO5_BLACK,
        DEVICE_HERO6_BLACK,
        DEVICE_HERO7_WHITE,
        DEVICE_HERO7_SILVER,
        DEVICE_HERO7_BLACK,
        DEVICE_FUSION,

    DEVICE_SONY = 256,
        DEVICE_HDR_AS300R,
        DEVICE_FDR_X1000VR,
        DEVICE_FDR_X3000R,

    DEVICE_GARMIN = 270,
        DEVICE_VIRB_ELITE,
        DEVICE_VIRB_X,
        DEVICE_VIRB_XE,
        DEVICE_VIRB_ULTRA30,
        DEVICE_VIRB_360,

    DEVICE_OLYMPUS = 280,
        DEVICE_TG_TRACKER,

    DEVICE_CONTOUR = 290,
        DEVICE_CONTOUR_ROAM3,
        DEVICE_CONTOUR_ROAM1600,
        DEVICE_CONTOUR_4K,

    DEVICE_KODAK = 300,
        DEVICE_PIXPRO_SP1,
        DEVICE_PIXPRO_SPZ1,

    DEVICE_YI = 310,
        DEVICE_YI_DISCOVERY_4K,
        DEVICE_YI_LITE,
        DEVICE_YI_4K,
        DEVICE_YI_4Kp,

} deviceModel_e;

typedef enum deviceStorage_e
{
    STORAGE_FILESYSTEM = 0,
    STORAGE_VIRTUAL_FILESYSTEM = 1,
    STORAGE_MTP = 2,

} deviceStorage_e;

typedef enum deviceState_e
{
    DEVICE_STATE_IDLE = 0,
    DEVICE_STATE_SCANNING = 1,

} deviceState_e;

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
    QString brand = "unknown";
    QString model = "device";
    QString serial;
    QString firmware;

    QStringList paths;
    QList <StorageFilesystem *> storages;
};

struct ofb_vfs_device
{
    QString brand = "brand";
    QString model = "MODEL";
    QString serial;
    QString firmware;

    //std::pair<uint32_t, uint32_t> currentMtpDevice;
    uint32_t devBus = 0;
    uint32_t devNum = 0;

    QStringList paths;
    QList <StorageFilesystem *> storages;
};

struct ofb_mtp_device
{
    QString brand = "brand";
    QString model = "MODEL";
    QString serial;
    QString firmware;

    //std::pair<uint32_t, uint32_t> currentMtpDevice;
    uint32_t devBus = 0;
    uint32_t devNum = 0;

    double battery = 0.0;

    LIBMTP_mtpdevice_t *device = nullptr;

    QList <StorageMtp *> storages;
};

/* ************************************************************************** */

/*!
 * \brief The Device class
 */
class Device: public QObject
{
    Q_OBJECT

    Q_PROPERTY(int deviceState READ getDeviceState NOTIFY stateUpdated)
    Q_PROPERTY(int deviceType READ getDeviceType NOTIFY deviceUpdated)
    Q_PROPERTY(int deviceStorage READ getDeviceStorage NOTIFY deviceUpdated)
    Q_PROPERTY(int deviceModel READ getDeviceModel NOTIFY deviceUpdated)

    Q_PROPERTY(QString uniqueId READ getUniqueId NOTIFY deviceUpdated)

    Q_PROPERTY(QString brand READ getBrand NOTIFY deviceUpdated)
    Q_PROPERTY(QString model READ getModel NOTIFY deviceUpdated)
    Q_PROPERTY(QString serial READ getSerial NOTIFY deviceUpdated)
    Q_PROPERTY(QString firmware READ getFirmware NOTIFY deviceUpdated)

    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY spaceUpdated)
    Q_PROPERTY(double spaceUsedPercent READ getSpaceUsed_percent NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY spaceUpdated)

    Q_PROPERTY(ShotModel *shotModel READ getShotModel NOTIFY shotModelUpdated)
    Q_PROPERTY(ShotFilter *shotFilter READ getShotFilter NOTIFY shotModelUpdated)

    deviceType_e m_deviceType = DEVICE_UNKNOWN;
    deviceModel_e m_deviceModel = MODEL_UNKNOWN;
    deviceStorage_e m_deviceStorage = STORAGE_FILESYSTEM;
    deviceState_e m_deviceState = DEVICE_STATE_IDLE;

    // Generic infos
    QString m_brand = "brand";
    QString m_model = "MODEL";
    QString m_serial;
    QString m_firmware;

    // HW infos
    LIBMTP_mtpdevice_t *m_mtpDevice = nullptr;
    uint32_t m_devBus = 0;
    uint32_t m_devNum = 0;
    double m_mtpBattery = 0.0;

    // Storage(s)
    QTimer m_updateStorageTimer;
    QList <StorageFilesystem *> m_filesystemStorages;
    QList <StorageMtp *> m_mtpStorages;

    // Shot(s)
    ShotModel *m_shotModel = nullptr;
    ShotFilter *m_shotFilter = nullptr;
    Shot *findShot(Shared::ShotType type, int file_id, int camera_id) const;

private slots:
    void refreshBatteryInfos();
    void refreshStorageInfos();

Q_SIGNALS:
    void deviceUpdated();
    void shotModelUpdated();
    void shotsUpdated();
    void stateUpdated();
    void spaceUpdated();

public:
    Device(const deviceType_e type, const deviceStorage_e storage,
           const QString &brand, const QString &model,
           const QString &serial, const QString &version);
    ~Device();

    bool isValid();

    bool addStorage_filesystem(const QString &path);
    bool addStorage_mtp(LIBMTP_mtpdevice_t *m_mtpDevice);

    bool addStorages_filesystem(ofb_fs_device *device);
    bool addStorages_mtp(ofb_mtp_device *device);

    void setMtpInfos(LIBMTP_mtpdevice_t *device, double battery,
                     uint32_t devBus, uint32_t devNum);

public slots:
    //
    int getDeviceState() const { return m_deviceState; }
    int getDeviceModel() const { return m_deviceModel; }
    int getDeviceType() const { return m_deviceType; }
    int getDeviceStorage() const { return m_deviceStorage; }
    QString getBrand() const { return m_brand; }
    QString getModel() const { return m_model; }
    QString getSerial() const { return m_serial; }
    QString getFirmware() const { return m_firmware; }

    QString getUniqueId() const;

    //
    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    double getSpaceUsed_percent();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();

    //
    QString getPath(const int index = 0) const;
    void getMtpIds(unsigned &devBus, unsigned &devNum) const;
    std::pair<unsigned, unsigned> getMtpIds() const;

    //
    void orderByDate();
    void orderByDuration();
    void orderByShotType();
    void orderByName();

    //
    void offloadCopyAll();
    void offloadMergeAll();
    void deleteAll();

    void offloadCopySelected(const QString shot_name);
    void offloadMergeSelected(const QString shot_name);
    void reencodeSelected(const QString shot_name);
    void deleteSelected(const QString shot_name);

    //
    void addShot(Shot *shot);
    void deleteShot(Shot *shot);

    void workerScanningStarted(QString s);
    void workerScanningFinished(QString s);

    //
    ShotModel *getShotModel() const { return m_shotModel; }
    ShotFilter *getShotFilter() const { return m_shotFilter; }
    //QVariant getShot(const int index) const { return QVariant::fromValue(m_shotModel->getShotAt(index)); }
    QVariant getShot(const QString name) const { return QVariant::fromValue(m_shotModel->getShotAt(name)); }
};

/* ************************************************************************** */
#endif // DEVICE_H
