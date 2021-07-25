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

#include "utils/utils_enums.h"

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
