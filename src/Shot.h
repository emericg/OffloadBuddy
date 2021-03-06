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

#ifndef SHOT_H
#define SHOT_H
/* ************************************************************************** */

#include "utils/utils_enums.h"

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
#include "GpmfKLV.h"
#include "GpmfBuffer.h"
#endif

#include <QObject>
#include <QDateTime>
#include <QAbstractListModel>

#include <QGeoCoordinate>
#include <QtCharts/QLineSeries>

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
    QString directory;              //!< Directory, if available

#ifdef ENABLE_LIBMTP
    LIBMTP_mtpdevice_t *mtpDevice = nullptr;
    uint32_t mtpObjectId = 0;
#endif

    // Metadata
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

/* ************************************************************************** */

class ShotFile: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString path READ getPath NOTIFY fileUpdated)
    Q_PROPERTY(QString directory READ getDirectory NOTIFY fileUpdated)
    Q_PROPERTY(QString name READ getName NOTIFY fileUpdated)
    Q_PROPERTY(QString ext READ getExt NOTIFY fileUpdated)
    Q_PROPERTY(unsigned type READ getType NOTIFY fileUpdated)
    Q_PROPERTY(qint64 size READ getSize NOTIFY fileUpdated)
    Q_PROPERTY(qint64 width READ getWidth NOTIFY fileUpdated)
    Q_PROPERTY(qint64 height READ getHeight NOTIFY fileUpdated)

    QString path;                   //!< Full path
    QString directory;              //!< Directory, no name or extension or anything
    QString name;                   //!< File base name only, no extension
    QString extension;              //!< Extension only, lowercase, no dot or anything

    unsigned type = 0;              //!<
    qint64 size = 0;                //!< Size in bytes
    unsigned width = 0;
    unsigned height = 0;

Q_SIGNALS:
    void fileUpdated();

public:
    ShotFile(ofb_file *f)
    {
        if (f)
        {
            path = f->filesystemPath;
            directory = f->directory;
            name = f->name;
            extension = f->extension;

            type = 0;
            size = f->size;
            if (f->media && f->media->tracks_video[0])
            {
                type = 1;
                width = f->media->tracks_video[0]->width;
                height = f->media->tracks_video[0]->height;
            }
            else
            {
                if (f->ed)
                    type = 2;
                else if (extension == "jpg" || extension == "jpeg" ||
                         extension == "png" || extension == "gpr")
                    type = 2;
                else if (extension == "gpx" || extension == "json")
                    type = 3;
            }
        }
    }
    ~ShotFile() = default;

    QString getPath() const { return path; }
    QString getDirectory() const { return directory; }
    QString getName() const { return name; }
    QString getExt() const { return extension; }
    unsigned getType() const { return type; }
    qint64 getSize() const { return size; }
    unsigned getWidth() const { return width; }
    unsigned getHeight() const { return height; }
};

/* ************************************************************************** */

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
    Q_PROPERTY(QString folder READ getFolderString NOTIFY shotUpdated)

    Q_PROPERTY(QString name READ getName NOTIFY shotUpdated)
    Q_PROPERTY(QString camera READ getCameraSource NOTIFY shotUpdated)
    Q_PROPERTY(qint64 size READ getSize NOTIFY shotUpdated)
    Q_PROPERTY(qint64 datasize READ getDataSize NOTIFY shotUpdated)

    Q_PROPERTY(QString previewPhoto READ getPreviewPhoto NOTIFY shotUpdated)
    Q_PROPERTY(QString previewVideo READ getPreviewVideo NOTIFY shotUpdated)
    Q_PROPERTY(QImage previewMtp READ getPreviewMtp NOTIFY shotUpdated)
    Q_PROPERTY(QStringList previewTimelapse READ getPreviewPhotos NOTIFY shotUpdated)

    Q_PROPERTY(unsigned chapterCount READ getChapterCount NOTIFY shotUpdated)
    Q_PROPERTY(QStringList chapterPaths READ getChapterPaths NOTIFY shotUpdated)
    Q_PROPERTY(QVariant chapterDurations READ getChapterDurations NOTIFY shotUpdated)

    Q_PROPERTY(unsigned fileCount READ getFileCount NOTIFY shotUpdated)
    Q_PROPERTY(QString filesString READ getFilesString NOTIFY shotUpdated)
    Q_PROPERTY(QStringList filesList READ getFilesStringList NOTIFY shotUpdated)
    Q_PROPERTY(QVariant filesShot READ getShotFiles NOTIFY shotUpdated)

    Q_PROPERTY(qint64 duration READ getDuration NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime date READ getDate NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime dateFile READ getDateFile NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime dateMetadata READ getDateMetadata NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime dateGPS READ getDateGPS NOTIFY shotUpdated)

    Q_PROPERTY(unsigned width READ getWidth NOTIFY shotUpdated)
    Q_PROPERTY(unsigned height READ getHeight NOTIFY shotUpdated)
    Q_PROPERTY(unsigned transformation READ getTransformation NOTIFY shotUpdated)
    Q_PROPERTY(int rotation READ getRotation NOTIFY shotUpdated)

    Q_PROPERTY(QString codecImage READ getCodecImage NOTIFY shotUpdated)
    Q_PROPERTY(QString iso READ getIso NOTIFY shotUpdated)
    Q_PROPERTY(QString focal READ getFocal NOTIFY shotUpdated)
    Q_PROPERTY(QString exposureTime READ getExposureTime NOTIFY shotUpdated)
    Q_PROPERTY(QString meteringMode READ getMeteringMode NOTIFY shotUpdated)
    Q_PROPERTY(bool flash READ getFlash NOTIFY shotUpdated)

    Q_PROPERTY(QString codecVideo READ getCodecVideo NOTIFY shotUpdated)
    Q_PROPERTY(double framerate READ getFramerate NOTIFY shotUpdated)
    Q_PROPERTY(unsigned bitrate READ getBitrate NOTIFY shotUpdated)
    Q_PROPERTY(QString timecode READ getTimecode NOTIFY shotUpdated)

    Q_PROPERTY(QString audioCodec READ getAudioCodec NOTIFY shotUpdated)
    Q_PROPERTY(unsigned audioChannels READ getAudioChannels NOTIFY shotUpdated)
    Q_PROPERTY(unsigned audioBitrate READ getAudioBitrate NOTIFY shotUpdated)
    Q_PROPERTY(unsigned audioSamplerate READ getAudioSamplerate NOTIFY shotUpdated)

    Q_PROPERTY(unsigned hilightCount READ getHiLightCount NOTIFY shotUpdated)
    Q_PROPERTY(QVariant hilight READ getHiLights NOTIFY shotUpdated)

    Q_PROPERTY(unsigned protune READ getProtune NOTIFY shotUpdated)
    Q_PROPERTY(unsigned cam_raw READ getCamRaw NOTIFY shotUpdated)
    Q_PROPERTY(unsigned broadcast_range READ getLowlight NOTIFY shotUpdated)
    Q_PROPERTY(unsigned lens_type READ getLensType NOTIFY shotUpdated)
    Q_PROPERTY(unsigned video_mode_fov READ getVideoModeFov NOTIFY shotUpdated)
    Q_PROPERTY(unsigned lowlight READ getLowlight NOTIFY shotUpdated)
    Q_PROPERTY(unsigned superview READ getSuperview NOTIFY shotUpdated)
    Q_PROPERTY(unsigned sharpening READ getSharpening NOTIFY shotUpdated)
    Q_PROPERTY(bool eis READ getEIS NOTIFY shotUpdated)
    Q_PROPERTY(unsigned media_type READ getMediaType NOTIFY shotUpdated)
    Q_PROPERTY(QString media_type_str READ getMediaTypeString NOTIFY shotUpdated)

    Q_PROPERTY(QString latitudeString READ getLatitudeStr NOTIFY metadataUpdated)
    Q_PROPERTY(QString longitudeString READ getLongitudeStr NOTIFY metadataUpdated)
    Q_PROPERTY(QString altitudeString READ getAltitudeStr NOTIFY metadataUpdated)
    Q_PROPERTY(double latitude READ getLatitude NOTIFY metadataUpdated)
    Q_PROPERTY(double longitude READ getLongitude NOTIFY metadataUpdated)
    Q_PROPERTY(double altitude READ getAltitude NOTIFY metadataUpdated)
    Q_PROPERTY(double altitudeOffset READ getAltitudeOffset NOTIFY metadataUpdated)

    Q_PROPERTY(bool selected READ isSelected WRITE setSelected NOTIFY selectionUpdated)
    bool selected = false;
    bool isSelected() const { return selected; }
    void setSelected(bool value) { selected = value; Q_EMIT selectionUpdated(); }

    QString m_uuid;                 //!< Shot unique identifier, generated at object creation

    Shared::ShotType m_type = Shared::SHOT_UNKNOWN;
    Shared::ShotState m_state = Shared::SHOT_STATE_DEFAULT;

    QString m_shot_name;
    int m_shot_id = -1;             //!< Shot ID (if we have a shot, not a single file)
    int m_camera_id = 0;            //!< Camera ID (if the shot is part of a multi camera system)

    //
    QString m_camera_source;        //!< Model of the camera that produced the shot
    QString m_camera_firmware;      //!< Firmware of the camera that produced the shot

    qint64 m_duration = 0;          //!< Duration (in ms for video, in pictures for pic or timelpase)

    // Root folder containing all of the shot files
    QString m_folder;

    // PICTURES files
    QList <ofb_file *> m_pictures;

    // VIDEOS files
    QList <ofb_file *> m_videos;
    QList <ofb_file *> m_videos_previews;
    QList <ofb_file *> m_videos_thumbnails;
    QList <ofb_file *> m_videos_hdAudio;

    // OTHER files?
    QList <ofb_file *> m_others;

    // QML facing structure
    QList <ShotFile *> m_shotfiles;

    // Dates
    QDateTime m_date_file;          //!< File creation
    QDateTime m_date_file_m;        //!< File modification
    QDateTime m_date_metadata;
    QDateTime m_date_gps;
    QDateTime m_date_user;          //!< Set by the user

    // GLOBAL metadata
    unsigned width = 0;
    unsigned height = 0;
    unsigned bpp = 0;
    bool alpha = false;
    unsigned projection = 0;
    unsigned transformation = 0;    //!< QImageIOHandler::Transformation
    int rotation = 0;

    // GPS "quick" metadata (from EXIF or first GPMF sample)
    QString gps_lat_str;
    QString gps_long_str;
    QString gps_alt_str;
    QString gps_alt_egm96_str;
    double gps_lat = 0.0;
    double gps_long = 0.0;
    double gps_alt = 0.0;
    double gps_alt_egm96 = 0.0;

    // PICTURES metadata
    QString icodec;
    QString focal;
    QString iso;
    QString exposure_time;
    QString metering_mode;
    bool flash = false;

    // VIDEO metadata
    QString vcodec;
    QString timecode;
    double framerate = 0.0;
    unsigned bitrate = 0;

    // AUDIO metadata
    QString acodec;
    unsigned achannels = 0;
    unsigned abitrate = 0;
    unsigned asamplerate = 0;

    // GoPro shot metadata
    unsigned protune = 0;
    unsigned cam_raw = 0;
    unsigned broadcast_range;
    unsigned video_mode_fov;
    unsigned lens_type;
    unsigned lowlight = 0;
    unsigned superview = 0;
    unsigned sharpening;
    bool eis = 0;
    unsigned media_type = 0;
    QList <int64_t> m_hilight;

    bool getMetadataFromPicture(int index = 0);
    bool getMetadataFromVideo(int index = 0);




    /// > GPMF WIP /////////////////////////

    typedef struct TriFloat {
        float x;
        float y;
        float z;
    } TriFloat;

    bool gpmf_parsed = false;

    uint32_t global_offset_ms = 0;

    std::vector <std::pair<float, float>> m_gps;
    std::vector <std::pair<std::string, unsigned>> m_gps_params;
    float m_gps_altitude_offset = 0;
    std::vector <float> m_alti;
    std::vector <float> m_speed;

    std::vector <TriFloat> m_gyro;
    std::vector <TriFloat> m_accl;
    std::vector <TriFloat> m_magn;
    std::vector <float> m_compass;

    bool parseGpmfSample(GpmfBuffer &buf, int &devc_count);
    bool parseGpmfSampleFast(GpmfBuffer &buf, int &devc_count);
    void parseData_gps5(GpmfBuffer &buf, GpmfKLV &klv, const float scales[16],
                        std::string &gps_tmcd, unsigned gps_fix, unsigned gps_dop);
    void parseData_triplet(GpmfBuffer &buf, GpmfKLV &klv, const float scales[16],
                           std::vector <TriFloat> &datalist);

    bool hasGoProMetadata = false;
    bool hasGPMetadata() { return hasGoProMetadata; }
    Q_PROPERTY(bool hasGoProMetadata READ hasGPMetadata NOTIFY metadataUpdated)

    bool hasEXIF = false;
    bool hasExif() { return hasEXIF; }
    Q_PROPERTY(bool hasEXIF READ hasExif NOTIFY metadataUpdated)

    bool hasGPS = false;
    bool hasGps() { return hasGPS; }
    Q_PROPERTY(bool hasGPS READ hasGps NOTIFY metadataUpdated)

    bool hasGPMF = false;
    bool hasGpmf() { return hasGPMF; }
    Q_PROPERTY(bool hasGPMF READ hasGpmf NOTIFY metadataUpdated)

    float minAlti;
    float maxAlti;
    float avgAlti;
    float getMinAlti() { return minAlti; }
    float getMaxAlti() { return maxAlti; }
    float getAvgAlti() { return avgAlti; }
    Q_PROPERTY(float minAlti READ getMinAlti NOTIFY metadataUpdated)
    Q_PROPERTY(float maxAlti READ getMaxAlti NOTIFY metadataUpdated)
    Q_PROPERTY(float avgAlti READ getAvgAlti NOTIFY metadataUpdated)

    float minSpeed;
    float maxSpeed;
    float avgSpeed;
    float getMinSpeed() { return minSpeed; }
    float getMaxSpeed() { return maxSpeed; }
    float getAvgSpeed() { return avgSpeed; }
    Q_PROPERTY(float minSpeed READ getMinSpeed NOTIFY metadataUpdated)
    Q_PROPERTY(float maxSpeed READ getMaxSpeed NOTIFY metadataUpdated)
    Q_PROPERTY(float avgSpeed READ getAvgSpeed NOTIFY metadataUpdated)

    float maxG = 1;
    float getMaxG() { return maxG; }
    Q_PROPERTY(float maxG READ getMaxG NOTIFY metadataUpdated)

    float distance_km = 0;
    float getDistanceKm() { return distance_km; }
    Q_PROPERTY(float distanceKm READ getDistanceKm NOTIFY metadataUpdated)

public slots:
    Q_INVOKABLE bool getMetadataFromVideoGPMF();
    Q_INVOKABLE void updateSpeedsSerie(QtCharts::QLineSeries *serie, int appUnit);
    Q_INVOKABLE void updateAltiSerie(QtCharts::QLineSeries *serie, int appUnit);
    Q_INVOKABLE void updateAcclSeries(QtCharts::QLineSeries *x, QtCharts::QLineSeries *y, QtCharts::QLineSeries *z);
    Q_INVOKABLE void updateGyroSeries(QtCharts::QLineSeries *x, QtCharts::QLineSeries *y, QtCharts::QLineSeries *z);
    Q_INVOKABLE QGeoCoordinate getGpsCoordinates(unsigned index);

    Q_INVOKABLE bool exportTelemetry(const QString &path, int format, int accl_frequency, int gps_frequency, bool egm96_correction);
    Q_INVOKABLE bool exportGps(const QString &path, int format, int gps_frequency, bool egm96_correction);

    /// < GPMF WIP /////////////////////////



Q_SIGNALS:
    void shotUpdated();
    void stateUpdated();
    void selectionUpdated();
    void metadataUpdated();
    void dataUpdated();

public:
    Shot(QObject *parent = nullptr);
    Shot(Shared::ShotType type, QObject *parent = nullptr);
    ~Shot();

    void addFile(ofb_file *file);

    QList <ofb_file *> getFiles(bool withPreviews = true, bool withHdAudio = true) const;

public:
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

    Q_INVOKABLE bool isValid() const;

    QString &getFolderRefString();
    QString getFolderString();
    QString getFilesString() const;
    QStringList getFilesStringList() const;
    QVariant getShotFiles();

    QString getUuid() const { return m_uuid; }

    QString getName() const { return m_shot_name; }
    qint64 getDuration() const;
    qint64 getSize() const;
    qint64 getDataSize() const;
    qint64 getFullSize() const;
    int getChapterCount() const;    //!< 0 means no notion of chapter
    int getFileCount();
    QDateTime getDate() const;
    QDateTime getDateFile() const;
    QDateTime getDateMetadata() const;
    QDateTime getDateGPS() const;
    QString getPreviewPhoto() const;
    QStringList getPreviewPhotos() const;
    QString getPreviewVideo() const;
    QStringList getChapterPaths() const;
    QVariant getChapterDurations() const;
    QImage getPreviewMtp();
    QString getCameraSource() const { return m_camera_source; }

    unsigned getWidth() const { return width; }
    unsigned getHeight() const { return height; }
    unsigned getTransformation() const { return transformation; }
    int getRotation() const { return rotation; }

    QString getCodecImage() const { return icodec; }
    QString getIso() const { return iso; }
    QString getFocal() const { return focal; }
    QString getExposureTime() const { return exposure_time; }
    QString getMeteringMode() const { return metering_mode; }
    bool getFlash() const { return flash; }

    QString getCodecVideo() const { return vcodec; }
    QString getTimecode() const { return timecode; }
    double getFramerate() const { return framerate; }
    unsigned getBitrate() const { return bitrate; }

    QString getAudioCodec() const { return acodec; }
    unsigned getAudioChannels() const { return achannels; }
    unsigned getAudioBitrate() const { return abitrate; }
    unsigned getAudioSamplerate() const { return asamplerate; }

    unsigned getProtune() const { return protune; }
    unsigned getCamRaw() const { return cam_raw; }
    unsigned getBroadcastRange() const { return broadcast_range; }
    unsigned getVideoModeFov() const { return video_mode_fov; }
    unsigned getLensType() const { return lens_type; }
    unsigned getLowlight() const { return lowlight; }
    unsigned getSuperview() const { return superview; }
    unsigned getSharpening() const { return sharpening; }
    bool getEIS() const { return eis; }
    unsigned getMediaType() const { return media_type; }
    QString getMediaTypeString() const {
        if (media_type == 12) return "video";
        else return QString::number(media_type);
    }

    QString getLatitudeStr() const { return gps_lat_str; }
    QString getLongitudeStr() const { return gps_long_str; }
    QString getAltitudeStr() const { return gps_alt_str; }
    double getLatitude() const { return gps_lat; }
    double getLongitude() const { return gps_long; }
    double getAltitude() const { return gps_alt; }
    double getAltitudeOffset() const { return m_gps_altitude_offset; }

    unsigned getHiLightCount() const { return m_hilight.size(); }
    QVariant getHiLights() const { if (m_hilight.size() > 0) { return QVariant::fromValue(m_hilight); } return QVariant(); }

    Q_INVOKABLE unsigned getGpsPointCount() const { return m_gps.size(); }

    int getFileId() const { return m_shot_id; }
    void setFileId(int id) { m_shot_id = id; }
    int getCameraId() const { return m_camera_id; }
    void setCameraId(int id) { m_camera_id = id; }

    Q_INVOKABLE void openFile() const;
    Q_INVOKABLE void openFolder() const;
};

/* ************************************************************************** */
#endif // SHOT_H
