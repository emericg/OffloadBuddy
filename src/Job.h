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

#ifndef JOB_H
#define JOB_H
/* ************************************************************************** */

#include "JobUtils.h"
#include "Shot.h"

#include <QObject>
#include <QString>
#include <QVariant>
#include <QDateTime>

class Shot;
class Device;
class MediaLibrary;
class JobWorkerAsync;
class JobWorkerSync;

/* ************************************************************************** */

typedef struct JobDestination
{
    QString mediaDirectory;

    QString folder;
    QString file;
    QString extension;

} JobDestination;

typedef struct JobSettingsDelete
{
    bool moveToTrash = true;

} JobSettingsDelete;

typedef struct JobSettingsOffload
{
    bool ignoreJunk = true;
    bool ignoreAudio = true;
    bool extractTelemetry = true;
    bool mergeChapters = true;
    bool autoDelete = true;

} JobSettingsOffload;

typedef struct JobSettingsTelemetry
{
    QString gps_format = "gpx";
    int gps_frequency = 2;
    QString telemetry_format = "json";
    int telemetry_frequency = 30;
    bool EGM96 = true;

} JobSettingsTelemetry;

typedef struct JobSettingsEncode
{
    QString mode = "";

    QString video_codec = "H.264";
    QString image_codec = "JPEG";

    int encoding_quality = 3;   // [1:5]
    int encoding_speed = 2;     // [1:3]

    float fps = -1;
    int resolution = -1;        // height
    int transform = 0;
    QString scale;
    QString crop;
    QString gif_effect;
    int timelapse_fps = 0;

    QString defisheye;
    bool deshake = false;

    bool screenshot = false;
    bool telemetry = false;

    int64_t startMs = -1;
    int64_t durationMs = -1;

} JobSettingsEncode;

/* ************************************************************************** */

typedef struct JobElement
{
    Shot *parent_shot = nullptr;
    QString destination_dir;
    QString destination_file;

    std::vector <ofb_file> files;

} JobElement;

/*!
 * \brief The JobTracker class, used by the UI to display jobs and their status
 */
class JobTracker: public QObject
{
    Q_OBJECT

    Q_PROPERTY(int id READ getId CONSTANT)
    Q_PROPERTY(QString name READ getName NOTIFY jobUpdated)

    Q_PROPERTY(int type READ getType CONSTANT)
    Q_PROPERTY(QString typeStr READ getTypeString CONSTANT)
    Q_PROPERTY(int state READ getState NOTIFY jobUpdated)
    Q_PROPERTY(QString stateStr READ getStateString NOTIFY jobUpdated)

    Q_PROPERTY(QStringList files READ getFiles CONSTANT)
    Q_PROPERTY(QString destinationFile READ getDestinationFile NOTIFY jobUpdated)
    Q_PROPERTY(QString destinationFolder READ getDestinationFolder NOTIFY jobUpdated)

    Q_PROPERTY(bool running READ isRunning NOTIFY jobUpdated)
    Q_PROPERTY(bool paused READ isPaused NOTIFY jobUpdated)

    Q_PROPERTY(float progress READ getProgress NOTIFY jobUpdated)
    Q_PROPERTY(int elementsIndex READ getElementsIndex NOTIFY jobUpdated)
    Q_PROPERTY(int elementsTotal READ getElementsTotal NOTIFY jobUpdated)

    Q_PROPERTY(QDateTime startDate READ getStartDate NOTIFY jobUpdated)
    Q_PROPERTY(QDateTime stopDate READ getStopDate NOTIFY jobUpdated)
    Q_PROPERTY(int elapsed READ getElapsed NOTIFY jobUpdated)
    Q_PROPERTY(int eta READ getETA NOTIFY jobUpdated)

    int m_id = -1;
    JobUtils::JobType m_type;
    JobUtils::JobState m_state = JobUtils::JOB_STATE_QUEUED;

    QString m_name;
    QStringList m_files;

    Device *m_source_device = nullptr;
    MediaLibrary *m_source_library = nullptr;
    //ShotProvider *m_shot_provider = nullptr; // TODO

    QString m_destinationFile;
    QString m_destinationFolder;

    // tracking
    float m_percent = 0.0;

    QDateTime m_start;
    QDateTime m_stop;
    QDateTime m_eta;

Q_SIGNALS:
    void jobUpdated();

public:
    // settings
    JobSettingsDelete settings_delete;
    JobSettingsOffload settings_offload;
    JobSettingsTelemetry settings_telemetry;
    JobSettingsEncode settings_encode;

    std::vector<JobElement *> elements;
    int elements_index = 0;

    int totalFiles = 0;
    int64_t totalSize = 0;

public:
    JobTracker(int job_id, int job_type, QObject *parent);
    ~JobTracker();

    int getId() const { return m_id; }

    JobUtils::JobType getType() const { return m_type; }
    QString getTypeString() const;

    void setState(int state) {
        m_state = static_cast<JobUtils::JobState>(state);
        if (m_state == JobUtils::JOB_STATE_WORKING) m_start = QDateTime::currentDateTime();
        if (m_state >= JobUtils::JOB_STATE_DONE) m_stop = QDateTime::currentDateTime();
        Q_EMIT jobUpdated();
    }
    int getState() const { return m_state; }
    QString getStateString() const;

    int isRunning() const { return (m_state & JobUtils::JOB_STATE_WORKING); }
    int isPaused() const { return (m_state & JobUtils::JOB_STATE_PAUSED); }

    ////////

    void setDevice(Device *d) { m_source_device = d; }
    Device *getDevice() const { return m_source_device; }
    void setLibrary(MediaLibrary *ml) { m_source_library = ml; }
    MediaLibrary *getLibrary() const { return m_source_library; }

    // TODO unify through a ShotProvider ?
    //void setProvider(ShotProvider *sp) { m_shot_provider = sp; }
    //ShotProvider *getProvider() const { return m_shot_provider; }

    ////////

    void setName(const QString &name) { m_name = name; Q_EMIT jobUpdated(); }
    QString getName() const { return m_name; }

    void setFiles(QStringList &fl) { m_files = fl; }
    QStringList getFiles() const { return m_files; }

    void setDestinationFile(QString dest) { m_destinationFile = dest; }
    QString getDestinationFile() const { return m_destinationFile; }

    void setDestinationFolder(QString dest) { if (m_type != JobUtils::JOB_DELETE) m_destinationFolder = dest; }
    QString getDestinationFolder() const { return m_destinationFolder; }

    int getElementsTotal() { return elements.size(); }
    void setElementsIndex(int i) { elements_index = i; Q_EMIT jobUpdated(); }
    int getElementsIndex() { return elements_index; }

    void setProgress(float p) { m_percent = p; Q_EMIT jobUpdated(); }
    float getProgress() { return m_percent / 100.f; }

    int getETA() { return -1; }
    int getElapsed() { return QDateTime::currentSecsSinceEpoch() - m_start.toSecsSinceEpoch(); }
    QDateTime getStartDate() { return m_start; }
    QDateTime getStopDate() { return m_stop; }

    Q_INVOKABLE void openDestinationFile() const;
    Q_INVOKABLE void openDestinationFolder() const;
};

/* ************************************************************************** */
#endif // JOB_H
