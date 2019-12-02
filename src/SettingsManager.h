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

    Q_PROPERTY(uint appTheme READ getAppTheme WRITE setAppTheme NOTIFY appThemeChanged)
    Q_PROPERTY(uint appUnits READ getAppUnits WRITE setAppUnits NOTIFY appUnitsChanged)
    Q_PROPERTY(bool autolaunch READ getAutoLaunch WRITE setAutoLaunch NOTIFY autoLaunchChanged)
    Q_PROPERTY(bool automerge READ getAutoMerge WRITE setAutoMerge NOTIFY autoMergeChanged)
    Q_PROPERTY(bool autometadata READ getAutoMetadata WRITE setAutoMetadata NOTIFY autoMetadataChanged)
    Q_PROPERTY(bool autodelete READ getAutoDelete WRITE setAutoDelete NOTIFY autoDeleteChanged)
    Q_PROPERTY(uint thumbQuality READ getThumbQuality WRITE setThumbQuality NOTIFY thumbQualityChanged)
    Q_PROPERTY(uint thumbFormat READ getThumbFormat WRITE setThumbFormat NOTIFY thumbFormatChanged)
    Q_PROPERTY(uint thumbSize READ getThumbSize WRITE setThumbSize NOTIFY thumbSizeChanged)
    Q_PROPERTY(bool ignorejunk READ getIgnoreJunk WRITE setIgnoreJunk NOTIFY ignoreJunkChanged)
    Q_PROPERTY(bool ignorehdaudio READ getIgnoreHdAudio WRITE setIgnoreHdAudio NOTIFY ignoreHdAudioChanged)
    Q_PROPERTY(bool mtpfullscan READ getMtpFullScan WRITE setMtpFullScan NOTIFY mtpFullScanChanged)
    Q_PROPERTY(uint contenthierarchy READ getContentHierarchy WRITE setContentHierarchy NOTIFY contentHierarchyChanged)
    Q_PROPERTY(QVariant directoriesList READ getDirectories NOTIFY directoriesUpdated)

    // Global
    unsigned m_appTheme = 0;
    unsigned m_appUnits = 0;
    bool m_autoLaunch = false;
    bool m_ignoreJunk = true;
    bool m_ignoreHdAudio = true;
    bool m_autoMerge = true;
    bool m_autoTelemetry = true;
    bool m_autoDelete = false;
    unsigned m_thumbQuality = 1;
    unsigned m_thumbFormat = 2;
    unsigned m_thumbSize = 2;
    bool m_mtpFullScan = false;
    unsigned m_contentHierarchy = 0;

    // Media directories
    QList <QObject *> m_mediaDirectories;

    // Singleton
    static SettingsManager *instance;
    SettingsManager();
    ~SettingsManager();

    bool readSettings();
    bool writeSettings();

Q_SIGNALS:
    void appThemeChanged();
    void appUnitsChanged();
    void autoLaunchChanged();
    void autoMergeChanged();
    void autoMetadataChanged();
    void autoDeleteChanged();
    void ignoreJunkChanged();
    void ignoreHdAudioChanged();
    void thumbQualityChanged();
    void thumbFormatChanged();
    void thumbSizeChanged();
    void mtpFullScanChanged();
    void contentHierarchyChanged();
    void directoriesUpdated();

public:
    static SettingsManager *getInstance();

    unsigned getAppTheme() const { return m_appTheme; }
    void setAppTheme(unsigned value);

    unsigned getAppUnits() const { return m_appUnits; }
    void setAppUnits(unsigned value);

    bool getAutoLaunch() const { return m_autoLaunch; }
    void setAutoLaunch(bool value);

    bool getAutoMerge() const { return m_autoMerge; }
    void setAutoMerge(bool value);

    bool getAutoMetadata() const { return m_autoTelemetry; }
    void setAutoMetadata(bool value);

    bool getAutoDelete() const { return m_autoDelete; }
    void setAutoDelete(bool value);

    bool getIgnoreJunk() const { return m_ignoreJunk; }
    void setIgnoreJunk(bool value);

    bool getIgnoreHdAudio() const { return m_ignoreHdAudio; }
    void setIgnoreHdAudio(bool value);

    unsigned getThumbQuality() const { return m_thumbQuality; }
    void setThumbQuality(unsigned value);

    unsigned getThumbFormat() const { return m_thumbFormat; }
    void setThumbFormat(unsigned value);

    unsigned getThumbSize() const { return m_thumbSize; }
    void setThumbSize(unsigned value);

    bool getMtpFullScan() const { return m_mtpFullScan; }
    void setMtpFullScan(bool value);

    unsigned getContentHierarchy() const { return m_contentHierarchy; }
    void setContentHierarchy(unsigned value);

    QVariant getDirectories() const { if (m_mediaDirectories.size() > 0) { return QVariant::fromValue(m_mediaDirectories); } return QVariant(); }
    const QList <QObject *> *getDirectoriesList() const { return &m_mediaDirectories; }

public slots:
    void addDirectory(const QString &path);
    void deleteDirectory(const QString &path);
    void directoryModified();
};

/* ************************************************************************** */
#endif // SETTINGS_MANAGER_H
