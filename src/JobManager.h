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

class MediaLibrary;
class JobWorkerAsync;
class JobWorkerSync;

/* ************************************************************************** */

typedef enum JobType
{
    JOB_INVALID = 0,

    JOB_METADATA,

    JOB_FORMAT,
    JOB_DELETE,

    JOB_COPY,
    JOB_MERGE,

    JOB_CLIP,
    JOB_TIMELAPSE_TO_VIDEO,
    JOB_REENCODE,
    JOB_STAB,

    JOB_FIRMWARE_DOWNLOAD,
    JOB_FIRMWARE_UPLOAD,

} JobType;

typedef enum JobState
{
    JOB_STATE_QUEUED = 0,
    JOB_STATE_WORKING,
    JOB_STATE_PAUSED,

    JOB_STATE_DONE = 8,
    JOB_STATE_ERRORED

} JobState;

typedef struct JobEncodeSettings
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

    int64_t startMs = -1;
    int64_t durationMs = -1;

} JobEncodeSettings;

typedef struct JobElement
{
    Shot *parent_shots;
    QString destination_dir;

    std::vector <ofb_file> files;

} JobElement;

typedef struct Job
{
    int id = -1;
    JobType type = JOB_INVALID;
    JobEncodeSettings settings;

    std::vector<JobElement *> elements;

    JobState state = JOB_STATE_QUEUED;
    int totalFiles = 0;
    int64_t totalSize = 0;

} Job;

/* ************************************************************************** */

/*!
 * \brief The JobTracker class
 */
class JobTracker: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ getName NOTIFY jobUpdated)
    Q_PROPERTY(QString type READ getTypeString NOTIFY jobUpdated)
    Q_PROPERTY(int state READ getState NOTIFY jobUpdated)
    Q_PROPERTY(float progress READ getProgress NOTIFY jobUpdated)

    QString m_name;
    JobType m_type;
    JobState m_state = JOB_STATE_QUEUED;
    float m_percent = 0.0;

    bool m_autoDelete = false;

    int m_job_id = -1;
    Device *m_source_device = nullptr;
    MediaLibrary *m_source_library = nullptr;
    //ShotProvider *m_shot_provider = nullptr;
    QString m_destination;

Q_SIGNALS:
    void jobUpdated();

public:
    JobTracker(int job_id, int job_type) { m_job_id = job_id; m_type = static_cast<JobType>(job_type); }
    ~JobTracker() {}

    int getId() { return m_job_id; }
    JobType getType() { return m_type; }
    QString getTypeString()
    {
        if (m_type == JOB_METADATA)
            return tr("METADATA EXTRACTION");
        else if (m_type == JOB_COPY)
            return tr("COPYING");
        else if (m_type == JOB_MERGE)
            return tr("MERGING");
        else if (m_type == JOB_FORMAT)
            return tr("FORMAT");
        else if (m_type == JOB_DELETE)
            return tr("DELETION");
        else if (m_type == JOB_CLIP)
            return tr("CLIP CREATION");
        else if (m_type == JOB_REENCODE ||
                 m_type == JOB_TIMELAPSE_TO_VIDEO)
            return tr("ENCODING");
        else if (m_type == JOB_STAB)
            return tr("STABILIZATION");
        else if (m_type == JOB_FIRMWARE_DOWNLOAD)
            return tr("DOWNLOADING");
        else if (m_type == JOB_FIRMWARE_UPLOAD)
            return tr("FIRMWARE");
        else
            return tr("UNKNOWN");
    }
    void setName(const QString &name) { m_name = name; }
    QString getName() { return m_name; }

    void setDevice(Device *d) { m_source_device = d; }
    Device *getDevice() const { return m_source_device; }
    void setLibrary(MediaLibrary *ml) { m_source_library = ml; }
    MediaLibrary *getLibrary() const { return m_source_library; }
    // TODO unify through a ShotProvider ?
    //void setProvider(ShotProvider *sp) { m_shot_provider = sp; }
    //ShotProvider *getProvider() const { return m_shot_provider; }

    void setDestination(QString dest) { m_destination = dest; }
    QString getDestination() const { return m_destination; }

    void setAutoDelete(bool d) { m_autoDelete = d; }
    bool getAutoDelete() const { return m_autoDelete; }

    void setState(int state) { m_state = static_cast<JobState>(state); jobUpdated(); }
    int getState() { return m_state; }

    void setProgress(float p) { m_percent = p; jobUpdated(); }
    float getProgress() { return m_percent / 100.f; }

public slots:
    void openDestination() const
    {
        QFileInfo d(m_destination);
        if (!m_destination.isEmpty() && d.exists())
        {
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
    // per device disk jobs (copy/merge...)
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

    bool addJob(JobType type, Device *d, MediaLibrary *ml, Shot *s,
                MediaDirectory *md = nullptr, JobEncodeSettings *set = nullptr);
    bool addJobs(JobType type, Device *d, MediaLibrary *ml, QList<Shot *> list,
                 MediaDirectory *md = nullptr, JobEncodeSettings *set = nullptr);

public slots:
    QVariant getTrackedJobs() const { if (m_trackedJobs.size() > 0) { return QVariant::fromValue(m_trackedJobs); } return QVariant(); }
    int getTrackedJobsCount() const { return m_trackedJobs.size(); }
    int getWorkingJobsCount() const { return m_workingJobs; }

    void clearFinishedJobs();

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
