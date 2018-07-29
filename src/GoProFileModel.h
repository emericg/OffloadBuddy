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

#ifndef GOPRO_FILE_MODEL_H
#define GOPRO_FILE_MODEL_H
/* ************************************************************************** */

#include "Shot.h"
#include <QString>

/*!
 * \brief getGoProShotInfos
 * \param file_name[in]: File name.
 * \param file_ext[in]: File extension.
 * \param file_type[out]: ShotType enum value.
 * \param file_number[out]:
 * \param group_number[out]:
 * \param camera_id[out]: Camera ID, usually 0 but with fusion or omni shots you can have other values.
 * \return true if the file is coming from a GoPro shot.
 *
 * \ref https://gopro.com/help/articles/question_answer/GoPro-Camera-File-Naming-Convention
 *
 * TODO: test if Qt::CaseSensitivity makes a performance difference?
 * TODO: merge file_number and group_number into shot_id?
 */
bool getGoProShotInfos(const QString &file_name, const QString &file_ext,
                       Shared::ShotType &file_type, int &file_number, int &group_number, int &camera_id);

/* ************************************************************************** */
#endif // GOPRO_FILE_MODEL_H
