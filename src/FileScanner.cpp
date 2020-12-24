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

    // Make sure the path is terminated with a separator.
    if (!m_selected_filesystem.endsWith('/')) m_selected_filesystem += '/';
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

void FileScanner::scanFilesystemDirectory(const QString &dir_path)
{
    //qDebug() << "  * Scanning subdir:" << dir_path;

    QDir dir(dir_path);
    for (const auto &subelement_name : dir.entryList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot))
    {
        //qDebug() << "  * Scanning subelement:" << subelement_name;

        QString subelement_path = dir_path;
        if (!subelement_path.endsWith('/')) subelement_path += '/';
        subelement_path += subelement_name;

        if (m_abort_scan)
            return;

        QFileInfo fi(subelement_path);
        if (fi.isDir())
        {
            scanFilesystemDirectory(subelement_path);
        }
        else
        {
            if (fi.exists() && fi.isReadable())
            {
                // Get file infos
                ofb_file *f = new ofb_file;
                if (f)
                {
                    f->filesystemPath = fi.absoluteFilePath();
                    f->directory = fi.absolutePath();
                    if (!f->directory.endsWith("/")) f->directory += "/";
                    f->name = fi.baseName();
                    f->extension = fi.suffix().toLower();
                    f->size = static_cast<uint64_t>(fi.size());
                    f->creation_date = fi.birthTime();
                    f->modification_date = fi.lastModified();

                    // Try to get shot infos, if applicable
                    ofb_shot *s = new ofb_shot;
                    bool shotStatus = getGoProShotInfos(*f, *s);
                    if (!shotStatus)
                        shotStatus = getGenericShotInfos(*f, *s);

                    // Pre-parse metadata on scanning thread
                    if (shotStatus)
                    {
                        if (f->extension == "mp4" || f->extension == "m4v" || f->extension == "mov" ||
                            f->extension == "mkv" || f->extension == "webm")
                        {
                            int minivideo_retcode = minivideo_open(f->filesystemPath.toLocal8Bit(), &f->media);
                            if (minivideo_retcode == 1)
                            {
                                minivideo_retcode = minivideo_parse(f->media, true, false);
                                if (minivideo_retcode != 1)
                                {
                                    qDebug() << "minivideo_parse() failed with retcode: " << minivideo_retcode;
                                    minivideo_close(&f->media);
                                }
                            }
                            else
                            {
                                qDebug() << "minivideo_open() failed with retcode: " << minivideo_retcode;
                            }
                        }
/*
                        // Disabled for now, so we don't parse 10k files from a timelapse before they have been associated with a shot
                        else if (f->extension == "jpg" ||
                                 f->extension == "jpeg")
                        {
                            f->ed = exif_data_new_from_file(f->filesystemPath.toLocal8Bit());
                        }
*/
                    }

                    // Send the file back to the UI
                    if (shotStatus)
                    {
                        emit fileFound(f, s);
                    }
                    else
                    {
                        delete f;
                        delete s;
                    }
                }
            }
        }
    }
}

bool FileScanner::scanFilesystemFile(const QString &file_path, ofb_file *f, ofb_shot *s)
{
    //qDebug() << "  * Scanning file:" << file_path;

    bool shotStatus = false;

    if (f && s)
    {
        // Get file infos
        QFileInfo fi(file_path);
        if (fi.isFile() && fi.exists() && fi.isReadable())
        {
            f->filesystemPath = fi.filePath();
            f->name = fi.baseName();
            f->extension = fi.suffix().toLower();
            f->size = static_cast<uint64_t>(fi.size());
#if (QT_VERSION_MINOR >= 10)
            f->creation_date = fi.birthTime();
#else
            f->creation_date = fi.created();
#endif
            f->modification_date = fi.lastModified();

            // Try to get shot infos, if applicable
            shotStatus = getGoProShotInfos(*f, *s);
            if (!shotStatus)
                shotStatus = getGenericShotInfos(*f, *s);

            // This function is not run on the scanning thread, so pre-parsing
            // metadata here doesn't really make sense
        }
    }

    return shotStatus;
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

    scanFilesystemDirectory(m_selected_filesystem);

    //qDebug() << "> SCANNING FINISHED (filesystem)";
    emit scanningFinished(m_selected_filesystem);
}

void FileScanner::scanFilesystemDCIM()
{
    if (m_selected_filesystem.isEmpty())
    {
        qWarning() << "> SCANNING FAILED (filesystem DCIM) no path provided...";
        return;
    }

    QString dcim_path = m_selected_filesystem + "DCIM/";

    //qDebug() << "> SCANNING STARTED (filesystem DCIM)";
    //qDebug() << "  * DCIM:" << dcim_path;
    emit scanningStarted(m_selected_filesystem);

    scanFilesystemDirectory(dcim_path);

    //qDebug() << "> SCANNING FINISHED (filesystem DCIM)";
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

                // Get file infos
                ofb_file *f = new ofb_file;
                {
                    f->name = file_name.mid(0, file_name.lastIndexOf("."));
                    f->extension = file_name.mid(file_name.lastIndexOf(".") + 1, -1).toLower();
                    f->size = mtpFile->filesize;
                    f->creation_date = f->modification_date = QDateTime::fromTime_t(mtpFile->modificationdate);

                    f->mtpDevice = device;
                    f->mtpObjectId = mtpFile->item_id;
                }

                // Try to get shot infos, if applicable
                ofb_shot *s = new ofb_shot;
                bool shotStatus = getGoProShotInfos(*f, *s);
                if (!shotStatus)
                    shotStatus = getGenericShotInfos(*f, *s);

                // Send the file back to the UI
                if (shotStatus)
                    emit fileFound(f, s);
                else
                {
                    delete f;
                    delete s;
                }
            }

            tmp = mtpFile;
            mtpFile = mtpFile->next;
            LIBMTP_destroy_file_t(tmp);
        }
    }
}

#endif // ENABLE_LIBMTP

/* ************************************************************************** */
