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
    qDeleteAll(m_shots);
    m_shots.clear();
}

/* ************************************************************************** */
/* ************************************************************************** */

void ShotModel::sanetize()
{
    // Check if each files of the shot still exists
    for (auto shot: qAsConst(m_shots))
    {
        QList <ofb_file *> files = shot->getFiles();

        for (auto file: qAsConst(files))
        {
            QFile f(file->filesystemPath);
            if (!f.exists())
            {
                // Remove the shot alltogether if one file is missing
                removeShot(shot);
                return;
            }
        }
    }
}

/* ************************************************************************** */

void ShotModel::addFile(ofb_file *f, ofb_shot *s)
{
    //qDebug() << "ShotModel::addFile()" << f->filesystemPath;

    Shot *shot = nullptr;

    if (s->shot_id > 0)
    {
        shot = getShotAt(s->shot_type, s->shot_id, s->camera_id);

        if (shot && f->filesystemPath.contains(shot->getFolderRefString()) == false)
        {
            // We make sure files are in the same folder. Useful when shot ids are looping.
            shot = nullptr;
        }
    }
    else
    {
        shot = getShotWithPath(f->filesystemPath);
        if (shot)
        {
            delete s;
            return;
        }
    }

    if (!shot)
    {
        //qDebug() << "File:" << f->name << "is from a new shot";
        shot = new Shot(s->shot_type, this);
        if (shot)
        {
            shot->setFileId(s->shot_id);
            shot->setCameraId(s->camera_id);
            addShot(shot);
        }
        else
        {
            delete f;
        }
    }

    if (shot)
    {
        //qDebug() << "Adding file:" << f->name << "to an existing shot";
        shot->addFile(f);

        // update content stats
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
        // update content stats
        m_fileCount -= shot->getFileCount();
        m_diskSpace -= shot->getFullSize();
        Q_EMIT statsUpdated();

        // remove
        beginRemoveRows(QModelIndex(), m_shots.indexOf(shot), m_shots.indexOf(shot));
        m_shots.removeOne(shot);
        delete shot;
        endRemoveRows();
    }
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
Shot *ShotModel::getShotAtIndex(int listIndex)
{
    //qDebug() << "ShotModel::getShotAtIndex:" << index(0, listIndex);

    if (listIndex >= 0 && listIndex < m_shots.size())
    {
        return m_shots.at(listIndex);
    }

    return nullptr;
}

/*!
 * \brief ShotModel::getShotWithName
 * \param name
 * \return
 */
Shot *ShotModel::getShotWithName(const QString &name)
{
    if (!name.isEmpty())
    {
        for (auto shot: qAsConst(m_shots))
        {
            Shot *search = qobject_cast<Shot*>(shot);
            if (search->getName() == name)
            {
                return search;
            }
        }

        //qDebug() << "No shot found for name" << name;
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
 * \brief ShotModel::getShotWithPath
 * \param path
 * \return
 */
Shot *ShotModel::getShotWithPath(const QString &path)
{
    if (!path.isEmpty())
    {
        for (auto shot: qAsConst(m_shots))
        {
            Shot *search = qobject_cast<Shot*>(shot);
            if (search)
            {
                QList <ofb_file *> files = search->getFiles();

                for (auto file: qAsConst(files))
                {
                    if (file->filesystemPath == path)
                    {
                        return search;
                    }
                }
            }
        }

        //qDebug() << "No shot found for path" << path;
    }

    return nullptr;
}

/*!
 * \brief ShotModel::getShotAt
 * \param type
 * \param file_id
 * \param camera_id
 * \return
 *
 * This function is used to associate new files to existing shots. We go backward
 * for faster association, because we will just most likely use the last created
 * shot.
 */
Shot *ShotModel::getShotAt(Shared::ShotType type, int file_id, int camera_id) const
{
    if (file_id > 0)
    {
        for (int i = m_shots.size()-1; i >= 0; i--)
        {
            Shot *search = qobject_cast<Shot*>(m_shots.at(i));
            if (search && search->getShotType() == type)
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
            if (shot->getFiles().empty())
            {
                qWarning() << "shot" << shot->getName() << "has no files (?)";
                return QVariant();
            }

            return shot->getFiles().at(0)->filesystemPath;
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
