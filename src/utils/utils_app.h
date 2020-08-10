/*!
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
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2019
 */

#ifndef UTILS_APP_H
#define UTILS_APP_H
/* ************************************************************************** */

#include <QObject>
#include <QUrl>
#include <QString>
#include <QStringList>

/* ************************************************************************** */

class UtilsApp : public QObject
{
    Q_OBJECT

    QString m_appPath;

    // Singleton
    static UtilsApp *instance;
    UtilsApp();
    ~UtilsApp();

public:
    static UtilsApp *getInstance();

    QString getAppPath() const { return m_appPath; }
    void setAppPath(const QString &value);

    static Q_INVOKABLE QString appVersion();
    static Q_INVOKABLE QString appBuildDate();
    static Q_INVOKABLE QString appBuildDateTime();
    static Q_INVOKABLE QString appBuildMode();

    static Q_INVOKABLE void appExit();
    static Q_INVOKABLE void openWith(const QString &path);
    static Q_INVOKABLE QUrl getStandardPath(const QString &type);

    static Q_INVOKABLE bool checkMobileStoragePermissions();
    static Q_INVOKABLE bool getMobileStoragePermissions();
    static Q_INVOKABLE bool checkMobileStorageReadPermission();
    static Q_INVOKABLE bool getMobileStorageReadPermission();
    static Q_INVOKABLE bool checkMobileStorageWritePermission();
    static Q_INVOKABLE bool getMobileStorageWritePermission();

    static Q_INVOKABLE bool checkMobileLocationPermission();
    static Q_INVOKABLE bool getMobileLocationPermission();

    static Q_INVOKABLE bool checkMobilePhoneStatePermission();
    static Q_INVOKABLE bool getMobilePhoneStatePermission();

    static Q_INVOKABLE QString getMobileDeviceModel();
    static Q_INVOKABLE QString getMobileDeviceSerial();

    static Q_INVOKABLE void vibrate(int ms);

#if defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
    static Q_INVOKABLE int getMobileStorageCount();
    static Q_INVOKABLE QString getMobileStorageInternal();
    static Q_INVOKABLE QString getMobileStorageExternal(int index = 0);
    static Q_INVOKABLE QStringList getMobileStorageExternals();
#else
    static Q_INVOKABLE int getMobileStorageCount() { return 0; }
    static Q_INVOKABLE QString getMobileStorageInternal() { return QString(); }
    static Q_INVOKABLE QString getMobileStorageExternal(int index = 0) { Q_UNUSED(index) return QString(); }
    static Q_INVOKABLE QStringList getMobileStorageExternals() { return QStringList(); }
#endif
};

/* ************************************************************************** */
#endif // UTILS_APP_H
