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

#include "GenericFileModel.h"

#include <QDebug>

/* ************************************************************************** */

bool parseGenericDCIM(const QString &path, generic_device_infos &infos)
{
    bool status = true;

    const QDir dcim(path + "/DCIM");
    const QStringList &dcim_list = dcim.entryList(QDir::Dirs | QDir::NoDotAndDotDot);

    if (dcim.exists() && dcim.isReadable())
    {
        //qDebug() << "WE HAVE a DCIM directory on" << path;

        // Try to guess brand
        for (const auto &subdir_name : dcim_list)
        {
            //qDebug() << "  * Scanning DCIM subdir:" << subdir_name;

            if (subdir_name.size() == 8)
            {
                QString brand = subdir_name.mid(3, 5).toUpper();

                if (brand == "ANDRO")
                {
                    infos.device_type = DeviceUtils::DeviceSmartphone;
                    infos.device_model = "Android";
                }
                else if (brand == "APPLE")
                {
                    infos.device_type = DeviceUtils::DeviceSmartphone;
                    infos.device_brand = "Apple";
                }
                else if (brand == "CANON")
                {
                    infos.device_type = DeviceUtils::DeviceCamera;
                    infos.device_brand = "Canon";
                }
                else if (brand == "GOPRO" || brand == "0GP")
                {
                    infos.device_type = DeviceUtils::DeviceActionCamera;
                    infos.device_brand = "GoPro";
                    infos.device_model = "HERO";
                }
                else if (brand == "GBACK"|| brand == "GFRNT")
                {
                    infos.device_type = DeviceUtils::DeviceActionCamera;
                    infos.device_brand = "GoPro";
                    infos.device_model = "Fusion";
                }
                else if (brand.toLower() == "olymp")
                {
                    infos.device_type = DeviceUtils::DeviceCamera;
                    infos.device_brand = "Olympus";
                }
                else if (brand == "SHARP")
                {
                    infos.device_type = DeviceUtils::DeviceCamera;
                    infos.device_brand = "Sharp";
                }
                else if (brand == "MSDCF")
                {
                    infos.device_type = DeviceUtils::DeviceCamera;
                    infos.device_brand = "Sony";
                }
                else if (brand == "MEDIA")
                {
                    infos.device_type = DeviceUtils::DeviceActionCamera;
                    infos.device_brand = "DJI"; // ???
                }
                else if (brand == "NIKON")
                {
                    infos.device_type = DeviceUtils::DeviceCamera;
                    infos.device_brand = "Nikon";
                }
                else if (subdir_name.startsWith("Camera0")) // 01 to 99
                {
                    infos.device_type = DeviceUtils::DeviceActionCamera;
                    infos.device_brand = "Insta360";
                }
            }
            else
            {
                if (subdir_name == "1000GP")
                {
                    infos.device_type = DeviceUtils::DeviceActionCamera;
                    infos.device_brand = "GoPro";
                    infos.device_model = "HERO";
                }
            }

            break; // we only try once
        }
    }

    if (infos.device_brand.isEmpty())
    {
        // I mean who knows...
        infos.device_type = DeviceUtils::DeviceCamera;
        infos.device_brand = "Generic";
        infos.device_model = "Camera";

        status = false;
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool getGenericShotInfos(ofb_file &file, ofb_shot &shot)
{
    shot.shot_id = 0;
    shot.file_number = 0;

    QString fileextension = file.extension.toLower();

    if (fileextension == "jpg" || fileextension == "jpeg" ||
        fileextension == "jp2" || fileextension == "j2k" || fileextension == "jxl" ||
        fileextension == "png" || fileextension == "webp" ||
        fileextension == "avif" || fileextension == "heif" || fileextension == "heic" ||
        fileextension == "gpr" ||
        fileextension == "insp")
    {
        file.isPicture = true;
        shot.shot_type = ShotUtils::SHOT_PICTURE;
    }
    else if (fileextension == "mov" || fileextension == "mp4" || fileextension == "m4v" ||
             fileextension == "avi" ||
             fileextension == "mkv" || fileextension == "webm" ||
             fileextension == "insv")
    {
        file.isVideo = true;
        shot.shot_type = ShotUtils::SHOT_VIDEO;
    }
    else if (fileextension == "lrv")
    {
        file.isVideo = true;
        file.isLowRes = true;
        shot.shot_type = ShotUtils::SHOT_VIDEO;
    }
    else if (fileextension == "thm")
    {
        file.isPicture = true;
        file.isLowRes = true;
        shot.shot_type = ShotUtils::SHOT_VIDEO;
    }
    else if (fileextension == "gpx" || fileextension == "json")
    {
        file.isTelemetry = true;
        shot.shot_type = ShotUtils::SHOT_VIDEO;
    }
    else
    {
        //qDebug() << "Unsupported file extension:" << file.extension;
        return false;
    }
/*
    qDebug() << "* FILE:" << file.name << "." << file.extension;
    qDebug() << "- " << shot.shot_type;
*/
    return true;
}

/* ************************************************************************** */
