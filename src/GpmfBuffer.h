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

#ifndef GPMF_BUFFER_H
#define GPMF_BUFFER_H
/* ************************************************************************** */

#include "GpmfKLV.h"

#include <cstdint>
#include <cstdlib>
#include <iostream>

/* ************************************************************************** */

/*!
 * \brief The GpmfBuffer class is actually a pretty straightforward bytestream reader.
 */
class GpmfBuffer
{
    uint8_t *m_buffer = nullptr;
    uint64_t m_buffer_size = 0;
    uint64_t m_buffer_index = 0;

public:
    GpmfBuffer();
    virtual ~GpmfBuffer();

    bool loadBuffer(uint8_t *buffer, uint64_t buffer_size);

    uint8_t *getBuffer();
    uint64_t getBufferSize();
    uint64_t getBytesIndex();
    uint64_t getBytesLeft();

    bool gotoIndex(uint64_t offset);

    char read_c(int &error);
    uint8_t read_u8(int &error);
    int8_t read_i8(int &error);
    uint16_t read_u16(int &error);
    int16_t read_i16(int &error);
    uint32_t read_u32(int &error);
    int32_t read_i32(int &error);
    uint64_t read_u64(int &error);
    int64_t read_i64(int &error);
    float read_float(int &error);
    double read_double(int &error);

    uint8_t *readBytes(int bytes, int &error);

    int32_t readData_i32(const GpmfKLV &klv, int &error);
    float readData_float(const GpmfKLV &klv, int &error);
    double readData_double(const GpmfKLV &klv, int &error);

    template<typename T>
    T readT(int &error)
    {
        if (m_buffer == nullptr || m_buffer_size == 0)
        {
            std::cerr << "GpmfBuffer::readT() ERROR : internal buffer is empty!" << std::endl;
            error = 1;
            return 0;
        }

        const std::size_t nbBytes = sizeof(T);
        int64_t bytes_left = static_cast<int64_t>(m_buffer_size - m_buffer_index);
        if (bytes_left < static_cast<int64_t>(nbBytes))
        {
            std::cerr << "GpmfBuffer::readT() ERROR : Cannot read(" << nbBytes << ") in internal buffer (" << bytes_left << "bytes left)!" << std::endl;
            error = 1;
            return 0;
        }

        T read;
        uint8_t *r = reinterpret_cast<uint8_t *>(&read);

        for (std::size_t i = 0; i < nbBytes; i++)
            r[nbBytes - i - 1] = m_buffer[m_buffer_index++];

        return read;
    }
};

/* ************************************************************************** */
#endif // GPMF_BUFFER_H
