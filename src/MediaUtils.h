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

#ifndef MEDIA_UTILS_H
#define MEDIA_UTILS_H
/* ************************************************************************** */

#include <QObject>
#include <QDebug>
#include <QQmlEngine>

class MediaUtils : public QObject
{
    Q_OBJECT

public:
    explicit MediaUtils(QObject *parent = nullptr) : QObject(parent)
    {
        qRegisterMetaType<MediaUtils::ProjectionType>("MediaUtils::ProjectionType");
        qRegisterMetaType<MediaUtils::AspectRatio>("MediaUtils::AspectRatio");
        qmlRegisterUncreatableType<MediaUtils>("MediaUtils", 1, 0, "MediaUtils", "blablabla");
    }
    ~MediaUtils()
    {
        //
    }

    ////////////////////////////////////////////////////////////////////////////

    enum ProjectionType
    {
        Projection_None = 0,
        Projection_Equirectangular,
        Projection_Cubeface
    };
    Q_ENUM(ProjectionType)

    enum AspectRatio
    {
        AspectRatio_custom  = -1,
        AspectRatio_auto    = 0,
        AspectRatio_1_1     = 1,

        AspectRatio_4_3,
        AspectRatio_3_2,
        AspectRatio_16_9,
        AspectRatio_2_1,
        AspectRatio_21_9,

        AspectRatio_3_4,
        AspectRatio_2_3,
        AspectRatio_9_16,
        AspectRatio_1_2,
        AspectRatio_9_21,
    };
    Q_ENUM(AspectRatio)

    ////////////////////////////////////////////////////////////////////////////

    Q_INVOKABLE static MediaUtils::AspectRatio arFromGeometry(const int width, const int height)
    {
        AspectRatio ar = AspectRatio_custom;

        if (width > 0 && height > 0)
        {
            float ar_float = 1.f;
            bool ar_invert = false;

            if (width >= height) {
                ar_float = width / static_cast<float>(height);
            } else {
                ar_float = height / static_cast<float>(width);
                ar_invert = true;
            }

            if (ar_float > 0.99f && ar_float < 1.01f) {
                ar = AspectRatio_1_1;
            } else if (ar_float > 1.323f && ar_float < 1.343f) {
                ar = (ar_invert) ? AspectRatio_3_4 : AspectRatio_4_3;
            } else if (ar_float > 1.49f && ar_float < 1.51f) {
                ar = (ar_invert) ? AspectRatio_2_3 : AspectRatio_3_2;
            } else if (ar_float > 1.767f && ar_float < 1.787f) {
                ar = (ar_invert) ? AspectRatio_9_16 : AspectRatio_16_9;
            } else if (ar_float > 1.99f && ar_float < 2.01f) {
                ar = (ar_invert) ? AspectRatio_1_2 : AspectRatio_2_1;
            } else if (ar_float > 2.33f && ar_float < 2.34f) {
                ar = (ar_invert) ? AspectRatio_9_21 : AspectRatio_21_9;
            }
        }

        return ar;
    }

    Q_INVOKABLE static QString arToString(const MediaUtils::AspectRatio ar)
    {
        QString str = "";

        if (ar == AspectRatio_1_1)
            str = "1:1";
        else if (ar == AspectRatio_4_3)
            str = "4:3";
        else if (ar == AspectRatio_3_2)
            str = "3:2";
        else if (ar == AspectRatio_16_9)
            str = "16:9";
        else if (ar == AspectRatio_2_1)
            str = "2:1";
        else if (ar == AspectRatio_21_9)
            str = "21:9";
        else if (ar == AspectRatio_3_4)
            str = "3:4";
        else if (ar == AspectRatio_2_3)
            str = "2:3";
        else if (ar == AspectRatio_9_16)
            str = "9:16";
        else if (ar == AspectRatio_1_2)
            str = "1:2";
        else if (ar == AspectRatio_9_21)
            str = "9:21";
        else
        {
            qWarning() << "arToString() missing enum for value:" << ar;
        }

        return str;
    }

    Q_INVOKABLE static float arToFloat(const MediaUtils::AspectRatio ar)
    {
        float flt = 16.f / 9.f;

        if (ar == AspectRatio_auto || ar == AspectRatio_custom)
            flt = 1.f;
        else if (ar == AspectRatio_1_1)
            flt = 1.f;
        else if (ar == AspectRatio_4_3)
            flt = 4.f / 3.f;
        else if (ar == AspectRatio_3_2)
            flt = 3.f / 2.f;
        else if (ar == AspectRatio_16_9)
            flt = 16.f / 9.f;
        else if (ar == AspectRatio_2_1)
            flt = 2.f / 1.f;
        else if (ar == AspectRatio_21_9)
            flt = 21.f / 9.f;
        else if (ar == AspectRatio_3_4)
            flt = 3.f / 4.f;
        else if (ar == AspectRatio_2_3)
            flt = 2.f / 3.f;
        else if (ar == AspectRatio_9_16)
            flt = 9.f / 16.f;
        else if (ar == AspectRatio_1_2)
            flt = 1.f / 2.f;
        else if (ar == AspectRatio_9_21)
            flt = 9.f / 21.f;
        else
        {
            qWarning() << "arToFloat() missing enum for value:" << ar;
        }

        return flt;
    }

    Q_INVOKABLE static int stringToAr(const QString str)
    {
        int ar = AspectRatio_16_9;

        if (str == "1:1")
            ar = AspectRatio_1_1;
        else if (str == "4:3")
            ar = AspectRatio_4_3;
        else if (str == "3:2")
            ar = AspectRatio_3_2;
        else if (str == "16:9")
            ar = AspectRatio_16_9;
        else if (str == "2:1")
            ar = AspectRatio_2_1;
        else if (str == "21:9")
            ar = AspectRatio_21_9;
        else if (str == "3:4")
            ar = AspectRatio_3_4;
        else if (str == "2:3")
            ar = AspectRatio_2_3;
        else if (str == "9:16")
            ar = AspectRatio_9_16;
        else if (str == "1:2")
            ar = AspectRatio_1_2;
        else if (str == "9:21")
            ar = AspectRatio_9_21;
        else
        {
            qWarning() << "stringToAr() missing enum for value:" << str;
        }

        return ar;
    }
};

/* ************************************************************************** */
#endif // MEDIA_UTILS_H
