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

#include "SettingsManager.h"
#include "Shot.h"

#include <QStandardPaths>
#include <QStorageInfo>
#include <QDir>

#include <QSettings>
#include <QDebug>

/* ************************************************************************** */

SettingsManager *SettingsManager::instance = nullptr;

SettingsManager *SettingsManager::getInstance()
{
    if (instance == nullptr)
    {
        instance = new SettingsManager();
        return instance;
    }
    else
    {
        return instance;
    }
}

SettingsManager::SettingsManager()
{
    readSettings();
}

SettingsManager::~SettingsManager()
{
    qDeleteAll(m_mediaDirectories);
    m_mediaDirectories.clear();
}

/* ************************************************************************** */

bool SettingsManager::readSettings()
{
    bool status = false;

    QSettings settings("OffloadBuddy", "OffloadBuddy");
    settings.sync();

    if (settings.status() == QSettings::NoError)
    {
        if (settings.contains("global/autoLaunch"))
            m_autoLaunch = settings.value("global/autoLaunch").toBool();

        if (settings.contains("global/autoMerge"))
            m_autoMerge = settings.value("global/autoMerge").toBool();

        if (settings.contains("global/autoMetadata"))
            m_autoMetadata = settings.value("global/autoMetadata").toBool();

        if (settings.contains("global/autoDelete"))
            m_autoDelete = settings.value("global/autoDelete").toBool();

        if (settings.contains("global/ignoreJunk"))
            m_ignoreJunk = settings.value("global/ignoreJunk").toBool();

        if (settings.contains("global/ignoreHdAudio"))
            m_ignoreHdAudio = settings.value("global/ignoreHdAudio").toBool();

        if (settings.contains("global/contentHierarchy"))
            m_contentHierarchy = settings.value("global/contentHierarchy").toUInt();

        for (int i = 1; i <= MEDIA_DIRECTORIES_MAX_COUNT; i++)
        {
            QString p = "mediadirectory/" + QString::number(i) + "/path";
            QString t = "mediadirectory/" + QString::number(i) + "/content";

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
            // Create a default entry
            MediaDirectory *d = new MediaDirectory();
            m_mediaDirectories.push_back(d);
        }

        emit directoriesUpdated();

        status = true;
    }
    else
    {
        qDebug() << "QSettings READ error:" << settings.status();
    }

    return status;
}

bool SettingsManager::writeSettings()
{
    bool status = false;

    QSettings settings("OffloadBuddy", "OffloadBuddy");

    if (settings.isWritable())
    {
        settings.setValue("global/autoLaunch", m_autoLaunch);
        settings.setValue("global/autoMerge", m_autoMerge);
        settings.setValue("global/autoMetadata", m_autoMetadata);
        settings.setValue("global/autoDelete", m_autoDelete);
        settings.setValue("global/ignoreJunk", m_ignoreJunk);
        settings.setValue("global/ignoreHdAudio", m_ignoreHdAudio);
        settings.setValue("global/contentHierarchy", m_contentHierarchy);
        settings.sync();

        int i = 1;
        for (auto d: m_mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd)
            {
                QString p = "mediadirectory/" + QString::number(i) + "/path";
                QString t = "mediadirectory/" + QString::number(i) + "/content";
                settings.setValue(p, dd->getPath());
                settings.setValue(t, dd->getContent());
                i++;
            }
        }
        for (; i < MEDIA_DIRECTORIES_MAX_COUNT; i++)
        {
            QString p = "mediadirectory/" + QString::number(i) + "/path";
            QString t = "mediadirectory/" + QString::number(i) + "/content";
            settings.remove(p);
            settings.remove(t);
        }

        if (settings.status() == QSettings::NoError)
        {
            status = true;
        }
        else
        {
            qDebug() << "QSettings WRITE error:" << settings.status();
        }
    }

    return status;
}

/* ************************************************************************** */

void SettingsManager::addDirectory(QString path)
{
    if (!path.isEmpty())
    {
        MediaDirectory *d = new MediaDirectory(path, 0);
        m_mediaDirectories.push_back(d);

        directoryModified();
        emit directoriesUpdated();
    }
}

void SettingsManager::deleteDirectory(QString path)
{
    if (!path.isEmpty())
    {
        for (auto d: m_mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                m_mediaDirectories.removeOne(d);
                break;
            }
        }

        directoryModified();
        emit directoriesUpdated();
    }
}

void SettingsManager::directoryModified()
{
    writeSettings();
}

/* ************************************************************************** */
/* ************************************************************************** */

/*!
 * \brief Used when there is no saved MediaDirectory.
 */
MediaDirectory::MediaDirectory()
{
    // Use default path
    // Windows 'C:/Users/USERNAME/Videos/GoPro'
    // Linux '/home/USERNAME/Videos/GoPro'

    QString path = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation) + "/OffloadBuddy";

    QDir path_dir(path);
    if (!path_dir.exists())
    {
        path_dir.mkpath(path);
    }

    if (path_dir.exists())
    {
        setPath(path);
        setContent(CONTENT_ALL);

        m_updateTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
        connect(&m_updateTimer, &QTimer::timeout, this, &MediaDirectory::refreshMediaDirectory);
        m_updateTimer.start();
    }
}

/*!
 * \brief Used when loading a saved MediaDirectory.
 */
MediaDirectory::MediaDirectory(QString &path, int content)
{
    QDir path_dir(path);

    if (path_dir.exists())
    {
        setPath(path);
        setContent(content);

        m_updateTimer.setInterval(MEDIA_DIRECTORIES_REFRESH_INTERVAL * 1000);
        connect(&m_updateTimer, &QTimer::timeout, this, &MediaDirectory::refreshMediaDirectory);
        m_updateTimer.start();
    }
}

MediaDirectory::~MediaDirectory()
{
    delete m_storage;
}

/* ************************************************************************** */

QString MediaDirectory::getPath()
{
    return m_path;
}

/*!
 * \brief MediaDirectory::setPath
 * \param path: The path of this MediaDirectory
 *
 * We could 'force create' the directory here, but there are many cases were it
 * could lead to unintended behavior.
 * Ex: A user set its output directory to E:/Videos.
 * Next time the soft is opened, E:/ exists, but Videos doesn't anymore, because
 * E:/ was a removable media and it is not the same disk anymore. Do we want to take
 * the risk to inadvertantly use another disk or just let the user know that its
 * output directory is now invalid?
 */
void MediaDirectory::setPath(QString path)
{
    m_path = path;
    emit directoryUpdated();

    if (m_storage)
    {
        delete m_storage;
        m_storage = nullptr;
    }

    QDir d(m_path);
    if (d.exists())
    {
        m_storage = new QStorageInfo(m_path);
        if (m_storage &&
            m_storage->isValid() && m_storage->isReady())
        {
            emit spaceUpdated(); // useful when path is changed?

            //qDebug() << "MediaDirectory(" << m_path << "/" << m_content_type << ")";
            //qDebug() << "MediaDirectory(" << m_storage->bytesAvailable() << "/" << m_storage->bytesTotal() << ")";

            // basic checks
            if (m_storage->bytesAvailable() > 128*1024*1024 &&
                m_storage->isReadOnly() == false)
            {
                m_available = true;

#if __linux
                // adanced permission checks
                QFileInfo fi(m_path);
                QFile::Permissions  e = fi.permissions();
                if (!e.testFlag(QFileDevice::WriteUser))
                {
                    m_available = false;
                    qDebug() << "PERMS error:" << e << (unsigned)e;
                }
#endif // __linux

                emit availableUpdated();
            }
        }
        else
        {
            m_available = false;
            emit availableUpdated();
        }
    }
    else
    {
        m_available = false;
        emit availableUpdated();
    }
}

int MediaDirectory::getContent()
{
    return m_content_type;
}

void MediaDirectory::setContent(int content)
{
    m_content_type = content;
}

bool MediaDirectory::isAvailable()
{
    return m_available;
}

bool MediaDirectory::isAvailableFor(unsigned shotType, int64_t shotSize)
{
    bool available = false;

    refreshMediaDirectory();

    if (m_available)
    {
        if (shotSize < getSpaceAvailable())
        {
            if ((shotType == Shared::SHOT_UNKNOWN && m_content_type == CONTENT_ALL) ||
                (shotType < Shared::SHOT_PICTURE && (m_content_type == CONTENT_VIDEOS || m_content_type == CONTENT_ALL)) ||
                (shotType >= Shared::SHOT_PICTURE && (m_content_type == CONTENT_PICTURES || m_content_type == CONTENT_ALL)))
            {
                available = true;
            }
        }
    }

    return available;
}

/* ************************************************************************** */

void MediaDirectory::refreshMediaDirectory()
{
    //qDebug() << "refreshMediaDirectory(" << m_storage->rootPath() << ")";

    if (m_storage &&
        m_storage->isValid() && m_storage->isReady())
    {
        m_storage->refresh();
        emit spaceUpdated();

        // basic checks
        if (m_storage->bytesAvailable() > 128*1024*1024 &&
            m_storage->isReadOnly() == false)
        {
#if __linux
            // adanced permission checks
            QFileInfo fi(m_path);
            QFile::Permissions  e = fi.permissions();
            if (!e.testFlag(QFileDevice::WriteUser))
            {
                m_available = false;
                emit availableUpdated();
            }
#endif // __linux
        }
    }
    else
    {
        m_available = false;
        emit availableUpdated();
    }
}

int64_t MediaDirectory::getSpaceTotal()
{
    if (m_storage)
        return m_storage->bytesTotal();

    return 0;
}

int64_t MediaDirectory::getSpaceUsed()
{
    if (m_storage)
        return (m_storage->bytesTotal() - m_storage->bytesAvailable());

    return 0;
}

double MediaDirectory::getSpaceUsed_percent()
{
    if (m_storage)
        return static_cast<double>(getSpaceUsed()) / static_cast<double>(m_storage->bytesTotal());

    return 0.0;
}

int64_t MediaDirectory::getSpaceAvailable()
{
    if (m_storage)
        return m_storage->bytesAvailable();

    return 0;
}

int64_t MediaDirectory::getSpaceAvailable_withrefresh()
{
    refreshMediaDirectory();
    return getSpaceAvailable();
}

/* ************************************************************************** */
