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

#include <QFile>
#include <QTextStream>
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
        QTextStream in(&versiontxt);
        while (!in.atEnd())
        {
            QString line = in.readLine();
            if (!line.isEmpty())
            {
                if (line.startsWith(',')) line.remove(0, 1); // HERO10+ hack
                if (line.endsWith(',')) line.remove(-1, 1);   // HERO9- hack

                QStringList kv = line.split(':');
                if (kv.size() == 2)
                {
                    QString key = kv.at(0);
                    key.remove(0, 1).chop(1);
                    QString value = kv.at(1);
                    value.remove(0, 1).chop(1);

                    //qDebug() << "key:" << key << " / value:" << value;

                    if (key == "info version")
                        if (value != "1.0" && value != "1.1" && value != "2.0")
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
/*
    if (status)
    {
        qDebug() << "> GOPRO SD CARD FOUND:";
        qDebug() << "- mountpoint   :" << path;
        qDebug() << "- camera type  :" << infos.camera_type;
        qDebug() << "- serial number:" << infos.camera_serial_number;
        qDebug() << "- firmware     :" << infos.firmware_version;
        qDebug() << "- wifi_mac       :" << infos.wifi_mac;
        qDebug() << "- wifi_version   :" << infos.wifi_version;
        qDebug() << "- wifi_bootloader:" << infos.wifi_bootloader_version;
    }
*/
    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool getGoProShotInfos(ofb_file &file, ofb_shot &shot)
{
    if (file.name.size() != 8)
    {
        //qDebug() << "-" << file.name << ": filename is not 8 chars... Probably not a GoPro file...";
        return false;
    }
    if (!file.name.startsWith("G"))
    {
        //qDebug() << "-" << file.name << ": filename doesn't start by 'G'... Probably not a GoPro file...";
        return false;
    }

    int group_number = -1;
    int file_number = file.name.mid(4, 4).toInt();
    QString fileextension = file.extension.toLower();

    if (file.name.startsWith("GOPR"))
    {
        if (fileextension == "jpg" || fileextension == "gpr")
        {
            // Single Photo
            shot.shot_type = ShotUtils::SHOT_PICTURE;
        }
        else
        {
            // Single Video
            shot.shot_type = ShotUtils::SHOT_VIDEO;
        }
    }
    else if (file.name.startsWith("GPBK") ||
             file.name.startsWith("GPFR"))
    {
        // Fusion
        if (fileextension == "jpg" || fileextension == "gpr")
        {
            // Single Photo
            shot.shot_type = ShotUtils::SHOT_PICTURE;
        }
        else
        {
            // Single Video
            shot.shot_type = ShotUtils::SHOT_VIDEO;
        }

        if (file.name.startsWith("GPBK")) shot.camera_id = 1;
    }
    else if (file.name.startsWith("GP"))
    {
        // Chaptered Video
        shot.shot_type = ShotUtils::SHOT_VIDEO;
        group_number = file.name.mid(2, 2).toInt();
    }
    else if (file.name.startsWith("GH") ||
             file.name.startsWith("GX") ||
             file.name.startsWith("GL"))
    {
        // HERO6+ Video
        shot.shot_type = ShotUtils::SHOT_VIDEO;
        group_number = file.name.mid(2, 2).toInt();
    }
    else if (file.name.startsWith("GB") ||
             file.name.startsWith("GF"))
    {
        // Fusion Chaptered
        shot.shot_type = ShotUtils::SHOT_VIDEO;
        group_number = file.name.mid(2, 2).toInt();

        if (fileextension == "jpg" || fileextension == "gpr")
        {
            // Burst or Time-Lapse Photo
            shot.shot_type = ShotUtils::SHOT_PICTURE_MULTI;
        }
        else
        {
            // Chaptered Video
            shot.shot_type = ShotUtils::SHOT_VIDEO;
        }

        if (file.name.startsWith("GB")) shot.camera_id = 1;
    }
    else if (file.name.startsWith("G"))
    {
        if (fileextension == "jpg" || fileextension == "gpr")
        {
            // Burst or Time-Lapse Photo
            shot.shot_type = ShotUtils::SHOT_PICTURE_MULTI;
        }
        else
        {
            // Looping Video
            shot.shot_type = ShotUtils::SHOT_VIDEO;
        }

        group_number = file.name.mid(1, 3).toInt();
    }
    else if (file.name.startsWith("3D_"))
    {
        // 3D Video
        shot.shot_type = ShotUtils::SHOT_VIDEO_3D;

        qWarning() << "Unhandled shot type: SHOT_VIDEO_3D";
    }
    else
    {
        qDebug() << "Unsupported file name format:" << file.name;
        return false;
    }

    if (fileextension == "mp4") file.isVideo = true;
    else if (fileextension == "jpg" || fileextension == "gpr") file.isPicture = true;
    else if (fileextension == "lrv") { file.isVideo = true; file.isLowRes = true; }
    else if (fileextension == "thm") { file.isPicture = true; file.isLowRes = true; }
    else if (fileextension == "wav") file.isAudio = true;
    else if (fileextension == "gpx" || fileextension == "json") file.isTelemetry = true;
    else file.isOther = true;

    file.isShot = true;
    shot.shot_id = (shot.shot_type == ShotUtils::SHOT_VIDEO) ? file_number : group_number;
    shot.file_number = file_number;
/*
    qDebug() << "* FILE:" << file.name << "." << file.extension;
    qDebug() << "- " << shot.shot_type;
    qDebug() << "- " << shot.shot_id;
    qDebug() << "- " << shot.file_number;
*/
    return true;
}

/* ************************************************************************** */
