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

#ifndef JOB_MANAGER_H
#define JOB_MANAGER_H
/* ************************************************************************** */

#include "Device.h"
#include "Shot.h"
#include "SettingsManager.h"
#include "JobWorker.h"

#include <QObject>
#include <QVariant>
#include <QList>
#include <QThread>

/* ************************************************************************** */

/*!
 * \brief The JobTracker class
 */
class JobTracker: public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString name READ getName NOTIFY jobUpdated)
    Q_PROPERTY(QString type READ getType NOTIFY jobUpdated)
    Q_PROPERTY(int state READ getState NOTIFY jobUpdated)
    Q_PROPERTY(float progress READ getProgress NOTIFY jobUpdated)

    QString m_name;
    JobType m_type;
    JobState m_state = JOB_STATE_QUEUED;
    float m_percent = 0.0;

    int m_job_id = -1;
    Device *m_device = nullptr;

public:

Q_SIGNALS:
    void jobUpdated();

public:
    JobTracker(int job_id, int job_type) {m_job_id = job_id; m_type = (JobType)job_type; }
    ~JobTracker() {}

    int getId() { return m_job_id; }
    QString getName() { return "NAME"; }
    QString getType()
    {
        if (m_type == JOB_COPY)
            return tr("COPY");
        else if (m_type == JOB_DELETE)
            return tr("DELETION");
        else
            return tr("UNKNOWN");
    }
    Device *getDevice() const { return m_device; }

    void setState(int state) { m_state = (JobState)state; jobUpdated(); }
    int getState() { return m_state; }

    void setProgress(float p) { m_percent = p; jobUpdated(); }
    float getProgress() { return m_percent / 100.f; }
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

    JobWorker *m_job_w1 = nullptr;
    QThread *m_job_w1_thread = nullptr;

    // instant jobs (deletion...)
    // web downloads jobs
    // CPU jobs (reencodes, stabs...)

    MediaDirectory * getAutoDestination(Shot *s);
    QString getAutoDestinationString(Shot *s);
    QString getandmakeDestination(Shot *s, Device *d);

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
    bool addJob(JobType type, Device *d, Shot *s, MediaDirectory *m = nullptr);
    bool addJobs(JobType type, Device *d, QList<Shot *> list, MediaDirectory *m = nullptr);

public slots:
    QVariant getTrackedJobs() const { if (m_trackedJobs.size() > 0) { return QVariant::fromValue(m_trackedJobs); } return QVariant(); }
    int getTrackedJobsCount() const { return m_trackedJobs.size(); }
    int getWorkingJobsCount() const { return m_workingJobs; }

    void clearFinishedJobs();

    void jobProgress(int, float);
    void jobStarted(int);
    void jobFinished(int, int);
    void shotStarted(int, Shot *);
    void shotFinished(int, Shot *);
};

/* ************************************************************************** */
#endif // JOB_MANAGER_H
