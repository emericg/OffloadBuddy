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
 * \date      2020
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "StorageManager.h"

#include <QCoreApplication>
#include <QStandardPaths>
#include <QStorageInfo>
#include <QDir>
#include <QSettings>
#include <QDebug>

#define MEDIA_DIRECTORIES_REFRESH_INTERVAL 30

/* ************************************************************************** */

StorageManager *StorageManager::instance = nullptr;

StorageManager *StorageManager::getInstance()
{
    if (instance == nullptr)
    {
        instance = new StorageManager();
    }

    return instance;
}

StorageManager::StorageManager()
{
    readSettings();
}

StorageManager::~StorageManager()
{
    qDeleteAll(m_mediaDirectories);
    m_mediaDirectories.clear();
}

/* ************************************************************************** */
/* ************************************************************************** */

bool StorageManager::readSettings()
{
    bool status = false;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());

    if (settings.status() == QSettings::NoError)
    {
        if (settings.contains("global/contentHierarchy"))
            m_contentHierarchy = settings.value("global/contentHierarchy").toUInt();

        for (int i = 1; i <= max_media_directories; i++)
        {
            QString p = "MediaDirectories/" + QString::number(i) + "/path";
            QString e = "MediaDirectories/" + QString::number(i) + "/enabled";
            QString c = "MediaDirectories/" + QString::number(i) + "/content";
            QString h = "MediaDirectories/" + QString::number(i) + "/hierarchy";

            bool ee = true;
            int cc = 0;
            int hh = 0;
            if (settings.contains(e)) ee = settings.value(e).toBool();
            if (settings.contains(c)) cc = settings.value(c).toInt();
            if (settings.contains(h)) hh = settings.value(h).toInt();

            if (settings.contains(p))
            {
                QString pp = settings.value(p).toString();

                MediaDirectory *d = new MediaDirectory(pp, cc, hh, ee, false, this);
                m_mediaDirectories.push_back(d);
                Q_EMIT directoryAdded(d->getPath());
                Q_EMIT directoriesUpdated();

                connect(d, SIGNAL(saveData()), this, SLOT(directoryModified()));
                connect(d, SIGNAL(enabledUpdated(QString,bool)), this, SLOT(directoryAvailabilityModified(QString,bool)));
                connect(d, SIGNAL(availableUpdated(QString,bool)), this, SLOT(directoryAvailabilityModified(QString,bool)));
            }
        }

        if (m_mediaDirectories.isEmpty())
        {
            //createDefaultDirectory();
        }

        status = true;
    }
    else
    {
        qWarning() << "QSettings READ error:" << settings.status();
    }

    return status;
}

bool StorageManager::writeSettings()
{
    bool status = false;

    QSettings settings(QCoreApplication::organizationName(), QCoreApplication::applicationName());

    if (settings.isWritable())
    {
        settings.setValue("global/contentHierarchy", m_contentHierarchy);

        int i = 1;
        for (auto d: qAsConst(m_mediaDirectories))
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd)
            {
                QString p = "MediaDirectories/" + QString::number(i) + "/path";
                QString e = "MediaDirectories/" + QString::number(i) + "/enabled";
                QString c = "MediaDirectories/" + QString::number(i) + "/content";
                QString h = "MediaDirectories/" + QString::number(i) + "/hierarchy";
                settings.setValue(p, dd->getPath());
                settings.setValue(e, dd->isEnabled());
                settings.setValue(c, dd->getContent());
                settings.setValue(h, dd->getHierarchy());
                i++;
            }
        }
        for (; i <= max_media_directories; i++)
        {
            QString p = "MediaDirectories/" + QString::number(i) + "/path";
            QString e = "MediaDirectories/" + QString::number(i) + "/enabled";
            QString c = "MediaDirectories/" + QString::number(i) + "/content";
            QString h = "MediaDirectories/" + QString::number(i) + "/hierarchy";
            settings.remove(p);
            settings.remove(e);
            settings.remove(c);
            settings.remove(h);
        }

        if (settings.status() == QSettings::NoError)
        {
            status = true;
        }
        else
        {
            qWarning() << "QSettings WRITE error:" << settings.status();
        }
    }
    else
    {
        qWarning() << "QSettings WRITE error: read only file?";
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

void StorageManager::setContentHierarchy(unsigned value)
{
    if (m_contentHierarchy != value)
    {
        m_contentHierarchy = value;
        writeSettings();
        Q_EMIT contentHierarchyChanged();
    }
}

void StorageManager::directoryAvailabilityModified(const QString &path, bool state)
{
    if (!path.isEmpty())
    {
        if (state)
        {
            Q_EMIT directoryAdded(path);
        }
        else
        {
            Q_EMIT directoryRemoved(path);
        }

        Q_EMIT directoriesUpdated();
    }
}

void StorageManager::directoryModified()
{
    writeSettings();
}

/* ************************************************************************** */

void StorageManager::createDefaultDirectory()
{
    // Create a default entry
    MediaDirectory *d = new MediaDirectory(this);
    if (d)
    {
        m_mediaDirectories.push_back(d);
        Q_EMIT directoryAdded(d->getPath());
        Q_EMIT directoriesUpdated();

        connect(d, SIGNAL(saveData()), this, SLOT(directoryModified()));
        connect(d, SIGNAL(enabledUpdated(QString)), this, SLOT(directoryAvailabilityModified(QString)));
        connect(d, SIGNAL(availableUpdated(QString)), this, SLOT(directoryAvailabilityModified(QString)));
        directoryModified();
    }
/*
    // Create a default entries
    QString pathV = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation) + "/GoPro";
    QString pathP = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation) + "/GoPro";
    MediaDirectory *dv = new MediaDirectory(pathV, 1);
    m_mediaDirectories.push_back(dv);
    MediaDirectory *dp = new MediaDirectory(pathP, 2);
    m_mediaDirectories.push_back(dp);
*/
}

void StorageManager::addDirectory(const QString &path)
{
    if (!path.isEmpty())
    {
        QString checkpath = path;
        if (!checkpath.endsWith('/'))
            checkpath += '/';

        // Check if already in the list?
        for (auto d: qAsConst(m_mediaDirectories))
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == checkpath)
            {
                qDebug() << "addDirectory(" << path << ") is already in the list";
                return;
            }
        }

        // Add
        MediaDirectory *dd = new MediaDirectory(path, 0, 0, true, false, this);
        if (dd)
        {
            m_mediaDirectories.push_back(dd);
            Q_EMIT directoryAdded(dd->getPath());
            Q_EMIT directoriesUpdated();

            connect(dd, SIGNAL(saveData()), this, SLOT(directoryModified()));
            connect(dd, SIGNAL(enabledUpdated(QString)), this, SLOT(directoryAvailabilityModified(QString)));
            connect(dd, SIGNAL(availableUpdated(QString)), this, SLOT(directoryAvailabilityModified(QString)));
            directoryModified();
        }
    }
}

void StorageManager::removeDirectory(const QString &path)
{
    if (!path.isEmpty())
    {
        for (auto d: qAsConst(m_mediaDirectories))
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                m_mediaDirectories.removeOne(d);
                Q_EMIT directoryRemoved(dd->getPath());
                Q_EMIT directoriesUpdated();

                directoryModified();
                break;
            }
        }
    }

    if (m_mediaDirectories.isEmpty())
    {
        //createDefaultDirectory();
    }
}

/* ************************************************************************** */
