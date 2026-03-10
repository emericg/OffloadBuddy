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

#ifndef DATASOURCE_FILE_H
#define DATASOURCE_FILE_H
/* ************************************************************************** */

// minivideo headers
#include "datasource.h"

// C standard libraries
#include <cstdint>

// C++ standard libraries
#include <string>

/* ************************************************************************** */

class DataSource_file: public DataSource
{
    FILE *file = nullptr;
    std::string file_path;

public:
    DataSource_file() = default;
    ~DataSource_file() = default;

    bool open(std::string &filePath) override;
    bool open(MediaUrl &uri) override;
    size_t read(uint8_t *buffer, int64_t offset, size_t size) override;
    void close() override;
};

/* ************************************************************************** */
#endif // DATASOURCE_FILE_H
