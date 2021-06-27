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

/*!
 * \brief The SettingsManager class
 *
 * Handle application settings, and syncing with associated settings file.
 */
class SettingsManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QSize initialSize READ getInitialSize NOTIFY initialSizeChanged)
    Q_PROPERTY(QSize initialPosition READ getInitialPosition NOTIFY initialSizeChanged)
    Q_PROPERTY(uint initialVisibility READ getInitialVisibility NOTIFY initialSizeChanged)

    Q_PROPERTY(uint appTheme READ getAppTheme WRITE setAppTheme NOTIFY appThemeChanged)
    Q_PROPERTY(bool appThemeAuto READ getAppThemeAuto WRITE setAppThemeAuto NOTIFY appThemeAutoChanged)
    Q_PROPERTY(bool appThemeCSD READ getAppThemeCSD WRITE setAppThemeCSD NOTIFY appThemeCSDChanged)
    Q_PROPERTY(uint appUnits READ getAppUnits WRITE setAppUnits NOTIFY appUnitsChanged)
    Q_PROPERTY(QString appLanguage READ getAppLanguage WRITE setAppLanguage NOTIFY appLanguageChanged)

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

    // Application specific
    bool m_ignoreJunk = true;
    bool m_ignoreHdAudio = true;
    bool m_autoMerge = false;
    bool m_autoTelemetry = false;
    bool m_autoDelete = false;
    unsigned m_thumbQuality = 1;
    unsigned m_thumbFormat = 2;
    unsigned m_thumbSize = 2;
    bool m_moveToTrash = false;
    bool m_mtpFullScan = false;

    // Singleton
    static SettingsManager *instance;
    SettingsManager();
    ~SettingsManager();

    bool readSettings();
    bool writeSettings();

Q_SIGNALS:
    void initialSizeChanged();
    void appThemeChanged();
    void appThemeAutoChanged();
    void appThemeCSDChanged();
    void appUnitsChanged();
    void appLanguageChanged();
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

public:
    static SettingsManager *getInstance();

    QSize getInitialSize() { return m_appSize; }
    QSize getInitialPosition() { return m_appPosition; }
    unsigned getInitialVisibility() { return m_appVisibility; }

    unsigned getAppTheme() const { return m_appTheme; }
    void setAppTheme(unsigned value);

    bool getAppThemeAuto() const { return m_appThemeAuto; }
    void setAppThemeAuto(bool value);

    bool getAppThemeCSD() const { return m_appThemeCSD; }
    void setAppThemeCSD(bool value);

    unsigned getAppUnits() const { return m_appUnits; }
    void setAppUnits(unsigned value);

    QString getAppLanguage() const { return m_appLanguage; }
    void setAppLanguage(const QString &value);

    bool getAutoMerge() const { return m_autoMerge; }
    void setAutoMerge(bool value);

    bool getAutoTelemetry() const { return m_autoTelemetry; }
    void setAutoTelemetry(bool value);

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

    bool getMoveToTrash() const { return m_moveToTrash; }
    void setMoveToTrash(bool value);

    bool getMtpFullScan() const { return m_mtpFullScan; }
    void setMtpFullScan(bool value);
};

/* ************************************************************************** */
#endif // SETTINGS_MANAGER_H
