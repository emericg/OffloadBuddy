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

#include "GpmfBuffer.h"
#include "GpmfTags.h"

#include <iostream>
#include <cmath>

/* ************************************************************************** */

GpmfBuffer::GpmfBuffer()
{
    //
}

GpmfBuffer::~GpmfBuffer()
{
    //
}

/* ************************************************************************** */

bool GpmfBuffer::loadBuffer(uint8_t *buffer, uint64_t buffer_size)
{
    if (m_buffer != nullptr || m_buffer_size != 0)
    {
        std::cerr << "GpmfBuffer::loadBuffer() ERROR : internal buffer is not empty!" << std::endl;
        return false;
    }

    if (buffer == nullptr || buffer_size == 0)
    {
        std::cerr << "GpmfBuffer::loadBuffer() ERROR : provided buffer is empty!" << std::endl;
        return false;
    }

    m_buffer = buffer;
    m_buffer_size = buffer_size;
    m_buffer_index = 0;

    return true;
}

uint8_t *GpmfBuffer::getBuffer()
{
    return m_buffer;
}

uint64_t GpmfBuffer::getBufferSize()
{
    return m_buffer_size;
}

uint64_t GpmfBuffer::getBytesIndex()
{
    return m_buffer_index;
}

uint64_t GpmfBuffer::getBytesLeft()
{
    return (m_buffer_size - m_buffer_index);
}

bool GpmfBuffer::gotoIndex(uint64_t index)
{
    if (m_buffer == nullptr || m_buffer_size == 0)
    {
        std::cerr << "GpmfBuffer::gotoIndex() ERROR : internal buffer is empty!";
        return false;
    }

    if (m_buffer_size < index)
    {
        std::cerr << "GpmfBuffer::gotoIndex() ERROR : internal buffer is not big enough to accomodate your read!" << std::endl;
        return false;
    }

    m_buffer_index = index;

    return true;
}

/* ************************************************************************** */

char GpmfBuffer::read_c(int &error)
{
    return readT<char>(error);
}

uint8_t GpmfBuffer::read_u8(int &error)
{
    return readT<uint8_t>(error);
}

int8_t GpmfBuffer::read_i8(int &error)
{
    return readT<int8_t>(error);
}

uint16_t GpmfBuffer::read_u16(int &error)
{
    return readT<uint16_t>(error);
}

int16_t GpmfBuffer::read_i16(int &error)
{
    return readT<int16_t>(error);
}

uint32_t GpmfBuffer::read_u32(int &error)
{
    return readT<uint32_t>(error);
}

int32_t GpmfBuffer::read_i32(int &error)
{
    return readT<int32_t>(error);
}

uint64_t GpmfBuffer::read_u64(int &error)
{
    return readT<uint64_t>(error);
}

int64_t GpmfBuffer::read_i64(int &error)
{
    return readT<int64_t>(error);
}

float GpmfBuffer::read_float(int &error)
{
    uint32_t u = read_u32(error);
    return *(float *)&u;
}

double GpmfBuffer::read_double(int &error)
{
    uint64_t u = read_u64(error);
    return *(double *)&u;
}

/* ************************************************************************** */

uint8_t *GpmfBuffer::readBytes(int bytes, int &error)
{
    if (m_buffer == nullptr || m_buffer_size == 0)
    {
        std::cerr << "GpmfBuffer::read() ERROR : internal buffer is empty!" << std::endl;
        error = 1;
        return nullptr;
    }

    if (m_buffer_size < (m_buffer_index + static_cast<uint64_t>(bytes)))
    {
        std::cerr << "GpmfBuffer::read() ERROR : internal buffer is not big enough to accomodate your read(" << bytes << ")!" << std::endl;
        error = 1;
        return nullptr;
    }

    uint8_t *read = &m_buffer[m_buffer_index];
    m_buffer_index += static_cast<uint64_t>(bytes);

    return read;
}

/* ************************************************************************** */

int32_t GpmfBuffer::readData_i32(const GpmfKLV &klv, int &error)
{
    int32_t value = 0;

    switch (klv.type)
    {
    case GPMF_TYPE_UNSIGNED_BYTE:
        value = read_u8(error);
        break;

    case GPMF_TYPE_SIGNED_BYTE:
        value = read_i8(error);
        break;

    case GPMF_TYPE_UNSIGNED_SHORT:
        value = read_u16(error);
        break;

    case GPMF_TYPE_SIGNED_SHORT:
        value = read_i16(error);
        break;

    case GPMF_TYPE_FOURCC:
    case GPMF_TYPE_UNSIGNED_LONG:
        value = read_u32(error);
        break;

    case GPMF_TYPE_SIGNED_LONG:
        value = read_i32(error);
        break;

    case GPMF_TYPE_UNSIGNED_64BIT:
        value = read_u64(error);
        break;

    case GPMF_TYPE_SIGNED_64BIT:
        value = read_i64(error);
        break;

    case GPMF_TYPE_FLOAT:
        value = std::lround(read_float(error));
        break;

    case GPMF_TYPE_DOUBLE:
        value = std::lround(read_double(error));
        break;

    default:
        error = 1;
        break;
    }

    return value;
}

float GpmfBuffer::readData_float(const GpmfKLV &klv, int &error)
{
    float value = 0;

    switch (klv.type)
    {
    case GPMF_TYPE_UNSIGNED_BYTE:
        value = read_u8(error);
        break;

    case GPMF_TYPE_SIGNED_BYTE:
        value = read_i8(error);
        break;

    case GPMF_TYPE_UNSIGNED_SHORT:
        value = read_u16(error);
        break;

    case GPMF_TYPE_SIGNED_SHORT:
        value = read_i16(error);
        break;

    case GPMF_TYPE_FOURCC:
    case GPMF_TYPE_UNSIGNED_LONG:
        value = read_u32(error);
        break;

    case GPMF_TYPE_SIGNED_LONG:
        value = read_i32(error);
        break;

    case GPMF_TYPE_UNSIGNED_64BIT:
        value = read_u64(error);
        break;

    case GPMF_TYPE_SIGNED_64BIT:
        value = read_i64(error);
        break;

    case GPMF_TYPE_FLOAT:
        value = read_float(error);
        break;

    case GPMF_TYPE_DOUBLE:
        value = static_cast<float>(read_double(error));
        break;

    default:
        error = 1;
        break;
    }

    return value;
}

double GpmfBuffer::readData_double(const GpmfKLV &klv, int &error)
{
    double value = 0;

    switch (klv.type)
    {
    case GPMF_TYPE_UNSIGNED_BYTE:
        value = read_u8(error);
        break;

    case GPMF_TYPE_SIGNED_BYTE:
        value = read_i8(error);
        break;

    case GPMF_TYPE_UNSIGNED_SHORT:
        value = read_u16(error);
        break;

    case GPMF_TYPE_SIGNED_SHORT:
        value = read_i16(error);
        break;

    case GPMF_TYPE_FOURCC:
    case GPMF_TYPE_UNSIGNED_LONG:
        value = read_u32(error);
        break;

    case GPMF_TYPE_SIGNED_LONG:
        value = read_i32(error);
        break;

    case GPMF_TYPE_UNSIGNED_64BIT:
        value = read_u64(error);
        break;

    case GPMF_TYPE_SIGNED_64BIT:
        value = read_i64(error);
        break;

    case GPMF_TYPE_FLOAT:
        value = static_cast<double>(read_float(error));
        break;

    case GPMF_TYPE_DOUBLE:
        value = read_double(error);
        break;

    default:
        error = 1;
        break;
    }

    return value;
}

/* ************************************************************************** */
