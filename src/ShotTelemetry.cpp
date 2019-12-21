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

#include <cmath>

#include "Shot.h"
#include "GpmfTags.h"
#include "utils_maths.h"

#include <QDir>
#include <QUrl>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QImageReader>
#include <QDesktopServices>
#include <QDebug>

/* ************************************************************************** */

bool Shot::parseGpmfSample(GpmfBuffer &buf, int &devc_count)
{
    bool status = true;

    bool parsing = true;
    GpmfKLV toplevel_klv;

    devc_count = 0;
    float scales[16];
    char stnm[64];
    int e = 0;

    while (parsing &&
           buf.getBytesLeft() > 8 &&
           readKLV(toplevel_klv, buf) == 0)
    {
        if (toplevel_klv.fcc == GPMF_TAG_DEVICE)
        {
            devc_count++;

            GpmfKLV sub_key;
            while (parsing &&
                   buf.getBytesLeft() > 8 &&
                   buf.getBytesIndex() < toplevel_klv.offset_end &&
                   readKLV(sub_key, buf) == 0)
            {
                uint32_t gps_fix = 0;
                uint32_t gps_dop = 0;
                std::string gps_tmcd = "000000000000.000";

                switch (sub_key.fcc)
                {
                case GPMF_TAG_STREAM:
                {
                    // ALWAYS reset scales when parsing a new stream
                    for (float &scale: scales)
                        scale = 1.0;

                    GpmfKLV strm;
                    while (parsing &&
                           buf.getBytesLeft() > 8 &&
                           buf.getBytesIndex() < sub_key.offset_end &&
                           readKLV(strm, buf) == 0)
                    {
                        switch (strm.fcc)
                        {
                        case GPMF_TAG_SCALE:
                        {
                            uint64_t i = 0;
                            for (i = 0; i < strm.datacount && i < 16; i++)
                                scales[i] = buf.readData_float(strm, e);
                            for (; i < 16; i++)
                                scales[i] = scales[0];
                        } break;

                        case GPMF_TAG_STREAM_NAME:
                        {
                            uint64_t i = 0;
                            for (i = 0; i < strm.datacount && i < 64; i++)
                                stnm[i] = buf.read_c(e);
                        } break;

                        case GPMF_TAG_GPSF:
                            gps_fix = buf.read_u32(e);
                            break;
                        case GPMF_TAG_GPSP:
                            gps_dop = buf.read_u16(e);
                            break;
                        case GPMF_TAG_GPSU:
                        {
                            // ex: '161222124837.150'
                            char *gpsu = (char *)buf.readBytes(strm.datacount, e);
                            if (gpsu != nullptr)
                            {
                                std::string str(gpsu);
                                gps_tmcd.clear();
                                gps_tmcd += "20" + str.substr(0,2) + "-" + str.substr(2,2) + "-" + str.substr(4,2) + "T";
                                gps_tmcd += str.substr(6,2) + ":" + str.substr(8,2) + ":" + str.substr(10,2) + "Z";
                            }
                        } break;
                        case GPMF_TAG_GPS5:
                            parseData_gps5(buf, strm, scales, gps_tmcd, gps_fix, gps_dop);
                            break;

                        case GPMF_TAG_GYRO:
                            parseData_triplet(buf, strm, scales, m_gyro);
                            break;
                        case GPMF_TAG_ACCL:
                            parseData_triplet(buf, strm, scales, m_accelero);
                            break;
                        case GPMF_TAG_MAGN:
                        {
                            parseData_triplet(buf, strm, scales, m_magneto);

                            // Generate compass data from magnetometer
                            {
                                // Calculate the angle of the vector y,x
                                float heading = (std::atan2(m_magneto.back().y, m_magneto.back().x) * 180.f) / M_PI;
                                // Normalize to 0-360
                                if (heading < 0) heading += 360.f;
                                m_compass.push_back(heading);
                            }
                        } break;

                        default:
                            break;
                        }

                        if (!buf.gotoIndex(strm.offset_end))
                            parsing = false;
                    }
                }
                break;

                default:
                    break;
                }

                if (!buf.gotoIndex(sub_key.offset_end))
                    parsing = false;
            }
        }
        else
        {
            parsing = false;
            status = false;
        }
    }

    if (m_gps.size() > 1)
    {
        // We have a GPS track
        hasGPS = true;
        emit shotUpdated();
    }

    return status;
}

/* ************************************************************************** */

bool Shot::parseGpmfSampleFast(GpmfBuffer &buf, int &devc_count)
{
    bool parsing = true;
    GpmfKLV toplevel_klv;

    devc_count = 0;
    float scales[16];
    char stnm[64];
    int e = 0;

    while (parsing &&
           buf.getBytesLeft() > 8 &&
           readKLV(toplevel_klv, buf) == 0)
    {
        if (toplevel_klv.fcc == GPMF_TAG_DEVICE)
        {
            devc_count++;

            GpmfKLV sub_key;
            while (parsing &&
                   buf.getBytesLeft() > 8 &&
                   buf.getBytesIndex() < toplevel_klv.offset_end &&
                   readKLV(sub_key, buf) == 0)
            {
                uint32_t gps_fix = 0;
                uint32_t gps_dop = 0;
                std::string gps_tmcd = "000000000000.000";

                switch (sub_key.fcc)
                {
                case GPMF_TAG_STREAM:
                {
                    // ALWAYS reset scales when parsing a new stream
                    for (float &scale: scales)
                        scale = 1.0;

                    GpmfKLV strm;
                    while (parsing &&
                           buf.getBytesLeft() > 8 &&
                           buf.getBytesIndex() < sub_key.offset_end &&
                           readKLV(strm, buf) == 0)
                    {
                        switch (strm.fcc)
                        {
                        case GPMF_TAG_SCALE:
                        {
                            uint64_t i = 0;
                            for (i = 0; i < strm.datacount && i < 16; i++)
                                scales[i] = buf.readData_float(strm, e);
                            for (; i < 16; i++)
                                scales[i] = scales[0];
                        } break;

                        case GPMF_TAG_STREAM_NAME:
                        {
                            uint64_t i = 0;
                            for (i = 0; i < strm.datacount && i < 64; i++)
                                stnm[i] = buf.read_c(e);
                        } break;

                        case GPMF_TAG_GPSF:
                            gps_fix = buf.read_u32(e);
                            break;
                        case GPMF_TAG_GPSP:
                            gps_dop = buf.read_u16(e);
                            break;
                        case GPMF_TAG_GPSU:
                        {
                            if (gps_fix > 1)
                            {
                                // ex: '161222124837.150'
                                char *gpsu = (char *)buf.readBytes(strm.datacount, e);
                                if (gpsu != nullptr)
                                {
                                    std::string str(gpsu);
                                    gps_tmcd.clear();
                                    gps_tmcd += "20" + str.substr(0,2) + "-" + str.substr(2,2) + "-" + str.substr(4,2) + "T";
                                    gps_tmcd += str.substr(6,2) + ":" + str.substr(8,2) + ":" + str.substr(10,2) + "Z";
                                }

                                QString dt = QString::fromStdString(gps_tmcd);
                                m_date_gps = QDateTime::fromString(dt, "yyyy-MM-ddThh:mm:ssZ");

                                emit shotUpdated();
                                return true;
                            }
                            break;
                        }
                        case GPMF_TAG_GPS5:
                        {
                            break;
                        }
                        default:
                            break;
                        }

                        if (!buf.gotoIndex(strm.offset_end))
                            parsing = false;
                    }
                }
                break;

                default:
                    break;
                }

                if (!buf.gotoIndex(sub_key.offset_end))
                    parsing = false;
            }
        }
        else
        {
            parsing = false;
        }
    }

    return false;
}

/* ************************************************************************** */

void Shot::parseData_gps5(GpmfBuffer &buf, GpmfKLV &klv,
                          const float scales[16],
                          std::string &gps_tmcd, unsigned gps_fix, unsigned gps_dop)
{
    // Validate GPS5 format first
    if (klv.fcc != GPMF_TAG_GPS5 || klv.type != GPMF_TYPE_SIGNED_LONG || klv.structsize != 20)
        return;

    // We use 3D lock and good DOP only, and even that is shaky at best...
    if (gps_fix < 3 || gps_dop > 500)
        return;

    // Update GPS date?
    if (gps_fix > 1 && !m_date_gps.isValid())
    {
        QString dt = QString::fromStdString(gps_tmcd);
        m_date_gps = QDateTime::fromString(dt, "yyyy-MM-ddThh:mm:ssZ");
        emit shotUpdated();
    }

    // Update altitude offset?
    if (m_gps.size() == 1)
    {
        m_gps_altitude_offset = 0; // TODO
    }

    //qDebug() << "GPS   FIX: " << gps_fix << "  DOP: " << gps_dop;

    std::pair<std::string, float> gps_params;
    gps_params.first = gps_tmcd;
    gps_params.second = gps_fix;

    std::pair<float, float> gps_coord;
    float alti, speed;
    int e = 0;

    for (uint64_t i = 0; i < klv.repeat; i++)
    {
        gps_coord.first = static_cast<float>(buf.read_i32(e)) / scales[0]; // latitude
        gps_coord.second = static_cast<float>(buf.read_i32(e)) / scales[1]; // longitude

        alti = static_cast<float>(buf.read_i32(e)) / scales[2];
        buf.read_i32(e);
        speed = static_cast<float>(buf.read_i32(e)) / scales[4];

        // yes, some points are REALLY messed up...
        // (also, assume no ones goes to space with their camera)
        {
            if ((gps_coord.first < 0.001f && gps_coord.first > -0.001f) ||
                (gps_coord.second < 0.001f && gps_coord.second > -0.001f))
            {
                //qDebug() << "GPS (null coordinates)  lat: " << gps_coord.first << "  long: " << gps_coord.second;
                //qDebug() << "GPS (null coordinates)  FIX: " << gps_fix << "  DOP: " << gps_dop;
                continue;
            }
            if (alti < -150 || alti > 80000 || speed < 0 || speed > 3000)
            {
                //qDebug() << "GPS (bad data)  alti: " << alti << "  speed: " << speed;
                //qDebug() << "GPS (bad data)  FIX: " << gps_fix << "  DOP: " << gps_dop;
                continue;
            }
        }

        m_gps.push_back(gps_coord);
        m_gps_params.emplace_back(gps_params);

        m_alti.push_back(alti + m_gps_altitude_offset);
        m_speed.push_back(speed);

        // Compute distance between this point and the previous one
        if (m_gps.size() > 1)
        {
            unsigned previous_point_id = m_gps.size() - 2;

            // 3D lock REQUIRED
            if (gps_fix > 2 && m_gps_params.at(previous_point_id).second >= 2)
            {
                distance_km += haversine_km(gps_coord.first, gps_coord.second,
                                            m_gps.at(previous_point_id).first,
                                            m_gps.at(previous_point_id).second);
            }
        }
    }
}

/* ************************************************************************** */

void Shot::parseData_triplet(GpmfBuffer &buf, GpmfKLV &klv,
                             const float scales[16],
                             std::vector <TriFloat> &datalist)
{
    int e = 0;
    int datasize = klv.structsize / getGpmfTypeSize(static_cast<GpmfType_e>(klv.type));

    if (klv.type == GPMF_TYPE_NESTED || datasize != 3)
        return;

    for (uint64_t i = 0; i < klv.repeat; i++)
    {
        TriFloat triplet;

        switch (klv.type)
        {
            case GPMF_TYPE_UNSIGNED_BYTE: {
                triplet.x = static_cast<float>(buf.read_u8(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_u8(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_u8(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_BYTE: {
                triplet.x = static_cast<float>(buf.read_i8(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_i8(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_i8(e)) / scales[2];
            } break;
            case GPMF_TYPE_UNSIGNED_SHORT: {
                triplet.x = static_cast<float>(buf.read_u16(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_u16(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_u16(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_SHORT: {
                triplet.x = static_cast<float>(buf.read_i16(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_i16(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_i16(e)) / scales[2];
            } break;
            case GPMF_TYPE_UNSIGNED_LONG: {
                triplet.x = static_cast<float>(buf.read_u32(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_u32(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_u32(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_LONG: {
                triplet.x = static_cast<float>(buf.read_i32(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_i32(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_i32(e)) / scales[2];
            } break;
            case GPMF_TYPE_UNSIGNED_64BIT: {
                triplet.x = static_cast<float>(buf.read_u64(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_u64(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_u64(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_64BIT: {
                triplet.x = static_cast<float>(buf.read_i64(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_i64(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_i64(e)) / scales[2];
            } break;
            case GPMF_TYPE_FLOAT: {
                triplet.x = buf.read_float(e) / scales[0];
                triplet.y = buf.read_float(e) / scales[1];
                triplet.z = buf.read_float(e) / scales[2];
            } break;
            case GPMF_TYPE_DOUBLE: {
                triplet.x = static_cast<float>(buf.read_double(e)) / scales[0];
                triplet.y = static_cast<float>(buf.read_double(e)) / scales[1];
                triplet.z = static_cast<float>(buf.read_double(e)) / scales[2];
            } break;
        }

        datalist.push_back(triplet);
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void Shot::updateSpeedsSerie(QLineSeries *serie, int appUnit)
{
    Q_UNUSED(appUnit)
    if (!serie) return;

    float current;
    minSpeed = 500000;
    avgSpeed = 0;
    maxSpeed = -500000;

    float speed_sync = 0;

    int id = 0;
    QVector<QPointF> points;
    for (unsigned i = 0; i < m_speed.size(); i++)
    {
        current = m_speed.at(i);

        //if (appUnit == 1) // imperial
        //    current /= 1609.344f;

        avgSpeed += current;
        speed_sync++;

        if (current < minSpeed)
            minSpeed = current;
        else if (current > maxSpeed)
            maxSpeed = current;

        points.insert(id, QPointF(id, current));
        id++;
    }

    avgSpeed /= speed_sync;

    serie->replace(points);
}

void Shot::updateAltiSerie(QLineSeries *serie, int appUnit)
{
    Q_UNUSED(appUnit)
    if (!serie) return;

    float current;
    minAlti = 500000;
    avgAlti = 0;
    maxAlti = -500000;

    float alti_sync = 0;

    int id = 0;
    QVector<QPointF> points;
    for (unsigned i = 0; i < m_alti.size(); i++)
    {
        current = m_alti.at(i);

        //if (appUnit == 1) // imperial
        //    current /= 0.3048f;

        avgAlti += current;
        alti_sync++;

        if (current < minAlti)
            minAlti = current;
        else if (current > maxAlti)
            maxAlti = current;

        points.insert(id, QPointF(id, current));
        id++;
    }

    avgAlti /= alti_sync;

    serie->replace(points);
}

void Shot::updateAcclSeries(QLineSeries *x, QLineSeries *y, QLineSeries *z)
{
    if (x == nullptr || y == nullptr || z == nullptr)
        return;

    maxG = 1;
    double currentG = 1;

    QVector<QPointF> pointsX;
    QVector<QPointF> pointsY;
    QVector<QPointF> pointsZ;

    int id = 0;
    for (unsigned i = 0; i < m_accelero.size(); i+=200)
    {
        pointsX.insert(id, QPointF(id, m_accelero.at(i).x));
        pointsY.insert(id, QPointF(id, m_accelero.at(i).y));
        pointsZ.insert(id, QPointF(id, m_accelero.at(i).z));
        id++;

        currentG = sqrt(pow(m_accelero.at(i).x, 2) + pow(m_accelero.at(i).y, 2) + pow(m_accelero.at(i).z, 2));
        if (currentG > maxG)
            maxG = currentG;
    }

    x->replace(pointsX);
    y->replace(pointsY);
    z->replace(pointsZ);
}

void Shot::updateGyroSeries(QLineSeries *x, QLineSeries *y, QLineSeries *z)
{
    if (x == nullptr || y == nullptr || z == nullptr)
        return;

    QVector<QPointF> pointsX;
    QVector<QPointF> pointsY;
    QVector<QPointF> pointsZ;

    int id = 0;
    for (unsigned i = 0; i < m_gyro.size(); i+=200)
    {
        pointsX.insert(id, QPointF(id, m_gyro.at(i).x));
        pointsY.insert(id, QPointF(id, m_gyro.at(i).y));
        pointsZ.insert(id, QPointF(id, m_gyro.at(i).z));
        id++;
    }

    x->replace(pointsX);
    y->replace(pointsY);
    z->replace(pointsZ);
}

QGeoCoordinate Shot::getGpsCoordinates(unsigned index)
{
    QGeoCoordinate c;
    if (index < m_gps.size())
    {
        if (m_gps_params.at(index).second >= 2) // we need at least a 2D lock
        {
            c.setLatitude(m_gps.at(index).first);
            c.setLongitude(m_gps.at(index).second);
        }

        //qDebug() << "GPS (" << index << ")" << m_gps.at(index).first << m_gps.at(index).second;
    }/*
    else // return last point?
    {
        if (m_gps.size() > 0)
        {
            c.setLatitude(m_gps.at(m_gps.size()-1).first);
            c.setLongitude(m_gps.at(m_gps.size()-1).second);
        }
    }*/

    return c;
}
