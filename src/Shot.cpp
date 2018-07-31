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

/* ************************************************************************** */

Shot::Shot(QObject *parent) : QObject(parent)
{
    //
}

Shot::Shot(Shared::ShotType type)
{
    m_type = type;
}

Shot::~Shot()
{
    qDeleteAll(m_jpg);
    m_jpg.clear();

    qDeleteAll(m_mp4);
    m_mp4.clear();
    qDeleteAll(m_lrv);
    m_lrv.clear();
    qDeleteAll(m_thm);
    m_thm.clear();
    qDeleteAll(m_wav);
    m_wav.clear();
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

    m_jpg = other.m_jpg;

    m_mp4 = other.m_mp4;
    m_lrv = other.m_lrv;
    m_thm = other.m_thm;
    m_wav = other.m_wav;
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
                m_jpg.push_front(file);
            }
            else if (file->extension == "mp4")
            {
                m_mp4.push_front(file);
            }
            else if (file->extension == "lrv")
            {
                m_lrv.push_front(file);
            }
            else if (file->extension == "thm")
            {
                m_thm.push_front(file);
            }
            else if (file->extension == "wav")
            {
                m_wav.push_front(file);
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
                m_jpg.push_back(file);
            }
            else if (file->extension == "mp4")
            {
                m_mp4.push_back(file);
            }
            else if (file->extension == "lrv")
            {
                m_lrv.push_back(file);
            }
            else if (file->extension == "thm")
            {
                m_thm.push_back(file);
            }
            else if (file->extension == "wav")
            {
                m_wav.push_back(file);
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
    bool status = true;

    return status;
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
    qint64 size = 0;

    for (auto f: m_jpg)
    {
        size += f->size;
    }
    for (auto f: m_mp4)
    {
        size += f->size;
    }
    for (auto f: m_thm)
    {
        size += f->size;
    }
    for (auto f: m_wav)
    {
        size += f->size;
    }
    for (auto f: m_lrv)
    {
        size += f->size;
    }

    return size;
}

QString Shot::getPreview() const
{
    if (m_jpg.size() > 0 && !m_jpg.at(0)->filesystemPath.isEmpty())
    {
        return m_jpg.at(0)->filesystemPath;
    }
    else if (m_thm.size() > 0 && !m_thm.at(0)->filesystemPath.isEmpty())
    {
        return m_thm.at(0)->filesystemPath;
    }

    return QString();
}

qint64 Shot::getDuration() const
{
    if (m_type < Shared::SHOT_PICTURE)
        return m_duration;
    else
        return m_jpg.count();
}

QStringList Shot::getFiles() const
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
