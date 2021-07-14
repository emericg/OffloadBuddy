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

#ifndef JOB_MANAGER_H
#define JOB_MANAGER_H
/* ************************************************************************** */

#include "MediaDirectory.h"
#include "Device.h"
#include "Shot.h"


#include <QObject>
#include <QUrl>
#include <QList>
#include <QHash>
#include <QVariant>
#include <QThread>
#include <QDesktopServices>
#include <QQmlApplicationEngine>

class MediaLibrary;
class JobWorkerAsync;
class JobWorkerSync;

/* ************************************************************************** */

class JobUtils: public QObject
{
    Q_OBJECT

public:
    static void registerQML()
    {
        qRegisterMetaType<JobUtils::JobType>("JobUtils::JobType");
        qRegisterMetaType<JobUtils::JobState>("JobUtils::JobState");

        qmlRegisterType<JobUtils>("JobUtils", 1, 0, "JobUtils");
    }

    enum JobType
    {
        JOB_INVALID = 0,

        JOB_FORMAT,
        JOB_DELETE,

        JOB_OFFLOAD,
        JOB_MOVE,

        JOB_CLIP,
        JOB_ENCODE,
        JOB_TELEMETRY,

        JOB_FIRMWARE_DOWNLOAD,
        JOB_FIRMWARE_UPLOAD,
    };
    Q_ENUM(JobType)

    enum JobState
    {
        JOB_STATE_QUEUED = 0,
        JOB_STATE_WORKING,
        JOB_STATE_PAUSED,

        JOB_STATE_DONE = 8,
        JOB_STATE_ERRORED
    };
    Q_ENUM(JobState)
};

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
    QString codec = "H.264";
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

    int64_t startMs = -1;
    int64_t durationMs = -1;

} JobSettingsEncode;

/* ************************************************************************** */

typedef struct JobElement
{
    Shot *parent_shots = nullptr;
    QString destination_dir;

    std::vector <ofb_file> files;

} JobElement;

typedef struct Job
{
    int id = -1;
    JobUtils::JobType type = JobUtils::JOB_INVALID;
    JobUtils::JobState state = JobUtils::JOB_STATE_QUEUED;

    JobSettingsDelete settings_delete;
    JobSettingsOffload settings_offload;
    JobSettingsTelemetry settings_telemetry;
    JobSettingsEncode settings_encode;

    std::vector<JobElement *> elements;
    int totalFiles = 0;
    int64_t totalSize = 0;

} Job;

/* ************************************************************************** */

/*!
 * \brief The JobTracker class, used by the UI to display jobs and their status
 */
class JobTracker: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ getName CONSTANT)
    Q_PROPERTY(QStringList files READ getFiles CONSTANT)
    Q_PROPERTY(QString destination READ getDestination CONSTANT)
    Q_PROPERTY(QString typeStr READ getTypeString CONSTANT)
    Q_PROPERTY(int type READ getType CONSTANT)
    Q_PROPERTY(int state READ getState NOTIFY jobUpdated)
    Q_PROPERTY(bool running READ isRunning NOTIFY jobUpdated)
    Q_PROPERTY(float progress READ getProgress NOTIFY jobUpdated)

    QString m_name;
    QStringList m_files;
    JobUtils::JobType m_type;

    JobUtils::JobState m_state = JobUtils::JOB_STATE_QUEUED;
    float m_percent = 0.0;
    qint64 m_eta;

    bool m_autoDelete = false;

    int m_job_id = -1;
    Device *m_source_device = nullptr;
    MediaLibrary *m_source_library = nullptr;
    //ShotProvider *m_shot_provider = nullptr;
    QString m_destination;

Q_SIGNALS:
    void jobUpdated();

public:
    JobTracker(int job_id, int job_type) { m_job_id = job_id; m_type = static_cast<JobUtils::JobType>(job_type); }
    ~JobTracker() {}

    int getId() { return m_job_id; }
    JobUtils::JobType getType() { return m_type; }
    QString getTypeString() {
        if (m_type == JobUtils::JOB_FORMAT) return tr("FORMAT");
        else if (m_type == JobUtils::JOB_DELETE) return tr("DELETION");
        else if (m_type == JobUtils::JOB_OFFLOAD) return tr("OFFLOADING");
        else if (m_type == JobUtils::JOB_MOVE) return tr("MOVE");
        else if (m_type == JobUtils::JOB_CLIP) return tr("CLIP");
        else if (m_type == JobUtils::JOB_ENCODE) return tr("ENCODING");
        else if (m_type == JobUtils::JOB_TELEMETRY) return tr("TELEMETRY EXTRACTION");
        else if (m_type == JobUtils::JOB_FIRMWARE_DOWNLOAD) return tr("DOWNLOADING");
        else if (m_type == JobUtils::JOB_FIRMWARE_UPLOAD) return tr("FIRMWARE");
        else return tr("UNKNOWN");
    }
    void setName(const QString &name) { m_name = name; }
    QString getName() { return m_name; }

    QStringList getFiles() { return m_files; }

    void setDevice(Device *d) { m_source_device = d; }
    Device *getDevice() const { return m_source_device; }
    void setLibrary(MediaLibrary *ml) { m_source_library = ml; }
    MediaLibrary *getLibrary() const { return m_source_library; }
    // TODO unify through a ShotProvider ?
    //void setProvider(ShotProvider *sp) { m_shot_provider = sp; }
    //ShotProvider *getProvider() const { return m_shot_provider; }

    void setDestination(QString dest) { if (m_type != JobUtils::JOB_DELETE) m_destination = dest; }
    QString getDestination() const { return m_destination; }

    void setAutoDelete(bool d) { m_autoDelete = d; }
    bool getAutoDelete() const { return m_autoDelete; }

    void setState(int state) { m_state = static_cast<JobUtils::JobState>(state); Q_EMIT jobUpdated(); }
    int getState() { return m_state; }

    int isRunning() const { return (m_state & JobUtils::JOB_STATE_WORKING); }

    void setProgress(float p) { m_percent = p; Q_EMIT jobUpdated(); }
    float getProgress() { return m_percent / 100.f; }

    Q_INVOKABLE void openDestination() const {
        QFileInfo d(m_destination);
        if (!m_destination.isEmpty() && d.exists()) {
            QDesktopServices::openUrl(QUrl::fromLocalFile(m_destination));
        }
    }
};

/* ************************************************************************** */

/*!
 * \brief The JobManager class
 */
class JobManager: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariant jobsList READ getTrackedJobs NOTIFY trackedJobsUpdated)
    Q_PROPERTY(int trackedJobCount READ getTrackedJobsCount NOTIFY trackedJobsUpdated)
    Q_PROPERTY(int workingJobCount READ getWorkingJobsCount NOTIFY trackedJobsUpdated)

    QList <QObject *> m_trackedJobs;
    int m_workingJobs = 0;

    // instant jobs (deletion...)
    JobWorkerSync *m_job_instant = nullptr;
    // disk jobs (copy/merge...) (PER DEVICE)
    QHash<QString, JobWorkerSync *> m_job_disk;
    // CPU jobs (reencodes, stabs...)
    JobWorkerAsync *m_job_cpu = nullptr;
    // web downloads jobs
    JobWorkerSync *m_job_web = nullptr;

    MediaDirectory *getAutoDestination(Shot *s);
    QString getAutoDestinationString(Shot *s);
    QString getandmakeDestination(Shot *s, Device *d, MediaDirectory *md = nullptr);

    MediaLibrary *m_library = nullptr;

    // Singleton
    static JobManager *instance;
    JobManager();
    ~JobManager();

Q_SIGNALS:
    void trackedJobsUpdated();
    void jobAdded();
    void jobCanceled();
    void jobFinished();

public:
    static JobManager *getInstance();

    void attachLibrary(MediaLibrary *l);
    void cleanup();

    bool addJob(JobUtils::JobType type, Device *dev, MediaLibrary *lib, Shot *shot,
                MediaDirectory *md = nullptr, JobDestination *dst = nullptr,
                JobSettingsDelete *sett_delete = nullptr,
                JobSettingsOffload *sett_offload = nullptr,
                JobSettingsTelemetry *sett_telemetry = nullptr,
                JobSettingsEncode *sett_encode = nullptr);
    bool addJobs(JobUtils::JobType type, Device *dev, MediaLibrary *lib, QList<Shot *> &list,
                 MediaDirectory *md = nullptr, JobDestination *dst = nullptr,
                 JobSettingsDelete *sett_delete = nullptr,
                 JobSettingsOffload *sett_offload = nullptr,
                 JobSettingsTelemetry *sett_telemetry = nullptr,
                 JobSettingsEncode *sett_encode = nullptr);

    int getWorkingJobsCount() const { return m_workingJobs; }
    int getTrackedJobsCount() const { return m_trackedJobs.size(); }
    QVariant getTrackedJobs() const {
        if (m_trackedJobs.size() > 0) {
            return QVariant::fromValue(m_trackedJobs);
        }
        return QVariant();
    }

    Q_INVOKABLE QString getDestinationHierarchy(Shot *s, const QString &path);

    Q_INVOKABLE bool hasMoveToTrash() const {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
        return true;
#endif
        return false;
    }

    Q_INVOKABLE void clearFinishedJobs();

    Q_INVOKABLE bool fileExists(const QString &path) const {
        QFileInfo f(path);
        if (path.isEmpty() || f.exists())
        {
            return true;
        }
        return false;
    }

public slots:
    void jobStarted(int);
    void jobProgress(int, float);
    void jobFinished(int, int);
    //void jobErrored(int, int); // TODO?

    void shotStarted(int, Shot *);
    void shotFinished(int, Shot *);
    //void shotErrored(int, Shot *); // TODO?

    void newFile(QString);
};

/* ************************************************************************** */
#endif // JOB_MANAGER_H
