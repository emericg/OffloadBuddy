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

#include "GoProFileModel.h"

#include <QDebug>

/* ************************************************************************** */

bool parseGoProVersionFile(const QString &path, gopro_device_infos &infos)
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
/* ************************************************************************** */

bool getGoProShotInfos(const ofb_file &file, ofb_shot &shot)
{
    QString group_string;

    if (file.name.size() != 8)
    {
        //qWarning() << "-" << file.name << ": filename is not 8 chars... Probably not a GoPro file...";
        return false;
    }
    if (!file.name.startsWith("G"))
    {
        //qWarning() << "-" << file.name << ": filename doesn't start by 'G'... Probably not a GoPro file...";
        return false;
    }

    if (file.name.startsWith("GOPR"))
    {
        if (file.extension == "jpg" || file.extension == "gpr")
        {
            // Single Photo
            shot.shot_type = Shared::SHOT_PICTURE;
        }
        else if (file.extension == "mp4")
        {
            // Single Video
            shot.shot_type = Shared::SHOT_VIDEO;
        }
    }
    else if (file.name.startsWith("GPBK") ||
             file.name.startsWith("GPFR"))
    {
        // Fusion Video
        if (file.extension == "jpg" || file.extension == "gpr")
        {
            shot.shot_type = Shared::SHOT_PICTURE;
        }
        else if (file.extension == "mp4" || file.extension == "lrv" ||
                 file.extension == "thm"  || file.extension == "wav")
        {
            shot.shot_type = Shared::SHOT_VIDEO;
        }

        if (file.name.startsWith("GPBK"))
            shot.camera_id = 1;
    }
    else if (file.name.startsWith("GP"))
    {
        // Chaptered Video
        shot.shot_type = Shared::SHOT_VIDEO;
        group_string = file.name.mid(2, 2);
        shot.group_number = group_string.toInt();
    }
    else if (file.name.startsWith("GH") ||
             file.name.startsWith("GX") ||
             file.name.startsWith("GL"))
    {
        // HERO6 Video
        shot.shot_type = Shared::SHOT_VIDEO;
        group_string = file.name.mid(2, 2);
        shot.group_number = group_string.toInt();
    }
    else if (file.name.startsWith("GB") ||
             file.name.startsWith("GF"))
    {
        // Chaptered Fusion Video
        shot.shot_type = Shared::SHOT_VIDEO;
        group_string = file.name.mid(2, 2);
        shot.group_number = group_string.toInt();

        if (file.extension == "jpg" || file.extension == "gpr")
        {
            shot.shot_type = Shared::SHOT_PICTURE_MULTI;
        }
        else if (file.extension == "mp4" || file.extension == "lrv" ||
                 file.extension == "thm"  || file.extension == "wav")
        {
            shot.shot_type = Shared::SHOT_VIDEO;
        }

        if (file.name.startsWith("GB"))
            shot.camera_id = 1;
    }
    else if (file.name.startsWith("G"))
    {
        if (file.extension == "jpg" || file.extension == "gpr")
        {
            // Burst or Time-Lapse Photo
            shot.shot_type = Shared::SHOT_PICTURE_MULTI;
        }
        else if (file.extension == "mp4" || file.extension == "lrv" ||
                 file.extension == "thm"  || file.extension == "wav")
        {
            // Looping Video
            shot.shot_type = Shared::SHOT_VIDEO;
        }

        group_string = file.name.mid(1, 3);
        shot.group_number = group_string.toInt();
    }
    else if (file.name.startsWith("3D_"))
    {
        // 3D Recording Video
        shot.shot_type = Shared::SHOT_VIDEO_3D;

        qDebug() << "Unhandled file name format:" << file.name;
        return false;
    }
    else
    {
        qDebug() << "Unsupported file name format:" << file.name;
        return false;
    }

    shot.file_number = file.name.midRef(4, 4).toInt();
    shot.shot_id = (shot.shot_type == Shared::SHOT_VIDEO) ? shot.file_number : shot.group_number;
/*
    qDebug() << "* FILE:" << file.name;
    qDebug() << "- " << file.extension;
    qDebug() << "- " << shot.file_type;
    qDebug() << "- " << shot.shot_type;
    qDebug() << "- " << shot.group_number;
    qDebug() << "- " << shot.file_number;
    qDebug() << "- " << shot.shot_id;
*/
    return true;
}

/* ************************************************************************** */
