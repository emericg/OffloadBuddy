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

#include "Shot.h"
#include "EGM96.h"
#include "GpmfTags.h"
#include "utils/utils_maths.h"

#include <cmath>

#include <QDir>
#include <QUrl>
#include <QUuid>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QImageReader>
#include <QDesktopServices>
#include <QDebug>

#include <QtCharts>
using namespace QtCharts;

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
    for (auto picture: qAsConst(m_pictures))
    {
        if (picture->ed)
        {
           exif_data_unref(picture->ed);
           picture->ed = nullptr;
        }
    }
    qDeleteAll(m_pictures);
    m_pictures.clear();

    for (auto video: qAsConst(m_videos))
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

    qDeleteAll(m_others);
    m_others.clear();

    qDeleteAll(m_shotfiles);
    m_shotfiles.clear();
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
                file->extension == "png" || file->extension == "gpr" ||
                file->extension == "webp")
            {
                m_pictures.push_front(file);
                getMetadataFromPicture();
            }
            else if (file->extension == "mp4" || file->extension == "m4v" || file->extension == "mov" ||
                     file->extension == "mkv" || file->extension == "webm")
            {
                m_videos.push_front(file);
                getMetadataFromVideo();
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
                //qDebug() << "Shot::addFile(" << file->extension << ") UNKNOWN FORMAT";
                m_others.push_back(file);
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

            if (file->extension == "jpg" || file->extension == "jpeg" ||
                file->extension == "png" || file->extension == "gpr" ||
                file->extension == "webp")
            {
                m_pictures.push_back(file);

                if (m_pictures.size() == 1) getMetadataFromPicture();
            }
            else if (file->extension == "mp4" || file->extension == "m4v" || file->extension == "mov" ||
                     file->extension == "mkv" || file->extension == "webm")
            {
                m_videos.push_back(file);
                getMetadataFromVideo(m_videos.size() - 1);
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
                //qDebug() << "Shot::addFile(" << file->extension << ") UNKNOWN FORMAT";
                m_others.push_back(file);
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
    QDateTime firstpossibledate(QDate(2001, 1, 1), QTime(0, 0));
    if (m_camera_source.contains("HERO4")) firstpossibledate = QDateTime(QDate(2014, 1, 1), QTime(0, 0));
    if (m_camera_source.contains("HERO5")) firstpossibledate = QDateTime(QDate(2016, 1, 1), QTime(0, 0));
    if (m_camera_source.contains("HERO6")) firstpossibledate = QDateTime(QDate(2017, 1, 1), QTime(0, 0));
    if (m_camera_source.contains("HERO7")) firstpossibledate = QDateTime(QDate(2018, 1, 1), QTime(0, 0));
    if (m_camera_source.contains("HERO8")) firstpossibledate = QDateTime(QDate(2019, 1, 1), QTime(0, 0));
    if (m_camera_source.contains("HERO9")) firstpossibledate = QDateTime(QDate(2020, 1, 1), QTime(0, 0));

    if (m_date_gps.isValid())
        return m_date_gps;
    if (m_date_metadata.isValid())
    {
        if (m_date_metadata > firstpossibledate && m_date_metadata < QDateTime::currentDateTime())
            return m_date_metadata;
    }

    return m_date_file;
}
QDateTime Shot::getDateFile() const
{
    return m_date_file;
}
QDateTime Shot::getDateMetadata() const
{
    return m_date_metadata;
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
    for (auto f: m_others)
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

QStringList Shot::getPreviewPhotos() const
{
    QStringList photos;

    if (m_pictures.size() > 1)
    {
        for (auto f: m_pictures) photos.push_back(f->filesystemPath);
    }

    return photos;
}

QString Shot::getPreviewVideo() const
{
    if (!m_videos.empty() && !m_videos.at(0)->filesystemPath.isEmpty())
    {
        return m_videos.at(0)->filesystemPath;
    }

    return QString();
}

QStringList Shot::getChapterPaths() const
{
    QStringList vids;

    if (m_videos.size() > 1)
    {
        for (auto f: m_videos) vids.push_back(f->filesystemPath);
    }

    return vids;
}

QVariant Shot::getChapterDurations() const
{
    QList <qint64> vids;

    if (m_videos.size() > 1)
    {
        for (auto f: m_videos) vids.push_back(f->media->duration);
    }

    return QVariant::fromValue(vids);
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

                if (retcode == 0 && img.loadFromData((const uchar *)(fsd->data), fsd->size))
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

bool Shot::isValid() const
{
    if (m_type >= Shared::SHOT_VIDEO && m_type <= Shared::SHOT_VIDEO_3D)
    {
        if (m_videos.size() > 0) return true;
    }
    else if (m_type >= Shared::SHOT_PICTURE && m_type <= Shared::SHOT_PICTURE_NIGHTLAPSE)
    {
        if (m_pictures.size() > 0) return true;
    }

    return false;
}

/* ************************************************************************** */

QVariant Shot::getShotFiles()
{
    if (m_shotfiles.size() <= 0)
    {
        for (auto f: qAsConst(m_pictures))
        {
            ShotFile *sf = new ShotFile(f);
            if (sf) m_shotfiles.push_back(sf);
        }
        for (auto f: qAsConst(m_videos))
        {
            ShotFile *sf = new ShotFile(f);
            if (sf) m_shotfiles.push_back(sf);
        }
        for (auto f: qAsConst(m_videos_previews))
        {
            ShotFile *sf = new ShotFile(f);
            if (sf) m_shotfiles.push_back(sf);
        }
        for (auto f: qAsConst(m_videos_thumbnails))
        {
            ShotFile *sf = new ShotFile(f);
            if (sf) m_shotfiles.push_back(sf);
        }
        for (auto f: qAsConst(m_videos_hdAudio))
        {
            ShotFile *sf = new ShotFile(f);
            if (sf) m_shotfiles.push_back(sf);
        }
        for (auto f: qAsConst(m_others))
        {
            ShotFile *sf = new ShotFile(f);
            if (sf) m_shotfiles.push_back(sf);
        }
    }

    if (m_shotfiles.size() > 0)
    {
        return QVariant::fromValue(m_shotfiles);
    }

    return QVariant();
}

QList <ofb_file *> Shot::getFiles(bool withPreviews, bool withHdAudio, bool withOthers) const
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
    if (withOthers)
    {
        for (auto f: m_others)
        list += f;
    }

    return list;
}

QStringList Shot::getFilesStringList() const
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
    for (auto f: m_others)
        list += f->filesystemPath;

    return list;
}

const QString & Shot::getFolderRefString()
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
        else if (!m_videos_previews.empty())
        {
            m_folder = m_videos_previews.at(0)->filesystemPath;
        }
        else if (!m_videos_thumbnails.empty())
        {
            m_folder = m_videos_thumbnails.at(0)->filesystemPath;
        }
        else if (!m_videos_hdAudio.empty())
        {
            m_folder = m_videos_hdAudio.at(0)->filesystemPath;
        }
        else if (!m_others.empty())
        {
            m_folder = m_others.at(0)->filesystemPath;
        }

        if (!m_folder.isEmpty())
        {
            QDir p(m_folder);
            p.cdUp();
            m_folder = p.absolutePath();

            // Make sure the path is terminated with a separator.
            if (!m_folder.endsWith('/')) m_folder += '/';
        }
    }

    return m_folder;
}

QString Shot::getFolderString()
{
    return getFolderRefString();
}

int Shot::getFileCount()
{
    int count = 0;

    count += m_pictures.size();
    count += m_videos.size();
    count += m_videos_previews.size();
    count += m_videos_thumbnails.size();
    count += m_videos_hdAudio.size();
    count += m_others.size();

    return count;
}

QString Shot::getFilesString() const
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
    for (auto f: m_others)
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
        for (auto f: m_others)
            list += "- " + f->name + "." + f->extension + "\n";
    }
#endif // ENABLE_LIBMTP

    return list;
}

void Shot::openFile() const
{
    QString file;

    if (m_pictures.size())
    {
        file = m_pictures.at(0)->filesystemPath;
    }
    else if (m_videos.size())
    {
        file = m_videos.at(0)->filesystemPath;
    }

    QFileInfo d(file);
    if (!file.isEmpty() && d.exists())
    {
        //qDebug() << "Shot::openFile()" << file;
        QDesktopServices::openUrl(QUrl::fromLocalFile(file));
    }
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

    if (!folder.isEmpty())
    {
        QDir p(folder);
        p.cdUp();
        folder = p.absolutePath();

        QFileInfo d(folder);
        if (!folder.isEmpty() && d.exists())
        {
            //qDebug() << "Shot::openFolder()" << folder;
            QDesktopServices::openUrl(QUrl::fromLocalFile(folder));
        }
    }
}

/* ************************************************************************** */
/* ************************************************************************** */
/*
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
*/
bool Shot::getMetadataFromPicture(int index)
{
    bool status = false;

    if (m_pictures.empty()) return false;
    if (m_pictures.at(index)->filesystemPath.isEmpty()) return false;

#if defined(ENABLE_LIBEXIF)

    // Check if the file is already parsed
    if (!m_pictures.at(index)->ed)
    {
        //qDebug() << "Shot::getMetadataFromPicture() PARSING ON MAIN THREAD";

        m_pictures.at(index)->ed = exif_data_new_from_file(m_pictures.at(index)->filesystemPath.toLocal8Bit());
    }

    if (m_pictures.at(index)->ed)
    {
        ExifData *ed = m_pictures.at(index)->ed;
        hasEXIF = true;

        // EXIF ////////////////////////////////////////////////////////////////

        ExifByteOrder byteOrder = exif_data_get_byte_order(ed);

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
/*
            1 = Horizontal (normal)     // "Top-left"
            2 = Mirror horizontal       // "Top-right"
            3 = Rotate 180              // "Bottom-right"
            4 = Mirror vertical         // "Bottom-left"
            5 = Mirror horizontal and rotate 270 CW // "Left-top"
            6 = Rotate 90 CW                        // "Right-top"
            7 = Mirror horizontal and rotate 90 CW  // "Right-bottom"
            8 = Rotate 270 CW                       // "Left-bottom"
*/
            int orientation = exif_get_short(entry->data, byteOrder);
            //qDebug() << "orientation:" << orientation;

            if (orientation == 1)
                transformation = QImageIOHandler::TransformationNone;
            else if (orientation == 2)
                transformation = QImageIOHandler::TransformationMirror;
            else if (orientation == 3)
                transformation = QImageIOHandler::TransformationRotate180;
            else if (orientation == 4)
                transformation = QImageIOHandler::TransformationFlip;
            else if (orientation == 5)
                transformation = QImageIOHandler::TransformationFlipAndRotate90;
            else if (orientation == 6)
                transformation = QImageIOHandler::TransformationRotate90;
            else if (orientation == 7)
                transformation = QImageIOHandler::TransformationMirrorAndRotate90;
            else if (orientation == 8)
                transformation = QImageIOHandler::TransformationRotate270;
/*
            exif_entry_get_value(entry, buf, sizeof(buf));
            //qDebug() << "orientation string:" << buf;

            if (strncmp(buf, "Top-left", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationNone;
            else if (strncmp(buf, "Top-right", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationMirror;
            else if (strncmp(buf, "Bottom-right", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationRotate180;
            else if (strncmp(buf, "Bottom-left", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationFlip;
            else if (strncmp(buf, "Left-top", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationFlipAndRotate90;
            else if (strncmp(buf, "Right-top", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationRotate90;
            else if (strncmp(buf, "Right-bottom", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationMirrorAndRotate90;
            else if (strncmp(buf, "Left-bottom", sizeof(buf)) == 0)
                transformation = QImageIOHandler::TransformationRotate270;
*/
        }

        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_FNUMBER);
        if (entry)
        {
            exif_entry_get_value(entry, buf, sizeof(buf));
            if (strlen(buf))
            {
                focal = buf;
                focal.replace("f", "ƒ");
            }
        }
        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_FOCAL_LENGTH);
        if (entry)
        {
            exif_entry_get_value(entry, buf, sizeof(buf));
            if (strlen(buf))
            {
                if (!focal.isEmpty()) focal += "  ";
                focal += buf;
            }
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
            exposure_time = buf;
        }
        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_FLASH);
        if (entry)
        {
            exif_entry_get_value(entry, buf, sizeof(buf));
            int flashvalue = QString::fromLatin1(buf).toInt();

            if (flashvalue > 0) flash = true;
        }
        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_EXIF], EXIF_TAG_METERING_MODE);
        if (entry)
        {
            exif_entry_get_value(entry, buf, sizeof(buf));
            metering_mode = buf;
        }

        entry = exif_content_get_entry(ed->ifd[EXIF_IFD_0], EXIF_TAG_DATE_TIME);
        if (entry)
        {
            // TODO
            //0x882a	TimeZoneOffset	int16s[n]	ExifIFD	(1 or 2 values: 1. The time zone offset of DateTimeOriginal from GMT in hours, 2. If present, the time zone offset of ModifyDate)
            //0x9010	OffsetTime	string	ExifIFD	(time zone for ModifyDate)

            // ex: DateTime: 2018:08:10 10:37:08
            exif_entry_get_value(entry, buf, sizeof(buf));
            m_date_metadata = QDateTime::fromString(buf, "yyyy:MM:dd hh:mm:ss");
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

            m_gps_altitude_offset = egm96_compute_altitude_offset(gps_lat, gps_long);
/*
            qDebug() << "gps_lat_str:" << gps_lat_str;
            qDebug() << "gps_long_str:" << gps_long_str;
            qDebug() << "gps_alt_str:" << gps_alt_str;
            qDebug() << "gps_lat:" << gps_lat;
            qDebug() << "gps_long:" << gps_long;
            qDebug() << "gps_alt:" << gps_alt;
            qDebug() << "gps_alt_offset:" << m_gps_altitude_offset;
            qDebug() << "gps_timestamp:" << m_date_gps;
*/
        }

        // MAKERNOTE ///////////////////////////////////////////////////////////////

        ExifMnoteData *mn = exif_data_get_mnote_data(ed);
        if (mn)
        {
            //qDebug() << "WE HAVE MAKERNOTEs";
        }

        exif_data_unref(m_pictures.at(index)->ed);
        m_pictures.at(index)->ed = nullptr;

        status = true;
    }
    else
    {
        //qDebug() << "File not readable or no EXIF data";
    }

#elif defined(ENABLE_EXIV2)

    Exiv2::Image::AutoPtr image = Exiv2::ImageFactory::open(m_pictures.at(index)->filesystemPath.toStdString());
    image->readMetadata();

    Exiv2::ExifData &exifData = image->exifData();
    if (!exifData.empty())
    {
        //
    }
    else
    {
        //qDebug() << "File not readable or no EXIF data";
    }

#endif // !defined(ENABLE_LIBEXIF) && !defined(ENABLE_EXIV2)

    // Gather additional (icodec) or backup (geometry & orientation) infos
    QImageReader img_infos(m_pictures.at(index)->filesystemPath);
    if (img_infos.canRead())
    {
        icodec = img_infos.format();
        width = static_cast<unsigned>(img_infos.size().rwidth());
        height = static_cast<unsigned>(img_infos.size().rheight());
        transformation = img_infos.transformation();

        status = true;
    }

    return status;
}

bool Shot::getMetadataFromVideo(int index)
{
    //qDebug() << "Shot::getMetadataFromVideo(" << index << " " << m_videos.at(index)->filesystemPath;

    if (m_videos.empty())
        return false;
    if (m_videos.at(index)->filesystemPath.isEmpty())
        return false;

#ifdef ENABLE_MINIVIDEO

    // Check if the file is already parsed
    if (!m_videos.at(index)->media)
    {
        //qDebug() << "Shot::getMetadataFromVideo() PARSING ON MAIN THREAD";

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
            qDebug() << "minivideo_open() failed with retcode: " << minivideo_retcode << " cannot open: " << m_videos.at(index)->filesystemPath;
        }
    }

    MediaFile_t *media = m_videos.at(index)->media;
    if (media)
    {
        m_date_metadata = QDateTime::fromSecsSinceEpoch(media->creation_time);

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
            projection = media->tracks_video[0]->video_projection;
            rotation = media->tracks_video[0]->video_rotation * 90;
            if (media->tracks_video[0]->video_rotation == 1)
                transformation = QImageIOHandler::TransformationRotate90;
            else if (media->tracks_video[0]->video_rotation == 2)
                transformation = QImageIOHandler::TransformationRotate180;
            else if (media->tracks_video[0]->video_rotation == 3)
                transformation = QImageIOHandler::TransformationRotate270;

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
                    // have that date already, so don't run this code twice (it's slow)
                    if (!m_date_gps.isValid())
                    {
                        // We start at the last GPMF sample, we have more chance
                        // to have a GPS lock than at the begining of the video
                        for (unsigned sp_index = gpmf_sample_count-1; sp_index > 0; sp_index--)
                        {
                            MediaSample_t *sp = minivideo_get_sample(media, t, sp_index);

                            GpmfBuffer buf;
                            if (buf.loadBuffer(sp->data, sp->size))
                            {
                                if (parseGpmfSampleFast(buf, devc_count))
                                {
                                    minivideo_destroy_sample(&sp);
                                    break; // we have GPS datetime
                                }
                            }

                            minivideo_destroy_sample(&sp);
                            break; // if we don't find a GPS sample immediately, we bail
                        }
                    }
                }
            }
        }
        if (media->chapters_count > 0 && media->chapters)
        {
            // Time offset (if chaptered video)
            int64_t timeoffset = 0;
            for (int i = 0; i < index; i++)
            {
                if (m_videos.at(i) && m_videos.at(i)->media)
                    timeoffset += m_videos.at(i)->media->duration;
            }
            // GoPro HiLight tags
            for (unsigned i = 0; i < media->chapters_count; i++)
            {
                m_hilight.push_back(timeoffset + media->chapters[i].pts);
            }
        }
        if (media->metadata_gopro)
        {
            hasGoProMetadata = true;

            // GoPro shot metadata (from MP4)
            m_camera_firmware = media->metadata_gopro->camera_firmware;
            if (m_camera_firmware.startsWith("HD9")) m_camera_source = "GoPro HERO9";
            if (m_camera_firmware.startsWith("HD8")) m_camera_source = "GoPro HERO8";
            if (m_camera_firmware.startsWith("HD7")) m_camera_source = "GoPro HERO7";
            if (m_camera_firmware.startsWith("HD6")) m_camera_source = "GoPro HERO6";
            if (m_camera_firmware.startsWith("HD5")) m_camera_source = "GoPro HERO5";
            if (m_camera_firmware.startsWith("HX")) m_camera_source = "GoPro HERO4 Session";
            if (m_camera_firmware.startsWith("HD4")) m_camera_source = "GoPro HERO4";
            if (m_camera_firmware.startsWith("HD3")) m_camera_source = "GoPro HERO3";

            protune = media->metadata_gopro->protune;
            cam_raw = media->metadata_gopro->cam_raw;
            broadcast_range = media->metadata_gopro->broadcast_range;
            video_mode_fov = media->metadata_gopro->video_mode_fov;
            lens_type = media->metadata_gopro->lens_type;
            lowlight = media->metadata_gopro->lowlight;
            superview = media->metadata_gopro->superview;
            sharpening = media->metadata_gopro->sharpening;
            eis = media->metadata_gopro->eis;
            media_type = media->metadata_gopro->media_type;
        }

        return true;
    }

#endif // ENABLE_MINIVIDEO

    return false;
}

bool Shot::getMetadataFromVideoGPMF()
{
    //qDebug() << "Shot::getMetadataFromVideoGPMF()";

    if (gpmf_parsed)
        return true;

    if (m_videos.empty())
        return false;

#ifdef ENABLE_MINIVIDEO

    for (auto video : qAsConst(m_videos))
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

        // PARSE METADATA //////////////////////////////////////////////////////

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

                        // Parse GPMF data
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
    emit metadataUpdated();

    return true;

#endif // ENABLE_MINIVIDEO

    return false;
}

/* ************************************************************************** */
/* ************************************************************************** */
