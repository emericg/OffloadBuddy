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

#include "SettingsManager.h"
#include "MediaDirectory.h"
#include "Shot.h"

#include <QStandardPaths>
#include <QStorageInfo>
#include <QDir>

#include <QSettings>
#include <QDebug>

#define MEDIA_DIRECTORIES_MAX_COUNT 16

/* ************************************************************************** */

SettingsManager *SettingsManager::instance = nullptr;

SettingsManager *SettingsManager::getInstance()
{
    if (instance == nullptr)
    {
        instance = new SettingsManager();
    }

    return instance;
}

SettingsManager::SettingsManager()
{
    readSettings();
}

SettingsManager::~SettingsManager()
{
    qDeleteAll(m_mediaDirectories);
    m_mediaDirectories.clear();
}

/* ************************************************************************** */
/* ************************************************************************** */

bool SettingsManager::readSettings()
{
    bool status = false;

    QSettings settings("OffloadBuddy", "OffloadBuddy");

    if (settings.status() == QSettings::NoError)
    {
        if (settings.contains("global/appTheme"))
            m_appTheme = settings.value("global/appTheme").toUInt();

        if (settings.contains("global/appUnits"))
            m_appUnits = settings.value("global/appUnits").toUInt();

        if (settings.contains("global/autoMerge"))
            m_autoMerge = settings.value("global/autoMerge").toBool();

        if (settings.contains("global/autoMetadata"))
            m_autoTelemetry = settings.value("global/autoMetadata").toBool();

        if (settings.contains("global/autoDelete"))
            m_autoDelete = settings.value("global/autoDelete").toBool();

        if (settings.contains("global/ignoreJunk"))
            m_ignoreJunk = settings.value("global/ignoreJunk").toBool();

        if (settings.contains("global/ignoreHdAudio"))
            m_ignoreHdAudio = settings.value("global/ignoreHdAudio").toBool();

        if (settings.contains("global/thumbQuality"))
            m_thumbQuality = settings.value("global/thumbQuality").toUInt();

        if (settings.contains("global/thumbFormat"))
            m_thumbFormat = settings.value("global/thumbFormat").toUInt();

        if (settings.contains("global/thumbSize"))
            m_thumbSize = settings.value("global/thumbSize").toUInt();

        if (settings.contains("global/contentHierarchy"))
            m_contentHierarchy = settings.value("global/contentHierarchy").toUInt();

        for (int i = 1; i <= MEDIA_DIRECTORIES_MAX_COUNT; i++)
        {
            QString p = "MediaDirectories/" + QString::number(i) + "/path";
            QString t = "MediaDirectories/" + QString::number(i) + "/content";

            if (settings.contains(p) && settings.contains(t))
            {
                QString pp = settings.value(p).toString();
                int tt = settings.value(t).toInt();

                MediaDirectory *d = new MediaDirectory(pp, tt);
                m_mediaDirectories.push_back(d);
            }
        }

        if (m_mediaDirectories.isEmpty())
        {
            //createDefaultDirectory();
        }

        emit directoriesUpdated();

        status = true;
    }
    else
    {
        qDebug() << "QSettings READ error:" << settings.status();
    }

    return status;
}

bool SettingsManager::writeSettings()
{
    bool status = false;

    QSettings settings("OffloadBuddy", "OffloadBuddy");

    if (settings.isWritable())
    {
        settings.setValue("global/appTheme", m_appTheme);
        settings.setValue("global/appUnits", m_appUnits);
        settings.setValue("global/autoMerge", m_autoMerge);
        settings.setValue("global/autoMetadata", m_autoTelemetry);
        settings.setValue("global/autoDelete", m_autoDelete);
        settings.setValue("global/ignoreJunk", m_ignoreJunk);
        settings.setValue("global/ignoreHdAudio", m_ignoreHdAudio);
        settings.setValue("global/thumbQuality", m_thumbQuality);
        settings.setValue("global/thumbFormat", m_thumbFormat);
        settings.setValue("global/thumbSize", m_thumbSize);
        settings.setValue("global/contentHierarchy", m_contentHierarchy);
        settings.sync();

        int i = 1;
        for (auto d: m_mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd)
            {
                QString p = "MediaDirectories/" + QString::number(i) + "/path";
                QString t = "MediaDirectories/" + QString::number(i) + "/content";
                settings.setValue(p, dd->getPath());
                settings.setValue(t, dd->getContent());
                i++;
            }
        }
        for (; i < MEDIA_DIRECTORIES_MAX_COUNT; i++)
        {
            QString p = "MediaDirectories/" + QString::number(i) + "/path";
            QString t = "MediaDirectories/" + QString::number(i) + "/content";
            settings.remove(p);
            settings.remove(t);
        }

        if (settings.status() == QSettings::NoError)
        {
            status = true;
        }
        else
        {
            qDebug() << "QSettings WRITE error:" << settings.status();
        }
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

void SettingsManager::addDirectory(const QString &path)
{
    if (!path.isEmpty())
    {
        MediaDirectory *dd = new MediaDirectory(path, 0);
        if (dd->isAvailable())
        {
            m_mediaDirectories.push_back(dd);
            emit directoryAdded(dd->getPath());
            emit directoriesUpdated();

            directoryModified();
        }
    }
}

void SettingsManager::removeDirectory(const QString &path)
{
    if (!path.isEmpty())
    {
        for (auto d: m_mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                m_mediaDirectories.removeOne(d);
                emit directoryRemoved(dd->getPath());
                emit directoriesUpdated();

                directoryModified();
                break;
            }
        }
    }

    if (m_mediaDirectories.isEmpty())
    {
        //createDefaultDirectory();
    }
}

void SettingsManager::directoryModified()
{
    writeSettings();
}

void SettingsManager::createDefaultDirectory()
{
    // Create a default entry
    MediaDirectory *d = new MediaDirectory();
    if (d)
    {
        m_mediaDirectories.push_back(d);
        writeSettings();
    }
/*
    // Create a default entries
    QString pathV = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation) + "/GoPro";
    QString pathP = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/GoPro";
    MediaDirectory *dv = new MediaDirectory(pathV, 1);
    m_mediaDirectories.push_back(dv);
    MediaDirectory *dp = new MediaDirectory(pathP, 2);
    m_mediaDirectories.push_back(dp);
*/
}

/* ************************************************************************** */
/* ************************************************************************** */

void SettingsManager::setAppTheme(unsigned value)
{
    if (m_appTheme != value)
    {
        m_appTheme = value;
        writeSettings();
        Q_EMIT appThemeChanged();
    }
}

void SettingsManager::setAppUnits(unsigned value)
{
    if (m_appUnits != value)
    {
        m_appUnits = value;
        writeSettings();
        Q_EMIT appUnitsChanged();
    }
}

void SettingsManager::setAutoMerge(bool value)
{
    if (m_autoMerge != value)
    {
        m_autoMerge = value;
        writeSettings();
        Q_EMIT autoMergeChanged();
    }
}

void SettingsManager::setAutoMetadata(bool value)
{
    if (m_autoTelemetry != value)
    {
        m_autoTelemetry = value;
        writeSettings();
        Q_EMIT autoMetadataChanged();
    }
}
void SettingsManager::setAutoDelete(bool value)
{
    if (m_autoDelete != value)
    {
        m_autoDelete = value;
        writeSettings();
        Q_EMIT autoDeleteChanged();
    }
}

void SettingsManager::setIgnoreJunk(bool value)
{
    if (m_ignoreJunk != value)
    {
        m_ignoreJunk = value;
        writeSettings();
        Q_EMIT ignoreJunkChanged();
    }
}

void SettingsManager::setIgnoreHdAudio(bool value)
{
    if (m_ignoreHdAudio != value)
    {
        m_ignoreHdAudio = value;
        writeSettings();
        Q_EMIT ignoreHdAudioChanged();
    }
}

void SettingsManager::setThumbQuality(unsigned value)
{
    if (m_thumbQuality != value)
    {
        m_thumbQuality = value;
        writeSettings();
        Q_EMIT thumbQualityChanged();
    }
}

void SettingsManager::setThumbFormat(unsigned value)
{
    if (m_thumbFormat != value)
    {
        m_thumbFormat = value;
        writeSettings();
        Q_EMIT thumbFormatChanged();
    }
}

void SettingsManager::setThumbSize(unsigned value)
{
    if (m_thumbSize != value)
    {
        m_thumbSize = value;
        writeSettings();
        Q_EMIT thumbSizeChanged();
    }
}

void SettingsManager::setMtpFullScan(bool value)
{
    if (m_mtpFullScan != value)
    {
        m_mtpFullScan = value;
    }
}

void SettingsManager::setContentHierarchy(unsigned value)
{
    if (m_contentHierarchy != value)
    {
        m_contentHierarchy = value;
        writeSettings();
        Q_EMIT contentHierarchyChanged();
    }
}
