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

#ifndef FIRMWARE_MANAGER_H
#define FIRMWARE_MANAGER_H
/* ************************************************************************** */

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QByteArray>
#include <QJsonDocument>

class QNetworkAccessManager;
class QNetworkReply;
class QFile;
class Device;

/* ************************************************************************** */

/*!
 * \brief The FirmwareManager class
 */
class FirmwareManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool hasGpFw READ hasGpFw NOTIFY firmwareCatalogUpdated)

    const QString m_catalogGoPro_url = "https://api.gopro.com/firmware/v2/catalog";
    QDateTime m_catalogGoPro_lastupdate;
    QByteArray m_catalogGoPro_data;
    QJsonDocument m_catalogGoPro_json;

    const QString m_catalogInsta_url = "https://openapi.insta360.com/website/appDownload/getGroupApp?group=%s&X-Language=en-us";
    QDateTime m_catalogInsta_lastupdate;
    QByteArray m_catalogInsta_data;
    QJsonDocument m_catalogInsta_json;

    QNetworkAccessManager *m_nwManager = nullptr;
    QNetworkReply *firmwareReply = nullptr;
    QFile *firmwareFile = nullptr;

    bool hasGpFw() const { return false; }

    // Saved settings
    bool readSettings();
    bool writeSettings();

    // Singleton
    static FirmwareManager *instance;
    FirmwareManager();
    ~FirmwareManager();

Q_SIGNALS:
    void firmwareCatalogUpdated();

    void fwDlStarted();
    void fwDlProgress(float progress);
    void fwDlErrored();
    void fwDlFinished();

private slots:
    void catalogsUpdated(QNetworkReply *reply);
    void errorHttp();
    void errorSSL();

    void firmwareReplied();
    void firmwareFinished();
    void firmwareProgress(qint64, qint64);

public:
    static FirmwareManager *getInstance();

    void loadCatalogs();
    void updateCatalogs();

    void downloadFirmware(Device *device);
    void cancelFirmware(Device *device);
    void extractFirmware(Device *device);

    Q_INVOKABLE bool hasUpdate(const QString &model, const QString &version);
    Q_INVOKABLE QString lastUpdate(const QString &model);
    Q_INVOKABLE QDateTime lastDate(const QString &model);
    Q_INVOKABLE QString lastReleaseNotes(const QString &model);
    Q_INVOKABLE QString lastUrl(const QString &model);
};

/* ************************************************************************** */
#endif // FIRMWARE_MANAGER_H
