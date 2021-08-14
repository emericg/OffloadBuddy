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

#include "FirmwareManager.h"
#include "Device.h"
#include "utils/utils_versionchecker.h"

#include <QFile>
#include <QSettings>
#include <QStandardPaths>
#include <QCoreApplication>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

/* ************************************************************************** */

FirmwareManager *FirmwareManager::instance = nullptr;

FirmwareManager *FirmwareManager::getInstance()
{
    if (instance == nullptr)
    {
        instance = new FirmwareManager();
    }

    return instance;
}

FirmwareManager::FirmwareManager()
{
    //
}

FirmwareManager::~FirmwareManager()
{
    delete m_nwManager;
}

/* ************************************************************************** */
/* ************************************************************************** */

bool FirmwareManager::readSettings()
{
    bool status = false;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());

    if (settings.status() == QSettings::NoError)
    {
        if (settings.contains("firmware/catalogGoPro"))
            m_catalogGoPro_lastupdate = settings.value("firmware/catalogGoPro").toDateTime();

        if (settings.contains("firmware/catalogInsta"))
            m_catalogInsta_lastupdate = settings.value("firmware/catalogInsta").toDateTime();

        status = true;
    }
    else
    {
        qWarning() << "QSettings READ error:" << settings.status();
    }

    return status;
}

bool FirmwareManager::writeSettings()
{
    bool status = false;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());

    if (settings.isWritable())
    {
        settings.setValue("firmware/catalogGoPro", m_catalogGoPro_lastupdate.toString("yyyy-MM-dd"));
        settings.setValue("firmware/catalogInsta", m_catalogInsta_lastupdate.toString("yyyy-MM-dd"));

        if (settings.status() == QSettings::NoError)
        {
            status = true;
        }
        else
        {
            qWarning() << "QSettings WRITE error:" << settings.status();
        }
    }
    else
    {
        qWarning() << "QSettings WRITE error: read only file?";
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

void FirmwareManager::loadCatalogs()
{
    //qDebug() << "FirmwareManager::loadCatalogs()";

    readSettings();

    QString path = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    if (!path.endsWith('/')) path += '/';

    bool status_gp = false;

    if (m_catalogGoPro_lastupdate.isValid() &&
        QDateTime::currentDateTime().daysTo(m_catalogGoPro_lastupdate) < 7)
    {
        QFile file(path + "gopro_firmwares.json");
        if (file.open(QIODevice::ReadOnly))
        {
            m_catalogGoPro_data.clear();
            m_catalogGoPro_data = file.readAll();
            if (m_catalogGoPro_data.size() > 0)
            {
                status_gp = true;

                // Parse
                m_catalogGoPro_json = QJsonDocument().fromJson(m_catalogGoPro_data);
            }

            file.close();
        }
    }

    if (!status_gp)
    {
        updateCatalogs();
    }
}

/* ************************************************************************** */

void FirmwareManager::updateCatalogs()
{
    //qDebug() << "FirmwareManager::updateCatalogs()";

    if (!m_nwManager)
    {
        m_nwManager = new QNetworkAccessManager(this);
    }

    if (m_nwManager)
    {
        connect(m_nwManager, &QNetworkAccessManager::finished, this, &FirmwareManager::catalogsUpdated);
        m_nwManager->get(QNetworkRequest(QUrl(m_catalogGoPro_url)));
    }
}

/* ************************************************************************** */

void FirmwareManager::catalogsUpdated(QNetworkReply *reply)
{
    //qDebug() << "FirmwareManager::catalogsUpdated()";

    m_catalogGoPro_data.clear();
    m_catalogGoPro_data = reply->readAll();

    if (m_catalogGoPro_data.size())
    {
        // Parse
        m_catalogGoPro_json = QJsonDocument().fromJson(m_catalogGoPro_data);

        // Write
        QString path = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
        if (!path.endsWith('/')) path += '/';
        QFile jsonFile(path + "gopro_firmwares.json");
        if (jsonFile.open(QIODevice::WriteOnly))
        {
            jsonFile.write(m_catalogGoPro_json.toJson());
            jsonFile.close();

            m_catalogGoPro_lastupdate = QDateTime::currentDateTime();
            writeSettings();
        }
    }
    else
    {
        qWarning() << "Catalog downloaded is empty";
    }
}

void FirmwareManager::errorHttp()
{
    qWarning() << "FirmwareManager::errorHttp()";
}

void FirmwareManager::errorSSL()
{
    qWarning() << "FirmwareManager::errorSSL()";
}

/* ************************************************************************** */
/* ************************************************************************** */

void FirmwareManager::downloadFirmware(Device *d)
{
    if (d)
    {
        QUrl url = lastUrl(d->getModel());
        qDebug() << "FirmwareManager::downloadFirmware(" << url << ")";

        QString folderPath = d->getPath();
        QString fileName = folderPath + "/UPDATE.zip";

        if (QFile::exists(fileName)) QFile::remove(fileName);

        firmwareFile = new QFile(fileName);
        if (!firmwareFile->open(QIODevice::WriteOnly))
        {
            qWarning() <<  "Unable to save the file" << fileName;

            delete firmwareFile;
            firmwareFile = nullptr;
            return;
        }

        //////////////////////////

        if (!m_nwManager)
        {
            m_nwManager = new QNetworkAccessManager(this);
        }

        if (m_nwManager)
        {
            firmwareReply = m_nwManager->get(QNetworkRequest(url));

            connect(firmwareReply, SIGNAL(readyRead()), this, SLOT(firmwareReplied()));
            connect(firmwareReply, SIGNAL(downloadProgress(qint64,qint64)),
                    this, SLOT(firmwareProgress(qint64,qint64)));
            connect(firmwareReply, SIGNAL(finished()), this, SLOT(firmwareFinished()));
        }
    }
}

void FirmwareManager::cancelFirmware(Device *device)
{
    if (device && firmwareReply)
    {
        firmwareReply->abort();
    }
}

/* ************************************************************************** */

void FirmwareManager::firmwareReplied()
{
    if (firmwareReply && firmwareFile)
    {
        firmwareFile->write(firmwareReply->readAll());
    }
}

void FirmwareManager::firmwareFinished()
{
/*
    // download canceled
    //if (httpRequestAborted)
    {
        if (firmwareFile)
        {
            firmwareFile->close();
            firmwareFile->remove();
            delete firmwareFile;
            firmwareFile = nullptr;
        }
    }
*/
    // download finished normally
    firmwareFile->flush();
    firmwareFile->close();
/*
    // handle redirection url?
    QVariant redirectionTarget = firmwareReply->attribute(QNetworkRequest::RedirectionTargetAttribute);
    if (firmwareReply->error())
    {
        //
    }
    else if (!redirectionTarget.isNull())
    {
        QUrl newUrl = url.resolved(redirectionTarget.toUrl());
    }
*/
    firmwareReply->deleteLater();
    firmwareReply = nullptr;
    delete firmwareFile;
    firmwareFile = nullptr;
}

void FirmwareManager::firmwareProgress(qint64 bytesRead, qint64 totalBytes)
{
    qDebug() << "FirmwareManager::firmwareProgress(" << bytesRead << "/" << totalBytes << ")";
}

/* ************************************************************************** */
/* ************************************************************************** */

bool FirmwareManager::hasUpdate(const QString &name, const QString &version)
{
    QJsonObject jsonObject = m_catalogGoPro_json.object();
    QJsonArray jsonArray = jsonObject["cameras"].toArray();

    foreach (const QJsonValue &value, jsonArray)
    {
        QJsonObject obj = value.toObject();
        QString n = obj["name"].toString();
        QString v = obj["version"].toString();

        if (n == name)
        {
            QString current = version;
            current.remove(0, 7);

            Version a(current);

            return !(a == v);
        }
    }

    return false;
}

QString FirmwareManager::lastUpdate(const QString &name)
{
    QJsonObject jsonObject = m_catalogGoPro_json.object();
    QJsonArray jsonArray = jsonObject["cameras"].toArray();

    foreach (const QJsonValue &value, jsonArray)
    {
        QJsonObject obj = value.toObject();
        if (name == obj["name"].toString())
        {
            return obj["version"].toString();
        }
    }

    return QString();
}

QDateTime FirmwareManager::lastDate(const QString &name)
{
    QJsonObject jsonObject = m_catalogGoPro_json.object();
    QJsonArray jsonArray = jsonObject["cameras"].toArray();

    foreach (const QJsonValue &value, jsonArray)
    {
        QJsonObject obj = value.toObject();
        if (name == obj["name"].toString())
        {
            return QDateTime::fromString(obj["release_date"].toString(), "yyyyMMdd");
        }
    }

    return QDateTime();
}

QString FirmwareManager::lastReleaseNotes(const QString &name)
{
    QJsonObject jsonObject = m_catalogGoPro_json.object();
    QJsonArray jsonArray = jsonObject["cameras"].toArray();

    foreach (const QJsonValue &value, jsonArray)
    {
        QJsonObject obj = value.toObject();
        if (name == obj["name"].toString())
        {
            return obj["release_html"].toString().section("</p>", 1, -1);
        }
    }

    return QString();
}

QString FirmwareManager::lastUrl(const QString &name)
{
    QJsonObject jsonObject = m_catalogGoPro_json.object();
    QJsonArray jsonArray = jsonObject["cameras"].toArray();

    foreach (const QJsonValue &value, jsonArray)
    {
        QJsonObject obj = value.toObject();
        if (name == obj["name"].toString())
        {
            return obj["url"].toString();
        }
    }

    return QString();
}

/* ************************************************************************** */
/* ************************************************************************** */
