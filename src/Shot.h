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

#ifndef SHOT_H
#define SHOT_H
/* ************************************************************************** */

#include "utils_enums.h"

#include "GpmfKLV.h"
#include "GpmfBuffer.h"

#include "minivideo.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QObject>
#include <QDateTime>
#include <QAbstractListModel>

#include <QGeoCoordinate>
#include <QtCharts/QLineSeries>
QT_CHARTS_USE_NAMESPACE

/* ************************************************************************** */

struct ofb_file
{
    QString name;                   //!< File base name only, no extension
    QString extension;              //!< Extension only, lowercase, no dot or anything

    uint64_t size = 0;              //!< Size in bytes
    QDateTime creation_date;
    QDateTime modification_date;

    QString filesystemPath;         //!< Absolute file path, if available

#ifdef ENABLE_LIBMTP
    LIBMTP_mtpdevice_t *mtpDevice = nullptr;
    uint32_t mtpObjectId = 0;
#endif
};

struct ofb_shot
{
    Shared::ShotType shot_type = Shared::SHOT_UNKNOWN;
    Shared::FileType file_type = Shared::FILE_UNKNOWN;
    int shot_id = -1;
    int camera_id = 0;              //!< for multi camera system

    int file_number = -1;
    int group_number = -1;
};

/*!
 * \brief The Shot class
 */
class Shot: public QObject
{
    Q_OBJECT

    Q_PROPERTY(unsigned state READ getState NOTIFY stateUpdated)

    Q_PROPERTY(unsigned type READ getType NOTIFY shotUpdated)
    //Q_PROPERTY(unsigned subType READ getType NOTIFY shotUpdated)

    Q_PROPERTY(QString name READ getName NOTIFY shotUpdated)
    Q_PROPERTY(QString camera READ getCameraSource NOTIFY shotUpdated)
    Q_PROPERTY(qint64 size READ getSize NOTIFY shotUpdated)
    Q_PROPERTY(qint64 datasize READ getDataSize NOTIFY shotUpdated)
    Q_PROPERTY(int chapters READ getChapterCount NOTIFY shotUpdated)
    Q_PROPERTY(int highlightCount READ getHighlightCount NOTIFY shotUpdated)

    Q_PROPERTY(QString previewPhoto READ getPreviewPhoto NOTIFY shotUpdated)
    Q_PROPERTY(QString previewVideo READ getPreviewVideo NOTIFY shotUpdated)
    Q_PROPERTY(QImage previewMtp READ getPreviewMtp NOTIFY shotUpdated)
    Q_PROPERTY(QString fileList READ getFilesQString NOTIFY shotUpdated)

    Q_PROPERTY(qint64 duration READ getDuration NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime date READ getDate NOTIFY shotUpdated)

    Q_PROPERTY(unsigned width READ getWidth NOTIFY shotUpdated)
    Q_PROPERTY(unsigned height READ getHeight NOTIFY shotUpdated)
    Q_PROPERTY(QString orientation READ getOrientation NOTIFY shotUpdated)

    Q_PROPERTY(QString iso READ getIso NOTIFY shotUpdated)
    Q_PROPERTY(QString focal READ getFocal NOTIFY shotUpdated)
    Q_PROPERTY(QString exposure READ getExposure NOTIFY shotUpdated)

    Q_PROPERTY(QString codecAudio READ getCodecAudio NOTIFY shotUpdated)
    Q_PROPERTY(QString codecVideo READ getCodecVideo NOTIFY shotUpdated)
    Q_PROPERTY(QString timecode READ getTimecode NOTIFY shotUpdated)
    Q_PROPERTY(double framerate READ getFramerate NOTIFY shotUpdated)
    Q_PROPERTY(unsigned bitrate READ getBitrate NOTIFY shotUpdated)

    Q_PROPERTY(QString latitudeString READ getLatitudeStr NOTIFY shotUpdated)
    Q_PROPERTY(QString longitudeString READ getLongitudeStr NOTIFY shotUpdated)
    Q_PROPERTY(QString altitudeString READ getAltitudeStr NOTIFY shotUpdated)
    Q_PROPERTY(double latitude READ getLatitude NOTIFY shotUpdated)
    Q_PROPERTY(double longitude READ getLongitude NOTIFY shotUpdated)
    Q_PROPERTY(double altitude READ getAltitude NOTIFY shotUpdated)

    //Q_PROPERTY(QString gps READ getGPS NOTIFY shotUpdated)

    bool m_onCamera = false; // TODO remove? //!< Shot datas currently located on a device

    Shared::ShotType m_type = Shared::SHOT_UNKNOWN;
    Shared::ShotState m_state = Shared::SHOT_STATE_DEFAULT;
    QString m_camera_source;        //!< Model of the camera that produced the shot
    QString m_camera_firmware;      //!< Firmware of the camera that produced the shot

    int m_shot_id = -1;
    int m_camera_id = 0;            //!< Shot is part of a multi camera systems

    QString m_name;
    QDateTime m_date_file;
    QDateTime m_date_metadatas;
    QDateTime m_date_gps;
    qint64 m_duration = 0;

    QList <QTime> m_highlights;

#ifdef ENABLE_LIBMTP
    // FIXME // remove this?
    LIBMTP_mtpdevice_t *m_mtpDevice = nullptr;
    LIBMTP_devicestorage_t *m_mtpStorage = nullptr;
#endif

    // PICTURES files
    QList <ofb_file *> m_pictures;

    // VIDEOS files
    QList <ofb_file *> m_videos;
    QList <MediaFile_t *> m_minivideos;
    QList <ofb_file *> m_videos_previews;
    QList <ofb_file *> m_videos_thumbnails;
    QList <ofb_file *> m_videos_hdAudio;

    // GLOBAL metadatas
    QString orientation;
    unsigned width = 0;
    unsigned height = 0;

    // GPS metadatas
    QString gps_lat_str;
    QString gps_long_str;
    QString gps_alt_str;
    double gps_lat = 0.0;
    double gps_long = 0.0;
    double gps_alt = 0.0;
    QDateTime gps_ts;

    // PICTURES metadatas
    int quality = 0;
    QString focal;
    QString iso;
    QString esposure_time;

    // VIDEO metadatas
    QString acodec;
    QString vcodec;
    QString timecode;
    double framerate = 0.0;
    unsigned bitrate = 0;

    bool getMetadatasFromPicture(int index = 0);
    bool getMetadatasFromVideo(int index = 0);


    /// GPMF WIP /////////////////////////

    bool gpmf_parsed = false;

    typedef struct TripleDouble {
        double x;
        double y;
        double z;
    } TripleDouble;
    uint32_t global_offset_ms = 0;

    std::vector <std::pair<double, double>> m_gps;
    std::vector <std::pair<std::string, unsigned>> m_gps_params;
    double m_gps_altitude_offset = 0;
    std::vector <double> m_alti;
    std::vector <double> m_speed;
/*
    QVector<QPointF> m_alti_points;
    QVector<QPointF> m_speed_points;
    QVector<QPointF> m_gps_points;
*/
    std::vector <TripleDouble> m_gyro;
    std::vector <TripleDouble> m_accelero;
    std::vector <TripleDouble> m_magneto;
    std::vector <double> m_compass;

    bool parseGpmfSample(GpmfBuffer &buf, int &devc_count);
    void parseData_gps5(GpmfBuffer &buf, GpmfKLV &klv, const double scales[16],
                        std::string &gps_tmcd, unsigned gps_fix, unsigned gps_dop);
    void parseData_triplet(GpmfBuffer &buf, GpmfKLV &klv, const double scales[16],
                           std::vector <TripleDouble> &datalist);

    bool hasEXIF = false;
    bool hasExif() { return hasEXIF; }
    Q_PROPERTY(bool hasEXIF READ hasExif NOTIFY metadatasUpdated)

    bool hasGPS = false;
    bool hasGpsSync() { return hasGPS; }
    Q_PROPERTY(bool hasGPS READ hasGpsSync NOTIFY metadatasUpdated)

    bool hasGPMF = false;
    bool hasGpmf() { return hasGPMF; }
    Q_PROPERTY(bool hasGPMF READ hasGpmf NOTIFY metadatasUpdated)

    float minAlti;
    float maxAlti;
    float avgAlti;
    float getMinAlti() { return minAlti; }
    float getMaxAlti() { return maxAlti; }
    float getAvgAlti() { return avgAlti; }
    Q_PROPERTY(float minAlti READ getMinAlti NOTIFY metadatasUpdated)
    Q_PROPERTY(float maxAlti READ getMaxAlti NOTIFY metadatasUpdated)
    Q_PROPERTY(float avgAlti READ getAvgAlti NOTIFY metadatasUpdated)

    float minSpeed;
    float maxSpeed;
    float avgSpeed;
    float getMinSpeed() { return minSpeed; }
    float getMaxSpeed() { return maxSpeed; }
    float getAvgSpeed() { return avgSpeed; }
    Q_PROPERTY(float minSpeed READ getMinSpeed NOTIFY metadatasUpdated)
    Q_PROPERTY(float maxSpeed READ getMaxSpeed NOTIFY metadatasUpdated)
    Q_PROPERTY(float avgSpeed READ getAvgSpeed NOTIFY metadatasUpdated)

    float maxG = 1;
    float getMaxG() { return maxG; }
    Q_PROPERTY(float maxG READ getMaxG NOTIFY metadatasUpdated)

    double distance_km = 0;
    double getDistanceKm() { return distance_km; }
    Q_PROPERTY(double distanceKm READ getDistanceKm NOTIFY metadatasUpdated)

public slots:
    Q_INVOKABLE bool getMetadatasFromVideoGPMF(int index = 0);
    Q_INVOKABLE void updateSpeedsSerie(QLineSeries *serie, int appUnit);
    Q_INVOKABLE void updateAltiSerie(QLineSeries *serie, int appUnit);
    Q_INVOKABLE void updateAcclSeries(QLineSeries *x, QLineSeries *y, QLineSeries *z);
    Q_INVOKABLE void updateGyroSeries(QLineSeries *x, QLineSeries *y, QLineSeries *z);
    Q_INVOKABLE QGeoCoordinate getGpsCoordinates(unsigned index);

    /// GPMF WIP /////////////////////////


public:
    Shot(QObject *parent = nullptr);
    Shot(Shared::ShotType type, QObject *parent = nullptr);
    ~Shot();

    void addFile(ofb_file *file);
#ifdef ENABLE_LIBMTP
    void attachMtpStorage(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage);
#endif

    QList <ofb_file *> getFiles(bool withPreviews = true, bool withHdAudio = true) const;

public slots:
    unsigned getType() const { return m_type; }
    unsigned getState() const { return m_state; }
    void setState(Shared::ShotState state) { m_state = state; emit stateUpdated(); }

    QString getFilesQString() const;
    QStringList getFilesQStringList() const;

    QString getName() const { return m_name; }
    qint64 getDuration() const;
    qint64 getSize() const;
    qint64 getDataSize() const;
    qint64 getFullSize() const;
    int getChapterCount() const;    //!< 0 means no notion of chapter
    QDateTime getDate() const;
    QString getPreviewPhoto() const;
    QString getPreviewVideo() const;
    QImage getPreviewMtp();
    QString getCameraSource() const { return m_camera_source; }

    QString getOrientation() const { return orientation; }
    int getWidth() const { return width; }
    int getHeight() const { return height; }

    QString getIso() const { return iso; }
    QString getFocal() const { return focal; }
    QString getExposure() const { return esposure_time; }

    QString getCodecAudio() const { return acodec; }
    QString getCodecVideo() const { return vcodec; }
    QString getTimecode() const { return timecode; }
    double getFramerate() const { return framerate; }
    int getBitrate() const { return bitrate; }

    QString getLatitudeStr() const { return gps_lat_str; }
    QString getLongitudeStr() const { return gps_long_str; }
    QString getAltitudeStr() const { return gps_alt_str; }
    double getLatitude() const { return gps_lat; }
    double getLongitude() const { return gps_long; }
    double getAltitude() const { return gps_alt; }

    int getHighlightCount() const { return m_highlights.size(); }

    int getFileId() const { return m_shot_id; }
    void setFileId(int id) { m_shot_id = id; }
    int getCameraId() const { return m_camera_id; }
    void setCameraId(int id) { m_camera_id = id; }

Q_SIGNALS:
    void shotUpdated();
    void stateUpdated();
    void metadatasUpdated();
    void datasUpdated();
};

//Q_DECLARE_METATYPE(Shot*);

/* ************************************************************************** */
#endif // SHOT_H
