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

Shot::Shot(QObject *parent)
{
    //
}

Shot::Shot(Shared::ShotType type)
{
    m_type = type;
}

Shot::~Shot()
{
    //
}

Shot::Shot(const Shot &other)
{
    m_type = other.m_type;
    m_camera_source = other.m_camera_source;

    m_file_name = other.m_file_name;
    m_file_date = other.m_file_date;
    m_file_number = other.m_file_number;

    m_date_shot = other.m_date_shot;

    m_jpg = other.m_jpg;

    m_duration = other.m_duration;
    m_mp4 = other.m_mp4;
    m_lrv = other.m_lrv;
    m_thm = other.m_thm;
}

/* ************************************************************************** */

void Shot::addFile(QString &file)
{
    QFileInfo fi(file);
    if (fi.exists() && fi.isReadable())
    {
        if (m_file_name.isEmpty())
            m_file_name = fi.baseName();

        if (!m_file_date.isValid())
            m_file_date = fi.birthTime();

        if (file.endsWith("JPG", Qt::CaseInsensitive))
        {
            m_jpg.push_back(file);
        }
        else if (file.endsWith("MP4", Qt::CaseInsensitive))
        {
            m_mp4.push_back(file);
        }
        else if (file.endsWith("LRV", Qt::CaseInsensitive))
        {
            m_lrv.push_back(file);
        }
        else if (file.endsWith("THM", Qt::CaseInsensitive))
        {
            m_thm.push_back(file);
        }
        else
        {
            qWarning() << "Shot::addFile(" << file << ") UNKNOWN FORMAT";
        }
    }
    else
    {
        qWarning() << "Shot::addFile(" << file << ") UNREADABLE";
    }
}

/* ************************************************************************** */

bool Shot::isValid()
{
    bool status = true;

    return status;
}

unsigned Shot::getType() const
{
/*
    if (m_type == Shared::SHOT_PICTURE_MULTI && m_jpg.size() == 1)
    {
        m_type = Shared::SHOT_PICTURE;
        emit shotUpdated();
    }
*/
    return m_type;
}

unsigned Shot::getSize() const
{
    return 0;
}

QString Shot::getPreview() const
{
    if (m_jpg.size() > 0)
        return m_jpg.at(0);
    else if (m_thm.size() > 0)
        return m_thm.at(0);

    return QString();
}

qint64 Shot::getDuration() const
{
    if (m_type < Shared::SHOT_PICTURE)
        return m_duration;
    else
        return m_jpg.count();
}

/* ************************************************************************** */
/* ************************************************************************** */

ShotModel::ShotModel(QObject *parent)
    : QAbstractListModel(parent)
{
    //
}

ShotModel::ShotModel(const ShotModel &other)
{
    m_shots = other.m_shots;
}

ShotModel::~ShotModel()
{
    qDeleteAll(m_shots);
    m_shots.clear();
}

void ShotModel::addShot(Shot *shot)
{
    beginInsertRows(QModelIndex(), rowCount(), rowCount());
    m_shots.push_back(shot);
    endInsertRows();
}

int ShotModel::rowCount(const QModelIndex & parent) const
{
    Q_UNUSED(parent);
    return m_shots.count();
}

QVariant ShotModel::data(const QModelIndex & index, int role) const
{
    if (index.row() < 0 || index.row() >= m_shots.count())
        return QVariant();

    Shot *shot = m_shots[index.row()];
    if (role == NameRole)
        return shot->getName();
    else if (role == TypeRole)
        return shot->getType();
    else if (role == PreviewRole)
        return shot->getPreview();
    else if (role == SizeRole)
        return shot->getSize();
    else if (role == DurationRole)
        return shot->getDuration();
    else if (role == PointerRole)
        return QVariant::fromValue(shot);
    else
        qDebug() << "Oups missing ShotModel role !!!";

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
    roles[DateFileRole] = "datefile";
    roles[DateShotRole] = "dateshot";
    roles[GpsRole] = "gps";
    roles[CameraRole] = "camera";

    roles[PointerRole] = "pointer";

    return roles;
}














/*
void ShotModel::appendRow(ListItem *item)
{
  appendRows(QList<ListItem*>() << item);
}

void ShotModel::appendRows(const QList<ListItem *> &items)
{
  beginInsertRows(QModelIndex(), rowCount(), rowCount()+items.size()-1);
  foreach(ListItem *item, items) {
    connect(item, SIGNAL(dataChanged()), SLOT(handleItemChange()));
    m_list.append(item);
  }
  endInsertRows();
}

void ShotModel::insertRow(int row, ListItem *item)
{
  beginInsertRows(QModelIndex(), row, row);
  connect(item, SIGNAL(dataChanged()), SLOT(handleItemChange()));
  m_list.insert(row, item);
  endInsertRows();
}

void ShotModel::handleItemChange()
{
  ListItem* item = static_cast<ListItem*>(sender());
  QModelIndex index = indexFromItem(item);
  if(index.isValid())
    emit dataChanged(index, index);
}

ListItem * ShotModel::find(const QString &id) const
{
  foreach(ListItem* item, m_list) {
    if(item->id() == id) return item;
  }
  return 0;
}

QModelIndex ShotModel::indexFromItem(const ListItem *item) const
{
  Q_ASSERT(item);
  for(int row=0; row<m_list.size(); ++row) {
    if(m_list.at(row) == item) return index(row);
  }
  return QModelIndex();
}

void ShotModel::clear()
{
  qDeleteAll(m_list);
  m_list.clear();
}

bool ShotModel::removeRow(int row, const QModelIndex &parent)
{
  Q_UNUSED(parent);
  if(row < 0 || row >= m_list.size()) return false;
  beginRemoveRows(QModelIndex(), row, row);
  delete m_list.takeAt(row);
  endRemoveRows();
  return true;
}

bool ShotModel::removeRows(int row, int count, const QModelIndex &parent)
{
  Q_UNUSED(parent);
  if(row < 0 || (row+count) >= m_list.size()) return false;
  beginRemoveRows(QModelIndex(), row, row+count-1);
  for(int i=0; i<count; ++i) {
    delete m_list.takeAt(row);
  }
  endRemoveRows();
  return true;
}

ListItem * ShotModel::takeRow(int row)
{
  beginRemoveRows(QModelIndex(), row, row);
  ListItem* item = m_list.takeAt(row);
  endRemoveRows();
  return item;
}
*/
