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

#include <cmath>

#include "Shot.h"
#include "EGM96.h"
#include "GpmfTags.h"
#include "utils/utils_maths.h"

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
                            parseData_triplet(buf, strm, scales, m_accl);
                            break;
                        case GPMF_TAG_MAGN:
                        {
                            parseData_triplet(buf, strm, scales, m_magn);

                            // Generate compass data from magnetometer:
                            {
                                // Calculate the angle of the vector y,x
                                float heading = (std::atan2(m_magn.back().y, m_magn.back().x) * 180.f) / M_PI;
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

        // Update altitude offset?
        if (m_gps.size() < 1/* && gps_fix == 3*/)
        {
            m_gps_altitude_offset = egm96_compute_altitude_offset(gps_coord.first, gps_coord.second);
        }

        m_gps.push_back(gps_coord);
        m_gps_params.emplace_back(gps_params);

        m_alti.push_back(alti - m_gps_altitude_offset);
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
    for (unsigned i = 0; i < m_accl.size(); i+=200)
    {
        pointsX.insert(id, QPointF(id, m_accl.at(i).x));
        pointsY.insert(id, QPointF(id, m_accl.at(i).y));
        pointsZ.insert(id, QPointF(id, m_accl.at(i).z));
        id++;

        currentG = sqrt(pow(m_accl.at(i).x, 2) + pow(m_accl.at(i).y, 2) + pow(m_accl.at(i).z, 2));
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

/* ************************************************************************** */
/* ************************************************************************** */

bool Shot::exportTelemetry(const QString &path, int accl_frequency, int gps_frequency, bool egm96_correction)
{
    //qDebug() << "Shot::exportTelemetry('" << path << "', " << accl_frequency << ", " << gps_frequency << ", " << egm96_correction << ")";
    bool status = false;

    if (hasGPMF && gpmf_parsed)
    {
        QString dirpath = path;
        if (path.isEmpty()) dirpath = getFolderString();
        if (!dirpath.endsWith("/")) dirpath += "/";

        if (accl_frequency < 1) accl_frequency = 1;
        int accl_rate = std::round((m_accl.size() / (m_duration/1000.f)) / accl_frequency);
        if (accl_rate < 1) accl_rate = 1;
        if (accl_rate > 400) accl_rate = 400;

        if (gps_frequency < 1) gps_frequency = 1;
        int gps_rate = std::round((m_gps.size() / (m_duration/1000.f)) / gps_frequency);
        if (gps_rate < 1) gps_rate = 1;
        if (gps_rate > 30) gps_rate = 30;

        // File
        QString exportFilename = dirpath + m_shot_name + ".json";

        QFile::remove(exportFilename);
        QFile exportFile(exportFilename);

        if (exportFile.open(QIODevice::WriteOnly))
        {
            QTextStream exportStream(&exportFile);

            exportStream << "{\n";

            // Timestamp
            exportStream << "\n  \"timestamp\": " << m_date_gps.toString();

            // Accelerometer
            exportStream << "\n  \"accelerometer\": { \"frequency\": " << QString::number(accl_frequency) << QString::fromUtf8(", \"unit\": [\"m/s²\", \"m/s²\", \"m/s²\"], \"data\": [\n  ");
            for (unsigned i = 0; i < m_accl.size(); i += accl_rate) {
                exportStream << "[" << m_accl.at(i).x << "," << m_accl.at(i).y << "," << m_accl.at(i).z << "],";
            } exportStream << "\n  ]},";

            // Gyroscope
            exportStream << "\n  \"gyroscope\": { \"frequency\": " << QString::number(accl_frequency) << ", \"unit\": [\"rad/s\", \"rad/s\", \"rad/s\"], \"data\": [\n  ";
            for (unsigned i = 0; i < m_gyro.size(); i += accl_rate) {
                exportStream << "[" << m_gyro.at(i).x << "," << m_gyro.at(i).y << "," << m_gyro.at(i).z << "],";
            } exportStream << "\n  ]},";

            if (m_magn.size() > 0)
            {
                // Magnetometer
                exportStream << "\n  \"magnetometer\": { \"frequency\": " << QString::number(gps_frequency) << ", \"unit\": [\"μT\", \"μT\", \"μT\"], \"data\": [\n  ";
                for (unsigned i = 0; i < m_magn.size(); i += gps_rate) {
                    exportStream << "[" << m_magn.at(i).x << "," << m_magn.at(i).y << "," << m_magn.at(i).z << "],";
                } exportStream << "\n  ]},";

                // Compass
                exportStream << "\n  \"compass\": { \"frequency\": " << QString::number(gps_frequency) << ", \"unit\": \"degree\", \"data\": [\n  ";
                for (unsigned i = 0; i < m_compass.size(); i += gps_rate) {
                    exportStream << m_compass.at(i) << ",";
                } exportStream << "\n  ]},";
            }

            if (m_gps.size() > 0)
            {
                // GPS
                exportStream << "\n  \"GPS\": { \"frequency\": " << QString::number(gps_frequency) << ", \"unit\": [\"DD, DD\"], \"data\": [\n  ";
                for (unsigned i = 0; i < m_gps.size(); i += gps_rate) {
                    exportStream << "[" << m_gps.at(i).first << "," << m_gps.at(i).second << "],";
                } exportStream << "\n  ]},";

                // Altimeter
                exportStream << "\n  \"altimeter\": { \"frequency\": " << QString::number(gps_frequency) << ", \"unit\": \"m\", \"data\": [\n  ";
                for (unsigned i = 0; i < m_alti.size(); i += gps_rate) {
                    exportStream << m_alti.at(i) << ",";
                } exportStream << "\n  ]},";

                // Speedometer
                exportStream << "\n  \"speedometer\": { \"frequency\": " << QString::number(gps_frequency) << ", \"unit\": \"m/s\", \"data\": [\n  ";
                for (unsigned i = 0; i < m_speed.size(); i += gps_rate) {
                    exportStream << m_speed.at(i) << ",";
                } exportStream << "\n  ]},";
            }

            if (m_hilight.size() > 0)
            {
                // HiLight tags
                exportStream << "\n  \"HiLight tags\": { \"unit\": \"ms\", \"data\": [\n  ";
                for (unsigned i = 0; i < m_hilight.size(); i++) {
                    exportStream << m_hilight.at(i) << ",";
                } exportStream << "\n  ]},";
            }

            exportStream << "\n}\n";

            exportFile.close();
            status = true;
        }
        else
        {
            qWarning() << "Could not create telemetry export file for: '" << exportFilename << "'";
        }
    }

    return status;
}

bool Shot::exportGps(const QString &path, int gps_frequency, bool egm96_correction)
{
    //qDebug() << "Shot::exportGps('" << path << "', " << gps_frequency << ")";
    bool status = false;

    if (hasGPS && gpmf_parsed)
    {
        QString dirpath = path;
        if (path.isEmpty()) dirpath = getFolderString();
        if (!dirpath.endsWith("/")) dirpath += "/";

        if (gps_frequency < 1) gps_frequency = 1;
        int gps_rate = std::round((m_gps.size() / (m_duration/1000.f)) / gps_frequency);
        if (gps_rate < 1) gps_rate = 1;
        if (gps_rate > 30) gps_rate = 30;

        // File
        QString exportFilename = dirpath + m_shot_name + ".gpx";

        QFile::remove(exportFilename);
        QFile exportFile(exportFilename);

        if (exportFile.open(QIODevice::WriteOnly))
        {
            QTextStream exportStream(&exportFile);

            // GPX header
            exportStream << "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\" ?>";

            exportStream << "\n<gpx version=\"1.1\" creator=\"OffloadBuddy - https://github.com/emericg/OffloadBuddy\"";
            exportStream << "\n    xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"";
            exportStream << "\n    xmlns=\"http://www.topografix.com/GPX/1/1\"";
            exportStream << "\n    xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\">";

            exportStream << "\n  <metadata>";
            exportStream << "\n    <name>GPS track extracted from video</name>";
            exportStream << "\n    <link href=\"https://github.com/emericg/OffloadBuddy\"><text>OffloadBuddy</text></link>";
            exportStream << "\n  </metadata>";

            exportStream << "\n<trk>";
            exportStream << "\n  <name>GPS track from video '" << m_shot_name << "'</name>";
            exportStream << "\n  <trkseg>";

            // GPX datas
            for (unsigned i = 0; i < m_gps.size(); i += gps_rate)
            {
                exportStream << "\n  <trkpt lat=\"" + QString::number(m_gps.at(i).first, 'f', 12) +"\" lon=\"" + QString::number(m_gps.at(i).second, 'f', 12) + "\">";

                exportStream << "<ele>" + QString::number(m_alti.at(i), 'f', 1) + "</ele>";
                exportStream << "<time>" + QString::fromStdString(m_gps_params.at(i).first) + "</time>";

                if (m_gps_params.at(i).second == 3) exportStream << "<fix>3d</fix>";
                else if (m_gps_params.at(i).second == 2) exportStream << "<fix>2d</fix>";
                else exportStream << "<fix>none</fix>";

                exportStream << "</trkpt>";
            }

            // GPX footer
            exportStream << "\n  </trkseg>";
            exportStream << "\n</trk>";
            exportStream << "\n</gpx>";
            exportStream << "\n";

            exportFile.close();
            status = true;
        }
        else
        {
            qWarning() << "Could not create GPS export file for: '" << exportFilename << "'";
        }
    }

    return status;
}
