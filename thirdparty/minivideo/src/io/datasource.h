/*!
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
 *
 * This file is part of MiniVideo.
 *
 * MiniVideo is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * MiniVideo is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with MiniVideo.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2017
 */

#ifndef DATASOURCE_H
#define DATASOURCE_H
/* ************************************************************************** */

// C standard libraries
#include <cstdint>

// C++ standard libraries
#include <string>

/* ************************************************************************** */

/*!
 * \brief The MediaUrl class
 */
class MediaUrl
{
    std::string media_url_raw;            //!< URL of the media, as given by the user

    std::string media_url;                //!< URL of the media (used to derive other paths/names/extention)
    std::string media_protocol;           //!< Protocol (ex: file, http, https, ftp)

    std::string network_host;             //!< Host address
    std::string network_port;             //!< Host port
    std::string network_directory;        //!< Directory containing the file

    std::string file_path_absolute;       //!< Absolute file path (if available)
    std::string file_name;                //!< File name (without file extension)
    std::string file_extension;           //!< File extension, without dot (may NOT correspond to the real file format)

    const std::string supported_protocols[1] = {"file"};

public:
    MediaUrl(std::string &url);
    ~MediaUrl() = default;

    void print() const;

    bool isSupported() const;

    std::string getUrl() const;
    std::string getProtocol() const;

    std::string getNetworkHost() const;
    std::string getNetworkPort() const;
    std::string getNetworkDirectory() const;

    std::string getFileDirectory() const;
    std::string getName() const;
    std::string getExtension() const;
};

/* ************************************************************************** */

/*!
 * \brief The DataSource class
 */
class DataSource
{
protected:
    bool source_opened = false;
    int64_t source_size = 0;
    int64_t source_offset = 0;

    // Stats?
    int64_t stats_bytes_read = 0;
    int64_t stats_seek_count = 0;

public:
    DataSource() = default;
    virtual ~DataSource() = default;

    void print() const;

    bool isOpened() const { return source_opened; }
    int64_t getSize() const { return source_size; }
    int64_t getOffset() const { return source_offset; }

    virtual bool open(std::string &path) = 0;
    virtual bool open(MediaUrl &uri) = 0;
    virtual void close() = 0;
    virtual size_t read(uint8_t *buffer, int64_t offset, size_t size) = 0;
};

/* ************************************************************************** */
#endif // DATASOURCE_H
