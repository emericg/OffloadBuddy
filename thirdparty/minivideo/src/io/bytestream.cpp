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
#include "bytestream.h"
#include "../minitraces.h"

// C POSIX library
#ifndef _MSC_VER
#include <unistd.h>
#endif

// C standard libraries
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>

/* ************************************************************************** */

char Bytestream::read_c(int &status)
{
    return readT<char>(status);
}

uint8_t Bytestream::read_u8(int &status)
{
    return readT<uint8_t>(status);
}

int8_t Bytestream::read_i8(int &status)
{
    return readT<int8_t>(status);
}

uint16_t Bytestream::read_u16(int &status)
{
    return readT<uint16_t>(status);
}

int16_t Bytestream::read_i16(int &status)
{
    return readT<int16_t>(status);
}

uint32_t Bytestream::read_u32(int &status)
{
    return readT<uint32_t>(status);
}

int32_t Bytestream::read_i32(int &status)
{
    return readT<int32_t>(status);
}

uint64_t Bytestream::read_u64(int &status)
{
    return readT<uint64_t>(status);
}

int64_t Bytestream::read_i64(int &status)
{
    return readT<int64_t>(status);
}

float Bytestream::read_float(int &status)
{
    uint32_t f = read_u32(status);
    return *(float *)&f;
}

double Bytestream::read_double(int &status)
{
    uint64_t d = read_u64(status);
    return *(double *)&d;
}

/* ************************************************************************** */
/* ************************************************************************** */

uint8_t *Bytestream::read_bytes(const unsigned bytes, int &status)
{
    //

    return nullptr;
}

/* ************************************************************************** */
/* ************************************************************************** */

void Bytestream::skip_bytes(const unsigned bytes, int &status)
{
    // Check if destination is outside the current buffer
    if (bytes > bytesLeftBuffer())
    {
        move_offset_bytes(get_offset_bytes() + bytes);
    }
    else
    {
        // Skip n bytes
        m_bufferOffset += bytes*8;
        //status = 0;
    }
}

void Bytestream::rewind_bytes(const unsigned bytes, int &status)
{
    // Check if destination is outside the current buffer
    if (bytes*8 > m_bufferOffset)
    {
        move_offset_bytes(get_offset_bytes() - bytes);
    }
    else
    {
        // Rewind n bytes
        m_bufferOffset -= bytes*8;
        //status = 0;
    }
}

/* ************************************************************************** */
