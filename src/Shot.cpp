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

#include "Shot.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

#include <QDebug>

#ifdef ENABLE_LIBEXIF
#include <libexif/exif-data.h>
#endif

#ifdef ENABLE_MINIVIDEO
#include <minivideo.h>
#endif

/* ************************************************************************** */

Shot::Shot(QObject *parent) : QObject(parent)
{
    //
}

Shot::Shot(Shared::ShotType type, QObject *parent) : QObject(parent)
{
    m_type = type;
}

Shot::~Shot()
{
    qDeleteAll(m_pictures);
    m_pictures.clear();

    qDeleteAll(m_videos);
    m_videos.clear();
    qDeleteAll(m_videos_previews);
    m_videos_previews.clear();
    qDeleteAll(m_videos_thumbnails);
    m_videos_thumbnails.clear();
    qDeleteAll(m_videos_hdAudio);
    m_videos_hdAudio.clear();
}

Shot::Shot(const Shot &other) : QObject()
{
    m_onCamera = other.m_onCamera;

    m_type = other.m_type;
    m_camera_source = other.m_camera_source;
    m_camera_id = other.m_camera_id;
    m_shot_id = other.m_shot_id;

    m_name = other.m_name;
    m_date = other.m_date;
    m_duration = other.m_duration;
    m_highlights = other.m_highlights;

    m_pictures = other.m_pictures;

    m_videos = other.m_videos;
    m_videos_previews = other.m_videos_previews;
    m_videos_thumbnails = other.m_videos_thumbnails;
    m_videos_hdAudio = other.m_videos_hdAudio;
}

/* ************************************************************************** */

void Shot::addFile(ofb_file *file)
{
    if (file)
    {
        // Fusion "first file" hack...
        if (file->name.startsWith("GPFR") || file->name.startsWith("GPBK"))
        {
            m_name = file->name;
            if (file->creation_date.isValid())
                m_date = file->creation_date;
            else
                m_date = file->modification_date;

            if (file->extension == "jpg")
            {
                m_pictures.push_front(file);
                getMetadatasFromPicture();
            }
            else if (file->extension == "mp4")
            {
                m_videos.push_front(file);
                getMetadatasFromVideo();
            }
            else if (file->extension == "lrv")
            {
                m_videos_previews.push_front(file);
            }
            else if (file->extension == "thm")
            {
                m_videos_thumbnails.push_front(file);
            }
            else if (file->extension == "wav")
            {
                m_videos_hdAudio.push_front(file);
            }
            else
            {
                qWarning() << "Shot::addFile(" << file->extension << ") UNKNOWN FORMAT";
            }
        }
        else
        {
            if (m_name.isEmpty())
                m_name = file->name;

            if (!m_date.isValid())
            {
                if (file->creation_date.isValid())
                    m_date = file->creation_date;
                else
                    m_date = file->modification_date;
            }

            if (file->extension == "jpg")
            {
                m_pictures.push_back(file);
                getMetadatasFromPicture();
            }
            else if (file->extension == "mp4")
            {
                m_videos.push_back(file);
                getMetadatasFromVideo();
            }
            else if (file->extension == "lrv")
            {
                m_videos_previews.push_back(file);
            }
            else if (file->extension == "thm")
            {
                m_videos_thumbnails.push_back(file);
            }
            else if (file->extension == "wav")
            {
                m_videos_hdAudio.push_back(file);
            }
            else
            {
                qWarning() << "Shot::addFile(" << file->extension << ") UNKNOWN FORMAT";
            }
        }
    }
    else
    {
        qWarning() << "Shot::addFile(" << file << ") nullptr";
    }
}

#ifdef ENABLE_LIBMTP
void Shot::attachMtpStorage(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage)
{
    m_mtpDevice = device;
    m_mtpStorage = storage;
}
#endif

/* ************************************************************************** */

bool Shot::isValid()
{
    if (m_pictures.size() > 0 || m_videos.size() > 0)
        return true;

    return false;
}
/*
unsigned Shot::getType() const
{
    // Fusion hack:
    if (m_type == Shared::SHOT_PICTURE_MULTI && m_jpg.size() == 1)
    {
        m_type = Shared::SHOT_PICTURE;
        emit shotUpdated();
    }
    return m_type;
}
*/
qint64 Shot::getSize() const
{
    return getFullSize();
}

int Shot::getChapterCount() const
{
    return m_videos.size();
}

qint64 Shot::getFullSize() const
{
    qint64 size = 0;

    for (auto f: m_pictures)
    {
        size += f->size;
    }
    for (auto f: m_videos)
    {
        size += f->size;
    }
    for (auto f: m_videos_thumbnails)
    {
        size += f->size;
    }
    for (auto f: m_videos_hdAudio)
    {
        size += f->size;
    }
    for (auto f: m_videos_previews)
    {
        size += f->size;
    }

    return size;
}

qint64 Shot::getDataSize() const
{
    qint64 size = 0;

    for (auto f: m_pictures)
    {
        size += f->size;
    }
    for (auto f: m_videos)
    {
        size += f->size;
    }

    return size;
}

QString Shot::getPreview() const
{
    if (m_pictures.size() > 0 && !m_pictures.at(0)->filesystemPath.isEmpty())
    {
        return m_pictures.at(0)->filesystemPath;
    }
    else if (m_videos_thumbnails.size() > 0 && !m_videos_thumbnails.at(0)->filesystemPath.isEmpty())
    {
        return m_videos_thumbnails.at(0)->filesystemPath;
    }

    return QString();
}

qint64 Shot::getDuration() const
{
    if (m_type < Shared::SHOT_PICTURE)
        return m_duration;
    else
        return m_pictures.count();
}

/* ************************************************************************** */

QList <ofb_file *> Shot::getFiles(bool withPreviews, bool withHdAudio) const
{
    QList <ofb_file *> list;

    for (auto f: m_pictures)
        list += f;
    for (auto f: m_videos)
        list += f;

    if (withPreviews)
    {
        for (auto f: m_videos_previews)
            list += f;
        for (auto f: m_videos_thumbnails)
            list += f;
    }
    if (withHdAudio)
    {
        for (auto f: m_videos_hdAudio)
        list += f;
    }

    return list;
}
/*
QStringList Shot::getFilePaths() const
{
    QStringList list;

    for (auto f: m_jpg)
        list += f->filesystemPath;
    for (auto f: m_mp4)
        list += f->filesystemPath;
    for (auto f: m_thm)
        list += f->filesystemPath;
    for (auto f: m_wav)
        list += f->filesystemPath;
    for (auto f: m_lrv)
        list += f->filesystemPath;

    return list;
}

QList<uint32_t> Shot::getFileObjects(LIBMTP_mtpdevice_t **mtpDevice) const
{
    QList<uint32_t> list;

    if (m_jpg.size() > 0)
        *mtpDevice = m_jpg.at(0)->mtpDevice;
    else if (m_mp4.size() > 0)
        *mtpDevice = m_mp4.at(0)->mtpDevice;

    for (auto f: m_jpg)
        list += f->mtpObjectId;
    for (auto f: m_mp4)
        list += f->mtpObjectId;
    for (auto f: m_thm)
        list += f->mtpObjectId;
    for (auto f: m_wav)
        list += f->mtpObjectId;
    for (auto f: m_lrv)
        list += f->mtpObjectId;

    return list;
}
*/
QString Shot::getFileList() const
{
    QString list;

    for (auto f: m_pictures)
        list += "- " + f->filesystemPath + "\n";
    for (auto f: m_videos)
        list += "- " + f->filesystemPath + "\n";
    for (auto f: m_videos_previews)
        list += "- " + f->filesystemPath + "\n";
    for (auto f: m_videos_thumbnails)
        list += "- " + f->filesystemPath + "\n";
    for (auto f: m_videos_hdAudio)
        list += "- " + f->filesystemPath + "\n";

#ifdef ENABLE_LIBMTP
    {
        for (auto f: m_pictures)
            list += "- " + f->name + "." + f->extension + "\n";
        for (auto f: m_videos)
            list += "- " + f->name + "." + f->extension + "\n";
        for (auto f: m_videos_previews)
            list += "- " + f->name + "." + f->extension + "\n";
        for (auto f: m_videos_thumbnails)
            list += "- " + f->name + "." + f->extension + "\n";
        for (auto f: m_videos_hdAudio)
            list += "- " + f->name + "." + f->extension + "\n";
    }
#endif // ENABLE_LIBMTP

    return list;
}
/* ************************************************************************** */
/* ************************************************************************** */

#ifdef ENABLE_LIBEXIF
static void show_tag(ExifData *d, ExifIfd ifd, ExifTag tag)
{
    ExifEntry *entry = exif_content_get_entry(d->ifd[ifd],tag);
    if (entry)
    {
        char buf[1024];
        exif_entry_get_value(entry, buf, sizeof(buf));
        if (*buf)
            qDebug() << exif_tag_get_name_in_ifd(tag,ifd) << ": " << buf;
    }
}
#endif // ENABLE_LIBEXIF

bool Shot::getMetadatasFromPicture()
{
    if (m_pictures.size() <= 0)
        return false;
    if (m_pictures.at(0)->filesystemPath.isEmpty())
        return  false;

#ifdef ENABLE_LIBEXIF

    // EXIF ////////////////////////////////////////////////////////////////////
    ExifData *ed = exif_data_new_from_file(m_pictures.at(0)->filesystemPath.toLatin1());
    if (!ed)
    {
        qWarning() << "File not readable or no EXIF data in file";
        return false;
    }

    // Parse tags
    ExifEntry *entry;
    char buf[1024];

    QString camera_maker;
    QString camera_model;
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_MAKE);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        camera_maker = buf;
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_MODEL);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        camera_model = buf;
    }
    m_camera_source = camera_maker + " " + camera_model;

    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_SOFTWARE);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        m_camera_firmware = buf;
    }

    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_PIXEL_X_DIMENSION);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        width = QString::fromLatin1(buf).toUInt();
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_PIXEL_Y_DIMENSION);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        height = QString::fromLatin1(buf).toUInt();
    }

    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_ORIENTATION);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        orientation = buf;

        if (strncmp(buf, "Top-left", sizeof(buf)) == 0)
        {
            //
        }
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_FNUMBER);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        focal = buf;
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_ISO_SPEED_RATINGS);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        iso = buf;
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_EXPOSURE_TIME);
    if (entry)
    {
        exif_entry_get_value(entry, buf, sizeof(buf));
        esposure_time = buf;
    }

    QDate gpsDate;
    QTime gpsTime;
    QDateTime exif_ts;
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_DATE_TIME);
    if (entry)
    {
        // ex: DateTime: 2018:08:10 10:37:08
        exif_entry_get_value(entry, buf, sizeof(buf));
        exif_ts = QDateTime::fromString(buf, "yyyy:MM:dd hh:mm:ss");
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                   static_cast<ExifTag>(EXIF_TAG_GPS_DATE_STAMP));
    if (entry)
    {
        // ex: GPSDateStamp: 2018:08:10
        exif_entry_get_value(entry, buf, sizeof(buf));
        gpsDate = QDate::fromString(buf, "yyyy:MM:dd");
    }
    entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                   static_cast<ExifTag>(EXIF_TAG_GPS_TIME_STAMP));
    if (entry)
    {
        // ex: GPSTimeStamp: 08:36:14,00
        exif_entry_get_value(entry, buf, sizeof(buf));
        gpsTime = QTime::fromString(buf, "hh:mm:ss,z");
    }
    gps_ts = QDateTime(gpsDate, gpsTime);

/*
    qDebug() << "gps_ts:" << gps_ts;
    qDebug() << "exif_ts:" << exif_ts;
*/

    // GPS infos ///////////////////////////////////////////////////////////////
    if (gps_ts.isValid())
    {
        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                       static_cast<ExifTag>(EXIF_TAG_GPS_LATITUDE));
        if (entry)
        {
            // ex: "45, 41, 24,5662800"
            exif_entry_get_value(entry, buf, sizeof(buf));
            QString str = buf;
            int deg = str.mid(0, 2).toInt();
            int min = str.mid(4, 2).toInt();
            double sec = str.mid(8, 10).toDouble();
            gps_lat = deg + min/60.0 + sec/3600.0;
            gps_lat_str = str.mid(0, 2) + "° " + str.mid(4, 2) + "` " + str.mid(8, 5) + "``";

            entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                           static_cast<ExifTag>(EXIF_TAG_GPS_LATITUDE_REF));
            if (entry)
            {
                exif_entry_get_value(entry, buf, sizeof(buf));
                if (strncmp(buf, "S", 1) == 0)
                    gps_lat = -gps_lat;
                gps_lat_str += " " +  QString::fromLatin1(buf);
            }
        }
        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                       static_cast<ExifTag>(EXIF_TAG_GPS_LONGITUDE));
        if (entry)
        {
            exif_entry_get_value(entry, buf, sizeof(buf));
            QString str = buf;
            int deg = str.mid(0, 2).toInt();
            int min = str.mid(4, 2).toInt();
            double sec = str.mid(8, 10).toDouble();
            gps_long = deg + min/60.0 + sec/3600.0;
            gps_long_str = str.mid(0, 2) + "° " + str.mid(4, 2) + "` " + str.mid(8, 5) + "``";

            entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                           static_cast<ExifTag>(EXIF_TAG_GPS_LONGITUDE_REF));
            if (entry)
            {
                exif_entry_get_value(entry, buf, sizeof(buf));
                if (strncmp(buf, "W", 1) == 0)
                    gps_long = -gps_long;
                gps_long_str += " " + QString::fromLatin1(buf);
            }
        }
        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                       static_cast<ExifTag>(EXIF_TAG_GPS_ALTITUDE));
        if (entry)
        {
            exif_entry_get_value(entry, buf, sizeof(buf));
            QString str = buf;
            str.replace(',', '.');
            gps_alt = str.toDouble();
            gps_alt_str = QString::number(gps_alt, 'g', 3);
            gps_alt_str += " " +  QObject::tr("meters");

            entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                           static_cast<ExifTag>(EXIF_TAG_GPS_ALTITUDE_REF));
            if (entry)
            {
                exif_entry_get_value(entry, buf, sizeof(buf));
                QString gps_alt_ref_qstr = buf;
                if (gps_alt_ref_qstr.contains("below", Qt::CaseInsensitive))
                    gps_alt = -gps_alt;
            }
        }
/*
        qDebug() << "gps_lat_str:" << gps_lat_str;
        qDebug() << "gps_long_str:" << gps_long_str;
        qDebug() << "gps_alt_str:" << gps_alt_str;
        qDebug() << "gps_lat:" << gps_lat;
        qDebug() << "gps_long:" << gps_long;
        qDebug() << "gps_alt:" << gps_alt;
*/
    }

    // MAKERNOTE ///////////////////////////////////////////////////////////////
    ExifMnoteData *mn = exif_data_get_mnote_data(ed);
    if (mn)
    {
        //qDebug() << "WE HAVE MAKERNOTEs";
    }

    // Adjust picture timestamp
    if (gps_ts.isValid())
    {
        m_date = gps_ts;
    }
    else if (exif_ts.isValid())
    {
        m_date = exif_ts;
    }

    exif_data_unref(ed);

    return true;
#endif // ENABLE_LIBEXIF

    return false;
}

bool Shot::getMetadatasFromVideo()
{
    if (m_videos.size() <= 0)
        return false;
    if (m_videos.at(0)->filesystemPath.isEmpty())
        return  false;

#ifdef ENABLE_MINIVIDEO

    // MINIVIDEO ///////////////////////////////////////////////////////////////
    MediaFile_t *media = nullptr;
    int minivideo_retcode = minivideo_open(m_videos.at(0)->filesystemPath.toLocal8Bit(), &media);

    if (minivideo_retcode == 1)
    {
        minivideo_retcode = minivideo_parse(media, false);

        if (minivideo_retcode != 1)
        {
            qDebug() << "minivideo_parse() failed with retcode: " << minivideo_retcode;
        }
        else
        {
            if (media->tracks_audio_count > 0)
            {
                acodec = QString::fromLocal8Bit(getCodecString(stream_AUDIO, media->tracks_audio[0]->stream_codec, false));
            }
            if (media->tracks_video_count > 0)
            {
                width = media->tracks_video[0]->width;
                height = media->tracks_video[0]->height;
                m_duration += media->tracks_video[0]->stream_duration_ms;

                vcodec = QString::fromLocal8Bit(getCodecString(stream_VIDEO, media->tracks_video[0]->stream_codec, false));
                framerate = media->tracks_video[0]->framerate;
                bitrate = media->tracks_video[0]->bitrate_avg;
                //timecode = QString::fromLocal8Bit(media->tracks_video[0]->time_reference);

                //QDateTime vt = QDateTime::fromTime_t(media->creation_time);
                //qDebug() << "media->creation_time:" << vt;
            }
        }

        minivideo_close(&media);
    }
    else
    {
        qDebug() << "minivideo_open() failed with retcode: " << minivideo_retcode;
    }

    return true;
#endif // ENABLE_MINIVIDEO

    return false;
}
