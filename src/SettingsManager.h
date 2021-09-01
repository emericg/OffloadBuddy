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

#ifndef SETTINGS_MANAGER_H
#define SETTINGS_MANAGER_H
/* ************************************************************************** */

#include <QObject>
#include <QVariant>
#include <QList>
#include <QSize>

/* ************************************************************************** */

namespace SettingsUtils
{
    Q_NAMESPACE

    enum OrderBy
    {
        OrderByDate = 0,
        OrderByDuration,
        OrderByShotType,
        OrderByName,
        OrderByFilePath,
        OrderBySize,
        OrderByGps,
        OrderByCamera,
    };
    Q_ENUM_NS(OrderBy)
}

/* ************************************************************************** */

/*!
 * \brief The SettingsManager class
 *
 * Handle application settings, and syncing with associated settings file.
 */
class SettingsManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool firstLaunch READ isFirstLaunch NOTIFY firstLaunchChanged)

    Q_PROPERTY(QSize initialSize READ getInitialSize NOTIFY initialSizeChanged)
    Q_PROPERTY(QSize initialPosition READ getInitialPosition NOTIFY initialSizeChanged)
    Q_PROPERTY(uint initialVisibility READ getInitialVisibility NOTIFY initialSizeChanged)

    Q_PROPERTY(uint appTheme READ getAppTheme WRITE setAppTheme NOTIFY appThemeChanged)
    Q_PROPERTY(bool appThemeAuto READ getAppThemeAuto WRITE setAppThemeAuto NOTIFY appThemeAutoChanged)
    Q_PROPERTY(bool appThemeCSD READ getAppThemeCSD WRITE setAppThemeCSD NOTIFY appThemeCSDChanged)
    Q_PROPERTY(uint appUnits READ getAppUnits WRITE setAppUnits NOTIFY appUnitsChanged)
    Q_PROPERTY(QString appLanguage READ getAppLanguage WRITE setAppLanguage NOTIFY appLanguageChanged)
    Q_PROPERTY(QString appOrientation READ getAppOrientation WRITE setAppOrientation NOTIFY appOrientationChanged)

    Q_PROPERTY(uint thumbQuality READ getThumbQuality WRITE setThumbQuality NOTIFY thumbQualityChanged)
    Q_PROPERTY(uint thumbFormat READ getThumbFormat WRITE setThumbFormat NOTIFY thumbFormatChanged)
    Q_PROPERTY(uint thumbSize READ getThumbSize WRITE setThumbSize NOTIFY thumbSizeChanged)
    Q_PROPERTY(bool autoMerge READ getAutoMerge WRITE setAutoMerge NOTIFY autoMergeChanged)
    Q_PROPERTY(bool autoTelemetry READ getAutoTelemetry WRITE setAutoTelemetry NOTIFY autoTelemetryChanged)
    Q_PROPERTY(bool autoDelete READ getAutoDelete WRITE setAutoDelete NOTIFY autoDeleteChanged)
    Q_PROPERTY(bool ignoreJunk READ getIgnoreJunk WRITE setIgnoreJunk NOTIFY ignoreJunkChanged)
    Q_PROPERTY(bool ignoreHdAudio READ getIgnoreHdAudio WRITE setIgnoreHdAudio NOTIFY ignoreHdAudioChanged)
    Q_PROPERTY(bool moveToTrash READ getMoveToTrash WRITE setMoveToTrash NOTIFY moveToTrashChanged)
    Q_PROPERTY(bool mtpFullScan READ getMtpFullScan WRITE setMtpFullScan NOTIFY mtpFullScanChanged)

    Q_PROPERTY(uint librarySortRole READ getLibrarySortRole WRITE setLibrarySortRole NOTIFY librarySortChanged)
    Q_PROPERTY(uint librarySortOrder READ getLibrarySortOrder WRITE setLibrarySortOrder NOTIFY librarySortChanged)
    Q_PROPERTY(uint deviceSortRole READ getDeviceSortRole WRITE setDeviceSortRole NOTIFY deviceSortChanged)
    Q_PROPERTY(uint deviceSortOrder READ getDeviceSortOrder WRITE setDeviceSortOrder NOTIFY deviceSortChanged)

    bool m_firstlaunch = true;

    // Application window
    QSize m_appSize;
    QSize m_appPosition;
    unsigned m_appVisibility = 1;               //!< QWindow::Visibility

    // Application generic
    unsigned m_appTheme = 0;
    bool m_appThemeAuto = false;
    bool m_appThemeCSD = false;
    unsigned m_appUnits = 0;                    //!< QLocale::MeasurementSystem
    QString m_appLanguage = "auto";
    QString m_appOrientation = "locked";

    // Application specific
    unsigned m_thumbQuality = 1;
    unsigned m_thumbFormat = 3;
    unsigned m_thumbSize = 3;
    bool m_ignoreJunk = true;
    bool m_ignoreHdAudio = true;
    bool m_autoMerge = false;
    bool m_autoTelemetry = false;
    bool m_autoDelete = false;
    bool m_moveToTrash = false;
    bool m_mtpFullScan = false;
    unsigned m_librarySortRole = SettingsUtils::OrderByDate;
    unsigned m_librarySortOrder = 1;
    unsigned m_deviceSortRole = SettingsUtils::OrderByDate;
    unsigned m_deviceSortOrder = 1;

    // Saved settings
    bool readSettings();
    bool writeSettings();

    // Singleton
    static SettingsManager *instance;
    SettingsManager();
    ~SettingsManager();

Q_SIGNALS:
    void firstLaunchChanged();
    void initialSizeChanged();
    void appThemeChanged();
    void appThemeAutoChanged();
    void appThemeCSDChanged();
    void appUnitsChanged();
    void appLanguageChanged();
    void appOrientationChanged();
    void autoMergeChanged();
    void autoTelemetryChanged();
    void autoDeleteChanged();
    void ignoreJunkChanged();
    void ignoreHdAudioChanged();
    void thumbQualityChanged();
    void thumbFormatChanged();
    void thumbSizeChanged();
    void moveToTrashChanged();
    void mtpFullScanChanged();
    void librarySortChanged();
    void deviceSortChanged();

public:
    static SettingsManager *getInstance();

    bool isFirstLaunch() const { return m_firstlaunch; }

    QSize getInitialSize() { return m_appSize; }
    QSize getInitialPosition() { return m_appPosition; }
    unsigned getInitialVisibility() { return m_appVisibility; }

    unsigned getAppTheme() const { return m_appTheme; }
    void setAppTheme(const unsigned value);

    bool getAppThemeAuto() const { return m_appThemeAuto; }
    void setAppThemeAuto(const bool value);

    bool getAppThemeCSD() const { return m_appThemeCSD; }
    void setAppThemeCSD(const bool value);

    unsigned getAppUnits() const { return m_appUnits; }
    void setAppUnits(const unsigned value);

    QString getAppLanguage() const { return m_appLanguage; }
    void setAppLanguage(const QString &value);

    QString getAppOrientation() const { return m_appOrientation; }
    void setAppOrientation(const QString &value);

    bool getAutoMerge() const { return m_autoMerge; }
    void setAutoMerge(const bool value);

    bool getAutoTelemetry() const { return m_autoTelemetry; }
    void setAutoTelemetry(const bool value);

    bool getAutoDelete() const { return m_autoDelete; }
    void setAutoDelete(const bool value);

    bool getIgnoreJunk() const { return m_ignoreJunk; }
    void setIgnoreJunk(const bool value);

    bool getIgnoreHdAudio() const { return m_ignoreHdAudio; }
    void setIgnoreHdAudio(const bool value);

    unsigned getThumbQuality() const { return m_thumbQuality; }
    void setThumbQuality(const unsigned value);

    unsigned getThumbFormat() const { return m_thumbFormat; }
    void setThumbFormat(const unsigned value);

    unsigned getThumbSize() const { return m_thumbSize; }
    void setThumbSize(const unsigned value);

    bool getMoveToTrash() const { return m_moveToTrash; }
    void setMoveToTrash(const bool value);

    bool getMtpFullScan() const { return m_mtpFullScan; }
    void setMtpFullScan(const bool value);

    unsigned getLibrarySortRole() const { return m_librarySortRole; }
    void setLibrarySortRole(const unsigned order);

    unsigned getLibrarySortOrder() const { return m_librarySortOrder; }
    void setLibrarySortOrder(const unsigned order);

    unsigned getDeviceSortRole() const { return m_deviceSortRole; }
    void setDeviceSortRole(const unsigned order);

    unsigned getDeviceSortOrder() const { return m_deviceSortOrder; }
    void setDeviceSortOrder(const unsigned order);
};

/* ************************************************************************** */
#endif // SETTINGS_MANAGER_H
