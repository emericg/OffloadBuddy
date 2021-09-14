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
 * \date      2021
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#ifndef GEO_CODING_H
#define GEO_CODING_H
/* ************************************************************************** */

#include <QObject>

class QGeoCoordinate;
class QGeoCodingManager;
class QGeoServiceProvider;
class Shot;

/* ************************************************************************** */

/*!
 * \brief The GeoCoding class
 */
class GeoCoding: public QObject
{
    Q_OBJECT

    QGeoServiceProvider *geo_pro = nullptr;
    QGeoCodingManager *geo_mgr = nullptr;

    // Singleton
    static GeoCoding *instance;
    GeoCoding();
    ~GeoCoding();

public:
    static GeoCoding *getInstance();

    void getLocation(Shot *shot);
};

/* ************************************************************************** */
#endif // GEO_CODING_H
