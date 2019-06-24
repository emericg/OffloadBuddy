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

#ifndef UTILS_ENUMS_H
#define UTILS_ENUMS_H
/* ************************************************************************** */

typedef enum contentTypes_e
{
    CONTENT_ALL = 0,
    CONTENT_VIDEOS,
    CONTENT_PICTURES,

} contentTypes_e;

typedef enum contentHierarchy_e
{
    HIERARCHY_DATE = 0,
    HIERARCHY_DATE_DEVICE,

} contentHierarchy_e;

/* ************************************************************************** */

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

typedef enum deviceType_e
{
    DEVICE_UNKNOWN = 0,

    DEVICE_COMPUTER,
    DEVICE_NETWORK,
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

/* ************************************************************************** */

#include <QMetaType>

namespace Shared
{
    Q_NAMESPACE

    enum FileType
    {
        FILE_UNKNOWN = 0,
        FILE_VIDEO = 8,
        FILE_PICTURE = 16,
    };
    Q_ENUM_NS(FileType)

    enum ShotType
    {
        SHOT_UNKNOWN = 0,

        SHOT_VIDEO = 8,
        SHOT_VIDEO_LOOPING,
        SHOT_VIDEO_TIMELAPSE,
        SHOT_VIDEO_NIGHTLAPSE,
        SHOT_VIDEO_3D,

        SHOT_PICTURE = 16,
        SHOT_PICTURE_MULTI,
        SHOT_PICTURE_BURST,
        SHOT_PICTURE_TIMELAPSE,
        SHOT_PICTURE_NIGHTLAPSE,
    };
    Q_ENUM_NS(ShotType)

    enum StorageType
    {
        STORAGE_FILESYSTEM = 0,
        STORAGE_VIRTUAL_FILESYSTEM = 1,
        STORAGE_MTP = 2,
    };
    Q_ENUM_NS(StorageType)

    enum ShotState
    {
        SHOT_STATE_DEFAULT = 0,
        SHOT_STATE_QUEUED,

        SHOT_STATE_OFFLOADING,
        SHOT_STATE_OFFLOADED,

        SHOT_STATE_ENCODING,
        SHOT_STATE_ENCODED,

        SHOT_STATE_DONE = 32,
        SHOT_STATE_ERRORED,
    };
    Q_ENUM_NS(ShotState)
}

/* ************************************************************************** */
#endif // UTILS_ENUMS_H
