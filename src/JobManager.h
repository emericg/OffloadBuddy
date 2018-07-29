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

#include <QObject>
#include <QVariant>
#include <QList>

/* ************************************************************************** */

/*!
 * \brief The JobManager class
 */
class JobManager: public QObject
{
    Q_OBJECT

    QList <QObject *> m_jobs;

Q_SIGNALS:
    void jobAdded();

public:
    JobManager();
    ~JobManager();

public slots:
    QVariant getJob(int index) const { if (m_jobs.size() > index) { return QVariant::fromValue(m_jobs.at(index)); } return QVariant(); }
};

#endif // JOB_MANAGER_H
