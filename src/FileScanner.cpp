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

#include "FileScanner.h"
#include "GenericFileModel.h"
#include "GoProFileModel.h"
#include "ShotModel.h"
#include "SettingsManager.h"

#include <QStorageInfo>
#include <QFile>
#include <QDir>
#include <QDebug>

/* ************************************************************************** */

FileScanner::FileScanner()
{
    //
}

FileScanner::~FileScanner()
{
    //
}

/* ************************************************************************** */
/* ************************************************************************** */

void FileScanner::chooseFilesystem(const QString &path)
{
    m_abort_scan = false;
    m_selected_filesystem = path;
}

void FileScanner::chooseMtpStorage(StorageMtp *mtpStorage)
{
#ifdef ENABLE_LIBMTP
    m_abort_scan = false;
    m_selected_mtpDevice = mtpStorage->m_device;
    m_selected_mtpStorage = mtpStorage->m_storage;
#endif
}

/* ************************************************************************** */

//void FileScanner::chooseFilesystems(QList<StorageFilesystem *> *storages)

//void FileScanner::chooseMtpStorages(QList<StorageMtp *> *storages)

/* ************************************************************************** */
/* ************************************************************************** */

void FileScanner::scanFilesystemElement(QString &dir_path)
{
    //qDebug() << "  * Scanning subdir:" << dir_path;

    QDir dir(dir_path);
    foreach (QString subelement_name, dir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot))
    {
        //qDebug() << "  * Scanning subelement:" << subelement_name;
        QString subelement_path = dir_path + QDir::separator() + subelement_name;

        if (m_abort_scan)
            return;

        QFileInfo fi(subelement_path);
        if (fi.isDir())
        {
            scanFilesystemElement(subelement_path);
        }
        else
        {
            if (fi.exists() && fi.isReadable())
            {
                ofb_file *f = new ofb_file;
                if (f)
                {
                    f->name = fi.baseName();
                    f->extension = fi.suffix().toLower();
                    f->size = static_cast<uint64_t>(fi.size());
#if (QT_VERSION_MINOR >= 10)
                    f->creation_date = fi.birthTime();
#endif
                    f->modification_date = fi.lastModified();

                    f->filesystemPath = fi.filePath();
                }

                ofb_shot *s = new ofb_shot;
                bool shotStatus = getGoProShotInfos(*f, *s);
                if (!shotStatus)
                    shotStatus = getGenericShotInfos(*f, *s);

                if (shotStatus)
                    emit fileFound(f, s);
                else
                    delete s;
            }
        }
    }
}

void FileScanner::scanFilesystem()
{
    if (m_selected_filesystem.isEmpty())
    {
        qWarning() << "> SCANNING FAILED (filesystem) no path provided...";
        return;
    }

    //qDebug() << "> SCANNING STARTED (filesystem)";
    emit scanningStarted(m_selected_filesystem);

    scanFilesystemElement(m_selected_filesystem);

    //qDebug() << "> SCANNING FINISHED";
    emit scanningFinished(m_selected_filesystem);
}

void FileScanner::scanFilesystemDCIM()
{
    if (m_selected_filesystem.isEmpty())
    {
        qWarning() << "> SCANNING FAILED (filesystem DCIM) no path provided...";
        return;
    }

    QString dcim_path = m_selected_filesystem + QDir::separator() + "DCIM";

    //qDebug() << "> SCANNING STARTED (filesystem)";
    //qDebug() << "  * DCIM:" << dcim_path;
    emit scanningStarted(m_selected_filesystem);

    scanFilesystemElement(dcim_path);

    //qDebug() << "> SCANNING FINISHED";
    emit scanningFinished(m_selected_filesystem);
}

/* ************************************************************************** */

void FileScanner::abortScan()
{
    qWarning() << ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> abortScan()";
    m_abort_scan = true;
}

/* ************************************************************************** */
/* ************************************************************************** */

void FileScanner::scanMtpDevice()
{
#ifdef ENABLE_LIBMTP

    if (!m_selected_mtpDevice || !m_selected_mtpStorage)
    {
        qWarning() << "> SCANNING FAILED (MTP device) no device provided...";
        return;
    }

    //qDebug() << "> SCANNING STARTED (MTP device)";
    emit scanningStarted(m_selected_filesystem);

    mtpFileLvl1(m_selected_mtpDevice,
                m_selected_mtpStorage->id,
                LIBMTP_FILES_AND_FOLDERS_ROOT);

    //qDebug() << "> SCANNING FINISHED";
    emit scanningFinished(m_selected_filesystem);

#endif // ENABLE_LIBMTP
}

#ifdef ENABLE_LIBMTP

void FileScanner::mtpFileLvl1(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf)
{
    // Get file listing
    LIBMTP_file_t *mtpFiles = LIBMTP_Get_Files_And_Folders(device, storageid, leaf);

    if (mtpFiles == nullptr)
    {
        LIBMTP_Dump_Errorstack(device);
        LIBMTP_Clear_Errorstack(device);
    }
    else
    {
        bool fullscan = false;
        SettingsManager *sm = SettingsManager::getInstance();
        if (sm)
        {
            fullscan = sm->getMtpFullScan();
        }

        LIBMTP_file_t *mtpFile, *tmp;
        mtpFile = mtpFiles;

        while (mtpFile != nullptr)
        {
            if (mtpFile->filetype == LIBMTP_FILETYPE_FOLDER)
            {
                //qDebug() << "- (folder lvl1) " << mtpFile->filename;

                if (fullscan)
                {
                    mtpFileRec(device, storageid, mtpFile->item_id);
                }
                else
                {
                    if (strcmp(mtpFile->filename, "DCIM") == 0 ||
                        strcmp(mtpFile->filename, "Pictures") == 0 ||
                        strcmp(mtpFile->filename, "Movies") == 0)
                    {
                        //qDebug() << "- (folder DCIM found)";
                        mtpFileRec(device, storageid, mtpFile->item_id);
                    }
                }
            }

            tmp = mtpFile;
            mtpFile = mtpFile->next;
            LIBMTP_destroy_file_t(tmp);
        }
    }
}

void FileScanner::mtpFileRec(LIBMTP_mtpdevice_t *device, uint32_t storageid, uint32_t leaf)
{
    LIBMTP_file_t *mtpFiles;

    // Get file listing
    mtpFiles = LIBMTP_Get_Files_And_Folders(device, storageid, leaf);

    if (mtpFiles == nullptr)
    {
        LIBMTP_Dump_Errorstack(device);
        LIBMTP_Clear_Errorstack(device);
    }
    else
    {
        LIBMTP_file_t *mtpFile, *tmp;
        mtpFile = mtpFiles;

        while (mtpFile != nullptr)
        {
            if (mtpFile->filetype == LIBMTP_FILETYPE_FOLDER)
            {
                //qDebug() << "- (subfolder) " << mtpFile->filename;
                mtpFileRec(device, storageid, mtpFile->item_id);
            }
            else
            {
                //qDebug() << "- (file) " << mtpFile->filename << "(" << mtpFile->filesize << "bytes)";
                QString file_name = mtpFile->filename;

                ofb_file *f = new ofb_file;
                {
                    f->name = file_name.mid(0, file_name.lastIndexOf("."));
                    f->extension = file_name.mid(file_name.lastIndexOf(".") + 1, -1).toLower();
                    f->size = mtpFile->filesize;
                    f->creation_date = f->modification_date = QDateTime::fromTime_t(mtpFile->modificationdate);

                    f->mtpDevice = device;
                    f->mtpObjectId = mtpFile->item_id;
                }

                ofb_shot *s = new ofb_shot;
                bool shotStatus = getGoProShotInfos(*f, *s);
                if (!shotStatus)
                    shotStatus = getGenericShotInfos(*f, *s);

                if (shotStatus)
                    emit fileFound(f, s);
                else
                    delete s;
            }

            tmp = mtpFile;
            mtpFile = mtpFile->next;
            LIBMTP_destroy_file_t(tmp);
        }
    }
}

#endif // ENABLE_LIBMTP

/* ************************************************************************** */
