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
#include "datasource_file.h"
#include "../minitraces.h"

/* ************************************************************************** */

// Windows large file support
#if defined(_WIN16) || defined(_WIN32) || defined(_WIN64)
#if defined(_MSC_VER) || defined(__MINGW32__)
    #include <cstdio>

    #undef stat64
    #define stat64 _stat64

    #undef fseek
    #define fseek(x, y, z) _fseeki64(x, y, z)

    #undef ftell
    #define ftell(x) _ftelli64(x)
#endif // defined(_MSC_VER) || defined(__MINGW32__)
#endif // defined(_WIN16) || defined(_WIN32) || defined(_WIN64)

/* ************************************************************************** */

void DataSource_file::close()
{
    if (isOpened() == true)
    {
        std::fclose(file);
        file = nullptr;

        file_path.clear();

        source_opened = false;
    }
}

bool DataSource_file::open(MediaUrl &uri)
{
    std::string ap = uri.getUrl();

    return open(ap);
}

bool DataSource_file::open(std::string &filePath)
{
    bool status = false;

    close();

    file_path = filePath;

    source_opened = false;
    source_size = 0;
    source_offset = 0;

    stats_bytes_read = 0;
    stats_seek_count = 0;

    file = std::fopen(file_path.c_str(), "rb");
    if (file)
    {
        status = true;
        source_opened = true;

        // Get file size
        std::fseek(file, 0, SEEK_END);
        source_size = static_cast<int64_t>(std::ftell(file));
        std::rewind(file);
    }
    else
    {
        TRACE_ERROR(IO, "Unable to open the media file: '%s'", file_path.c_str());
    }

    return status;
}

size_t DataSource_file::read(uint8_t *buffer, int64_t offset, size_t size)
{
    if (isOpened() == true)
    {
        if (source_offset != offset)
        {
            TRACE_ERROR(IO, "need seek(%lli)", offset);
            if (std::fseek(file, offset, SEEK_SET) == 0)
            {
                TRACE_ERROR(IO, "seek OK");
                source_offset = offset;
                stats_seek_count++;
            }
        }

        if (source_offset == offset)
        {
            TRACE_INFO(IO, "go for read");

            size_t actual_read = std::fread(buffer, sizeof(uint8_t), size, file);

            source_offset += actual_read;
            stats_bytes_read += actual_read;

            return actual_read;
        }
    }

    return 0;
}

/* ************************************************************************** */
