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

#ifndef SHOT_H
#define SHOT_H
/* ************************************************************************** */

#include <QObject>
#include <QMetaType>
#include <QDateTime>
#include <QAbstractListModel>

/* ************************************************************************** */

namespace Shared
{
    Q_NAMESPACE
    enum ShotType
    {
        SHOT_UNKNOWN = 0,

        SHOT_VIDEO,
        SHOT_VIDEO_LOOPING,
        SHOT_VIDEO_TIMELAPSE,
        //SHOT_VIDEO_3D,

        SHOT_PICTURE,
        SHOT_PICTURE_MULTI,
        //SHOT_PICTURE_BURST,
        //SHOT_PICTURE_TIMELAPSE,
    };
    Q_ENUM_NS(ShotType)
}

/* ************************************************************************** */

/*!
 * \brief The Shot class
 */
class Shot: public QObject
{
    Q_OBJECT

    Q_PROPERTY(unsigned type READ getType NOTIFY shotUpdated)
    Q_PROPERTY(QString name READ getName NOTIFY shotUpdated)
    Q_PROPERTY(QString camera READ getCameraSource NOTIFY shotUpdated)

    Q_PROPERTY(QString preview READ getPreview NOTIFY shotUpdated)

    Q_PROPERTY(unsigned highlightCount READ getHighlightCount NOTIFY shotUpdated)

    Q_PROPERTY(qint64 duration READ getDuration NOTIFY shotUpdated)
    //Q_PROPERTY(QString dateFile READ getDate NOTIFY shotUpdated)
    //Q_PROPERTY(QString dateShot READ getDate NOTIFY shotUpdated)
    //Q_PROPERTY(QString gps READ getGPS NOTIFY shotUpdated)

public:
    Shared::ShotType m_type;
    QString m_camera_source;

    QString m_file_name;
    QDateTime m_file_date;
    int m_file_number;

    QDateTime m_date_shot;

    //QList <HighLight> m_highlights;

    // PICTURES
    QList <QString> m_jpg;

    // VIDEOS
    qint64 m_duration;

    QList <QString> m_mp4;
    QList <QString> m_lrv;
    QList <QString> m_thm;

    QList <QString> m_gpx;
    QList <QString> m_json;

Q_SIGNALS:
    void shotUpdated();
    void spaceUpdated();

public:
    Shot(QObject *parent = nullptr);
    Shot(Shared::ShotType type);
    ~Shot();

    Shot(const Shot &other);

    bool isValid();
    void addFile(QString &file);

public slots:
    unsigned getType() const;
    unsigned getSize() const;
    QString getName() const { return m_file_name; }
    QString getCameraSource() const { return m_camera_source; }
    qint64 getDuration() const;
    QString getPreview() const;

    unsigned getHighlightCount() const { return 0; }

    void setFileId(int number) { m_file_number = number; }
    int getFileNumber() const { return m_file_number; }

    //QString getCamera() const { return m_camera; }
};

//Q_DECLARE_METATYPE(Shot*);

/* ************************************************************************** */

class ShotModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(ShotRoles)

    QList<Shot *> m_shots;

public:
    enum ShotRoles {
        NameRole = Qt::UserRole+1,
        TypeRole,
        PreviewRole,
        SizeRole,
        DurationRole,
        DateFileRole,
        DateShotRole,
        GpsRole,
        CameraRole,

        PointerRole,
    };

    ShotModel(QObject *parent = nullptr);
    ShotModel(const ShotModel &other);
    ~ShotModel();

    const QList<Shot *> * getShotList() { return &m_shots; }

    void addShot(Shot *shot);

    int rowCount(const QModelIndex & parent = QModelIndex()) const;

    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;

protected:
    QHash<int, QByteArray> roleNames() const;
};

//Q_DECLARE_METATYPE(ShotModel*)

/* ************************************************************************** */
#endif // SHOT_H
