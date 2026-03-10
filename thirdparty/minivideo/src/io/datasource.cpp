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

// minivideo headers
#include "datasource.h"
#include "../minitraces.h"

// C standard libraries
#include <cstdio>
#include <cstdlib>
#include <cstring>

// C++ standard libraries
#include <string>
#if __cplusplus > 201703L
#include <filesystem>
#endif

#ifdef _MSC_VER
    // MSVC library
    #include <direct.h>
    #define getcwd _getcwd
#else
    // C POSIX library
    #include <unistd.h>
#endif

/* ************************************************************************** */

MediaUrl::MediaUrl(std::string &url)
{
    TRACE_2(IO, "getInfosFromPath()");

    media_url_raw = url;

    if (url.substr(0, 7) == "http://")
    {
        // file over network
        media_protocol = "http";
        media_url = url;
    }
    else if (url.substr(0, 8) == "https://")
    {
        // file over network
        media_protocol = "https";
        media_url = url;
    }
    else if (url.substr(0, 6) == "ftp://")
    {
        // file over network
        media_protocol = "ftp";
        media_url = url;
    }
    else // detect file on disk
    {
        if (url.substr(0, 7) == "file://")
        {
            media_protocol = "file";
            media_url = url.substr(6);
        }
        else
        {
            // assume local file
            media_protocol = "file";
            media_url = url;
        }

#if __cplusplus > 201703L // C++ 17 implementation
        if (std::filesystem::exists(p))
        {
            TRACE_WARNING(IO, "CPP17");

            file_path_absolute = std::filesystem::absolute(url);

            std::filesystem::path p = url;
        }
#else // C implementation
        FILE *file = fopen(media_url.c_str(), "r");
        if (file)
        {
            fclose(file);
            file = nullptr;

            const char *path_cstr = media_url.c_str();
            file_path_absolute = media_url;

            // Check if uri is an absolute path
            const char *pos_first_slash_p = strchr(path_cstr, '/');

            if ((pos_first_slash_p != NULL) && ((pos_first_slash_p - path_cstr) == 0))
            {
                TRACE_2(IO, "* mediaFile->file_path seems to be an absolute path already (first caracter is /)");
            }
            else
            {
                // use GetFullPathName() ?
                //realpath() ?

                char cwd[4096];
                char absolute_filepath[4096];

                // First attempt
                if (getcwd(cwd, sizeof(cwd)) != NULL)
                {
                    strncpy(absolute_filepath, strncat(cwd, path_cstr, sizeof(cwd) - 1), sizeof(absolute_filepath) - 1);
                    file = fopen(absolute_filepath, "rb");
                }

                if (file != NULL)
                {
                    TRACE_2(IO, "* New absolute file path found, new using method 1: '%s'", absolute_filepath);
                    file_path_absolute = absolute_filepath;

                    fclose(file);
                    file = nullptr;
                }
                else
                {
                    // Second attempt
                    if (getcwd(cwd, sizeof(cwd)) != NULL)
                    {
                        strncpy(absolute_filepath, strncat(cwd, "/", 2), sizeof(absolute_filepath) - 1);
                        strncat(absolute_filepath, path_cstr, sizeof(absolute_filepath) - 1);
                        file = fopen(absolute_filepath, "rb");
                    }

                    if (file != NULL)
                    {
                        TRACE_2(IO, "* New absolute file path found, new using method 2");
                        file_path_absolute = absolute_filepath;

                        fclose(file);
                        file = nullptr;
                    }
                    else
                    {
                        TRACE_2(IO, "* mediaFile->file_path seems to be an absolute path already");
                    }
                }
            }

            network_directory = file_path_absolute.substr(0, file_path_absolute.rfind("/"));
            file_extension = file_path_absolute.substr(file_path_absolute.find(".")+1, -1);
            file_name = file_path_absolute.substr(file_path_absolute.rfind("/")+1, file_path_absolute.rfind("."));
        }
        else
        {
            TRACE_ERROR(IO, "Cannot even open file '%s'", media_url.c_str());
        }
#endif // __cplusplus
    }
}

/* ************************************************************************** */

void MediaUrl::print() const
{
    TRACE_INFO(IO, "MediaUrl::print()");

    TRACE_INFO(IO, "- media_url: '%s'", media_url.c_str());
    TRACE_INFO(IO, "- media_protocol: '%s'", media_protocol.c_str());

    TRACE_INFO(IO, "- network_host: '%s'", network_host.c_str());
    TRACE_INFO(IO, "- network_port: '%s'", network_port.c_str());
    TRACE_INFO(IO, "- network_directory: '%s'", network_directory.c_str());

    TRACE_INFO(IO, "- file_path_absolute: '%s'", file_path_absolute.c_str());
    TRACE_INFO(IO, "- file_name: '%s'", file_name.c_str());
    TRACE_INFO(IO, "- file_extension: '%s'", file_extension.c_str());
}

bool MediaUrl::isSupported() const
{
    bool supported = false;

    for (auto s: supported_protocols)
    {
        if (media_protocol == s)
        {
            supported = true;
            break;
        }
    }

    return supported;
}

std::string MediaUrl::getUrl() const
{
    return media_url;
}

std::string MediaUrl::getProtocol() const
{
    return media_protocol;
}

std::string MediaUrl::getNetworkHost() const
{
    return network_host;
}

std::string MediaUrl::getNetworkPort() const
{
    return network_port;
}

std::string MediaUrl::getNetworkDirectory() const
{
    return network_directory;
}

std::string MediaUrl::getFileDirectory() const
{
    return media_url;
}

std::string MediaUrl::getName() const
{
    return file_name;
}

std::string MediaUrl::getExtension() const
{
    return file_extension;
}

/* ************************************************************************** */

void DataSource::print() const
{
    TRACE_INFO(IO, "DataSource::print()");

    TRACE_INFO(IO, "- source_opened: %i", source_opened);
    TRACE_INFO(IO, "- source_size: %lli", source_size);
    TRACE_INFO(IO, "- source_offset: %lli", source_offset);

    TRACE_INFO(IO, "- stats_bytes_read: %lli", stats_bytes_read);
    TRACE_INFO(IO, "- stats_seek_count: %lli", stats_seek_count);
}

/* ************************************************************************** */
