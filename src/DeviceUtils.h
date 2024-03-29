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

#ifndef DEVICE_UTILS_H
#define DEVICE_UTILS_H
/* ************************************************************************** */

#include "StorageUtils.h"

#include <QObject>
#include <QList>
#include <QStringList>
#include <QStorageInfo>

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#else
typedef void LIBMTP_mtpdevice_t;
typedef void LIBMTP_devicestorage_t;
#endif // ENABLE_LIBMTP

/* ************************************************************************** */

namespace DeviceUtils
{
    Q_NAMESPACE

    enum DeviceType
    {
        DeviceUnknown = 0,

        DeviceActionCamera,
        DeviceCamera,
        DeviceSmartphone,
        DeviceComputer,
    };
    Q_ENUM_NS(DeviceType)

    enum DeviceModel
    {
        ModelUnknown = 0,

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
            DEVICE_HERO8,
            DEVICE_HERO9,
            DEVICE_HERO10,
            DEVICE_HERO11,
            DEVICE_HERO11_MINI,
            DEVICE_HERO12,
            DEVICE_FUSION,
            DEVICE_MAX,

        DEVICE_SONY = 256,
            DEVICE_HDR_AS50,
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

        DEVICE_DJI = 330,
            DEVICE_DJI_ACTION2,
            DEVICE_DJI_POCKET2,
            DEVICE_DJI_POCKET3,
            DEVICE_DJI_OSMO,
            DEVICE_DJI_OSMOp,
            DEVICE_DJI_OSMO_POCKET,
            DEVICE_DJI_OSMO_ACTION,
            DEVICE_DJI_OSMO_ACTION2,
            DEVICE_DJI_OSMO_ACTION3,
            DEVICE_DJI_OSMO_ACTION4,

        DEVICE_RYLO = 350,
            DEVICE_RYLO_360,

        DEVICE_INSTA360 = 370,
            DEVICE_INSTA360_ONE_R,
            DEVICE_INSTA360_ONE_RS,
            DEVICE_INSTA360_ONE_X,
            DEVICE_INSTA360_ONE_X2,
            DEVICE_INSTA360_X3,
            DEVICE_INSTA360_GO,
            DEVICE_INSTA360_GO2,
            DEVICE_INSTA360_GO3,
            DEVICE_INSTA_EVO,
    };
    Q_ENUM_NS(DeviceModel)

    enum DeviceState
    {
        DeviceStateIdle = 0,
        DeviceStateScanning = 1,
    };
    Q_ENUM_NS(DeviceState)

    enum DeviceFirmwareState
    {
        FirmwareUnknown = 0,

        FirmwareUpToDate,
        FirmwareUpdateAvailable,
        FirmwareUpdating,
        FirmwareUpdateInstalled,
    };
    Q_ENUM_NS(DeviceFirmwareState)
};

/* ************************************************************************** */

typedef struct generic_device_infos
{
    DeviceUtils::DeviceType device_type;
    QString device_brand;
    QString device_model;

} generic_device_infos;

typedef struct gopro_device_infos
{
    StorageUtils::StorageType device_type;

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

typedef struct insta360_device_infos
{
    StorageUtils::StorageType device_type;

    QString camera_string;          // ex: "Insta360 OneR"
    QString camera_firmware;        // ex: "v1.1.30_build1"
    QString camera_serial_number;   // ex: "IAREH55BYABTUG"

} insta360_device_infos;

/* ************************************************************************** */

struct StorageFilesystem
{
    QString m_path;
    QStorageInfo m_storage;
    bool m_writable = false;
};

struct StorageMtp
{
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
#endif // DEVICE_UTILS_H
