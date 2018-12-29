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

#ifndef SHOT_FILTER_H
#define SHOT_FILTER_H
/* ************************************************************************** */

#include "Shot.h"

#include <QObject>
#include <QSortFilterProxyModel>

/* ************************************************************************** */

class ShotFilter : public QSortFilterProxyModel
{
    Q_OBJECT

    QList<int> m_acceptedTypes;
    QString m_acceptedFolder;

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

public:
    ShotFilter(QObject *parent = nullptr);
    ~ShotFilter();

    void setAcceptedTypes(const QList<int> acceptedTypes) { m_acceptedTypes = acceptedTypes; }
    void setAcceptedFolder(const QString acceptedFolder) { m_acceptedFolder = acceptedFolder; }
};

//Q_DECLARE_METATYPE(ShotFilter*)

/* ************************************************************************** */
#endif // SHOT_FILTER_H
