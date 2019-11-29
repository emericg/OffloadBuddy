/*!
 * COPYRIGHT (C) 2019 Emeric Grange - All Rights Reserved
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
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2019
 */

#ifndef UTILS_APP_H
#define UTILS_APP_H
/* ************************************************************************** */

#include <QUrl>
#include <QSize>
#include <QString>
#include <QObject>
#include <QVariantMap>

/* ************************************************************************** */

class UtilsApp : public QObject
{
    Q_OBJECT

public:
    explicit UtilsApp(QObject* parent = nullptr);
   ~UtilsApp();

    static Q_INVOKABLE void openWith(const QString &path);

    static Q_INVOKABLE QUrl getStandardPath(const QString &type);

    static Q_INVOKABLE QString appVersion();
    static Q_INVOKABLE QString appBuildDate();
    static Q_INVOKABLE void appExit();
};

/* ************************************************************************** */
#endif // UTILS_APP_H
