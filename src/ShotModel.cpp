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

#include "ShotModel.h"
#include "ShotUtils.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>

#include <QDebug>

/* ************************************************************************** */

ShotModel::ShotModel(QObject *parent)
    : QAbstractListModel(parent)
{
    //
}

ShotModel::ShotModel(const ShotModel &other, QObject *parent)
    : QAbstractListModel(parent)
{
    m_shots = other.m_shots;
}

ShotModel::~ShotModel()
{
    qDeleteAll(m_statstracks);
    m_statstracks.clear();

    qDeleteAll(m_shots);
    m_shots.clear();
}

/* ************************************************************************** */
/* ************************************************************************** */

void ShotModel::sanetize(const QString &path)
{
    // Check if each files of the shot still exists
    for (auto shot: qAsConst(m_shots))
    {
        if (!path.isEmpty() && shot->getFolderString().contains(path))
        {
            // Remove the shot alltogether if one file is missing
            removeShot(shot);
            continue;
        }

        QList <ofb_file *> files = shot->getFiles();
        for (auto file: qAsConst(files))
        {
            QFile f(file->filesystemPath);
            if (!f.exists())
            {
                // Remove the shot alltogether if one file is missing
                removeShot(shot);
                break;
            }
        }
    }
}

/* ************************************************************************** */

void ShotModel::computeStats()
{
    int audio_file = 0;
    qint64 audio_space = 0;
    int video_file = 0;
    qint64 video_space = 0;
    int picture_file = 0;
    qint64 picture_space = 0;
    int telemetry_file = 0;
    qint64 telemetry_space = 0;
    int other_file = 0;
    qint64 other_space = 0;

    for (auto shot: qAsConst(m_shots))
    {
/*
        // (1) Compute stats by shot type
        if (shot->getShotType() < ShotUtils::SHOT_PICTURE)
        {
            video_file += shot->getFileCount();
            video_space += shot->getFullSize();
        }
        else
        {
            picture_file += shot->getFileCount();
            picture_space += shot->getFullSize();
        }
*/
        // (2) Compute stats by shot files type
        QList <ofb_file *> files = shot->getFiles();
        for (auto file: qAsConst(files))
        {
            if (file->isAudio)
            {
                audio_file++;
                audio_space += file->size;
            }
            else if (file->isVideo)
            {
                video_file++;
                video_space += file->size;
            }
            else if (file->isPicture)
            {
                picture_file++;
                picture_space += file->size;
            }
            else if (file->isTelemetry)
            {
                telemetry_file++;
                telemetry_space += file->size;
            }
            else
            {
                other_file++;
                other_space += file->size;
            }
        }
    }

    qDeleteAll(m_statstracks);
    m_statstracks.clear();

    m_fileCount = audio_file + video_file + picture_file + telemetry_file + other_file;
    m_diskSpace = audio_space + video_space + picture_space + telemetry_space + other_space;

    if (audio_file)
    {
        ShotModelStatsTrack *t = new ShotModelStatsTrack(ShotUtils::FILE_AUDIO, audio_file, m_fileCount, audio_space, m_diskSpace);
        m_statstracks.push_back(t);
    }
    if (video_file)
    {
        ShotModelStatsTrack *t = new ShotModelStatsTrack(ShotUtils::FILE_VIDEO, video_file, m_fileCount, video_space, m_diskSpace);
        m_statstracks.push_back(t);
    }
    if (picture_file)
    {
        ShotModelStatsTrack *t = new ShotModelStatsTrack(ShotUtils::FILE_PICTURE, picture_file, m_fileCount, picture_space, m_diskSpace);
        m_statstracks.push_back(t);
    }
    if (telemetry_file)
    {
        ShotModelStatsTrack *t = new ShotModelStatsTrack(ShotUtils::FILE_METADATA, telemetry_file, m_fileCount, telemetry_space, m_diskSpace);
        m_statstracks.push_back(t);
    }
    if (other_file)
    {
        ShotModelStatsTrack *t = new ShotModelStatsTrack(ShotUtils::FILE_UNKNOWN, other_file, m_fileCount, other_space, m_diskSpace);
        m_statstracks.push_back(t);
    }

    Q_EMIT statsAdvUpdated();
}

/* ************************************************************************** */

void ShotModel::addFile(ofb_file *f, ofb_shot *s)
{
    //qDebug() << "ShotModel::addFile()" << f->filesystemPath << ">" << s->shot_type << s->shot_id << s->camera_id;

    Shot *shot = nullptr;

    // If we think this file may be from a shot, look for its parent shot
    if (f->isShot)
    {
        if (s->shot_id > 0)
        {
            // Search for parent (using shot ID)
            shot = searchForShot(s->shot_type, s->shot_id, s->camera_id, f->filesystemPath);

            // Duplicate?
            if (shot && shot->containFile(f->filesystemPath))
            {
                //qDebug() << "File:" << f->name << f->extension << "is a duplicate. Refreshing shot.";
                shot->refresh();

                delete s;
                return;
            }
        }
    }
    else
    {
        // Search for duplicate (using full path)
        shot = searchForDuplicate(f->filesystemPath);
        if (shot)
        {
            //qDebug() << "File:" << f->name << f->extension << "is a duplicate. Refreshing shot.";
            shot->refresh();

            delete s;
            return;
        }
    }

    if (shot)
    {
        //qDebug() << "Adding file:" << f->name << f->extension << "to an existing shot";
        shot->addFile(f);
    }
    else
    {
        //qDebug() << "File:" << f->name << f->extension << "is from a new shot";
        shot = new Shot(s, this);
        if (shot)
        {
            shot->addFile(f);
            addShot(shot);
        }
        else
        {
            delete f;
            f = nullptr;
        }
    }

    // update content stats
    if (f)
    {
        m_fileCount++;
        m_diskSpace += f->size;
        Q_EMIT statsUpdated();
    }

    delete s;
}

void ShotModel::addShot(Shot *shot)
{
    if (shot)
    {
        // add
        beginInsertRows(QModelIndex(), getShotCount(), getShotCount());
        m_shots.push_back(shot);
        endInsertRows();

        if (shot->getFileCount())
        {
            // update content stats
            m_fileCount += shot->getFileCount();
            m_diskSpace += shot->getFullSize();
            Q_EMIT statsUpdated();
        }
    }
}

void ShotModel::removeShot(Shot *shot)
{
    if (shot)
    {
        int id = m_shots.indexOf(shot);
        if (id >= 0 && id < m_shots.size())
        {
            // update content stats
            m_fileCount -= shot->getFileCount();
            m_diskSpace -= shot->getFullSize();
            Q_EMIT statsUpdated();

            // remove
            beginRemoveRows(QModelIndex(), id, id);
            m_shots.removeAt(id);
            delete shot;
            endRemoveRows();
        }
    }
}

/* ************************************************************************** */

/*!
 * \param type: see ShotUtils::ShotType
 * \param file_id
 * \param camera_id
 * \param folder
 * \return Pointer to an existing shot
 *
 * This function is used to associate new/scanned files to existing shots. We go
 * backward for faster association, because we will just most likely use the last
 * created shot.
 * We try only the last 32 shots created, to avoid wasting time.
 *
 * Also we make sure the shot files are from the same folder. Mandatory when
 * shot IDs are looping (same IDs, from different parsing threads, from different
 * camera/year/whatever, ...)
 *
 * \todo Handle timelapse shots looping IDs (ex from 49999 to 50000, the ID goes from 4 to 5).
 */
Shot *ShotModel::searchForShot(const ShotUtils::ShotType type,
                               const int64_t file_id, const int camera_id,
                               const QString &folder) const
{
    if (file_id > 0)
    {
        for (int i = m_shots.size()-1, t = 0; i >= 0 && t < 32; i--, t++)
        {
            Shot *search = qobject_cast<Shot*>(m_shots.at(i));
            if (search && search->getShotType() == type)
            {
                if (search->getFileId() == file_id &&
                    search->getCameraId() == camera_id)
                {
                    // We make sure shot files are from the same folder
                    if (folder.contains(search->getFolderRefString()))
                    {
                        return search;
                    }
                }
            }
        }

        //qDebug() << "No shot found for id" << file_id;
    }

    return nullptr;
}

/*!
 * \brief ShotModel::searchForDuplicate
 * \param path
 * \return
 */
Shot *ShotModel::searchForDuplicate(const QString &path)
{
    if (!path.isEmpty())
    {
        for (auto shot: qAsConst(m_shots))
        {
            Shot *search = qobject_cast<Shot*>(shot);
            if (search && search->containFile(path))
                return search;
        }
    }

    return nullptr;
}

/* ************************************************************************** */

/*!
 * \brief Return all of the shots from a device.
 * \param shots[out]
 */
void ShotModel::getShots(QList<Shot *> &shots)
{
    for (auto shot: qAsConst(m_shots))
    {
        shots.push_back(shot);
    }
}

/*!
 * \brief ShotModel::getShotAtIndex
 * \param listIndex: UNFILTERED INDEX be careful
 * \return
 */
Shot *ShotModel::getShotAtIndex(const int listIndex)
{
    //qDebug() << "ShotModel::getShotAtIndex:" << index(0, listIndex);

    if (listIndex >= 0 && listIndex < m_shots.size())
    {
        return m_shots.at(listIndex);
    }

    return nullptr;
}

/*!
 * \brief ShotModel::getShotWithUuid
 * \param uuid
 * \return
 */
Shot *ShotModel::getShotWithUuid(const QString &uuid)
{
    if (!uuid.isEmpty())
    {
        for (auto shot: qAsConst(m_shots))
        {
            Shot *search = qobject_cast<Shot*>(shot);
            if (search->getUuid() == uuid)
            {
                return search;
            }
        }

        //qDebug() << "No shot found for uuid" << uuid;
    }

    return nullptr;
}

/*!
 * \brief ShotModel::getShotsWithName
 * \param name
 * \return
 */
std::vector<Shot *> ShotModel::getShotsWithName(const QString &name)
{
    std::vector<Shot *> list;

    if (!name.isEmpty())
    {
        for (auto shot: qAsConst(m_shots))
        {
            Shot *search = qobject_cast<Shot*>(shot);
            if (search->getName() == name)
            {
                list.push_back(search);
            }
        }

        //qDebug() << "No shot(s) found for name" << name;
    }

    return list;
}

/* ************************************************************************** */

int ShotModel::rowCount(const QModelIndex & parent) const
{
    Q_UNUSED(parent)
    return m_shots.size();
}

QVariant ShotModel::data(const QModelIndex & index, int role) const
{
    //qDebug() << "ShotModel::data(r:" << index.row() << "c:" << index.column();

    if (index.row() < 0 || index.row() >= m_shots.size() || !index.isValid())
        return QVariant();

    Shot *shot = m_shots[index.row()];
    if (shot)
    {
        if (role == NameRole)
            return shot->getName();
        if (role == ShotTypeRole)
            return shot->getShotType();
        if (role == FileTypeRole)
            return shot->getFileType();
        if (role == PreviewRole)
            return shot->getPreviewPhoto();
        if (role == SizeRole)
            return shot->getSize();
        if (role == DurationRole)
            return shot->getDuration();
        if (role == DateRole)
            return shot->getDate();
        if (role == PointerRole)
            return QVariant::fromValue(shot);
        if (role == PathRole)
        {
            if (shot->getFolderRefString().isEmpty())
            {
                qWarning() << "shot" << shot->getName() << "has no files (?)";
                return QVariant();
            }
            else
            {
                return shot->getFolderRefString() + shot->getNameRefString();
            }
        }

        // If we made it here...
        qWarning() << "Ooops missing ShotModel role !!! " << role;
    }

    return QVariant();
}

QHash<int, QByteArray> ShotModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[NameRole] = "name";
    roles[ShotTypeRole] = "shotType";
    roles[FileTypeRole] = "fileType";
    roles[PreviewRole] = "preview";
    roles[DurationRole] = "duration";
    roles[SizeRole] = "size";
    roles[DateRole] = "date";
    roles[GpsRole] = "gps";
    roles[CameraRole] = "camera";

    roles[PointerRole] = "pointer";
    roles[PathRole] = "path";

    return roles;
}

/* ************************************************************************** */
