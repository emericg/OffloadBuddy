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

#include "GenericFileModel.h"

#include <QDebug>

/* ************************************************************************** */

bool parseGenericDCIM(const QString &path, generic_device_infos &infos)
{
    bool status = false;

    QDir dcim(path + "/DCIM");
    if (dcim.exists() && dcim.isReadable())
    {
        //qDebug() << "WE HAVE DCIM at ";
        status = true;

        // Try to guess brand
        foreach (QString subdir_name, dcim.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
        {
            //qDebug() << "  * Scanning DCIM subdir:" << subdir_name;

            if (subdir_name.size() == 8)
            {
                QString brand = subdir_name.mid(3, 5);

                if (brand.toUpper() == "ANDRO")
                {
                    infos.device_type = DEVICE_SMARTPHONE;
                    infos.device_model = "Android";
                }
                else if (brand.toUpper() == "APPLE")
                {
                    infos.device_type = DEVICE_SMARTPHONE;
                    infos.device_brand = "Apple";
                }
                else if (brand.toUpper() == "CANON")
                {
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_brand = "Canon";
                }
                else if (brand.toUpper() == "GOPRO" || brand.toUpper() == "0GP")
                {
                    infos.device_type = DEVICE_ACTIONCAM;
                    infos.device_brand = "GoPro";
                    infos.device_model = "HERO";
                }
                else if (brand.toUpper() == "GBACK"|| brand.toUpper() == "GFRNT")
                {
                    infos.device_type = DEVICE_ACTIONCAM;
                    infos.device_brand = "GoPro";
                    infos.device_model = "Fusion";
                }
                else if (brand.toLower() == "olymp")
                {
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_brand = "Olympus";
                }
                else if (brand.toUpper() == "SHARP")
                {
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_brand = "Sharp";
                }
                else if (brand.toUpper() == "MSDCF")
                {
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_brand = "Sony";
                }
                else if (brand.toUpper() == "MEDIA")
                {
                    // DJI ???
                }
                else if (brand.toUpper() == "NIKON")
                {
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_brand = "Nikon";
                }
                else
                {
                    // Assume model number? why not?
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_model = brand;
                }
            }
            else
            {
                if (subdir_name == "1000GP")
                {
                    // I mean of course they broke the rule...
                    infos.device_type = DEVICE_ACTIONCAM;
                    infos.device_brand = "GoPro";
                    infos.device_model = "HERO";
                }
                else
                {
                    // I mean who knows...
                    infos.device_type = DEVICE_CAMERA;
                    infos.device_brand = "Generic";
                    infos.device_model = "Camera";
                }
            }

            break;
        }
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool getGenericShotInfos(const ofb_file &file, ofb_shot &shot)
{
    bool status = true;

    shot.group_number = 0;
    shot.file_number = 0;
    shot.shot_id = 0;

    if (file.extension == "jpg" || file.extension == "png")
    {
        shot.file_type = Shared::SHOT_PICTURE;
    }
    else if (file.extension == "mov" || file.extension == "mp4" || file.extension == "m4v" ||
             file.extension == "avi" ||
             file.extension == "mkv")
    {
        shot.file_type = Shared::SHOT_VIDEO;
    }
    else
    {
        qWarning() << "Unknown file extension:" << file.extension;
        status = false;
    }
/*
    qDebug() << "* FILE:" << file.name;
    qDebug() << "- " << file.extension;
    qDebug() << "- " << shot.file_type;
*/
    return  status;
}

/* ************************************************************************** */
