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
 * \date      2018
 */

#ifndef BYTESTREAM_H
#define BYTESTREAM_H
/* ************************************************************************** */

// minivideo
#include "datastream.h"

// C standard libraries
#include <cstdint>
#include <cstdlib>

/* ************************************************************************** */

class Bytestream: public DataStream
{
public:
    // Bytes operations ////////////////////////////////////////////////////////

    char read_c(int &status);
    uint8_t read_u8(int &status);
    int8_t read_i8(int &status);
    uint16_t read_u16(int &status);
    int16_t read_i16(int &status);
    uint32_t read_u32(int &status);
    int32_t read_i32(int &status);
    uint64_t read_u64(int &status);
    int64_t read_i64(int &status);
    float read_float(int &status);
    double read_double(int &status);

    uint8_t *read_bytes(const unsigned bytes, int &status);

    uint32_t next_bytes(const unsigned bytes, int &status);

    void skip_bytes(const unsigned bytes, int &status);
    void rewind_bytes(const unsigned bytes, int &status);

    template<typename T>
    T readT(int &status)
    {
        if (m_buffer == nullptr || m_bufferSize == 0)
        {
            //std::cerr << "GpmfBuffer::readT() ERROR : internal buffer is empty!" << std::endl;
            status = 1;
            return 0;
        }

        const std::size_t nbBytes = sizeof(T);
        int64_t bytes_left = m_bufferSize - (m_bufferOffset/8);
        if (bytes_left < static_cast<int64_t>(nbBytes))
        {
            //std::cerr << "GpmfBuffer::readT() ERROR : Cannot read(" << nbBytes << ") in internal buffer (" << bytes_left << "bytes left)!" << std::endl;
            status = 1;
            return 0;
        }

        T read;
        uint8_t *r = reinterpret_cast<uint8_t *>(&read);

        for (std::size_t i = 0; i < nbBytes; i++)
        {
            r[nbBytes - i - 1] = m_buffer[(m_bufferOffset/8)];
            m_bufferOffset += 8;
        }

        return read;
    }
};

/* ************************************************************************** */
#endif // BYTESTREAM_H
