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
 * \date      2020
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#ifndef STORAGE_UTILS_H
#define STORAGE_UTILS_H
/* ************************************************************************** */

#include <QObject>

namespace StorageUtils
{
    Q_NAMESPACE

    enum StorageType
    {
        StorageUnknown = 0,

        StorageFilesystem,
        StorageVirtualFilesystem,
        StorageNetworkFilesystem,
        StorageMTP,
    };
    Q_ENUM_NS(StorageType)

    enum StorageContent
    {
        ContentAll = 0,

        ContentAudio,
        ContentVideo,
        ContentPictures,
    };
    Q_ENUM_NS(StorageContent)

    enum StorageHierarchy
    {
        HierarchyNone = 0,

        HierarchyShot,
        HierarchyDateShot,
        HierarchyDateDeviceShot,
        HierarchyYearDateDeviceShot,

        HierarchyCustom = 32,
    };
    Q_ENUM_NS(StorageHierarchy)

    enum DeviceType
    {
        DeviceUnknown = 0,

        DeviceActionCamera,
        DeviceCamera,
        DeviceMobile,
        DeviceComputer,
    };
    Q_ENUM_NS(DeviceType)
}

/* ************************************************************************** */
#endif // STORAGE_UTILS_H
