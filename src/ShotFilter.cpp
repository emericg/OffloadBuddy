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

#include "ShotFilter.h"
#include "ShotModel.h"

#include <QDebug>

/* ************************************************************************** */

ShotFilter::ShotFilter(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    //
}

ShotFilter::~ShotFilter()
{
    //
}

/* ************************************************************************** */

bool ShotFilter::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    bool accepted = true;

    if (m_acceptedTypes.empty() && m_acceptedFolder.isEmpty())
        return accepted;

    QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);

    if (!m_acceptedFolder.isEmpty())
    {
        QString path = sourceModel()->data(index, ShotModel::PathRole).toString();
        if (!path.contains(m_acceptedFolder))
            accepted = false;
    }

    if (!m_acceptedTypes.empty())
    {
        int type = sourceModel()->data(index, ShotModel::TypeRole).toInt();
        if (!m_acceptedTypes.contains(type))
            accepted = false;
    }

    return accepted;
}

/* ************************************************************************** */
