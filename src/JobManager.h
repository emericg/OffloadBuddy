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

#include <QObject>
#include <QVariant>
#include <QList>

/* ************************************************************************** */

typedef enum JobType
{
    JOB_INVALID = 0,

    JOB_METADATAS,

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

/* ************************************************************************** */

class Job: public QObject
{
    Q_OBJECT

    JobType m_type = JOB_INVALID;
    float m_percent = 0.0;

public:
    Job() {}
    virtual~Job() {}
};

class CopyJob: public Job
{
    std::list<Shot *>m_shots;
    MediaDirectory *m_dest = nullptr;

public:
    CopyJob() {}
    ~CopyJob() {}

    virtual void work();
};

class DeleteJob: public Job
{
    std::list<Shot *> m_shots;

public:
    DeleteJob() {}
    ~DeleteJob() {}

    virtual void work();
};

/* ************************************************************************** */

/*!
 * \brief The JobManager class
 */
class JobManager: public QObject
{
    Q_OBJECT

    QList <QObject *> m_job_queue_1;
    QList <QObject *> m_job_queue_2;
    QList <QObject *> m_job_queue_3;
    QList <QObject *> m_job_queue_4;

    // Singleton
    static JobManager *instance;
    JobManager();
    ~JobManager();

    //bool getAutoDestination(Shot &s, QString &destination)
    MediaDirectory * getAutoDestination(Shot *s);
    QString getAutoDestinationString(Shot *s);

Q_SIGNALS:
    void jobAdded();
    void jobCanceled();
    void jobFinished();

public:
    static JobManager *getInstance();
    bool addJob(JobType type, Device *d, Shot *s, MediaDirectory *m = nullptr);
    bool addJobs(JobType type, Device *d, QList<Shot *> list, MediaDirectory *m = nullptr);

public slots:
    QVariant getJob(int index) const { if (m_job_queue_1.size() > index) { return QVariant::fromValue(m_job_queue_1.at(index)); } return QVariant(); }
};

#endif // JOB_MANAGER_H
