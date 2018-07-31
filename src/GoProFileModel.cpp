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

#include "GoProFileModel.h"

#include <QDebug>

/* ************************************************************************** */

bool getGoProShotInfos(const QString &file_name, const QString &file_ext,
                       Shared::ShotType &file_type, int &file_number, int &group_number, int &camera_id)
{
    bool status = true;
    QString group_string;

    if (file_name.size() != 8)
        qWarning() << "This filename is not 8 chars... Probably not a GoPro file...";
    if (file_name.startsWith("G") == false)
        qWarning() << "This filename doesn't start by 'G'... Probably not a GoPro file...";

    file_number = file_name.mid(4, 4).toInt();

    if (file_name.startsWith("GOPR"))
    {
        if (file_ext == "jpg")
        {
            // Single Photo
            file_type = Shared::SHOT_PICTURE;
        }
        else if (file_ext == "mp4")
        {
            // Single Video
            file_type = Shared::SHOT_VIDEO;
        }
    }
    else if (file_name.startsWith("GPBK") ||
             file_name.startsWith("GPFR"))
    {
        // Fusion Video
        if (file_ext == "jpg")
        {
            file_type = Shared::SHOT_PICTURE;
        }
        else if (file_ext == "mp4" || file_ext == "lrv" ||
                 file_ext == "thm"  || file_ext == "wav")
        {
            file_type = Shared::SHOT_VIDEO;
        }

        if (file_name.startsWith("GPBK"))
            camera_id = 1;
    }
    else if (file_name.startsWith("GP"))
    {
        // Chaptered Video
        file_type = Shared::SHOT_VIDEO;
        group_string = file_name.mid(2, 2);
        group_number = group_string.toInt();
    }
    else if (file_name.startsWith("GH") ||
             file_name.startsWith("GX") ||
             file_name.startsWith("GL"))
    {
        // HERO6 Video
        file_type = Shared::SHOT_VIDEO;
        group_string = file_name.mid(2, 2);
        group_number = group_string.toInt();
    }
    else if (file_name.startsWith("GB") ||
             file_name.startsWith("GF"))
    {
        // Chaptered Fusion Video
        file_type = Shared::SHOT_VIDEO;
        group_string = file_name.mid(2, 2);
        group_number = group_string.toInt();

        if (file_ext == "jpg")
        {
            file_type = Shared::SHOT_PICTURE_MULTI;
        }
        else if (file_ext == "mp4" || file_ext == "lrv" ||
                 file_ext == "thm"  || file_ext == "wav")
        {
            file_type = Shared::SHOT_VIDEO;
        }

        if (file_name.startsWith("GB"))
            camera_id = 1;
    }
    else if (file_name.startsWith("G"))
    {
        if (file_ext == "jpg")
        {
            // Burst or Time-Lapse Photo
            file_type = Shared::SHOT_PICTURE_MULTI;
        }
        else if (file_ext == "mp4" || file_ext == "lrv" ||
                 file_ext == "thm"  || file_ext == "wav")
        {
            // Looping Video
            file_type = Shared::SHOT_VIDEO;
        }

        group_string = file_name.mid(1, 3);
        group_number = group_string.toInt();
    }
    else if (file_name.startsWith("3D_"))
    {
        // 3D Recording Video
        //file_type = Shared::SHOT_VIDEO_3D;
        qWarning() << "Unhandled file name format:" << file_name;
        status = false;
    }
    else
    {
        qWarning() << "Unknown file name format:" << file_name;
        status = false;
    }

    //int shot_id = (file_type == Shared::SHOT_VIDEO) ? file_number : group_number;

/*
    qDebug() << "* FILE:" << file_name;
    qDebug() << "- " << file_ext;
    qDebug() << "- " << file_type;
    qDebug() << "- " << group_number;
    qDebug() << "- " << file_number;
    qDebug() << "- " << shot_id;
*/
    return  status;
}

/* ************************************************************************** */
