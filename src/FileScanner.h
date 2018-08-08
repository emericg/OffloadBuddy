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

#ifndef FILE_SCANNER
#define FILE_SCANNER
/* ************************************************************************** */

#include "Shot.h"
#include "Device.h"

#ifdef ENABLE_LIBMTP
#include <libmtp.h>
#endif

#include <QObject>
#include <QVariant>
#include <QList>

#include <QStorageInfo>
#include <QTimer>

/* ************************************************************************** */

class FileScanner: public QObject
{
    Q_OBJECT

    QString m_selected_filesystem;

#ifdef ENABLE_LIBMTP
    LIBMTP_mtpdevice_t *m_selected_mtpDevice = nullptr;
    LIBMTP_devicestorage_t *m_selected_mtpStorage = nullptr;

    void mtpFileLvl1(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf);
    void mtpFileRec(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf);
    void mtpFileUseless(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf);
#endif // ENABLE_LIBMTP

public:
    FileScanner();
    ~FileScanner();

public slots:
    void chooseFilesystem(const QString &m_selected_filesystem);
    void chooseMtpStorage(StorageMtp *mtpStorage);
    //void chooseMtpStorages(QList<StorageMtp *> *storages);

    void scanFilesystem();
    void scanMtpDevice();

signals:
    void fileFound(ofb_file *, ofb_shot *);
    void scanningStarted(QString);
    void scanningFinished(QString);
};

/* ************************************************************************** */
#endif // FILE_SCANNER
