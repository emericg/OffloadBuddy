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
