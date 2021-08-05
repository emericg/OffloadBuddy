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

#ifndef SHOT_UTILS_H
#define SHOT_UTILS_H
/* ************************************************************************** */

#include <QObject>
#include <QQmlApplicationEngine>

class ShotUtils: public QObject
{
    Q_OBJECT

public:
    static void registerQML()
    {
        qRegisterMetaType<ShotUtils::FileType>("ShotUtils::FileType");
        qRegisterMetaType<ShotUtils::ShotType>("ShotUtils::ShotType");
        qRegisterMetaType<ShotUtils::ShotState>("ShotUtils::ShotState");

        qmlRegisterType<ShotUtils>("ShotUtils", 1, 0, "ShotUtils");
    }

    enum FileType
    {
        FILE_UNKNOWN = 0,
        FILE_AUDIO = 4,
        FILE_VIDEO = 8,
        FILE_PICTURE = 16,
        FILE_METADATA = 32,
    };
    Q_ENUM(FileType)

    enum ShotType
    {
        SHOT_UNKNOWN = 0,

        SHOT_VIDEO = 8,
        SHOT_VIDEO_LOOPING,
        SHOT_VIDEO_TIMELAPSE,
        SHOT_VIDEO_NIGHTLAPSE,
        SHOT_VIDEO_3D,

        SHOT_PICTURE = 16,
        SHOT_PICTURE_MULTI,
        SHOT_PICTURE_BURST,
        SHOT_PICTURE_TIMELAPSE,
        SHOT_PICTURE_NIGHTLAPSE,
    };
    Q_ENUM(ShotType)

    enum ShotState
    {
        SHOT_STATE_DEFAULT = 0,
        SHOT_STATE_QUEUED,

        SHOT_STATE_OFFLOADING,
        SHOT_STATE_OFFLOADED,

        SHOT_STATE_ENCODING,
        SHOT_STATE_ENCODED,

        SHOT_STATE_DONE = 32,
        SHOT_STATE_ERRORED,
    };
    Q_ENUM(ShotState)
};

/* ************************************************************************** */
#endif // SHOT_UTILS_H
