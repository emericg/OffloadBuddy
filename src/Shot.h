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

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

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

    enum ShotState
    {
        SHOT_STATE_DEFAULT = 0,
        SHOT_STATE_QUEUED,
        SHOT_STATE_WORKING,
        SHOT_STATE_OFFLOADED,
    };
    Q_ENUM_NS(ShotState)
}

/* ************************************************************************** */

struct ofb_file
{
    QString name;                   //!< File base name only, no extension
    QString extension;              //!< Extension only, lowercase, no dot or anything

    uint64_t size = 0;              //!< Size in bytes
    QDateTime creation_date;
    QDateTime modification_date;

    QString filesystemPath;         //!< Absolute file path, if available

#ifdef ENABLE_LIBMTP
    LIBMTP_mtpdevice_t *mtpDevice = nullptr;
    //LIBMTP_devicestorage_t *mtpStorage = nullptr;
    uint32_t mtpObjectId = 0;
#endif
};

/*!
 * \brief The Shot class
 */
class Shot: public QObject
{
    Q_OBJECT

    Q_PROPERTY(unsigned type READ getType NOTIFY shotUpdated)
    Q_PROPERTY(unsigned state READ getState NOTIFY shotUpdated)
    Q_PROPERTY(QString name READ getName NOTIFY shotUpdated)
    Q_PROPERTY(QString camera READ getCameraSource NOTIFY shotUpdated)
    Q_PROPERTY(qint64 size READ getSize NOTIFY shotUpdated)

    Q_PROPERTY(QString preview READ getPreview NOTIFY shotUpdated)

    Q_PROPERTY(int highlightCount READ getHighlightCount NOTIFY shotUpdated)

    Q_PROPERTY(qint64 duration READ getDuration NOTIFY shotUpdated)
    Q_PROPERTY(QDateTime date READ getDate NOTIFY shotUpdated)
    //Q_PROPERTY(QString gps READ getGPS NOTIFY shotUpdated)

    bool m_onCamera = false;        //!< Shot datas currently located on a device

    Shared::ShotType m_type;
    Shared::ShotState m_state;
    QString m_camera_source;        //!< Model of the camera that produced the shot

    int m_shot_id = -1;
    int m_camera_id = 0;            //!< Shot is part of a multi camera systems

    QString m_name;
    QDateTime m_date;
    qint64 m_duration = 0;

    QList <QTime> m_highlights;

#ifdef ENABLE_LIBMTP
    LIBMTP_mtpdevice_t *m_mtpDevice = nullptr;
    LIBMTP_devicestorage_t *m_mtpStorage = nullptr;
#endif

    // PICTURES files
    QList <ofb_file *> m_jpg;

    // VIDEOS files
    QList <ofb_file *> m_mp4;
    QList <ofb_file *> m_lrv;
    QList <ofb_file *> m_thm;
    QList <ofb_file *> m_wav;

public:
    Shot(QObject *parent = nullptr);
    Shot(Shared::ShotType type);
    ~Shot();

    Shot(const Shot &other);

    bool isValid();
    void addFile(ofb_file *file);
#ifdef ENABLE_LIBMTP
    void attachMtpStorage(LIBMTP_mtpdevice_t *device, LIBMTP_devicestorage_t *storage);
#endif

    QStringList getFiles() const;

public slots:
    unsigned getType() const { return m_type; }
    unsigned getState() const { return m_state; }
    void setState(Shared::ShotState state) { m_state = state; emit shotUpdated(); }

    QString getName() const { return m_name; }
    qint64 getSize() const;
    qint64 getDuration() const;
    QDateTime getDate() const { return m_date; }
    QString getPreview() const;
    QString getCameraSource() const { return m_camera_source; }

    int getHighlightCount() const { return m_highlights.size(); }

    int getFileId() const { return m_shot_id; }
    void setFileId(int id) { m_shot_id = id; }
    int getCameraId() const { return m_camera_id; }
    void setCameraId(int id) { m_camera_id = id; }

Q_SIGNALS:
    void shotUpdated();
};

//Q_DECLARE_METATYPE(Shot*);

/* ************************************************************************** */
#endif // SHOT_H
