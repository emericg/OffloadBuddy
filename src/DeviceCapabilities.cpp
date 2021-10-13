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

#include "DeviceCapabilities.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/* ************************************************************************** */

DeviceCapabilities::DeviceCapabilities(QObject *parent) : QObject(parent)
{
    //
}

DeviceCapabilities::~DeviceCapabilities()
{
    qDeleteAll(m_modes_video_table);
    m_modes_video_table.clear();
}

/* ************************************************************************** */

bool DeviceCapabilities::load(const QString &brand, const QString &model)
{
    //qDebug() << "DeviceCapabilities::load(" << brand << "/" << model << ")";
    bool status = false;

    QFile file;
    if (brand == "GoPro")
        file.setFileName(":/cameras/gopro_devices.json");
    else if (brand == "Insta360")
        file.setFileName(":/cameras/insta360_devices.json");

    if (file.open(QIODevice::ReadOnly))
    {
        QJsonDocument capsDoc = QJsonDocument().fromJson(file.readAll());
        QJsonObject capsObject = capsDoc.object();
        QJsonArray cameraArray = capsObject["cameras"].toArray();
        file.close();

        foreach (const QJsonValue &value, cameraArray)
        {
            QJsonObject obj = value.toObject();
            if (brand == obj["brand"].toString() && model == obj["model"].toString())
            {
                m_year =  obj["year"].toInt();

                foreach (const QJsonValue &vv, obj["codecs"].toArray())
                {
                    m_codecs << vv.toString();
                }
                foreach (const QJsonValue &vv, obj["features"].toArray())
                {
                    m_features << vv.toString();
                }
                foreach (const QJsonValue &vv, obj["connectivity"].toArray())
                {
                    m_connectivity << vv.toString();
                }
                foreach (const QJsonValue &vv, obj["modes_video"].toArray())
                {
                    m_modes_video << vv.toString();
                }
                foreach (const QJsonValue &vv, obj["modes_photo"].toArray())
                {
                    m_modes_photo << vv.toString();
                }
                foreach (const QJsonValue &vv, obj["modes_timelapse"].toArray())
                {
                    m_modes_timelapse << vv.toString();
                }

                foreach (const QJsonValue &vv, obj["modes_video_table"].toArray())
                {
                    QJsonArray vvv = vv.toArray();
                    if (vvv.size() == 6)
                    {
                        GridMode *gm = new GridMode(vvv.at(0).toString(),
                                                    vvv.at(1).toString(),
                                                    vvv.at(2).toString(),
                                                    vvv.at(3).toString(),
                                                    vvv.at(4).toInt(),
                                                    vvv.at(5).toString(),
                                                    this);
                        m_modes_video_table.push_back(gm);
                    }
                }

                status = true;
                break;
            }
        }
    }

    return status;
}

/* ************************************************************************** */
