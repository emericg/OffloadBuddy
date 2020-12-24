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
            QString t = "MediaDirectories/" + QString::number(i) + "/content";

            if (settings.contains(p) && settings.contains(t))
            {
                QString pp = settings.value(p).toString();
                int tt = settings.value(t).toInt();

                MediaDirectory *d = new MediaDirectory(pp, tt);
                m_mediaDirectories.push_back(d);
            }
        }

        if (m_mediaDirectories.isEmpty())
        {
            //createDefaultDirectory();
        }

        emit directoriesUpdated();

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
                QString t = "MediaDirectories/" + QString::number(i) + "/content";
                settings.setValue(p, dd->getPath());
                settings.setValue(t, dd->getContent());
                i++;
            }
        }
        for (; i <= max_media_directories; i++)
        {
            QString p = "MediaDirectories/" + QString::number(i) + "/path";
            QString t = "MediaDirectories/" + QString::number(i) + "/content";
            settings.remove(p);
            settings.remove(t);
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
        MediaDirectory *dd = new MediaDirectory(path, 0);
        //if (dd->isAvailable())
        {
            m_mediaDirectories.push_back(dd);
            emit directoryAdded(dd->getPath());
            emit directoriesUpdated();

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
                emit directoryRemoved(dd->getPath());
                emit directoriesUpdated();

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

void StorageManager::directoryModified()
{
    writeSettings();
}

void StorageManager::createDefaultDirectory()
{
    // Create a default entry
    MediaDirectory *d = new MediaDirectory();
    if (d)
    {
        m_mediaDirectories.push_back(d);
        writeSettings();
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

/* ************************************************************************** */
