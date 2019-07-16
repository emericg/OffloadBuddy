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

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#ifdef ENABLE_LIBEXIF
#include <libexif/exif-data.h>
#endif

#ifdef ENABLE_EXIV2
#include <exiv2/exiv2.hpp>
#endif

#ifdef ENABLE_MINIVIDEO
#include <minivideo.h>
#endif
#include "GpmfKLV.h"
#include "GpmfBuffer.h"

#include <QObject>
#include <QDateTime>
#include <QAbstractListModel>

#include <QGeoCoordinate>
#include <QtCharts/QLineSeries>
QT_CHARTS_USE_NAMESPACE

/* ************************************************************************** */

struct ofb_file
{
    // Generic infos
    QString name;                   //!< File base name only, no extension
    QString extension;              //!< Extension only, lowercase, no dot or anything
    uint64_t size = 0;              //!< Size in bytes
    QDateTime creation_date;
    QDateTime modification_date;

    // File
    QString filesystemPath;         //!< Absolute file path, if available

#ifdef ENABLE_LIBMTP
    LIBMTP_mtpdevice_t *mtpDevice = nullptr;
    uint32_t mtpObjectId = 0;
#endif

    // Metadatas
    MediaFile_t *media = nullptr;
    ExifData *ed = nullptr;
};

struct ofb_shot
{
    Shared::ShotType shot_type = Shared::SHOT_UNKNOWN;
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

    Q_PROPERTY(unsigned shotType READ getShotType NOTIFY shotUpdated)
    Q_PROPERTY(unsigned fileType READ getFileType NOTIFY shotUpdated)

    Q_PROPERTY(QString uuid READ getUuid NOTIFY shotUpdated)

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
    Q_PROPERTY(QDateTime dateFile READ getDateFile NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime dateMetadata READ getDateMetadata NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime dateGPS READ getDateGPS NOTIFY shotUpdated)

    Q_PROPERTY(unsigned width READ getWidth NOTIFY shotUpdated)
    Q_PROPERTY(unsigned height READ getHeight NOTIFY shotUpdated)
    Q_PROPERTY(unsigned orientation READ getOrientation NOTIFY shotUpdated)

    Q_PROPERTY(QString iso READ getIso NOTIFY shotUpdated)
    Q_PROPERTY(QString focal READ getFocal NOTIFY shotUpdated)
    Q_PROPERTY(QString exposure READ getExposure NOTIFY shotUpdated)
    Q_PROPERTY(bool flash READ getFlash NOTIFY shotUpdated)

    Q_PROPERTY(QString codecVideo READ getCodecVideo NOTIFY shotUpdated)
    Q_PROPERTY(double framerate READ getFramerate NOTIFY shotUpdated)
    Q_PROPERTY(unsigned bitrate READ getBitrate NOTIFY shotUpdated)
    Q_PROPERTY(QString timecode READ getTimecode NOTIFY shotUpdated)

    Q_PROPERTY(QString audioCodec READ getAudioCodec NOTIFY shotUpdated)
    Q_PROPERTY(unsigned audioChannels READ getAudioChannels NOTIFY shotUpdated)
    Q_PROPERTY(unsigned audioBitrate READ getAudioBitrate NOTIFY shotUpdated)
    Q_PROPERTY(unsigned audioSamplerate READ getAudioSamplerate NOTIFY shotUpdated)

    Q_PROPERTY(QString latitudeString READ getLatitudeStr NOTIFY metadatasUpdated)
    Q_PROPERTY(QString longitudeString READ getLongitudeStr NOTIFY metadatasUpdated)
    Q_PROPERTY(QString altitudeString READ getAltitudeStr NOTIFY metadatasUpdated)
    Q_PROPERTY(double latitude READ getLatitude NOTIFY metadatasUpdated)
    Q_PROPERTY(double longitude READ getLongitude NOTIFY metadatasUpdated)
    Q_PROPERTY(double altitude READ getAltitude NOTIFY metadatasUpdated)

    Shared::ShotType m_type = Shared::SHOT_UNKNOWN;
    Shared::ShotState m_state = Shared::SHOT_STATE_DEFAULT;

    Q_PROPERTY(bool selected READ isSelected WRITE setSelected NOTIFY selectionUpdated)
    bool selected = false;
    bool isSelected() const { return selected; }
    void setSelected(bool value) { selected = value; Q_EMIT selectionUpdated(); }

    QString m_uuid;                 //!< Shot unique identifier, generated at object creation

    QString m_shot_name;
    int m_shot_id = -1;             //!< Shot ID (if we have a shot, not a single file)
    int m_camera_id = 0;            //!< Camera ID (if the shot is part of a multi camera system)

    QString m_folder;

    // PICTURES files
    QList <ofb_file *> m_pictures;

    // VIDEOS files
    QList <ofb_file *> m_videos;
    QList <ofb_file *> m_videos_previews;
    QList <ofb_file *> m_videos_thumbnails;
    QList <ofb_file *> m_videos_hdAudio;





    //
    QString m_camera_source;        //!< Model of the camera that produced the shot
    QString m_camera_firmware;      //!< Firmware of the camera that produced the shot

    QDateTime m_date_file;
    QDateTime m_date_metadatas;
    QDateTime m_date_gps;
    qint64 m_duration = 0;

    // GLOBAL metadatas
    unsigned orientation = 0;
    unsigned width = 0;
    unsigned height = 0;

    // GPS metadatas
    QString gps_lat_str;
    QString gps_long_str;
    QString gps_alt_str;
    double gps_lat = 0.0;
    double gps_long = 0.0;
    double gps_alt = 0.0;

    // PICTURES metadatas
    QString focal;
    QString iso;
    QString esposure_time;
    bool flash = false;

    // VIDEO metadatas
    QString vcodec;
    QString timecode;
    double framerate = 0.0;
    unsigned bitrate = 0;

    QString acodec;
    unsigned achannels = 0;
    unsigned abitrate = 0;
    unsigned asamplerate = 0;

    bool getMetadatasFromPicture(int index = 0);
    bool getMetadatasFromVideo(int index = 0);





    QList <QTime> m_highlights;

    /// GPMF WIP /////////////////////////

    bool gpmf_parsed = false;

    typedef struct TriFloat {
        float x;
        float y;
        float z;
    } TriFloat;
    uint32_t global_offset_ms = 0;

    std::vector <std::pair<float, float>> m_gps;
    std::vector <std::pair<std::string, unsigned>> m_gps_params;
    float m_gps_altitude_offset = 0;
    std::vector <float> m_alti;
    std::vector <float> m_speed;
/*
    QVector<QPointF> m_alti_points;
    QVector<QPointF> m_speed_points;
    QVector<QPointF> m_gps_points;
*/
    std::vector <TriFloat> m_gyro;
    std::vector <TriFloat> m_accelero;
    std::vector <TriFloat> m_magneto;
    std::vector <float> m_compass;

    bool parseGpmfSample(GpmfBuffer &buf, int &devc_count);
    bool parseGpmfSampleFast(GpmfBuffer &buf, int &devc_count);
    void parseData_gps5(GpmfBuffer &buf, GpmfKLV &klv, const float scales[16],
                        std::string &gps_tmcd, unsigned gps_fix, unsigned gps_dop);
    void parseData_triplet(GpmfBuffer &buf, GpmfKLV &klv, const float scales[16],
                           std::vector <TriFloat> &datalist);

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

    float distance_km = 0;
    float getDistanceKm() { return distance_km; }
    Q_PROPERTY(float distanceKm READ getDistanceKm NOTIFY metadatasUpdated)

public slots:
    Q_INVOKABLE bool getMetadatasFromVideoGPMF();
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

    QList <ofb_file *> getFiles(bool withPreviews = true, bool withHdAudio = true) const;

public slots:
    unsigned getShotType() const { return m_type; }
    unsigned getFileType() const {
        if (m_type >= Shared::SHOT_VIDEO && m_type <= Shared::SHOT_VIDEO_3D)
           return Shared::FILE_VIDEO;
        else if (m_type >= Shared::SHOT_PICTURE && m_type <= Shared::SHOT_PICTURE_NIGHTLAPSE)
            return Shared::FILE_PICTURE;

         return Shared::FILE_UNKNOWN;
    }
    unsigned getState() const { return m_state; }
    void setState(Shared::ShotState state) { m_state = state; emit stateUpdated(); }

    QString & getFolder();
    QString getFilesQString() const;
    QStringList getFilesQStringList() const;

    QString getUuid() const { return m_uuid; }

    QString getName() const { return m_shot_name; }
    qint64 getDuration() const;
    qint64 getSize() const;
    qint64 getDataSize() const;
    qint64 getFullSize() const;
    int getChapterCount() const;    //!< 0 means no notion of chapter
    QDateTime getDate() const;
    QDateTime getDateFile() const;
    QDateTime getDateMetadata() const;
    QDateTime getDateGPS() const;
    QString getPreviewPhoto() const;
    QString getPreviewVideo() const;
    QImage getPreviewMtp();
    QString getCameraSource() const { return m_camera_source; }

    unsigned getOrientation() const { return orientation; }
    unsigned getWidth() const { return width; }
    unsigned getHeight() const { return height; }

    QString getIso() const { return iso; }
    QString getFocal() const { return focal; }
    QString getExposure() const { return esposure_time; }
    bool getFlash() const { return flash; }

    QString getCodecVideo() const { return vcodec; }
    QString getTimecode() const { return timecode; }
    double getFramerate() const { return framerate; }
    unsigned getBitrate() const { return bitrate; }

    QString getAudioCodec() const { return acodec; }
    unsigned getAudioChannels() const { return achannels; }
    unsigned getAudioBitrate() const { return abitrate; }
    unsigned getAudioSamplerate() const { return asamplerate; }

    QString getLatitudeStr() const { return gps_lat_str; }
    QString getLongitudeStr() const { return gps_long_str; }
    QString getAltitudeStr() const { return gps_alt_str; }
    double getLatitude() const { return gps_lat; }
    double getLongitude() const { return gps_long; }
    double getAltitude() const { return gps_alt; }

    int getHighlightCount() const { return m_highlights.size(); }
    int getGpsPointCount() const { return m_gps.size(); }

    int getFileId() const { return m_shot_id; }
    void setFileId(int id) { m_shot_id = id; }
    int getCameraId() const { return m_camera_id; }
    void setCameraId(int id) { m_camera_id = id; }

    void openFolder() const;

Q_SIGNALS:
    void shotUpdated();
    void stateUpdated();
    void selectionUpdated();
    void metadatasUpdated();
    void datasUpdated();
};

//Q_DECLARE_METATYPE(Shot*);

/* ************************************************************************** */
#endif // SHOT_H
