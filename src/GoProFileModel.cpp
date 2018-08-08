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

bool parseGoProVersionFile(const QString &path, gopro_info_version &infos)
{
    bool status = false;

    QFile versiontxt(path + "/MISC/version.txt");

    if (versiontxt.exists() &&
        versiontxt.size() > 0 &&
        versiontxt.open(QIODevice::ReadOnly))
    {
/*
        qDebug() << "> GOPRO SD CARD FOUND:";
        qDebug() << "- mountpoint:" << storage.displayName();
        qDebug() << "- type:" << storage.fileSystemType();
*/
        QTextStream in(&versiontxt);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            if (!line.isEmpty())
            {
                QStringList kv = line.split(':');
                if (kv.size() == 2)
                {
                    QString key = kv.at(0);
                    key.remove(0,1).chop(1);
                    QString value = kv.at(1);
                    value.remove(0,1).chop(2);
                    //qDebug() << "key:" << key << " / value:" << value;

                    if (key == "info version")
                        if (value != "1.0" && value != "1.1" &&  value != "2.0")
                            qWarning() << "SD Card version.txt is unsupported!";

                    if (key == "firmware version")
                        infos.firmware_version = value;

                    if (key == "camera type")
                        infos.camera_type = value;

                    if (key == "camera serial number")
                        infos.camera_serial_number = value;

                    if (key == "wifi mac")
                        infos.wifi_mac = value;
                    if (key == "wifi version")
                        infos.wifi_version = value;
                    if (key == "wifi bootloader version")
                        infos.wifi_bootloader_version = value;
                }
            }
        }

        if (!infos.camera_type.isEmpty() && !infos.camera_serial_number.isEmpty())
            status = true;
    }

    versiontxt.close();

    return status;
}

/* ************************************************************************** */

bool getGoProShotInfos(const ofb_file &file, ofb_shot &shot)
{
    bool status = true;
    QString group_string;

    if (file.name.size() != 8)
        qWarning() << "-" << file.name << ": filename is not 8 chars... Probably not a GoPro file...";
    if (file.name.startsWith("G") == false)
        qWarning() << "-" << file.name << ": filename doesn't start by 'G'... Probably not a GoPro file...";

    shot.file_number = file.name.mid(4, 4).toInt();

    if (file.name.startsWith("GOPR"))
    {
        if (file.extension == "jpg")
        {
            // Single Photo
            shot.file_type = Shared::SHOT_PICTURE;
        }
        else if (file.extension == "mp4")
        {
            // Single Video
            shot.file_type = Shared::SHOT_VIDEO;
        }
    }
    else if (file.name.startsWith("GPBK") ||
             file.name.startsWith("GPFR"))
    {
        // Fusion Video
        if (file.extension == "jpg")
        {
            shot.file_type = Shared::SHOT_PICTURE;
        }
        else if (file.extension == "mp4" || file.extension == "lrv" ||
                 file.extension == "thm"  || file.extension == "wav")
        {
            shot.file_type = Shared::SHOT_VIDEO;
        }

        if (file.name.startsWith("GPBK"))
            shot.camera_id = 1;
    }
    else if (file.name.startsWith("GP"))
    {
        // Chaptered Video
        shot.file_type = Shared::SHOT_VIDEO;
        group_string = file.name.mid(2, 2);
        shot.group_number = group_string.toInt();
    }
    else if (file.name.startsWith("GH") ||
             file.name.startsWith("GX") ||
             file.name.startsWith("GL"))
    {
        // HERO6 Video
        shot.file_type = Shared::SHOT_VIDEO;
        group_string = file.name.mid(2, 2);
        shot.group_number = group_string.toInt();
    }
    else if (file.name.startsWith("GB") ||
             file.name.startsWith("GF"))
    {
        // Chaptered Fusion Video
        shot.file_type = Shared::SHOT_VIDEO;
        group_string = file.name.mid(2, 2);
        shot.group_number = group_string.toInt();

        if (file.extension == "jpg")
        {
            shot.file_type = Shared::SHOT_PICTURE_MULTI;
        }
        else if (file.extension == "mp4" || file.extension == "lrv" ||
                 file.extension == "thm"  || file.extension == "wav")
        {
            shot.file_type = Shared::SHOT_VIDEO;
        }

        if (file.name.startsWith("GB"))
            shot.camera_id = 1;
    }
    else if (file.name.startsWith("G"))
    {
        if (file.extension == "jpg")
        {
            // Burst or Time-Lapse Photo
            shot.file_type = Shared::SHOT_PICTURE_MULTI;
        }
        else if (file.extension == "mp4" || file.extension == "lrv" ||
                 file.extension == "thm"  || file.extension == "wav")
        {
            // Looping Video
            shot.file_type = Shared::SHOT_VIDEO;
        }

        group_string = file.name.mid(1, 3);
        shot.group_number = group_string.toInt();
    }
    else if (file.name.startsWith("3D_"))
    {
        // 3D Recording Video
        //shot.file_type = Shared::SHOT_VIDEO_3D;
        qWarning() << "Unhandled file name format:" << file.name;
        status = false;
    }
    else
    {
        qWarning() << "Unknown file name format:" << file.name;
        status = false;
    }

    shot.shot_id = (shot.file_type == Shared::SHOT_VIDEO) ? shot.file_number : shot.group_number;
/*
    qDebug() << "* FILE:" << file.name;
    qDebug() << "- " << file.extension;
    qDebug() << "- " << shot.file_type;
    qDebug() << "- " << shot.group_number;
    qDebug() << "- " << shot.file_number;
    qDebug() << "- " << shot.shot_id;
*/
    return  status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool getGoProShotInfos(const QString &file_name, const QString &file_ext,
                       Shared::ShotType &file_type, int &file_number, int &group_number, int &camera_id)
{
    bool status = true;
    QString group_string;

    if (file_name.size() != 8)
        qWarning() << "-" << file_name << ": filename is not 8 chars... Probably not a GoPro file...";
    if (file_name.startsWith("G") == false)
        qWarning() << "-" << file_name << ": filename doesn't start by 'G'... Probably not a GoPro file...";

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
