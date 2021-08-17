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

#ifndef DEVICE_CAPABILITIES_H
#define DEVICE_CAPABILITIES_H
/* ************************************************************************** */

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariant>

/* ************************************************************************** */

class GridMode: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ getName CONSTANT)
    Q_PROPERTY(QString fov READ getFov CONSTANT)
    Q_PROPERTY(QString ratio READ getRatio CONSTANT)
    Q_PROPERTY(QString resolution READ getResolution CONSTANT)
    Q_PROPERTY(int fps READ getFps CONSTANT)
    Q_PROPERTY(QString codec READ getCodec CONSTANT)

    QString m_name;
    QString m_fov;
    QString m_ratio;
    QString m_res;
    int m_fps;
    QString m_codec;

public:
    GridMode(const QString &name, const QString &fov, const QString &ratio,
             const QString &res, int fps, const QString &codec,
             QObject *parent) : QObject(parent) {
        m_name = name;
        m_fov = fov;
        m_ratio = ratio;
        m_res = res;
        m_fps = fps;
        m_codec = codec;
    }
    ~GridMode() = default;

    QString getName() const { return m_name; }
    QString getFov() const { return m_fov; }
    QString getRatio() const { return m_ratio; }
    QString getResolution() const { return m_res; }
    int getFps() const { return m_fps; }
    QString getCodec() const { return m_codec; }
};

/* ************************************************************************** */

class DeviceCapabilities: public QObject
{
    Q_OBJECT

    Q_PROPERTY(int year READ getYear CONSTANT)
    Q_PROPERTY(QStringList codecs READ getCodecs CONSTANT)
    Q_PROPERTY(QStringList features READ getFeatures CONSTANT)
    Q_PROPERTY(QStringList connectivity READ getConnectivity CONSTANT)
    Q_PROPERTY(QStringList modesVideo READ getModesVideo CONSTANT)
    Q_PROPERTY(QStringList modesPhoto READ getModesPhoto CONSTANT)
    Q_PROPERTY(QStringList modesTimelapse READ getModesTimelapse CONSTANT)
    Q_PROPERTY(QVariant modesVideoTable READ getModesVideoTable CONSTANT)

    int m_year = 1234;
    QStringList m_codecs;
    QStringList m_features;
    QStringList m_connectivity;

    QStringList m_modes_video;
    QStringList m_modes_photo;
    QStringList m_modes_timelapse;

    QList <QObject *> m_modes_video_table;

public:
    DeviceCapabilities(QObject *parent);
    ~DeviceCapabilities();

    bool load(const QString &brand, const QString &model);

    int getYear() const { return m_year; }
    QStringList getCodecs() const { return m_codecs; }
    QStringList getFeatures() const { return m_features; }
    QStringList getConnectivity() const { return m_features; }

    QStringList getModesVideo() const { return m_modes_video; }
    QStringList getModesPhoto() const { return m_modes_photo; }
    QStringList getModesTimelapse() const { return m_modes_timelapse; }

    QVariant getModesVideoTable() const { return QVariant::fromValue(m_modes_video_table); }

};

/* ************************************************************************** */
#endif // DEVICE_CAPABILITIES_H
