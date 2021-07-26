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

#include "MediaLibrary.h"
#include "MediaDirectory.h"
#include "FileScanner.h"
#include "JobManager.h"
#include "StorageManager.h"
#include "SettingsManager.h"

#include <QMap>
#include <QJSValue>
#include <QVariant>

#include <QUuid>
#include <QThread>
#include <QDebug>

/* ************************************************************************** */

MediaLibrary::MediaLibrary()
{
    StorageManager *sm = StorageManager::getInstance();
    if (sm)
    {
        connect(sm, SIGNAL(directoryAdded(QString)), this, SLOT(searchMediaDirectory(QString)));
        connect(sm, SIGNAL(directoryRemoved(QString)), this, SLOT(cleanMediaDirectory(QString)));
    }

    if (m_shotFilter)
    {
        SettingsManager *st = SettingsManager::getInstance();
        int sortRoleSettings = st->getLibrarySortRole();
        int sortRole = ShotModel::DateRole;

        switch (sortRoleSettings)
        {
            case SettingsUtils::OrderByCamera:
                sortRole = ShotModel::CameraRole;
                break;
            case SettingsUtils::OrderByGps:
                sortRole = ShotModel::GpsRole;
                break;
            case SettingsUtils::OrderBySize:
                sortRole = ShotModel::SizeRole;
                break;
            case SettingsUtils::OrderByFilePath:
                sortRole = ShotModel::PathRole;
                break;
            case SettingsUtils::OrderByName:
                sortRole = ShotModel::NameRole;
                break;
            case SettingsUtils::OrderByShotType:
                sortRole = ShotModel::ShotTypeRole;
                break;
            case SettingsUtils::OrderByDuration:
                sortRole = ShotModel::DurationRole;
                break;
            default:
            case SettingsUtils::OrderByDate:
                sortRole = ShotModel::DateRole;
                break;
        }

        m_sortOrder = (Qt::SortOrder)st->getLibrarySortOrder();
        m_shotFilter->setSortRole(sortRole);
        m_shotFilter->sort(0, m_sortOrder);
    }
}

MediaLibrary::~MediaLibrary()
{
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::scanMediaDirectory(MediaDirectory *md)
{
    if (md && md->isAvailable())
    {
        if (m_shotModel)
        {
            //qDebug() << "MediaLibrary::scanMediaDirectory(" << md->getPath() << ")";

            QThread *thread = new QThread();
            FileScanner *fs = new FileScanner();

            if (thread && fs)
            {
                fs->chooseFilesystem(md->getPath());
                fs->moveToThread(thread);

                connect(thread, SIGNAL(started()), fs, SLOT(scanFilesystem()));
                connect(fs, SIGNAL(fileFound(ofb_file*,ofb_shot*)), m_shotModel, SLOT(addFile(ofb_file*,ofb_shot*)));
                connect(fs, SIGNAL(scanningStarted(QString)), this, SLOT(workerScanningStarted(QString)));
                connect(fs, SIGNAL(scanningFinished(QString)), this, SLOT(workerScanningFinished(QString)));

                // automatically delete thread and everything when the work is done
                connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
                connect(fs, SIGNAL(scanningFinished(QString)), fs, SLOT (deleteLater()));
                connect(fs, SIGNAL(scanningFinished(QString)), thread, SLOT(quit()));

                thread->start();
            }
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::searchMediaDirectory(const QString &path)
{
    //qDebug() << "MediaLibrary::searchMediaDirectory(" << path << ")";

    StorageManager *sm = StorageManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path && dd->isEnabled())
            {
                scanMediaDirectory(dd);
                return;
            }
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::searchMediaDirectories()
{
    //qDebug() << "MediaLibrary::searchMediaDirectories()";

    StorageManager *sm = StorageManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->isEnabled())
            {
                scanMediaDirectory(dd);
            }
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::cleanMediaDirectory(const QString &path)
{
    //qDebug() << "MediaLibrary::cleanMediaDirectory(" << path << ")";
    Q_UNUSED(path)

    if (m_shotModel)
    {
        if (m_libraryState != DEVICE_STATE_SCANNING)
        {
            m_shotModel->sanetize();

            // TODO...
        }
    }
}

/* ************************************************************************** */

void MediaLibrary::invalidate()
{
    //qDebug() << "MediaLibrary::invalidate()";

    if (m_shotFilter)
    {
        m_shotFilter->invalidate();
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::workerScanningStarted(const QString &path)
{
    //qDebug() << "> MediaLibrary::workerScanningStarted(" << path << ")";

    StorageManager *sm = StorageManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                dd->setScanning(true);
            }
        }
    }

    if (m_libraryScan < 0) m_libraryScan = 0;
    m_libraryScan++;

    m_libraryState = DEVICE_STATE_SCANNING;
    emit stateUpdated();
}

void MediaLibrary::workerScanningFinished(const QString &path)
{
    //qDebug() << "> MediaLibrary::workerScanningFinished(" << path << ")";

    StorageManager *sm = StorageManager::getInstance();
    if (sm)
    {
        const QList <QObject *> *mediaDirectories = sm->getDirectoriesList();
        for (auto d: *mediaDirectories)
        {
            MediaDirectory *dd = qobject_cast<MediaDirectory*>(d);
            if (dd && dd->getPath() == path)
            {
                dd->setScanning(false);
            }
        }
    }
/*
    // Update sort
    // This may still be needed for things like timelapses, where Shots are
    // not yet complete when they are added to the ShotModel
    if (m_shotFilter)
    {
        m_shotFilter->sort(0, m_sortOrder);
        m_shotFilter->invalidate();
    }
*/
    m_libraryScan--;
    if (m_libraryScan <= 0)
    {
        m_libraryState = DEVICE_STATE_IDLE;
        emit stateUpdated();
    }
}

/* ************************************************************************** */
/* ************************************************************************** */

QStringList MediaLibrary::getSelectedShotsUuids(const QVariant &indexes)
{
    //qDebug() << "MediaLibrary::getSelectedShotsUuids(" << indexes << ")";
    QStringList selectedUuids;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedUuids += shot->getUuid();
        //qDebug() << "MediaLibrary::getSelectedShotsUuids(" <<  shot->getUuid();
    }

    return selectedUuids;
}

/* ************************************************************************** */

QStringList MediaLibrary::getSelectedShotsNames(const QVariant &indexes)
{
    //qDebug() << "MediaLibrary::getSelectedShotsNames(" << indexes << ")";
    QStringList selectedNames;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedNames += shot->getName();
        //qDebug() << "MediaLibrary::getSelectedShotsNames(" <<  shot->getName();
    }

    return selectedNames;
}

/* ************************************************************************** */

QStringList MediaLibrary::getSelectedShotsFilepaths(const QVariant &indexes)
{
    //qDebug() << "MediaLibrary::getSelectedShotsFilepaths(" << indexes << ")";
    QStringList selectedPaths;

    // indexes from qml gridview (after filtering)
    QJSValue jsArray = indexes.value<QJSValue>();
    const int jsArray_length = jsArray.property("length").toInt();
    QList<QPersistentModelIndex> proxyIndexes;

    for (int i = 0; i < jsArray_length; i++)
    {
        QModelIndex proxyIndex = m_shotFilter->index(jsArray.property(static_cast<quint32>(i)).toInt(), 0);
        proxyIndexes.append(QPersistentModelIndex(proxyIndex));

        Shot *shot = qvariant_cast<Shot*>(m_shotFilter->data(proxyIndexes.at(i), ShotModel::PointerRole));
        if (shot) selectedPaths += shot->getFilesStringList();
        //qDebug() << "MediaLibrary::listSelected(" <<  shot->getFilesQStringList();
    }

    return selectedPaths;
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::moveSelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "MediaLibrary::moveSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shot
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_MOVE, nullptr, this, shot,
                               &dst, nullptr, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */

void MediaLibrary::moveSelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "MediaLibrary::moveSelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> list;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JobUtils::JOB_MOVE, nullptr, this, list,
                                         &dst, nullptr, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::deleteSelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "MediaLibrary::deleteSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shot
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get settings
    JobSettingsDelete set;
    {
        if (variantMap.contains("moveToTrash"))
            set.moveToTrash = variantMap.value("moveToTrash").toBool();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_DELETE, nullptr, this, shot,
                               nullptr, &set, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */

void MediaLibrary::deleteSelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "MediaLibrary::deleteSelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> list;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    // Get settings
    JobSettingsDelete set;
    {
        if (variantMap.contains("moveToTrash"))
            set.moveToTrash = variantMap.value("moveToTrash").toBool();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JobUtils::JOB_DELETE, nullptr, this, list,
                                         nullptr, &set, nullptr, nullptr, nullptr);
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::reencodeSelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "MediaLibrary::reencodeSelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsEncode set;
    {
        if (variantMap.contains("codec"))
            set.codec = variantMap.value("codec").toString();

        if (variantMap.contains("quality"))
            set.encoding_quality = variantMap.value("quality").toInt();
        if (variantMap.contains("speed"))
            set.encoding_speed = variantMap.value("speed").toInt();

        if (variantMap.contains("resolution"))
            set.resolution = variantMap.value("resolution").toInt();

        if (variantMap.contains("scale"))
            set.scale = variantMap.value("scale").toString();

        if (variantMap.contains("transform"))
            set.transform = variantMap.value("transform").toInt();

        if (variantMap.contains("crop"))
            set.crop = variantMap.value("crop").toString();

        if (variantMap.contains("fps"))
            set.fps = variantMap.value("fps").toFloat();

        if (variantMap.contains("gif_effect"))
            set.gif_effect = variantMap.value("gif_effect").toString();

        if (variantMap.contains("timelapse_fps"))
            set.timelapse_fps = variantMap.value("timelapse_fps").toInt();

        if (variantMap.contains("defisheye"))
            set.defisheye = variantMap.value("defisheye").toString();
        if (variantMap.contains("deshake"))
            set.deshake = variantMap.value("deshake").toBool();

        if (variantMap.contains("screenshot"))
            set.screenshot = variantMap.value("screenshot").toBool();

        if (variantMap.contains("clipStartMs"))
            set.startMs = variantMap.value("clipStartMs").toInt();
        if (variantMap.contains("clipDurationMs"))
            set.durationMs = variantMap.value("clipDurationMs").toInt();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_ENCODE, nullptr, this, shot,
                               &dst, nullptr, nullptr, nullptr, &set);
}

/* ************************************************************************** */

void MediaLibrary::reencodeSelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "MediaLibrary::reencodeSelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> list;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsEncode set;
    {
        if (variantMap.contains("codec"))
            set.codec = variantMap.value("codec").toString();

        if (variantMap.contains("quality"))
            set.encoding_quality = variantMap.value("quality").toInt();
        if (variantMap.contains("speed"))
            set.encoding_speed = variantMap.value("speed").toInt();

        if (variantMap.contains("resolution"))
            set.resolution = variantMap.value("resolution").toInt();

        if (variantMap.contains("scale"))
            set.scale = variantMap.value("scale").toString();

        if (variantMap.contains("transform"))
            set.transform = variantMap.value("transform").toInt();

        if (variantMap.contains("crop"))
            set.crop = variantMap.value("crop").toString();

        if (variantMap.contains("fps"))
            set.fps = variantMap.value("fps").toFloat();

        if (variantMap.contains("gif_effect"))
            set.gif_effect = variantMap.value("gif_effect").toString();

        if (variantMap.contains("timelapse_fps"))
            set.timelapse_fps = variantMap.value("timelapse_fps").toInt();

        if (variantMap.contains("defisheye"))
            set.defisheye = variantMap.value("defisheye").toString();
        if (variantMap.contains("deshake"))
            set.deshake = variantMap.value("deshake").toBool();

        if (variantMap.contains("screenshot"))
            set.screenshot = variantMap.value("screenshot").toBool();

        if (variantMap.contains("clipStartMs"))
            set.startMs = variantMap.value("clipStartMs").toInt();
        if (variantMap.contains("clipDurationMs"))
            set.durationMs = variantMap.value("clipDurationMs").toInt();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JobUtils::JOB_ENCODE, nullptr, this, list,
                                         &dst, nullptr, nullptr, nullptr, &set);
}

/* ************************************************************************** */
/* ************************************************************************** */

void MediaLibrary::extractTelemetrySelected(const QString &shot_uuid, const QVariant &settings)
{
    qDebug() << "MediaLibrary::extractTelemetrySelected(" << shot_uuid << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shot
    Shot *shot = m_shotModel->getShotWithUuid(shot_uuid);

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsTelemetry set;
    {
        if (variantMap.contains("telemetry_format"))
            set.telemetry_format = variantMap.value("telemetry_format").toString();

        if (variantMap.contains("telemetry_frequency"))
            set.telemetry_frequency = variantMap.value("telemetry_frequency").toInt();

        if (variantMap.contains("gps_format"))
            set.gps_format = variantMap.value("gps_format").toString();

        if (variantMap.contains("gps_frequency"))
            set.gps_frequency = variantMap.value("gps_frequency").toInt();

        if (variantMap.contains("egm96_correction"))
            set.EGM96 = variantMap.value("egm96_correction").toBool();
    }

    // Submit job
    JobManager *jm = JobManager::getInstance();
    if (jm && shot) jm->addJob(JobUtils::JOB_TELEMETRY, nullptr, this, shot,
                               &dst, nullptr, nullptr, &set, nullptr);
}

void MediaLibrary::extractTelemetrySelection(const QVariant &uuids, const QVariant &settings)
{
    qDebug() << "MediaLibrary::extractTelemetrySelection(" << uuids << ")";

    QVariant variant = qvariant_cast<QJSValue>(settings).toVariant();
    if (static_cast<QMetaType::Type>(variant.type()) != QMetaType::QVariantMap) return;
    QVariantMap variantMap = variant.toMap();
    //qDebug() << "> variantMap " << variantMap;

    // Get shots
    QList<Shot *> list;
    const QStringList selectedUuids = qvariant_cast<QStringList>(uuids);
    for (const auto &u: selectedUuids)
    {
        list.push_back(m_shotModel->getShotWithUuid(u));
    }

    // Get destination
    JobDestination dst;
    {
        if (variantMap.contains("mediaDirectory"))
            dst.mediaDirectory = variantMap.value("mediaDirectory").toString();

        if (variantMap.contains("folder"))
            dst.folder = variantMap.value("folder").toString();

        if (variantMap.contains("file"))
            dst.file = variantMap.value("file").toString();

        if (variantMap.contains("extension"))
            dst.file = variantMap.value("extension").toString();
    }

    // Get settings
    JobSettingsTelemetry set;
    {
        if (variantMap.contains("telemetry_format"))
            set.telemetry_format = variantMap.value("telemetry_format").toString();

        if (variantMap.contains("telemetry_frequency"))
            set.telemetry_frequency = variantMap.value("telemetry_frequency").toInt();

        if (variantMap.contains("gps_format"))
            set.gps_format = variantMap.value("gps_format").toString();

        if (variantMap.contains("gps_frequency"))
            set.gps_frequency = variantMap.value("gps_frequency").toInt();

        if (variantMap.contains("egm96_correction"))
            set.EGM96 = variantMap.value("egm96_correction").toBool();
    }

    // Submit jobs
    JobManager *jm = JobManager::getInstance();
    if (jm && !list.empty()) jm->addJobs(JobUtils::JOB_TELEMETRY, nullptr, this, list,
                                         &dst, nullptr, nullptr, &set, nullptr);
}

/* ************************************************************************** */
/* ************************************************************************** */
