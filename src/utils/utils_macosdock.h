/*!
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
 * \date      2019
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#ifndef UTILS_MACOS_DOCK_H
#define UTILS_MACOS_DOCK_H
/* ************************************************************************** */

#include <QObject>

/* ************************************************************************** */
#ifdef Q_OS_MACOS

/*!
 * \brief macOS dock click handler
 */
class MacOSDockHandler : public QObject
{
    Q_OBJECT

    MacOSDockHandler();
    ~MacOSDockHandler();

signals:
    void dockIconClicked();

public:
    static MacOSDockHandler *getInstance();
};

#endif // Q_OS_MACOS
/* ************************************************************************** */
#endif // UTILS_MACOS_DOCK_H
