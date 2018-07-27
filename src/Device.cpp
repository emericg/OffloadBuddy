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
    }

    if (!path.isEmpty())
    {
        m_root_path = path;
        m_storage = new QStorageInfo(m_root_path);

        if (m_storage && m_storage->isValid() && m_storage->isReady())
        {
            // basic checks
            if (m_storage->bytesAvailable() > 128*1024*1024 &&
                m_storage->isReadOnly() == false)
            {
                m_writable = true;
#if __linux
/*
                // adanced permission checks
                QFileInfo fi(m_path);
                QFile::Permissions  e = fi.permissions();
                if (!e.testFlag(QFileDevice::WriteUser))
                {
                    m_writable = false;
                    qDebug() << "PERMS error on device:" << e << (unsigned)e;
                }
*/
#endif // __linux
            }
        }
        else
        {
            qDebug() << "* device storage invalid? '" << m_storage->displayName() << "'";
            m_root_path.clear();
            delete m_storage;
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

bool Device::addSecondaryDevice(const QString &path)
{
    if (!path.isEmpty())
    {
        m_secondary_root_path = path;
        m_secondary_storage = new QStorageInfo(m_secondary_root_path);

        if (m_secondary_storage && m_secondary_storage->isValid() && m_secondary_storage->isReady())
        {
            return true;
        }
        else
        {
            qDebug() << "* device secondary storage invalid? '" << m_secondary_storage->displayName() << "'";
            m_secondary_root_path.clear();
            delete m_secondary_storage;
        }
    }

    return false;
}


bool Device::scanFiles()
{
    return scanFiles(m_root_path);
}
bool Device::scanSecondaryDevice()
{
    return scanFiles(m_secondary_root_path);
}

bool Device::scanFiles(const QString &path)
{
    QString dcim_path = path + QDir::separator() + "DCIM";

    qDebug() << "> SCANNING STARTED";
    qDebug() << "DCIM:" << dcim_path;

    QDir dcim;
    dcim.setPath(dcim_path);
    foreach (QString subdir_name, dcim.entryList(QDir::Dirs | QDir::NoDotAndDotDot))
    {
        qDebug() << "Scanning subdir:" << subdir_name;

        // ex:  100GOPRO
        //      100ANDRO
        //      1000GP

        QDir subdir;
        subdir.setPath(dcim_path + QDir::separator() + subdir_name);

        foreach (QString file_name, subdir.entryList(QDir::Files| QDir::NoDotAndDotDot))
        {
            QString file_path = dcim_path + QDir::separator() + subdir_name + QDir::separator() + file_name;

            Shared::ShotType file_type = Shared::SHOT_UNKNOWN;
            QString file_ext = file_name.right(3).toLower();

            int camera_id = 0; // for multi camera system
            int file_number = file_name.mid(4, 4).toInt();
            QString group_string;
            int group_number = 0;

            if (file_name.size() != 12)
                qWarning() << "This filename is not 12 chars... Probably not a GoPro file...";

            //https://gopro.com/help/articles/question_answer/GoPro-Camera-File-Naming-Convention

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
            else if (file_name.startsWith("GPBK") ||
                     file_name.startsWith("GPFR"))
            {
                // Fusion Video
                if (file_ext == "jpg")
                {
                    file_type = Shared::SHOT_PICTURE;
                }
                else if (file_ext == "mp4" || file_ext == "lrv" ||
                         file_ext == "thm"  || file_ext == "wav")
                {
                    file_type = Shared::SHOT_VIDEO;
                }

                if (file_name.startsWith("GPBK"))
                    camera_id = 1;
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
                else if (file_ext == "mp4" || file_ext == "lrv" ||
                         file_ext == "thm"  || file_ext == "wav")
                {
                    file_type = Shared::SHOT_VIDEO;
                }

                if (file_name.startsWith("GB"))
                    camera_id = 1;
            }
            else if (file_name.startsWith("G"))
            {
                if (file_ext == "jpg")
                {
                    // Burst or Time-Lapse Photo
                    file_type = Shared::SHOT_PICTURE_MULTI;
                }
                else if (file_ext == "mp4" || file_ext == "lrv" ||
                         file_ext == "thm"  || file_ext == "wav")
                {
                    // Looping Video
                    file_type = Shared::SHOT_VIDEO;
                }

                group_string = file_name.mid(1, 3);
                group_number = group_string.toInt();
            }
            else if (file_name.startsWith("3D_"))
            {
                // 3D Recording Video
                //file_type = Shared::SHOT_VIDEO_3D;
                qWarning() << "Unhandled file name format:" << file_name;
            }
            else
            {
                qWarning() << "Unknown file name format:" << file_name;
            }

            int file_id = (file_type == Shared::SHOT_VIDEO) ? file_number : group_number;
            Shot *s = findShot(file_type, file_id, camera_id);
            if (s)
            {
                //qWarning() << "Adding file:" << file_name << "to an existing shot";
                s->addFile(file_path);
            }
            else
            {
                //qWarning() << "file:" << file_name << "is a new shot";
                Shot *s = new Shot(file_type);
                if (s)
                {
                    s->addFile(file_path);
                    s->setFileId(file_id);
                    s->setCameraId(camera_id);
                    if (s->isValid())
                    {
                        m_shotModel->addShot(s);
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

Shot * Device::findShot(Shared::ShotType type, int file_id, int camera_id) const
{
    if (m_shotModel->getShotList()->size() > 0 && file_id > 0)
    {
        for (int i = m_shotModel->getShotList()->size()-1; i >= 0; i--)
        {
            Shot *search = qobject_cast<Shot*>(m_shotModel->getShotList()->at(i));
            if (search && search->getType() == type)
            {
                if (search->getFileId() == file_id &&
                    search->getCameraId() == camera_id)
                {
                    return search;
                }
            }
        }

        //qDebug() << "No shot found for id" << file_id;
    }

    return nullptr;
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

        // Check if writable and some space is available // For firmware upates
        if (m_storage->isReadOnly() == false &&
            m_storage->bytesAvailable() > 128*1024*1024)
        {
            m_writable = true;
        }
        else
            m_writable = false;
    }

    if (m_secondary_storage &&
        m_secondary_storage->isValid() && m_secondary_storage->isReady())
    {
        m_secondary_storage->refresh();
        emit spaceUpdated();

        // Check if writable and some space is available // For firmware upates
        if (m_secondary_storage->isReadOnly() == true &&
            m_secondary_storage->bytesAvailable() < 128*1024*1024)
        {
            m_writable = false;
        }
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

QString Device::getSecondayRootPath() const
{
    return m_secondary_root_path;
}

int64_t Device::getSpaceTotal()
{
    int64_t s = 0;

    if (m_storage)
        s += m_storage->bytesTotal();
    if (m_secondary_storage)
        s += m_secondary_storage->bytesTotal();

    return s;
}

int64_t Device::getSpaceUsed()
{
    int64_t s = 0;

    if (m_storage)
        s += (m_storage->bytesTotal() - m_storage->bytesAvailable());
    if (m_secondary_storage)
        s += (m_storage->bytesTotal() - m_storage->bytesAvailable());

    return s;
}

double Device::getSpaceUsed_percent()
{
    if (getSpaceTotal() > 0)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(getSpaceTotal());

    return 0.0;
}

int64_t Device::getSpaceAvailable()
{
    int64_t s = 0;

    if (m_storage)
        s += m_storage->bytesAvailable();
    if (m_secondary_storage)
        s += m_secondary_storage->bytesAvailable();

    return s;
}

int64_t Device::getSpaceAvailable_withrefresh()
{
    refreshDevice();
    return getSpaceAvailable();
}

/* ************************************************************************** */
