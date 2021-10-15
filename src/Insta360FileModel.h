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

#ifndef INSTA360_FILE_MODEL_H
#define INSTA360_FILE_MODEL_H
/* ************************************************************************** */

#include "Shot.h"
#include "Device.h"

#include <QString>

/* ************************************************************************** */

/*!
 * \brief parseInsta360VersionFile
 * \param path[in]: Path where to look for a fileinfo_list.list file.
 * \param infos[in,out] Infos parsed from a fileinfo_list.list file.
 * \return true if a Insta360 fileinfo_list.list file has been found and successfully parsed.
 */
bool parseInsta360VersionFile(const QString &path, insta360_device_infos &infos);

/*!
 * \brief getInsta360ShotInfos
 * \param file[in]: Describe the file.
 * \param shot[out]: Describe the shot.
 * \return true if the file is coming from a Insta360 shot.
 *
 * File format seems to be:
 * TYPE_DATE(yyyyMMdd)_TIME(hhmmss)_??_filenumber.ext
 *
 * Example:
 * - IMG_20210424_174249_00_002.insp
 * - VID_20210424_174231_00_001.insv
 */
bool getInsta360ShotInfos(ofb_file &file, ofb_shot &shot);

/* ************************************************************************** */
#endif // INSTA360_FILE_MODEL_H
