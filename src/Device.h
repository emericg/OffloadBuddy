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

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#else
typedef void LIBMTP_mtpdevice_t;
typedef void LIBMTP_devicestorage_t;
#endif

#include <QObject>
#include <QVariant>
#include <QList>

#include <QStorageInfo>
#include <QTimer>

/* ************************************************************************** */

typedef struct gopro_info_version
{
    //QString info_version;         // "1.0",
    QString camera_type;            // ex: "HERO6 Black", "FUSION", "Hero3-Black Edition", "HD2"
    QString firmware_version;       // ex: "HD6.01.02.01.00"

    //QString info_version;         // "1.1",
    QString wifi_mac;               // ex: "0441693db024"
    QString wifi_version;           // ex: "3.4.2.9"
    QString wifi_bootloader_version;// ex: "0.2.2"

    //QString info_version;         // "2.0",
    QString camera_serial_number;   // ex: "C3221324521518"

} gopro_info_version;

typedef enum deviceModel_e
{
    DEVICE_UNKNOWN = 0,

    DEVICE_COMPUTER = 1,
    DEVICE_CAMERA   = 2,
    DEVICE_PHONE    = 3,

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

    DEVICE_YI = 300,
        DEVICE_YI_DISCOVERY_4K,
        DEVICE_YI_LITE,
        DEVICE_YI_4K,
        DEVICE_YI_4Kp,

} deviceModel_e;

typedef enum deviceType_e
{
    DEVICE_FILESYSTEM = 0,
    //DEVICE_VIRTUAL_FILESYSTEM = ?,
    DEVICE_MTP = 1,

} deviceType_e;

typedef enum deviceState_e
{
    DEVICE_STATE_IDLE = 0,
    DEVICE_STATE_SCANNING = 1,
    //DEVICE_STATE_JobInProgress = ?,

} deviceState_e;

/* ************************************************************************** */

class StorageFilesystem
{
public:
    QString m_path;
    // QStrin gm_dcim_path?
    QStorageInfo m_storage;
    bool m_writable = false;
};

class StorageMtp
{
public:
    unsigned m_dcim_id = 0;
    LIBMTP_mtpdevice_t *m_device = nullptr;
    LIBMTP_devicestorage_t *m_storage;
    bool m_writable = false;
};

/*!
 * \brief The Device class
 */
class Device: public QObject
{
    Q_OBJECT
    Q_PROPERTY(int deviceModel READ getDeviceModel NOTIFY deviceUpdated)
    Q_PROPERTY(int deviceType READ getDeviceType NOTIFY deviceUpdated)

    Q_PROPERTY(QString brand READ getBrand NOTIFY deviceUpdated)
    Q_PROPERTY(QString model READ getModel NOTIFY deviceUpdated)
    Q_PROPERTY(QString serial READ getSerial NOTIFY deviceUpdated)
    Q_PROPERTY(QString firmware READ getFirmware NOTIFY deviceUpdated)

    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY spaceUpdated)
    Q_PROPERTY(double spaceUsedPercent READ getSpaceUsed_percent NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY spaceUpdated)

    Q_PROPERTY(ShotModel* shotModel READ getShotModel NOTIFY shotsUpdated)

    deviceModel_e m_deviceModel = DEVICE_UNKNOWN;
    deviceType_e m_deviceType = DEVICE_FILESYSTEM;
    deviceState_e m_deviceState = DEVICE_STATE_IDLE;

    // Generic infos
    QString m_brand = "GoPro";
    QString m_model = "HERO?";
    QString m_serial;
    QString m_firmware;

    // HW infos
    double m_battery = 0.0;

    // Storage(s)
    QTimer m_updateTimer;

    QList <StorageFilesystem *> m_filesystemStorages;
    //QList <LIBMTP_devicestorage_t *> m_mtpStorages;
    QList <StorageMtp *> m_mtpStorages;
    LIBMTP_mtpdevice_t *m_mtpDevice = nullptr;

    // Shot(s)
    ShotModel *m_shotModel = nullptr;
    Shot *findShot(Shared::ShotType type, int file_id, int camera_id) const;

private slots:
    void refreshDevice();

Q_SIGNALS:
    void scanningStarted();
    void scanningFinished();
    void deviceUpdated();
    void shotsUpdated();
    void spaceUpdated();

public:
    Device(const QString &brand, const QString &model,
           const QString &serial, const QString &version);
    ~Device();

    bool isValid();
    bool scanFilesystem(const QString &path);
    bool scanMtpDevices();

    bool addStorage_filesystem(const QString &path);
    bool addStorage_mtp(LIBMTP_mtpdevice_t *m_mtpDevice);
        void mtpFileRec(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf);

public slots:
    //
    int getDeviceModel() const { return m_deviceModel; }
    int getDeviceType() const { return m_deviceType; }
    QString getBrand() const { return m_brand; }
    QString getModel() const { return m_model; }
    QString getSerial() const { return m_serial; }
    QString getFirmware() const { return m_firmware; }

    //
    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    double getSpaceUsed_percent();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();

    //
    QString getPath(int index = 0) const;
    void getMtpIds(int &devBus, int &devNum) const;

    //
    void offloadAll();
    void deleteAll();

    //
    //void addShot(Shot *shot);
    //void deleteShot(Shot *shot);

    //
    ShotModel *getShotModel() const { return m_shotModel; }
    QVariant getShot(int index) const { if (index >= 0 && index < m_shotModel->getShotList()->size()) { return QVariant::fromValue(m_shotModel->getShotList()->at(index)); } return QVariant(); }
};

/* ************************************************************************** */
#endif // DEVICE_H
