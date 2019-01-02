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

#define _USE_MATH_DEFINES
#include <cmath>

#include "Shot.h"
#include "GpmfTags.h"
#include "utils_maths.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDebug>

#ifdef ENABLE_LIBEXIF
#include <libexif/exif-data.h>
#endif

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
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
        // TODO // File already in the list?

        // FUSION hack // "first file" is actually not the first file
        if (file->name.startsWith("GPFR") || file->name.startsWith("GPBK"))
        {
            m_name = file->name;
            if (file->creation_date.isValid())
                m_date = file->creation_date;
            else
                m_date = file->modification_date;

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
            if (m_name.isEmpty())
                m_name = file->name;

            if (!m_date.isValid())
            {
                if (file->creation_date.isValid())
                    m_date = file->creation_date;
                else
                    m_date = file->modification_date;
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

#ifdef ENABLE_LIBMTP
        // Associat mtpDevice
        if (file->mtpDevice && !m_mtpDevice)
        {
            m_mtpDevice = file->mtpDevice;
        }
#endif
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

QString Shot::getPreviewPhoto() const
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

QString Shot::getPreviewVideo() const
{
    if (m_videos.size() > 0 && !m_videos.at(0)->filesystemPath.isEmpty())
    {
        return m_videos.at(0)->filesystemPath;
    }

    return QString();
}

QImage Shot::getPreviewMtp()
{
    QImage img;

#ifdef ENABLE_LIBMTP

    if (m_videos.size() > 0 || m_pictures.size() > 0)
    {
        unsigned mtp_object_id = 0;
        unsigned char *mtp_buffer = nullptr;
        unsigned mtp_buffer_size = 0;

        if (m_videos.size() > 0 && m_videos.at(0)->mtpDevice)
        {
            mtp_object_id = m_videos.at(0)->mtpObjectId;
            m_mtpDevice = m_videos.at(0)->mtpDevice;
        }
        else if (m_pictures.size() > 0 && m_pictures.at(0)->mtpDevice)
        {
            mtp_object_id = m_pictures.at(0)->mtpObjectId;
            m_mtpDevice = m_pictures.at(0)->mtpDevice;
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

            int retcode = LIBMTP_Get_Representative_Sample_Format(m_mtpDevice, ft, &fsd);
            if (retcode == 0 && fsd)
            {
                retcode =  LIBMTP_Get_Representative_Sample(m_mtpDevice, mtp_object_id, fsd);

                if (img.loadFromData((const uchar *)fsd->data, fsd->size))
                {
                    status = true;
                }

                LIBMTP_destroy_filesampledata_t(fsd);
            }
        }

        // backup method, using LIBMTP_Get_Thumbnail()
        if (!status)
        {
            retcode = LIBMTP_Get_Thumbnail(m_mtpDevice, mtp_object_id,  &mtp_buffer, &mtp_buffer_size);
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

#endif

    return img;
}

qint64 Shot::getDuration() const
{
    if (m_type < Shared::SHOT_PICTURE)
        return m_duration;
    else
        return m_pictures.size();
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
    if (m_pictures.size() <= 0)
        return false;
    if (m_pictures.at(index)->filesystemPath.isEmpty())
        return false;

#ifdef ENABLE_LIBEXIF

    // EXIF ////////////////////////////////////////////////////////////////////
    ExifData *ed = exif_data_new_from_file(m_pictures.at(index)->filesystemPath.toLatin1());
    if (!ed)
    {
        //qWarning() << "File not readable or no EXIF data in file";
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
            double deg = str.mid(0, 2).toDouble();
            double min = str.mid(4, 2).toDouble();
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
            double deg = str.mid(0, 2).toDouble();
            double min = str.mid(4, 2).toDouble();
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

bool Shot::getMetadatasFromVideo(int index)
{
    if (m_videos.size() <= 0)
        return false;
    if (m_videos.at(index)->filesystemPath.isEmpty())
        return false;

#ifdef ENABLE_MINIVIDEO

    // MINIVIDEO ///////////////////////////////////////////////////////////////
    MediaFile_t *media = nullptr;
    int minivideo_retcode = minivideo_open(m_videos.at(index)->filesystemPath.toLocal8Bit(), &media);

    if (minivideo_retcode == 1)
    {
        minivideo_retcode = minivideo_parse(media, true, false);

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

                //QDateTime vt = QDateTime::fromTime_t(media->creation_time);
                //qDebug() << "media->creation_time:" << vt;
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
                        bool status = false;
                        uint32_t gpmf_sample_count = t->sample_count;
                        //int64_t trim_in = -1, trim_out = -1;
                        int devc_count = 0;

                        for (int32_t sp_index = 0; sp_index < gpmf_sample_count; sp_index++)
                        {
                            // Get GPMF sample from MP4
                            MediaSample_t *sp = minivideo_get_sample(media, t, sp_index);

                            // Validate timestamp
                            //if ((int64_t)(sp->pts + global_offset_ms) > trim_out)
                            //    return status;
                            //if ((int64_t)(sp->pts + global_offset_ms) >= trim_in)
                            {
                                // Load GPMF datas
                                GpmfBuffer buf;
                                status = buf.loadBuffer(sp->data, sp->size);
                                if (status == false)
                                {
                                    std::cerr << "buf.loadBuffer(#" << sp_index << ") FAILED" << std::endl;
                                    minivideo_destroy_sample(&sp);
                                    return false; // FIXME
                                }

                                // Parse GPMF datas
                                status = parseGpmfSample(buf, devc_count);
                                if (status == false)
                                {
                                    std::cerr << "parseGpmfSample(#" << sp_index << ") FAILED" << std::endl;
                                    minivideo_destroy_sample(&sp);
                                    return false; // FIXME
                                }
                                else
                                    hasGPMF = true;
                            }

                            minivideo_destroy_sample(&sp);
                        }

                        //
                        if (global_offset_ms == 0 && m_gps.size() > 0)
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

/* ************************************************************************** */
/* ************************************************************************** */

bool Shot::parseGpmfSample(GpmfBuffer &buf, int &devc_count)
{
    //std::cout << ">>> parseGpmfSample()" << std::endl;

    bool status = true;

    bool parsing = true;
    GpmfKLV toplevel_klv;

    devc_count = 0;
    double scales[16];
    char stnm[64];
    int e = 0;

    while (parsing == true &&
           buf.getBytesLeft() > 8 &&
           readKLV(toplevel_klv, buf) == 0)
    {
        if (toplevel_klv.fcc == GPMF_TAG_DEVICE)
        {
            devc_count++;

            GpmfKLV sub_key;
            while (parsing == true &&
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
                    for (int sc = 0; sc < 16; sc++)
                        scales[sc] = 1.0;

                    GpmfKLV strm;
                    while (parsing == true &&
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
                                scales[i] = buf.readData_double(strm, e);
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
                                double heading = (std::atan2(m_magneto.back().y,m_magneto.back().x) * 180.0) / M_PI;
                                // Normalize to 0-360
                                if (heading < 0) heading += 360.0;
                                m_compass.push_back(heading);
                            }
                        } break;

                        default:
                            break;
                        }

                        if (buf.gotoIndex(strm.offset_end) == false)
                            parsing = false;
                    }
                }
                break;

                default:
                    break;
                }

                if (buf.gotoIndex(sub_key.offset_end) == false)
                    parsing = false;
            }
        }
        else
        {
            parsing = false;
            status = false;
        }
    }

    return status;
}

/* ************************************************************************** */

void Shot::parseData_gps5(GpmfBuffer &buf, GpmfKLV &klv,
                          const double scales[16],
                          std::string &gps_tmcd, unsigned gps_fix, unsigned gps_dop)
{
    // Validate GPS5 format first
    if (klv.fcc != GPMF_TAG_GPS5 || klv.type != GPMF_TYPE_SIGNED_LONG || klv.structsize != 20)
        return;

    int e = 0;

    std::pair<std::string, double> gps_params;
    gps_params.first = gps_tmcd;
    gps_params.second = gps_fix;
    Q_UNUSED(gps_dop);

    for (uint64_t i = 0; i < klv.repeat; i++)
    {
        std::pair<double, double> gps_coord;
        gps_coord.first = static_cast<double>(buf.read_i32(e)) / scales[0]; // latitude
        gps_coord.second = static_cast<double>(buf.read_i32(e)) / scales[1]; // longitude
        m_gps.push_back(gps_coord);
        m_gps_params.push_back(gps_params);

        if (m_gps.size() == 1)
        {
            m_gps_altitude_offset = 0; // TODO
        }
        m_alti.push_back(static_cast<double>((buf.read_i32(e)) / scales[2]) + m_gps_altitude_offset); // altitude

        buf.read_i32(e); // speed 2D // but we don't care
        m_speed.push_back(static_cast<double>(buf.read_i32(e)) / scales[4]); // speed 3D

        // Compute distance between this point and the previous one
        if (m_gps.size() > 1)
        {
            unsigned previous_point_id = m_gps.size() - 2;

            if (gps_fix >= 2 && m_gps_params.at(previous_point_id).second >= 2)
            {
                hasGPS = true;
                distance_km += haversine_km(gps_coord.first, gps_coord.second,
                                            m_gps.at(previous_point_id).first,
                                            m_gps.at(previous_point_id).second);
            }
        }
    }
}

/* ************************************************************************** */

void Shot::parseData_triplet(GpmfBuffer &buf, GpmfKLV &klv,
                             const double scales[16],
                             std::vector <TripleDouble> &datalist)
{
    int e = 0;
    int datasize = klv.structsize / getGpmfTypeSize((GpmfType_e)klv.type);

    if (klv.type == GPMF_TYPE_NESTED || datasize != 3)
        return;

    for (uint64_t i = 0; i < klv.repeat; i++)
    {
        TripleDouble triplet;

        switch (klv.type)
        {
            case GPMF_TYPE_UNSIGNED_BYTE: {
                triplet.x = static_cast<double>(buf.read_u8(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_u8(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_u8(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_BYTE: {
                triplet.x = static_cast<double>(buf.read_i8(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_i8(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_i8(e)) / scales[2];
            } break;
            case GPMF_TYPE_UNSIGNED_SHORT: {
                triplet.x = static_cast<double>(buf.read_u16(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_u16(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_u16(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_SHORT: {
                triplet.x = static_cast<double>(buf.read_i16(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_i16(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_i16(e)) / scales[2];
            } break;
            case GPMF_TYPE_UNSIGNED_LONG: {
                triplet.x = static_cast<double>(buf.read_u32(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_u32(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_u32(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_LONG: {
                triplet.x = static_cast<double>(buf.read_i32(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_i32(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_i32(e)) / scales[2];
            } break;
            case GPMF_TYPE_UNSIGNED_64BIT: {
                triplet.x = static_cast<double>(buf.read_u64(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_u64(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_u64(e)) / scales[2];
            } break;
            case GPMF_TYPE_SIGNED_64BIT: {
                triplet.x = static_cast<double>(buf.read_i64(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_i64(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_i64(e)) / scales[2];
            } break;
            case GPMF_TYPE_FLOAT: {
                triplet.x = static_cast<double>(buf.read_float(e)) / scales[0];
                triplet.y = static_cast<double>(buf.read_float(e)) / scales[1];
                triplet.z = static_cast<double>(buf.read_float(e)) / scales[2];
            } break;
            case GPMF_TYPE_DOUBLE: {
                triplet.x = buf.read_double(e) / scales[0];
                triplet.y = buf.read_double(e) / scales[1];
                triplet.z = buf.read_double(e) / scales[2];
            } break;
        }

        datalist.push_back(triplet);
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void Shot::updateSpeedsSerie(QLineSeries *serie, int appUnit)
{
    if (serie == nullptr)
        return;

    float current;
    minSpeed = 500000;
    avgSpeed = 0;
    maxSpeed = -500000;

    int speed_sync = 0;

    int id = 0;
    QVector<QPointF> points;
    for (unsigned i = 0; i < m_speed.size(); i++)
    {
        if (m_gps_params.at(i).second >= 3) // we need at the very least2D a  lock for speed
        {
            current = m_speed.at(i);
            avgSpeed += current;
            speed_sync++;

            if (current < minSpeed)
                minSpeed = current;
            else if (current > maxSpeed)
                maxSpeed = current;
        }
        else
            current = 0;

        points.insert(id, QPointF(id, current));
        id++;
    }

    avgSpeed /= speed_sync;

    serie->replace(points);
}

void Shot::updateAltiSerie(QLineSeries *serie, int appUnit)
{
    if (serie == nullptr)
        return;

    float current;
    minAlti = 500000;
    avgAlti = 0;
    maxAlti = -500000;

    int alti_sync = 0;

    int id = 0;
    QVector<QPointF> points;
    for (unsigned i = 0; i < m_alti.size(); i++)
    {
        if (m_gps_params.at(i).second >= 3) // we need at least a 3D lock for altitude
        {
            current = m_alti.at(i);
            avgAlti += current;
            alti_sync++;

            if (current < minAlti)
                minAlti = current;
            else if (current > maxAlti)
                maxAlti = current;
        }
        else
            current = 0;

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
