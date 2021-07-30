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
#include "Job.h"
#include "JobUtils.h"

#include <QObject>
#include <QList>
#include <QHash>
#include <QVariant>
#include <QFileInfo>

class Shot;
class Device;
class MediaLibrary;
class MediaDirectory;
class JobWorkerAsync;
class JobWorkerSync;

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
                JobDestination *dst = nullptr,
                JobSettingsDelete *sett_delete = nullptr,
                JobSettingsOffload *sett_offload = nullptr,
                JobSettingsTelemetry *sett_telemetry = nullptr,
                JobSettingsEncode *sett_encode = nullptr);
    bool addJobs(JobUtils::JobType type, Device *dev, MediaLibrary *lib, QList<Shot *> &list,
                 JobDestination *dst = nullptr,
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

    Q_INVOKABLE QString getDestinationHierarchyDisplay(Shot *s, const QString &path);
    Q_INVOKABLE QString getDestinationHierarchy(Shot *s, const QString &path);

    Q_INVOKABLE bool hasMoveToTrash() const {
#if (QT_VERSION >= QT_VERSION_CHECK(5, 15, 0))
        return true;
#endif
        return false;
    }

    Q_INVOKABLE void playPauseJob(int jobId);

    Q_INVOKABLE void stopJob(int jobId);

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
    void jobAborted(int, int); // TODO?
    void jobErrored(int, int); // TODO?

    void shotStarted(int, Shot *);
    void shotFinished(int, int, Shot *);
    //void shotErrored(int, int, Shot *); // TODO?

    void newFile(QString);
};

/* ************************************************************************** */
#endif // JOB_MANAGER_H
