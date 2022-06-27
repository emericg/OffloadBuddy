/*!
 * Copyright (c) 2022 Emeric Grange - All Rights Reserved
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
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2021
 */

#ifndef UTILS_OS_LINUX_H
#define UTILS_OS_LINUX_H

#include <QtGlobal>

#if defined(Q_OS_LINUX)
/* ************************************************************************** */

#include <QString>

/*!
 * \brief Linux utils
 *
 * Use with "QT += dbus"
 */
class UtilsLinux
{
public:
   static uint32_t screenKeepOn(const QString &application, const QString &reason);
   static void screenKeepAuto(uint32_t screensaverId);
};

/* ************************************************************************** */
#endif // Q_OS_LINUX
#endif // UTILS_OS_LINUX_H
