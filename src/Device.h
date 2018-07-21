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

#ifndef DEVICE_H
#define DEVICE_H
/* ************************************************************************** */

#include "Shot.h"

#include <QObject>
#include <QVariant>
#include <QList>

#include <QStorageInfo>
#include <QTimer>

/* ************************************************************************** */

typedef struct gopro_version_11
{
    //QString info_version;         // ex: "1.1",
    QString firmware_version;       // ex: "HD3.03.02.39"
    QString wifi_version;           // ex: "3.4.2.9"
    QString wifi_bootloader_version;// ex: "0.2.2"
    QString wifi_mac;               // ex: "d89685292066"
    QString camera_type;            // ex: "Hero3-Black Edition"

} gopro_version_11;

typedef struct gopro_version_20
{
    //QString info_version;         // ex: "2.0",
    QString firmware_version;       // ex: "HD6.01.02.01.00"
    QString wifi_mac;               // ex: "0441693db024"
    QString camera_type;            // ex: "HERO6 Black"
    QString camera_serial_number;   // ex: "C3221324521518"

} gopro_version_20;

typedef enum device_e
{
    DEVICE_UNKNOWN = 0,

    DEVICE_COMPUTER = 1,

    DEVICE_GOPRO = 128,
        DEVICE_HERO2,
        DEVICE_HERO3_WHITE,
        DEVICE_HERO3_SILVER,
        DEVICE_HERO3_BLACK,
        DEVICE_HERO3p_WHITE,
        DEVICE_HERO3p_SILVER,
        DEVICE_HERO3p_BLACK,
        DEVICE_HERO,
        DEVICE_HEROp,
        DEVICE_HEROpLCD,
        DEVICE_HERO4_SILVER,
        DEVICE_HERO4_BLACK,
        DEVICE_HERO4_SESSION,
        DEVICE_HERO5_SESSION,
        DEVICE_HERO5_WHITE,
        DEVICE_HERO5_BLACK,
        DEVICE_HERO6_BLACK,
        DEVICE_HERO7_BLACK,
        DEVICE_FUSION,

    DEVICE_SONY = 256,
        DEVICE_HDR_AS300R,
        DEVICE_FDR_X1000VR,
        DEVICE_FDR_X3000R,

    DEVICE_GARMIN = 270,
        DEVICE_VIRB_ELITE,
        DEVICE_VIRB_X,
        DEVICE_VIRB_XE,
        DEVICE_VIRB_ULTRA30,
        DEVICE_VIRB_360,

    DEVICE_OLYMPUS = 280,
        DEVICE_TG_TRACKER,

    DEVICE_CONTOUR = 290,
        DEVICE_CONTOUR_ROAM3,
        DEVICE_CONTOUR_ROAM1600,
        DEVICE_CONTOUR_4K,

    DEVICE_YI = 300,
        DEVICE_YI_DISCOVERY_4K,
        DEVICE_YI_LITE,
        DEVICE_YI_4K,
        DEVICE_YI_4Kp,

} device_e;

/* ************************************************************************** */

/*!
 * \brief The Device class
 */
class Device: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString brand READ getBrand NOTIFY deviceUpdated)
    Q_PROPERTY(QString model READ getModel NOTIFY deviceUpdated)
    Q_PROPERTY(QString serial READ getSerial NOTIFY deviceUpdated)
    Q_PROPERTY(QString firmware READ getFirmware NOTIFY deviceUpdated)
    //Q_PROPERTY(int directoryContent READ getContent NOTIFY deviceUpdated)
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableUpdated)

    Q_PROPERTY(qint64 spaceTotal READ getSpaceTotal NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed NOTIFY spaceUpdated)
    Q_PROPERTY(double spaceUsedPercent READ getSpaceUsed_percent NOTIFY spaceUpdated)
    Q_PROPERTY(qint64 spaceAvailable READ getSpaceAvailable NOTIFY spaceUpdated)

    //Q_PROPERTY(QVariant shotsList READ getShots NOTIFY shotsUpdated)
    Q_PROPERTY(ShotModel* shotModel READ getShotModel NOTIFY shotsUpdated)

    // Generic
    QString m_brand;
    QString m_model;
    QString m_serial;
    QString m_firmware;

    // GoPro
    QString m_wifi_mac;

    // Filesystem
    QString m_root_path;
    QStorageInfo *m_storage = nullptr;
    bool m_available = false;
    QTimer m_updateTimer;

    // Files and shots
    //QList <QString> m_files;
    //QList <QObject *> m_shots;
    ShotModel *m_shotModel = nullptr;

    Shot *findShot(Shared::ShotType type, int file_id) const;

Q_SIGNALS:
    void scanningStarted();
    void scanningFinished();
    void deviceUpdated();
    void shotsUpdated();
    void availableUpdated();
    void spaceUpdated();

public:
    Device();
    Device(const QString path, const gopro_version_20 *infos = nullptr);
    ~Device();

    bool isValid();
    bool scanFiles();
    bool scanFilesFinished();

public slots:
    QString getBrand() const { return m_brand; }
    QString getModel() const { return m_model; }
    QString getSerial() const { return m_serial; }
    QString getFirmware() const { return m_firmware; }

    //QVariant getShots() const { return QVariant::fromValue(m_shots); }
    ShotModel *getShotModel() const { return m_shotModel; }

    bool isAvailable();

    QString getRootPath() const;

    int64_t getSpaceTotal();
    int64_t getSpaceUsed();
    double getSpaceUsed_percent();
    int64_t getSpaceAvailable();
    int64_t getSpaceAvailable_withrefresh();

private slots:
    void refreshDevice();
};

/* ************************************************************************** */
#endif // DEVICE_H
