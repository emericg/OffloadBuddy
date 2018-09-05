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

#ifndef GENERIC_FILE_MODEL_H
#define GENERIC_FILE_MODEL_H
/* ************************************************************************** */

#include "Shot.h"
#include "Device.h"

#include <QString>

/* ************************************************************************** */

/*!
 * \brief parseGenericDCIM
 * \param path[in]: Path where to look for a DCIM directory.
 * \param infos[in,out] Infos guessed from DCIM subfolders.
 * \return true if a DCIM directory has been found.
 */
bool parseGenericDCIM(const QString &path, generic_device_infos &infos);

/*!
 * \brief getGenericShotInfos
 * \param file[in]: Describe the file.
 * \param shot[out]: Describe the shot.
 * \return true if the file has an extension that we can use.
 *
 * \todo implement DCM file model.
 * \ref https://en.wikipedia.org/wiki/Design_rule_for_Camera_File_system
 */
bool getGenericShotInfos(const ofb_file &file, ofb_shot &shot);

/* ************************************************************************** */
#endif // GENERIC_FILE_MODEL_H
