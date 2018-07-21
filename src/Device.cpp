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

#include "Device.h"

#include <QStorageInfo>
#include <QFile>
#include <QDir>
#include <QDebug>

/* ************************************************************************** */

Device::Device()
{
    //
}

Device::Device(const QString path, const gopro_version_20 *infos)
{
    m_brand = "GoPro";
    m_model = "HERO?";

    if (infos)
    {
        m_model = infos->camera_type;
        m_firmware = infos->firmware_version;
        m_serial = infos->camera_serial_number;
        m_wifi_mac = infos->wifi_mac;
    }

    if (!path.isEmpty())
    {
        m_root_path = path;
        m_storage = new QStorageInfo(m_root_path);

        if (m_storage && m_storage->isValid() && m_storage->isReady())
        {
            // yas
        }
        else
        {
            qDebug() << "* device storage invalid? '" << m_storage->displayName() << "'";
        }
    }

    m_shotModel = new ShotModel;

    m_updateTimer.setInterval(5 * 1000);
    connect(&m_updateTimer, &QTimer::timeout, this, &Device::refreshDevice);
    m_updateTimer.start();
}

Device::~Device()
{
    //
}

/* ************************************************************************** */

bool Device::isValid()
{
    bool status = true;

    if (m_brand.isEmpty() || m_model.isEmpty())
        status = false;

    if (m_root_path.isEmpty() || m_storage == nullptr)
        status = false;

    return status;
}

/* ************************************************************************** */

//https://gopro.com/help/articles/question_answer/GoPro-Camera-File-Naming-Convention

bool Device::scanFiles()
{
    QString dcim_path = m_root_path + QDir::separator() + "DCIM";

    qDebug() << "> SCANNING STARTED";
    qDebug() << "DCIM:" << dcim_path;

    QDir dcim;
    dcim.setPath(dcim_path);
    foreach (QString subdir_name, dcim.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
    {
        qDebug() << "Scanning subdir:" << subdir_name;

        QDir subdir;
        subdir.setPath(dcim_path + QDir::separator() + subdir_name);

        foreach (QString file_name, subdir.entryList(QDir::Files| QDir::NoDotAndDotDot))
        {
            QString file_path = dcim_path + QDir::separator() + subdir_name + QDir::separator() + file_name;

            Shared::ShotType file_type = Shared::SHOT_UNKNOWN;
            QString file_ext = file_name.right(3).toLower();
            int file_number = file_name.mid(4, 4).toInt();
            QString group_string;
            int group_number = 0;

            if (file_name.size() != 12)
                qWarning() << "This filename is not 12 chars... Probably not a GoPro file...";

            if (file_name.startsWith("GOPR"))
            {
                if (file_ext == "jpg")
                {
                    // Single Photo
                    file_type = Shared::SHOT_PICTURE;
                }
                else if (file_ext == "mp4")
                {
                    // Single Video
                    file_type = Shared::SHOT_VIDEO;
                }
            }
            else if (file_name.startsWith("GP"))
            {
                // Chaptered Video
                file_type = Shared::SHOT_VIDEO;
                group_string = file_name.mid(2, 2);
                group_number = group_string.toInt();
            }
            else if (file_name.startsWith("GH") ||
                     file_name.startsWith("GX") ||
                     file_name.startsWith("GL"))
            {
                // HERO6 Video
                file_type = Shared::SHOT_VIDEO;
                group_string = file_name.mid(2, 2);
                group_number = group_string.toInt();
            }
            else if (file_name.startsWith("G"))
            {
                if (file_ext == "jpg")
                {
                    // Burst or Time-Lapse Photo
                    file_type = Shared::SHOT_PICTURE_MULTI;
                }
                else if (file_ext == "mp4")
                {
                    // Looping Video
                    file_type = Shared::SHOT_VIDEO;
                }

                group_string = file_name.mid(1, 3);
                group_number = group_string.toInt();
            }
            else if (file_name.startsWith("GPBK") ||
                     file_name.startsWith("GPFR"))
            {
                // Fusion Video
                if (file_ext == "jpg")
                {
                    file_type = Shared::SHOT_PICTURE;
                }
                else if (file_ext == "mp4")
                {
                    file_type = Shared::SHOT_VIDEO;
                }
            }
            else if (file_name.startsWith("GB") ||
                     file_name.startsWith("GF"))
            {
                // Chaptered Fusion Video
                file_type = Shared::SHOT_VIDEO;
                group_string = file_name.mid(2, 2);
                group_number = group_string.toInt();

                if (file_ext == "jpg")
                {
                    file_type = Shared::SHOT_PICTURE_MULTI;
                }
                else if (file_ext == "mp4")
                {
                    file_type = Shared::SHOT_VIDEO;
                }
            }
            else if (file_name.startsWith("3D_"))
            {
                qWarning() << "Unhandled file name format:" << file_name;
            }
            else
            {
                // 3D Recording Video
                //file_type = Shared::SHOT_VIDEO_3D;
                qWarning() << "Unknown file name format:" << file_name;
            }

            int id = (file_type == Shared::SHOT_VIDEO) ? file_number : group_number;
            Shot *s = findShot(file_type, id);
            if (s)
            {
                s->addFile(file_path);
            }
            else
            {
                Shot *s = new Shot(file_type);
                if (s)
                {
                    s->addFile(file_path);
                    s->setFileId(id);
                    if (s->isValid())
                    {
                        m_shotModel->addShot(s);
                        //m_shots.push_back(s);
                    }
                }
            }
/*
            qDebug() << "* " << file_path;
            qDebug() << "- " << file_name;
            qDebug() << "- " << file_ext;
            qDebug() << "- " << file_type;
            qDebug() << "- " << group_number;
            qDebug() << "- " << file_number;
*/
        }
    }

    qDebug() << "> SCANNING FINISHED";
    qDebug() << "-" << m_shotModel->getShotList()->size() << "shots found";

    return false;
}

Shot * Device::findShot(Shared::ShotType type, int file_id) const
{
    if (m_shotModel->getShotList()->size() > 0 && file_id > 0)
    {
        for (int i = m_shotModel->getShotList()->size()-1; i >= 0; i--)
        {
            Shot *search = qobject_cast<Shot*>(m_shotModel->getShotList()->at(i));
            if (search && search->getType() == type)
            {
                if (search->getFileNumber() == file_id)
                {
                    return search;
                }
            }
        }

        //qDebug() << "No shot found for id" << file_id;
    }

    return nullptr;
}

bool Device::isAvailable()
{
    return m_available;
}

/* ************************************************************************** */

void Device::refreshDevice()
{
    //qDebug() << "refreshDevice(" << m_storage->rootPath() << ")";

    if (m_storage &&
        m_storage->isValid() && m_storage->isReady())
    {
        m_storage->refresh();
        emit spaceUpdated();
/*
        // basic checks
        if (m_storage->bytesAvailable() > 128*1024*1024 &&
            m_storage->isReadOnly() == false)
        {
#if __linux
            // adanced permission checks
            QFileInfo fi(m_path);
            QFile::Permissions  e = fi.permissions();
            if (!e.testFlag(QFileDevice::WriteUser))
            {
                m_available = false;
                emit availableUpdated();
            }
#endif // __linux
        }
*/
    }
    else
    {
        //m_available = false;
        //emit availableUpdated();
    }
}

QString Device::getRootPath() const
{
/*
    if (m_storage)
        return m_storage->rootPath();

    return QString();
*/
    return m_root_path;
}

int64_t Device::getSpaceTotal()
{
    if (m_storage)
        return m_storage->bytesTotal();

    return 0;
}

int64_t Device::getSpaceUsed()
{
    if (m_storage)
        return (m_storage->bytesTotal() - m_storage->bytesAvailable());

    return 0;
}

double Device::getSpaceUsed_percent()
{
    if (m_storage)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(m_storage->bytesTotal());

    return 0.0;
}

int64_t Device::getSpaceAvailable()
{
    if (m_storage)
        return m_storage->bytesAvailable();

    return 0;
}

int64_t Device::getSpaceAvailable_withrefresh()
{
    refreshDevice();
    return getSpaceAvailable();
}

/* ************************************************************************** */
