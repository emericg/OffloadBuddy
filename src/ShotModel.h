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

#ifndef SHOT_MODEL_H
#define SHOT_MODEL_H
/* ************************************************************************** */

#include "Shot.h"

#include <QObject>
#include <QMetaType>
#include <QDateTime>
#include <QAbstractListModel>

/* ************************************************************************** */

class ShotModelStatsTrack: public QObject
{
    Q_OBJECT

    Q_PROPERTY(int trackType READ getTrackType CONSTANT)
    Q_PROPERTY(int fileCount READ getFileCount CONSTANT)
    Q_PROPERTY(float filePercent READ getFilePercent CONSTANT)
    Q_PROPERTY(qint64 spaceUsed READ getSpaceUsed CONSTANT)
    Q_PROPERTY(float spacePercent READ getSpacePercent CONSTANT)

    int m_trackType;

    int m_file_count = 0;
    float m_file_percentage = 0.f;

    qint64 m_space_used = 0;
    float m_space_percentage = 0.f;

    int getTrackType() const { return m_trackType; }
    int getFileCount() const { return m_file_count; }
    float getFilePercent() const { return m_file_percentage; }
    qint64 getSpaceUsed() const { return m_space_used; }
    float getSpacePercent() const { return m_space_percentage; }

public:
    ShotModelStatsTrack(int t, int fc, int fc_total, qint64 sp, qint64 sp_total) {
        m_trackType = t;
        m_file_count = fc;
        m_file_percentage = fc / static_cast<float>(fc_total);
        m_space_used = sp;
        m_space_percentage = sp / static_cast<float>(sp_total);
    }

    ~ShotModelStatsTrack() = default;
};

/* ************************************************************************** */

class ShotModel : public QAbstractListModel
{
    Q_OBJECT

    Q_PROPERTY(qint64 diskSpace READ getDiskSpace NOTIFY statsUpdated)
    Q_PROPERTY(int shotCount READ getShotCount NOTIFY statsUpdated)
    Q_PROPERTY(int fileCount READ getFileCount NOTIFY statsUpdated)

    QList<Shot *> m_shots;

    qint64 m_diskSpace = 0;
    int m_fileCount = 0;

    qint64 getDiskSpace() const { return m_diskSpace; }
    int getShotCount() const { return m_shots.size(); }
    int getFileCount() const { return m_fileCount; }

    Q_PROPERTY(QVariant statsTracks READ getStatsTracks NOTIFY statsAdvUpdated)
    QList <QObject *> m_statstracks;
    Q_INVOKABLE QVariant getStatsTracks() const { if (m_statstracks.size() > 0) { return QVariant::fromValue(m_statstracks); } return QVariant(); }

Q_SIGNALS:
    void statsUpdated();
    void statsAdvUpdated();

protected:
    QHash<int, QByteArray> roleNames() const;

public:
    enum ShotRoles {
        NameRole = Qt::UserRole+1,
        ShotTypeRole,
        FileTypeRole,
        PreviewRole,
        SizeRole,
        DurationRole,
        DateRole,
        GpsRole,
        CameraRole,

        PointerRole,
        PathRole,
    };
    Q_ENUM(ShotRoles)

    ShotModel(QObject *parent = nullptr);
    ShotModel(const ShotModel &other, QObject *parent = nullptr);
    ~ShotModel();

    int rowCount(const QModelIndex & parent = QModelIndex()) const;
    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;

    void getShots(QList<Shot *> &shots);
    Shot *getShotAt(ShotUtils::ShotType type, int file_id, int camera_id) const;
    Shot *getShotAtIndex(int index);
    Shot *getShotWithUuid(const QString &uuid);
    Shot *getShotWithName(const QString &name);
    Shot *getShotWithPath(const QString &path);

    void addShot(Shot *shot);
    void removeShot(Shot *shot);
    //void removeFile(); // TODO
    void sanetize(const QString &path);

    Q_INVOKABLE void computeStats();

public slots:
    void addFile(ofb_file *f, ofb_shot *s);
};

/* ************************************************************************** */
#endif // SHOT_MODEL_H
