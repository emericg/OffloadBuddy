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

ShotModel::ShotModel(const ShotModel &other)
    : QAbstractListModel()
{
    m_shots = other.m_shots;
}

ShotModel::~ShotModel()
{
    qDeleteAll(m_shots);
    m_shots.clear();
}

/* ************************************************************************** */

void ShotModel::addFile(ofb_file *f, ofb_shot *s)
{
    //qDebug() << "ShotModel::addFile()";

    Shot *shot = getShotAt(s->file_type, s->shot_id, s->camera_id);
    if (shot)
    {
        //qDebug() << "Adding file:" << f->name << "to an existing shot";
        shot->addFile(f);
    }
    else
    {
        //qDebug() << "file:" << file_name << "is a new shot";
        shot = new Shot(s->file_type, this);
        if (shot)
        {
            shot->addFile(f);
            shot->setFileId(s->shot_id);
            shot->setCameraId(s->camera_id);
            if (shot->isValid())
            {
                addShot(shot);
            }
            else // FIXME what if the THM arrives first?
            {
                qDebug() << "Invalid shot: " << shot->getName();
                delete shot;
            }
        }
    }

    delete s;
}

void ShotModel::addShot(Shot *shot)
{
    if (shot)
    {
        beginInsertRows(QModelIndex(), getShotCount(), getShotCount());
        m_shots.push_back(shot);
        endInsertRows();
    }
}

void ShotModel::removeShot(Shot *shot)
{
    if (shot)
    {
        beginRemoveRows(QModelIndex(), m_shots.indexOf(shot), m_shots.indexOf(shot));
        m_shots.removeOne(shot);
        delete shot;
        endRemoveRows();
    }
}

/*!
 * \brief Return all of the shots from a device.
 * \param shots[out]
 */
void ShotModel::getShots(QList<Shot *> &shots)
{
    for (auto shot: m_shots)
    {
        shots.push_back(shot);
    }
}

/*!
 * \brief ShotModel::getShotAt
 * \param listIndex: might not be the same than gridview index...
 * \return
 */
Shot *ShotModel::getShotAt(int listIndex)
{
    //qDebug() << "ShotModel::index:" << index(0, listIndex);

    if (listIndex >= 0 && listIndex < m_shots.size())
    {
        return m_shots.at(listIndex);
    }

    return nullptr;
}

/*!
 * \brief ShotModel::getShotAt
 * \param name
 * \return
 */
Shot *ShotModel::getShotAt(QString name)
{
    //qDebug() << "ShotModel::name:" << name;

    if (!name.isEmpty())
    {
        for (int i = 0; i < m_shots.size(); i++)
        {
            Shot *search = qobject_cast<Shot*>(m_shots.at(i));
            if (search->getName() == name)
            {
                return search;
            }
        }

        //qDebug() << "No shot found for id" << file_id;
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

int ShotModel::getShotCount() const
{
    return m_shots.size();
}

/* ************************************************************************** */

int ShotModel::rowCount(const QModelIndex & parent) const
{
    Q_UNUSED(parent);
    return m_shots.count();
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
        else if (role == TypeRole)
            return shot->getType();
        else if (role == PreviewRole)
            return shot->getPreviewPicture();
        else if (role == SizeRole)
            return shot->getSize();
        else if (role == DurationRole)
            return shot->getDuration();
        else if (role == DateRole)
            return shot->getDate();
        else if (role == PointerRole)
            return QVariant::fromValue(shot);
        else
            qDebug() << "Ooops missing ShotModel role !!!";
    }

    return QVariant();
}

QHash<int, QByteArray> ShotModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[NameRole] = "name";
    roles[TypeRole] = "type";
    roles[PreviewRole] = "preview";
    roles[DurationRole] = "duration";
    roles[SizeRole] = "size";
    roles[DateRole] = "date";
    roles[GpsRole] = "gps";
    roles[CameraRole] = "camera";

    roles[PointerRole] = "pointer";

    return roles;
}

/* ************************************************************************** */
