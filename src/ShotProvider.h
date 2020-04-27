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

#ifndef SHOT_PROVIDER_H
#define SHOT_PROVIDER_H
/* ************************************************************************** */

#include "Shot.h"
#include "ShotModel.h"
#include "ShotFilter.h"

#include <QObject>
#include <QVariant>

/* ************************************************************************** */

/*!
 * \brief The ShotProvider class
 */
class ShotProvider: public QObject
{
    Q_OBJECT

protected:
    Q_PROPERTY(ShotModel *shotModel READ getShotModel NOTIFY shotModelUpdated)
    Q_PROPERTY(ShotFilter *shotFilter READ getShotFilter NOTIFY shotModelUpdated)

    ShotModel *m_shotModel = nullptr;
    ShotFilter *m_shotFilter = nullptr;

Q_SIGNALS:
    void shotModelUpdated();
    void shotsUpdated();

public:
    ShotProvider();
    virtual ~ShotProvider();

    ShotModel *getShotModel() const { return m_shotModel; }
    ShotFilter *getShotFilter() const { return m_shotFilter; }

    void addShot(Shot *shot);
    void deleteShot(Shot *shot);

public slots:
    void orderByDate();
    void orderByDuration();
    void orderByShotType();
    void orderByName();

    void filterByType(const QString &type);
    void filterByFolder(const QString &path);

    //QVariant getShotByModelIndex(const int index) const { return QVariant::fromValue(m_shotModel->getShotAtIndex(index)); }
    QVariant getShotByProxyIndex(const int index) const { QModelIndex proxyIndex = m_shotFilter->index(index, 0); return QVariant::fromValue(m_shotFilter->data(proxyIndex, ShotModel::PointerRole)); }
    //QVariant getShotByName(const QString &name) const { return QVariant::fromValue(m_shotModel->getShotWithName(name)); }
    QVariant getShotByUuid(const QString &uuid) const { return QVariant::fromValue(m_shotModel->getShotWithUuid(uuid)); }
};

/* ************************************************************************** */
#endif // SHOT_PROVIDER_H
