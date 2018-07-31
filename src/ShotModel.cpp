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
    if (index.row() < 0 || index.row() >= m_shots.size())
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
    else if (role == DateRole)
        return shot->getDate();
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
    roles[DateRole] = "date";
    roles[GpsRole] = "gps";
    roles[CameraRole] = "camera";

    roles[PointerRole] = "pointer";

    return roles;
}
