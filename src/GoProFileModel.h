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

#ifndef GOPRO_FILE_MODEL_H
#define GOPRO_FILE_MODEL_H
/* ************************************************************************** */

#include "Shot.h"
#include "Device.h"

#include <QString>

/* ************************************************************************** */

/*!
 * \brief parseGoProVersionFile
 * \param path[in]: Path where to look for a version.txt file.
 * \param infos[in,out] Infos parsed from a version.txt file.
 * \return true if a GoPro version.txt file has been found and successfully parsed.
 */
bool parseGoProVersionFile(const QString &path, gopro_device_infos &infos);

/*!
 * \brief getGoProShotInfos
 * \param file[in]: Describe the file.
 * \param shot[out]: Describe the shot.
 * \return true if the file is coming from a GoPro shot.
 *
 * \ref https://gopro.com/help/articles/question_answer/GoPro-Camera-File-Naming-Convention
 * \ref https://gopro.com/help/articles/question_answer/GoPro-Camera-File-Chaptering-Information
 *
 * Limitation: Timelapse groups are sometimes from the same timelapse...
 *
 * TODO: test if Qt::CaseSensitivity makes a performance difference?
 */
bool getGoProShotInfos(ofb_file &file, ofb_shot &shot);

/* ************************************************************************** */
#endif // GOPRO_FILE_MODEL_H
