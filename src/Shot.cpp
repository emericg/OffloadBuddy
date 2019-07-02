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

#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES
#endif
#include <cmath>

#include "Shot.h"
#include "GpmfTags.h"
#include "utils_maths.h"

#include <QDir>
#include <QUrl>
#include <QUuid>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QImageReader>
#include <QDesktopServices>
#include <QDebug>

/* ************************************************************************** */

Shot::Shot(QObject *parent) : QObject(parent)
{
    m_uuid = QUuid::createUuid().toString();
}

Shot::Shot(Shared::ShotType type, QObject *parent) : QObject(parent)
{
    m_uuid = QUuid::createUuid().toString();
    m_type = type;
}

Shot::~Shot()
{
    for (auto picture: m_pictures)
    {
        if (picture->ed)
            exif_data_unref(picture->ed);
    }
    qDeleteAll(m_pictures);
    m_pictures.clear();

    for (auto video: m_videos)
    {
        if (video->media)
            minivideo_close(&video->media);
    }
    qDeleteAll(m_videos);
    m_videos.clear();

    qDeleteAll(m_videos_previews);
    m_videos_previews.clear();

    qDeleteAll(m_videos_thumbnails);
    m_videos_thumbnails.clear();

    qDeleteAll(m_videos_hdAudio);
    m_videos_hdAudio.clear();
}

/* ************************************************************************** */
/* ************************************************************************** */

void Shot::addFile(ofb_file *file)
{
    if (file)
    {
        // TODO // File already in the list?

        // FUSION hack // "first file" is actually not the first file
        if (file->name.startsWith("GPFR") || file->name.startsWith("GPBK"))
        {
            m_shot_name = file->name;
            if (file->creation_date.isValid())
                m_date_file = file->creation_date;
            else
                m_date_file = file->modification_date;

            if (file->extension == "jpg" || file->extension == "jpeg" ||
                file->extension == "png" ||
                file->extension == "gpr")
            {
                m_pictures.push_front(file);
                getMetadatasFromPicture();
            }
            else if (file->extension == "mp4" || file->extension == "m4v" ||
                     file->extension == "mov" ||
                     file->extension == "mkv" || file->extension == "webm")
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
            if (m_shot_name.isEmpty())
                m_shot_name = file->name;

            if (!m_date_file.isValid())
            {
                if (file->creation_date.isValid())
                    m_date_file = file->creation_date;
                else
                    m_date_file = file->modification_date;
            }

            if (file->extension == "jpg" ||
                file->extension == "jpeg" ||
                file->extension == "png" ||
                file->extension == "gpr")
            {
                m_pictures.push_back(file);
                getMetadatasFromPicture();
            }
            else if (file->extension == "mp4" ||
                     file->extension == "m4v" ||
                     file->extension == "mov" ||
                     file->extension == "mkv" ||
                     file->extension == "webm")
            {
                m_videos.push_back(file);
                getMetadatasFromVideo(m_videos.size() - 1);
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

/* ************************************************************************** */
/*
unsigned Shot::getType() const
{
    // FUSION hack
    if (m_type == Shared::SHOT_PICTURE_MULTI && m_jpg.size() == 1)
    {
        m_type = Shared::SHOT_PICTURE;
        emit shotUpdated();
    }
    return m_type;
}
*/
int Shot::getChapterCount() const
{
    return m_videos.size();
}

QDateTime Shot::getDate() const
{
    if (m_date_gps.isValid())
        return m_date_gps;
    if (m_date_metadatas.isValid())
        return m_date_metadatas;

    return m_date_file;
}
QDateTime Shot::getDateFile() const
{
    return m_date_file;
}
QDateTime Shot::getDateMetadata() const
{
    return m_date_metadatas;
}
QDateTime Shot::getDateGPS() const
{
    return m_date_gps;
}

qint64 Shot::getDuration() const
{
    if (m_type < Shared::SHOT_PICTURE)
        return m_duration;

    return m_pictures.size();
}

qint64 Shot::getSize() const
{
    return getFullSize();
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

/* ************************************************************************** */

QString Shot::getPreviewPhoto() const
{
    if (!m_pictures.empty() && !m_pictures.at(0)->filesystemPath.isEmpty())
    {
        return m_pictures.at(0)->filesystemPath;
    }
    if (!m_videos_thumbnails.empty() && !m_videos_thumbnails.at(0)->filesystemPath.isEmpty())
    {
        return m_videos_thumbnails.at(0)->filesystemPath;
    }

    return QString();
}

QString Shot::getPreviewVideo() const
{
    if (!m_videos.empty() && !m_videos.at(0)->filesystemPath.isEmpty())
    {
        return m_videos.at(0)->filesystemPath;
    }

    return QString();
}

QImage Shot::getPreviewMtp()
{
    QImage img;

#ifdef ENABLE_LIBMTP

    if (!m_videos.empty() || !m_pictures.empty())
    {
        LIBMTP_mtpdevice_t *mtp_device = nullptr;
        unsigned mtp_object_id = 0;
        unsigned char *mtp_buffer = nullptr;
        unsigned mtp_buffer_size = 0;

        if (!m_videos.empty() && m_videos.at(0)->mtpDevice)
        {
            mtp_object_id = m_videos.at(0)->mtpObjectId;
            mtp_device = m_videos.at(0)->mtpDevice;
        }
        else if (!m_pictures.empty() && m_pictures.at(0)->mtpDevice)
        {
            mtp_object_id = m_pictures.at(0)->mtpObjectId;
            mtp_device = m_pictures.at(0)->mtpDevice;
        }
        else
        {
            return img;
        }

        bool status = false;
        int retcode = 0;

        // primary method using LIBMTP_Get_Representative_Sample()
        {
            LIBMTP_filetype_t ft = LIBMTP_FILETYPE_JPEG;
            LIBMTP_filesampledata_t *fsd = nullptr;

            int retcode = LIBMTP_Get_Representative_Sample_Format(mtp_device, ft, &fsd);
            if (retcode == 0 && fsd)
            {
                retcode =  LIBMTP_Get_Representative_Sample(mtp_device, mtp_object_id, fsd);

                if (img.loadFromData((const uchar *)(fsd->data), fsd->size))
                {
                    status = true;
                }

                LIBMTP_destroy_filesampledata_t(fsd);
            }
        }

        // backup method, using LIBMTP_Get_Thumbnail()
        if (!status)
        {
            retcode = LIBMTP_Get_Thumbnail(mtp_device, mtp_object_id,  &mtp_buffer, &mtp_buffer_size);
            if (retcode == 0)
            {
                if (img.loadFromData(mtp_buffer, mtp_buffer_size))
                {
                    status = true;
                }
            }

            free(mtp_buffer);
        }
    }

#endif // ENABLE_LIBMTP

    return img;
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

QStringList Shot::getFilesQStringList() const
{
    QStringList list;

    for (auto f: m_pictures)
        list += f->filesystemPath;
    for (auto f: m_videos)
        list += f->filesystemPath;
    for (auto f: m_videos_previews)
        list += f->filesystemPath;
    for (auto f: m_videos_thumbnails)
        list += f->filesystemPath;
    for (auto f: m_videos_hdAudio)
        list += f->filesystemPath;

    return list;
}

QString & Shot::getFolder()
{
    if (m_folder.isEmpty())
    {
        if (!m_pictures.empty())
        {
            m_folder = m_pictures.at(0)->filesystemPath;
        }
        else if (!m_videos.empty())
        {
            m_folder = m_videos.at(0)->filesystemPath;
        }

        QDir p(m_folder);
        p.cdUp();
        m_folder = p.absolutePath();
    }

    return m_folder;
}

QString Shot::getFilesQString() const
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
    if (list.isEmpty())
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

void Shot::openFolder() const
{
    QString folder;

    if (!m_pictures.empty())
    {
        folder = m_pictures.at(0)->filesystemPath;
    }
    else if (!m_videos.empty())
    {
        folder = m_videos.at(0)->filesystemPath;
    }

    QDir p(folder);
    p.cdUp();
    folder = p.absolutePath();

    QFileInfo d(folder);
    if (!folder.isEmpty() && d.exists())
    {
        //qDebug() << "openFolder:" << folder;
        QDesktopServices::openUrl(QUrl::fromLocalFile(folder));
    }
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

bool Shot::getMetadatasFromPicture(int index)
{
    bool status = false;

    if (m_pictures.empty())
        return false;
    if (m_pictures.at(index)->filesystemPath.isEmpty())
        return false;

#ifdef ENABLE_LIBEXIF

    // Check if the file is already parsed;
    ExifData *ed = m_pictures.at(index)->ed;

     if (!ed)
        ed = exif_data_new_from_file(m_pictures.at(index)->filesystemPath.toLocal8Bit());

    if (ed)
    {
        hasEXIF = true;

        // EXIF ////////////////////////////////////////////////////////////////

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
            //orientation = buf;

            if (strncmp(buf, "Top-left", sizeof(buf)) == 0)
            {
                // TODO
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

        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_DATE_TIME);
        if (entry)
        {
            // ex: DateTime: 2018:08:10 10:37:08
            exif_entry_get_value(entry, buf, sizeof(buf));
            m_date_metadatas = QDateTime::fromString(buf, "yyyy:MM:dd hh:mm:ss");
        }

        QDate gpsDate;
        QTime gpsTime;
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

            if (!gpsTime.isValid())
                gpsTime = QTime::fromString(buf, "hh:mm:ss.z");
        }

        if (gpsDate.isValid() && gpsTime.isValid())
            m_date_gps = QDateTime(gpsDate, gpsTime);

        // GPS infos ///////////////////////////////////////////////////////////////
        if (m_date_gps.isValid())
        {
            hasGPS = true;

            entry = exif_content_get_entry(ed->ifd[EXIF_IFD_GPS],
                                           static_cast<ExifTag>(EXIF_TAG_GPS_LATITUDE));
            if (entry)
            {
                // ex: "45, 41, 24,5662800"
                exif_entry_get_value(entry, buf, sizeof(buf));
                QString str = buf;
                double deg = str.midRef(0, 2).toDouble();
                double min = str.midRef(4, 2).toDouble();
                double sec = str.mid(8, 10).replace(',', '.').toDouble();
                gps_lat = deg + min/60.0 + sec/3600.0;
                gps_lat_str = str.mid(0, 2) + "° " + str.mid(4, 2) + "` " + str.mid(8, 8) + "``";

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
                double deg = str.midRef(0, 2).toDouble();
                double min = str.midRef(4, 2).toDouble();
                double sec = str.mid(8, 10).replace(',', '.').toDouble();
                gps_long = deg + min/60.0 + sec/3600.0;
                gps_long_str = str.mid(0, 2) + "° " + str.mid(4, 2) + "` " + str.mid(8, 8) + "``";

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
            qDebug() << "gps_timestamp:" << m_date_gps;
*/
        }

        // MAKERNOTE ///////////////////////////////////////////////////////////////
        ExifMnoteData *mn = exif_data_get_mnote_data(ed);
        if (mn)
        {
            //qDebug() << "WE HAVE MAKERNOTEs";
        }

        exif_data_unref(ed);

        status = true;
    }
    else
    {
        //qWarning() << "File not readable or no EXIF data in file";
    }
#endif // ENABLE_LIBEXIF

    // Gather additional infos
    QImageReader img_infos(m_pictures.at(index)->filesystemPath);
    if (img_infos.canRead())
    {
        //qDebug() << "Backup path with QImageReader";

        vcodec = img_infos.format();
        width = img_infos.size().rwidth();
        height = img_infos.size().rheight();
        orientation = img_infos.transformation();

        status = true;
    }

    return status;
}

bool Shot::getMetadatasFromVideo(int index)
{
    //qDebug() << "Shot::getMetadatasFromVideoGPMF(" << index << " " << m_videos.at(index)->filesystemPath;

    if (m_videos.empty())
        return false;
    if (m_videos.at(index)->filesystemPath.isEmpty())
        return false;

#ifdef ENABLE_MINIVIDEO

    // Check if the file is already parsed
    if (!m_videos.at(index)->media)
    {
        // If not, open it
        int minivideo_retcode = minivideo_open(m_videos.at(index)->filesystemPath.toLocal8Bit(), &m_videos.at(index)->media);
        if (minivideo_retcode == 1)
        {
            minivideo_retcode = minivideo_parse(m_videos.at(index)->media, true, false);
            if (minivideo_retcode != 1)
            {
                qDebug() << "minivideo_parse() failed with retcode: " << minivideo_retcode;
                minivideo_close(&m_videos.at(index)->media);
            }
        }
        else
        {
            qDebug() << "minivideo_open() failed with retcode: " << minivideo_retcode;
            qDebug() << "minivideo_open() cannot open: " << m_videos.at(index)->filesystemPath;
            qDebug() << "minivideo_open() cannot open: " << m_videos.at(index)->filesystemPath.toLocal8Bit();
        }
    }

    MediaFile_t *media = m_videos.at(index)->media;
    if (media)
    {
        m_date_metadatas = QDateTime::fromTime_t(media->creation_time);

        if (media->tracks_audio_count > 0)
        {
            acodec = QString::fromLocal8Bit(getCodecString(stream_AUDIO, media->tracks_audio[0]->stream_codec, false));
            achannels = media->tracks_audio[0]->channel_count;
            asamplerate = media->tracks_audio[0]->sampling_rate;
            abitrate = media->tracks_audio[0]->bitrate_avg;
        }
        if (media->tracks_video_count > 0)
        {
            width = media->tracks_video[0]->width;
            height = media->tracks_video[0]->height;
            m_duration += media->tracks_video[0]->stream_duration_ms;

            vcodec = QString::fromLocal8Bit(getCodecString(stream_VIDEO, media->tracks_video[0]->stream_codec, false));
            framerate = media->tracks_video[0]->framerate;
            bitrate = media->tracks_video[0]->bitrate_avg;
        }
        for (unsigned i = 0; i < media->tracks_others_count; i++)
        {
            if (media->tracks_others[i])
            {
                MediaStream_t *t = media->tracks_others[i];

                if (t->stream_type == stream_TMCD && timecode.isEmpty())
                {
                    timecode += QString("%1:%2:%3-%4")\
                                    .arg(t->time_reference[0], 2, 'u', 0, '0')\
                                    .arg(t->time_reference[1], 2, 'u', 0, '0')\
                                    .arg(t->time_reference[2], 2, 'u', 0, '0')\
                                    .arg(t->time_reference[3], 2, 'u', 0, '0');
                }
                else if (t->stream_fcc == fourcc_be("gpmd"))
                {
                    MediaStream_t *t = media->tracks_others[i];

                    uint32_t gpmf_sample_count = t->sample_count;
                    int devc_count = 0;

                    if (devc_count)
                        hasGPMF = true;

                    // Now the purpose of the following code is to get accurate
                    // date from the GPS, but in case of chaptered videos, we may
                    // have that date already, so don't run this code twice
                    if (!m_date_gps.isValid())
                    {
                        for (unsigned sp_index = 0; sp_index < gpmf_sample_count; sp_index++)
                        {
                            MediaSample_t *sp = minivideo_get_sample(media, t, sp_index);

                            GpmfBuffer buf;
                            if (buf.loadBuffer(sp->data, sp->size))
                            {
                                if (parseGpmfSampleFast(buf, devc_count))
                                {
                                    // we have GPS datetime
                                    minivideo_destroy_sample(&sp);
                                    break;
                                }
                            }

                            minivideo_destroy_sample(&sp);
                        }
                    }
                }
            }
        }

        return true;
    }

#endif // ENABLE_MINIVIDEO

    return false;
}

bool Shot::getMetadatasFromVideoGPMF()
{
    //qDebug() << "Shot::getMetadatasFromVideoGPMF()";

    if (gpmf_parsed)
        return true;

    if (m_videos.empty())
        return false;

#ifdef ENABLE_MINIVIDEO

    for (auto video : m_videos)
    {
        gpmf_parsed = true;

        // OPEN MEDIA //////////////////////////////////////////////////////////

        // Check if the file is already parsed;
        if (!video->media)
        {
            // If not, open it
            int minivideo_retcode = minivideo_open(video->filesystemPath.toLocal8Bit(), &video->media);
            if (minivideo_retcode == 1)
            {
                minivideo_retcode = minivideo_parse(video->media, true, false);
                if (minivideo_retcode != 1)
                {
                    qDebug() << "minivideo_parse() failed with retcode: " << minivideo_retcode;
                    minivideo_close(&video->media);
                }
            }
            else
            {
                qDebug() << "minivideo_open() failed with retcode: " << minivideo_retcode;
            }
        }

        // PARSE METADATAS /////////////////////////////////////////////////////

        MediaFile_t *media = video->media;
        if (media)
        {
            for (unsigned i = 0; i < media->tracks_others_count; i++)
            {
                if (media->tracks_others[i] && media->tracks_others[i]->stream_fcc == fourcc_be("gpmd"))
                {
                    MediaStream_t *t = media->tracks_others[i];

                    bool status = false;
                    unsigned gpmf_sample_count = t->sample_count;
                    int devc_count = 0;

                    for (unsigned sp_index = 0; sp_index < gpmf_sample_count; sp_index++)
                    {
                        // Get GPMF sample from MP4
                        MediaSample_t *sp = minivideo_get_sample(media, t, sp_index);

                        // Load that sample into a GpmfBuffer
                        GpmfBuffer buf;
                        status = buf.loadBuffer(sp->data, sp->size);
                        if (!status)
                        {
                            qWarning() << "buf.loadBuffer(#" << sp_index << ") FAILED";
                            minivideo_destroy_sample(&sp);
                            return false; // FIXME
                        }

                        // Parse GPMF datas
                        status = parseGpmfSample(buf, devc_count);
                        if (!status)
                        {
                            qWarning() << "parseGpmfSample(#" << sp_index << ") FAILED";
                            minivideo_destroy_sample(&sp);
                            return false; // FIXME
                        }
                        else
                            hasGPMF = true;

                        minivideo_destroy_sample(&sp);
                    }

                    //
                    if (global_offset_ms == 0 && !m_gps.empty())
                    {
                        gps_lat = m_gps.at(m_gps.size() / 2).first;
                        gps_long = m_gps.at(m_gps.size() / 2).second;
                        gps_alt = m_alti.at(m_alti.size() / 2);
                        //QDateTime gps_ts; // TODO
                    }

                    // update time offset
                    global_offset_ms += t->stream_duration_ms;

                    //qDebug() << "GPMF SAMPLES:" << m_gps.size();
                }
            }
        }
    }

    emit shotUpdated();
    emit metadatasUpdated();

    return true;

#endif // ENABLE_MINIVIDEO

    return false;
}

/* ************************************************************************** */
/* ************************************************************************** */
