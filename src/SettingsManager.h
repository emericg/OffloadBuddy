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

#ifndef SETTINGS_MANAGER_H
#define SETTINGS_MANAGER_H
/* ************************************************************************** */

#include <QObject>
#include <QVariant>
#include <QList>

#include <QTimer>

class QStorageInfo;
class MediaDirectory;

/* ************************************************************************** */

/*!
 * \brief The SettingsManager class
 *
 * Handle application settings, and syncing with associated settings file.
 */
class SettingsManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(uint apptheme READ getAppTheme WRITE setAppTheme NOTIFY appThemeChanged)
    Q_PROPERTY(uint appunits READ getAppUnits WRITE setAppUnits NOTIFY appUnitsChanged)
    Q_PROPERTY(bool autolaunch READ getAutoLaunch WRITE setAutoLaunch NOTIFY autoLaunchChanged)
    Q_PROPERTY(bool automerge READ getAutoMerge WRITE setAutoMerge NOTIFY autoMergeChanged)
    Q_PROPERTY(bool autometadata READ getAutoMetadata WRITE setAutoMetadata NOTIFY autoMetadataChanged)
    Q_PROPERTY(bool autodelete READ getAutoDelete WRITE setAutoDelete NOTIFY autoDeleteChanged)
    Q_PROPERTY(bool ignorejunk READ getIgnoreJunk WRITE setIgnoreJunk NOTIFY ignoreJunkChanged)
    Q_PROPERTY(bool ignorehdaudio READ getIgnoreHdAudio WRITE setIgnoreHdAudio NOTIFY ignoreHdAudioChanged)
    Q_PROPERTY(uint contenthierarchy READ getContentHierarchy WRITE setContentHierarchy NOTIFY contentHierarchyChanged)

    Q_PROPERTY(QVariant directoriesList READ getDirectories NOTIFY directoriesUpdated)

    bool readSettings();
    bool writeSettings();

    // Global
    unsigned m_appTheme = 0;
    unsigned m_appUnits = 0;
    bool m_autoLaunch = false;
    bool m_ignoreJunk = true;
    bool m_ignoreHdAudio = false;
    bool m_autoMerge = true;
    bool m_autoTelemetry = true;
    bool m_autoDelete = false;
    unsigned m_contentHierarchy = 0;

    // Media directories
    QList <QObject *> m_mediaDirectories;

    // Singleton
    static SettingsManager *instance;
    SettingsManager();
    ~SettingsManager();

Q_SIGNALS:
    void appThemeChanged();
    void appUnitsChanged();
    void autoLaunchChanged();
    void autoMergeChanged();
    void autoMetadataChanged();
    void autoDeleteChanged();
    void ignoreJunkChanged();
    void ignoreHdAudioChanged();
    void contentHierarchyChanged();
    void directoriesUpdated();

public:
    static SettingsManager *getInstance();

    unsigned getAppTheme() const { return m_appTheme; }
    void setAppTheme(unsigned value) { m_appTheme = value; writeSettings(); }

    unsigned getAppUnits() const { return m_appUnits; }
    void setAppUnits(unsigned value) { m_appUnits = value; writeSettings(); }

    bool getAutoLaunch() const { return m_autoLaunch; }
    void setAutoLaunch(bool value) { m_autoLaunch = value; writeSettings(); }

    bool getAutoMerge() const { return m_autoMerge; }
    void setAutoMerge(bool value) { m_autoMerge = value; writeSettings(); }

    bool getAutoMetadata() const { return m_autoTelemetry; }
    void setAutoMetadata(bool value) { m_autoTelemetry = value; writeSettings(); }

    bool getAutoDelete() const { return m_autoDelete; }
    void setAutoDelete(bool value) { m_autoDelete = value; writeSettings(); }

    bool getIgnoreJunk() const { return m_ignoreJunk; }
    void setIgnoreJunk(bool value) { m_ignoreJunk = value; writeSettings(); }

    bool getIgnoreHdAudio() const { return m_ignoreHdAudio; }
    void setIgnoreHdAudio(bool value) { m_ignoreHdAudio = value; writeSettings(); }

    unsigned getContentHierarchy() const { return m_contentHierarchy; }
    void setContentHierarchy(unsigned value) { m_contentHierarchy = value; writeSettings(); }

    QVariant getDirectories() const { if (m_mediaDirectories.size() > 0) { return QVariant::fromValue(m_mediaDirectories); } return QVariant(); }
    const QList <QObject *> *getDirectoriesList() const { return &m_mediaDirectories; }

public slots:
    void addDirectory(QString path);
    void deleteDirectory(QString path);
    void directoryModified();
};

/* ************************************************************************** */
#endif // SETTINGS_MANAGER_H
