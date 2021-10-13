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
 * \date      2021
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "Insta360FileModel.h"
#include "GpmfBuffer.h"

#include <QDebug>

/* ************************************************************************** */

typedef struct InstaSegment
{
    uint64_t offset_begin = 0;
    uint64_t offset_end = 0;

    uint32_t tag = 0;
    uint32_t size = 0;

} InstaSegment;

int readSegment(InstaSegment &seg, GpmfBuffer &buf)
{
    int status = 0;

    seg.offset_begin = buf.getBytesIndex();

    seg.tag = buf.read_u8(status);
    buf.read_u8(status); // waste?
    seg.size = buf.getBufferSize() - 2;

    seg.offset_end = seg.offset_begin + seg.size;

    return status;
}

int readTopSegment(InstaSegment &seg, GpmfBuffer &buf)
{
    int status = 0;

    seg.offset_begin = buf.getBytesIndex();

    seg.tag = buf.read_u32(status);
    seg.size = buf.read_u8(status);

    seg.offset_end = seg.offset_begin + 4 + seg.size;

    return status;
}

int readSubSegment(InstaSegment &seg, GpmfBuffer &buf)
{
    int status = 0;

    seg.offset_begin = buf.getBytesIndex();

    seg.tag = buf.read_u8(status);
    seg.size = buf.read_u8(status);

    seg.offset_end = seg.offset_begin + 2 + seg.size;

    return status;
}

/* ************************************************************************** */

bool parseInsta360VersionFile(const QString &path, insta360_device_infos &infos)
{
    bool status = false;

    QFile fileinfo_list(path + "/DCIM/fileinfo_list.list");

    if (fileinfo_list.exists() &&
        fileinfo_list.size() > 0 &&
        fileinfo_list.open(QIODevice::ReadOnly))
    {
        char bufdata[fileinfo_list.size()];
        fileinfo_list.read(bufdata, fileinfo_list.size());
        int e = 0;

        GpmfBuffer buf;
        if (buf.loadBuffer((uint8_t*)bufdata, 1024))
        {
            // tag?
            buf.read_u32(e);

            // path tag? 0x0A
            //buf.read_u8(e);
            // path size
            int ppathsize = buf.read_u8(e);
            // path
            uint8_t *ppath = buf.readBytes(ppathsize, e);
            //qDebug() << "- path:" << QString::fromLocal8Bit((const char*)ppath, ppathsize);

            // tag?
            buf.read_u32(e);

            // serial tag? 0x0A
            //buf.read_u8(e);
            // serial size
            int serialsize = buf.read_u8(e);
            // serial
            uint8_t *serial = buf.readBytes(serialsize, e);
            infos.camera_serial_number = QString::fromLocal8Bit((const char*)serial, serialsize);
            //qDebug() << "- serial:" << infos.camera_serial_number;

            // model tag? 0x12
            buf.read_u8(e);
            // model size
            int modelsize = buf.read_u8(e);
            // model
            uint8_t *model = buf.readBytes(modelsize, e);
            infos.camera_string = QString::fromLocal8Bit((const char*)model, modelsize);
            //qDebug() << "- model:" << infos.camera_string;

            // firmware tag? 0x1A
            buf.read_u8(e);
            // firmware size
            int firmwaresize = buf.read_u8(e);
            // firmware
            uint8_t *firmware = buf.readBytes(firmwaresize, e);
            infos.camera_firmware = QString::fromLocal8Bit((const char*)firmware, firmwaresize);
            //qDebug() << "- firmware:" << infos.camera_firmware;

            // lens tag? 0x1A
            buf.read_u8(e);
            // lens size
            int lenssize = buf.read_u8(e);
            // lens
            uint8_t *lens = buf.readBytes(lenssize, e);
            //qDebug() << "- lens:" << QString::fromLocal8Bit((const char*)lens, lenssize);

            status = true;
        }
    }

    fileinfo_list.close();
/*
    if (status)
    {
        qDebug() << "> INSTA360 SD CARD FOUND:";
        qDebug() << "- mountpoint   :" << path;
        qDebug() << "- camera string:" << infos.camera_string;
        qDebug() << "- serial number:" << infos.camera_serial_number;
        qDebug() << "- firmware     :" << infos.camera_firmware;
    }
*/
    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool getInsta360ShotInfos(const ofb_file &file, ofb_shot &shot)
{
    shot.group_number = 0;
    shot.file_number = 0;
    shot.shot_id = 0;

    if (file.extension == "jpg" || file.extension == "jpeg" ||
        file.extension == "png" || file.extension == "webp" ||
        file.extension == "insp")
    {
        shot.shot_type = ShotUtils::SHOT_PICTURE;
    }
    else if (file.extension == "mov" || file.extension == "mp4" || file.extension == "m4v" ||
             file.extension == "lrv" ||
             file.extension == "avi" ||
             file.extension == "mkv" || file.extension == "webm" ||
             file.extension == "insv")
    {
        shot.shot_type = ShotUtils::SHOT_VIDEO;
    }
    else
    {
        //qDebug() << "Unsupported file extension:" << file.extension;
        return false;
    }
/*
    qDebug() << "* FILE:" << file.name;
    qDebug() << "- " << file.extension;
    //qDebug() << "- " << shot.file_type;
    qDebug() << "- " << shot.shot_type;
    qDebug() << "- " << shot.group_number;
    qDebug() << "- " << shot.file_number;
    qDebug() << "- " << shot.shot_id;
*/
    return true;
}

/* ************************************************************************** */
