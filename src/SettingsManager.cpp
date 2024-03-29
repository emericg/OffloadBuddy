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

#include "SettingsManager.h"
#include "MediaDirectory.h"

#include <QCoreApplication>
#include <QSettings>
#include <QLocale>
#include <QDebug>

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
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

bool SettingsManager::readSettings()
{
    bool status = false;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());

    if (settings.status() == QSettings::NoError)
    {
        if (settings.contains("ApplicationWindow/x"))
            m_appPosition.setWidth(settings.value("ApplicationWindow/x").toInt());
        if (settings.contains("ApplicationWindow/y"))
            m_appPosition.setHeight(settings.value("ApplicationWindow/y").toInt());
        if (settings.contains("ApplicationWindow/width"))
            m_appSize.setWidth(settings.value("ApplicationWindow/width").toInt());
        if (settings.contains("ApplicationWindow/height"))
            m_appSize.setHeight(settings.value("ApplicationWindow/height").toInt());
        if (settings.contains("ApplicationWindow/visibility"))
            m_appVisibility = settings.value("ApplicationWindow/visibility").toUInt();

        if (settings.contains("global/appTheme"))
            m_appTheme = settings.value("global/appTheme").toString();

        if (settings.contains("global/appThemeAuto"))
            m_appThemeAuto = settings.value("global/appThemeAuto").toBool();

        if (settings.contains("global/appThemeCSD"))
            m_appThemeCSD = settings.value("global/appThemeCSD").toBool();

        if (settings.contains("global/appUnits"))
            m_appUnits = settings.value("global/appUnits").toUInt();

        if (settings.contains("global/appLanguage"))
            m_appLanguage = settings.value("global/appLanguage").toString();

        if (settings.contains("global/autoMerge"))
            m_autoMerge = settings.value("global/autoMerge").toBool();

        if (settings.contains("global/autoTelemetry"))
            m_autoTelemetry = settings.value("global/autoTelemetry").toBool();

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

        if (settings.contains("global/moveToTrash"))
            m_moveToTrash = settings.value("global/moveToTrash").toBool();

        if (settings.contains("global/librarySortRole"))
            m_librarySortRole = settings.value("global/librarySortRole").toUInt();

        if (settings.contains("global/librarySortOrder"))
            m_librarySortOrder = settings.value("global/librarySortOrder").toUInt();

        if (settings.contains("global/deviceSortRole"))
            m_deviceSortRole = settings.value("global/deviceSortRole").toUInt();

        if (settings.contains("global/deviceSortOrder"))
            m_deviceSortOrder = settings.value("global/deviceSortOrder").toUInt();

        status = true;
    }
    else
    {
        qWarning() << "QSettings READ error:" << settings.status();
    }

    return status;
}

/* ************************************************************************** */

bool SettingsManager::writeSettings()
{
    bool status = false;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());

    if (settings.isWritable())
    {
        settings.setValue("global/appTheme", m_appTheme);
        settings.setValue("global/appThemeAuto", m_appThemeAuto);
        settings.setValue("global/appThemeCSD", m_appThemeCSD);
        settings.setValue("global/appUnits", m_appUnits);
        settings.setValue("global/appLanguage", m_appLanguage);
        settings.setValue("global/autoMerge", m_autoMerge);
        settings.setValue("global/autoTelemetry", m_autoTelemetry);
        settings.setValue("global/autoDelete", m_autoDelete);
        settings.setValue("global/ignoreJunk", m_ignoreJunk);
        settings.setValue("global/ignoreHdAudio", m_ignoreHdAudio);
        settings.setValue("global/thumbQuality", m_thumbQuality);
        settings.setValue("global/thumbFormat", m_thumbFormat);
        settings.setValue("global/thumbSize", m_thumbSize);
        settings.setValue("global/moveToTrash", m_moveToTrash);
        settings.setValue("global/librarySortRole", m_librarySortRole);
        settings.setValue("global/librarySortOrder", m_librarySortOrder);
        settings.setValue("global/deviceSortRole", m_deviceSortRole);
        settings.setValue("global/deviceSortOrder", m_deviceSortOrder);

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

void SettingsManager::setAppTheme(const QString &value)
{
    if (m_appTheme != value)
    {
        m_appTheme = value;
        writeSettings();
        Q_EMIT appThemeChanged();
    }
}

void SettingsManager::setAppThemeAuto(const bool value)
{
    if (m_appThemeAuto != value)
    {
        m_appThemeAuto = value;
        writeSettings();
        Q_EMIT appThemeAutoChanged();
    }
}

void SettingsManager::setAppThemeCSD(const bool value)
{
    if (m_appThemeCSD != value)
    {
        m_appThemeCSD = value;
        writeSettings();
        Q_EMIT appThemeCSDChanged();
    }
}

void SettingsManager::setAppUnits(const unsigned value)
{
    if (m_appUnits != value)
    {
        m_appUnits = value;
        writeSettings();
        Q_EMIT appUnitsChanged();
    }
}

void SettingsManager::setAppLanguage(const QString &value)
{
    if (m_appLanguage != value)
    {
        m_appLanguage = value;
        writeSettings();
        Q_EMIT appLanguageChanged();
    }
}

void SettingsManager::setAppOrientation(const QString &value)
{
    if (m_appOrientation != value)
    {
        m_appOrientation = value;
        writeSettings();
        Q_EMIT appOrientationChanged();
    }
}

void SettingsManager::setAutoMerge(const bool value)
{
    if (m_autoMerge != value)
    {
        m_autoMerge = value;
        writeSettings();
        Q_EMIT autoMergeChanged();
    }
}

void SettingsManager::setAutoTelemetry(const bool value)
{
    if (m_autoTelemetry != value)
    {
        m_autoTelemetry = value;
        writeSettings();
        Q_EMIT autoTelemetryChanged();
    }
}
void SettingsManager::setAutoDelete(const bool value)
{
    if (m_autoDelete != value)
    {
        m_autoDelete = value;
        writeSettings();
        Q_EMIT autoDeleteChanged();
    }
}

void SettingsManager::setIgnoreJunk(const bool value)
{
    if (m_ignoreJunk != value)
    {
        m_ignoreJunk = value;
        writeSettings();
        Q_EMIT ignoreJunkChanged();
    }
}

void SettingsManager::setIgnoreHdAudio(const bool value)
{
    if (m_ignoreHdAudio != value)
    {
        m_ignoreHdAudio = value;
        writeSettings();
        Q_EMIT ignoreHdAudioChanged();
    }
}

void SettingsManager::setThumbQuality(const unsigned value)
{
    if (m_thumbQuality != value)
    {
        m_thumbQuality = value;
        writeSettings();
        Q_EMIT thumbQualityChanged();
    }
}

void SettingsManager::setThumbFormat(const unsigned value)
{
    if (m_thumbFormat != value)
    {
        m_thumbFormat = value;
        writeSettings();
        Q_EMIT thumbFormatChanged();
    }
}

void SettingsManager::setThumbSize(const unsigned value)
{
    if (m_thumbSize != value)
    {
        m_thumbSize = value;
        writeSettings();
        Q_EMIT thumbSizeChanged();
    }
}

void SettingsManager::setMoveToTrash(const bool value)
{
    if (m_moveToTrash != value)
    {
        m_moveToTrash = value;
        writeSettings();
        Q_EMIT moveToTrashChanged();
    }
}

void SettingsManager::setMtpFullScan(const bool value)
{
    if (m_mtpFullScan != value)
    {
        m_mtpFullScan = value;
        writeSettings();
        Q_EMIT mtpFullScanChanged();
    }
}

void SettingsManager::setLibrarySortRole(const unsigned value)
{
    if (m_librarySortRole != value)
    {
        m_librarySortRole = value;
        writeSettings();
        Q_EMIT librarySortChanged();
    }
}

void SettingsManager::setLibrarySortOrder(const unsigned value)
{
    if (m_librarySortOrder != value)
    {
        m_librarySortOrder = value;
        writeSettings();
        Q_EMIT librarySortChanged();
    }
}

void SettingsManager::setDeviceSortRole(const unsigned value)
{
    if (m_deviceSortRole != value)
    {
        m_deviceSortRole = value;
        writeSettings();
        Q_EMIT deviceSortChanged();
    }
}

void SettingsManager::setDeviceSortOrder(const unsigned value)
{
    if (m_deviceSortOrder != value)
    {
        m_deviceSortOrder = value;
        writeSettings();
        Q_EMIT deviceSortChanged();
    }
}
