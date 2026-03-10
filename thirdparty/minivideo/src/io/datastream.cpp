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
#include "datastream.h"
#include "datasource.h"
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

DataStream::DataStream()
{
    //
}

DataStream::~DataStream()
{
    closeDataSource();
    closeBuffer();
}

/* ************************************************************************** */

void DataStream::closeDataSource()
{
    m_data = nullptr;
    m_dataOffset = 0;
    m_dataSize = 0;
    m_dataFreeRun = false;
}

void DataStream::closeBuffer()
{
    deleteBuffer();

    m_bufferOwnership = true;

    m_bufferSize = 0;
    m_bufferCapacity = 0;
    m_bufferOffset = 0;
    m_bufferDiscardedBytes = 0;
}

void DataStream::deleteBuffer()
{
    if (m_bufferOwnership == true)
    {
        delete [] m_buffer;
    }

    m_buffer = nullptr;
}

/* ************************************************************************** */

bool DataStream::setCacheSize(uint32_t cacheSize)
{
    bool status = false;

    if (cacheSize)
    {
        if (cacheSize >= 16 && cacheSize <= m_cacheSize_max)
        {
            m_cacheSize_saved = cacheSize;
            status = true;
        }
        else
        {
            TRACE_WARNING(IO, "setCacheSize(%u) invalid cache size...", cacheSize);
        }
    }

    return status;
}

/* ************************************************************************** */

bool DataStream::loadFile(DataSource *datasource, int64_t offset, uint32_t cacheSize)
{
    bool status = false;

    closeDataSource();
    closeBuffer();

    // Check datasource
    if (datasource && datasource->isOpened())
    {
        m_data = datasource;
        m_dataSize = datasource->getSize();
        m_dataOffset = 0;
        m_dataFreeRun = true;

        setCacheSize(cacheSize);
        status = feedBuffer(offset);
    }
    else
    {
        TRACE_ERROR(IO, "loadFile() invalid DataSource...");
    }

    return status;
}

bool DataStream::loadBuffer(uint8_t *buffer, uint32_t bufferSize)
{
    bool status = false;

    closeDataSource();

    // Check buffer
    if (buffer && bufferSize > 0 && bufferSize <= m_bufferSize_max)
    {
        if (m_bufferCapacity < bufferSize)
        {
            deleteBuffer();
            m_buffer = new uint8_t[bufferSize];
        }

        if (m_buffer)
        {
            memcpy(m_buffer, buffer, bufferSize);

            m_dataOffset = 0;
            m_dataSize = bufferSize;

            m_bufferOffset = 0;
            m_bufferSize = bufferSize;
            m_bufferCapacity = bufferSize;
            m_bufferDiscardedBytes = 0;

            status = true;
        }
        else
        {
            TRACE_ERROR(IO, "loadBuffer() unable to alloate buffer...");
        }
    }
    else
    {
        TRACE_ERROR(IO, "loadBuffer() invalid buffer...");
    }

    return status;
}

bool DataStream::wrapBuffer(uint8_t *buffer, uint32_t bufferSize, bool bufferOwnership)
{
    bool status = false;

    closeDataSource();
    closeBuffer();

    // Check buffer
    if (buffer && bufferSize > 0 && bufferSize <= m_bufferSize_max)
    {
        if (bufferOwnership == true)
            m_bufferOwnership = true;

        m_dataOffset = 0;
        m_dataSize = bufferSize;

        m_buffer = buffer;
        m_bufferSize = bufferSize;
        m_bufferCapacity = bufferSize;
        m_bufferDiscardedBytes = 0;

        status = true;
    }
    else
    {
        TRACE_ERROR(IO, "wrapBuffer() invalid buffer...");
    }

    return status;
}

bool DataStream::feedBuffer(int64_t offset)
{
    bool status = false;

    TRACE_INFO(IO, "feedBuffer(%lli)", offset);

    // Check datasource
    if (m_data && m_data->isOpened())
    {
        // Continuous feeding requested?
        if (offset == -1)
        {
            offset = get_offset_bytes();
        }

        // Check offset
        if (offset >= 0 && offset < m_dataSize)
        {
            m_dataOffset = offset;

            // Adapt cache size
            {
                if (m_cacheSize_saved == 0)
                    m_cacheSize_saved = m_cacheSize_default;

                int64_t dataSizeLeft = m_dataSize - (m_dataOffset /*+ m_cacheSize_saved*/);

                TRACE_INFO(IO, "<b> " BLD_BLUE "dataSizeLeft(%lli)", dataSizeLeft);
                TRACE_INFO(IO, "<b> " BLD_BLUE "m_cacheSize_saved(%lli)", m_cacheSize_saved);

                if (m_cacheSize_saved <= dataSizeLeft)
                    m_bufferSize = m_cacheSize_saved;
                else
                    m_bufferSize = static_cast<int64_t>(dataSizeLeft);
            }

            // (Re)Init buffer
            if (m_bufferCapacity < m_bufferSize)
            {
                deleteBuffer();

                TRACE_INFO(IO, "<b> " BLD_BLUE "feedBuffer(%lli) INIT BUFF", offset);

                m_buffer = new uint8_t[m_bufferSize];
                m_bufferCapacity = m_bufferSize;
                m_bufferOwnership = true;

                TRACE_INFO(IO, "<b> " BLD_BLUE "m_bufferCapacity(%u)" , m_bufferCapacity);
                TRACE_INFO(IO, "<b> " BLD_BLUE "m_bufferSize(%u)", m_bufferSize);
                TRACE_INFO(IO, "<b> " BLD_BLUE "m_dataSize(%lli)", m_dataSize);
            }

            // Read data
            if (m_buffer && m_bufferCapacity >= m_bufferSize)
            {
                size_t data_read = m_data->read(m_buffer, m_dataOffset, m_bufferSize);

                unsigned fp = (m_bufferOffset % 8); // front padding, in bit

                m_bufferOffset = fp; // keep front padding
                m_bufferDiscardedBytes = 0;

                if (data_read == m_bufferSize)
                {
                    TRACE_INFO(IO, "<b> " BLD_BLUE "feedBuffer(%lli) DATAS READ %lli", offset, m_bufferSize);
                    status = true;
                }
                else if (data_read > 0)
                {
                    TRACE_INFO(IO, "DATAS READ ERR1 %lli  /  m_bufferSize %lli", data_read, m_bufferSize);
                    m_bufferSize = data_read;
                    status = true;
                }
                else
                {
                    TRACE_INFO(IO, "DATAS READ ERR2 %lli  /  m_bufferSize %lli", data_read, m_bufferSize);
                }
            }
            else
            {
                TRACE_ERROR(IO, "feedBuffer() invalid buffer...");
            }
        }
        else
        {
            if (offset >= m_dataSize)
                TRACE_ERROR(IO, "feedBuffer(%lli) End Of File...", offset);
            else
                TRACE_ERROR(IO, "feedBuffer(%lli) bad offset...", offset);
        }
    }
    else
    {
        TRACE_ERROR(IO, "feedBuffer() invalid DataSource...");
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */

uint32_t DataStream::bitsLeftBuffer()
{
    return (((m_bufferSize - m_bufferDiscardedBytes)*8) - m_bufferOffset);
}

uint32_t DataStream::bytesLeftBuffer()
{
    return ((m_bufferSize - m_bufferDiscardedBytes) - (m_bufferOffset/8));
}

int64_t DataStream::get_size_bytes()
{
    return m_dataSize;
}

int64_t DataStream::get_offset_bytes()
{
    // will ignore front padding (if any)
    return m_dataOffset + static_cast<int64_t>(m_bufferOffset/8);

    //return m_dataOffset + static_cast<int64_t>(std::floor(m_bufferOffset / 8.0));
}

int64_t DataStream::get_offset_bits()
{
    return (m_dataOffset*8) + static_cast<int64_t>(m_bufferOffset);
}

/* ************************************************************************** */
/* ************************************************************************** */

void DataStream::print_size_bytes()
{
    TRACE_INFO(IO, "print_size_bytes(%lli)", m_dataSize);
}

void DataStream::print_offset_bytes()
{
    int64_t offset_bytes = m_dataOffset + static_cast<int64_t>(m_bufferOffset/8);
    TRACE_INFO(IO, "get_offset_bytes(%lli)", offset_bytes);
}

void DataStream::print_offset_bits()
{
    int64_t offset_bits = (m_dataOffset*8) + static_cast<int64_t>(m_bufferOffset);
    TRACE_INFO(IO, "get_offset_bits(%lli)", offset_bits);
}

/* ************************************************************************** */
/* ************************************************************************** */

bool DataStream::move_offset_bytes(const int64_t n)
{
    bool status = false;

    // New offset is in the current stream?
    if (n >= 0 && n <= m_dataSize)
    {
        // New offset is in the current cache?
        if ((n >= m_dataOffset) && (n < (m_dataOffset + m_bufferSize)))
        {
            m_bufferOffset = static_cast<uint32_t>(m_dataOffset - n) * 8;
            status = true;
        }
        else
        {
            status = feedBuffer(n);
        }
    }
    else
    {
        TRACE_ERROR(IO, "move_offset_bytes(%lli) bad offset...", n);
    }

    return status;
}

bool DataStream::move_offset_bits(const int64_t n)
{
    bool status = false;

    // New offset is in the current stream?
    if (n >= 0 && n <= m_dataSize*8)
    {
        // New offset is in the current cache?
        if ((n >= m_dataOffset*8) && (n < (m_dataOffset*8 + m_bufferSize)))
        {
            m_bufferOffset = static_cast<uint32_t>(m_dataOffset*8 - n);
            status = true;
        }
        else
        {
            int64_t new_byte_offset = std::floor(n/8);
            int64_t new_bit_offset = n%8;

            status = feedBuffer(new_byte_offset);
            m_bufferOffset += new_bit_offset;
        }
    }
    else
    {
        TRACE_ERROR(IO, "move_offset_bits(%lli) bad offset...", n);
    }

    return status;
}

/* ************************************************************************** */
/* ************************************************************************** */
/*
// Data boundaries
bool DataStream::bitstream_check_alignment();
bool DataStream::bitstream_force_alignment();
*/
bool DataStream::more_bitstream_data()
{
    bool more_data = false;

    if (get_offset_bytes() < m_dataSize)
    {
        more_data = true;
    }

    return more_data;
}

bool DataStream::isEOF()
{
    bool eof = false;

    if (get_offset_bytes() >= m_dataSize)
    {
        eof = true;
    }

    return eof;
}

/* ************************************************************************** */
/* ************************************************************************** */
/*
// Debug operations
void DataStream::bitstream_print_stats();
void DataStream::bitstream_print_buffer();
*/
/* ************************************************************************** */
/* ************************************************************************** */

/*!
 * \brief Flip endianness variable content.
 * \param src: The source variable to flip.
 * \return The destination variable, with flipped endianness.
 *
 * Only useful for variable bigger than 1 byte!
 */
uint16_t DataStream::endian_flip_16(uint16_t src)
{
    return ( ((src & 0x00FF) << 8)
           | ((src & 0xFF00) >> 8) );
}

/* ************************************************************************** */

/*!
 * \brief Flip endianness variable content.
 * \param src: The source variable to flip.
 * \param n: The number size in bits.
 * \return The destination variable, with flipped endianness.
 *
 * Only useful for variable bigger than 1 byte!
 */
uint16_t DataStream::endian_flip_cut_16(uint16_t src, const int n)
{
    if (n > 0 && n < 16)
    {
        return ( ((src & 0x00FF) << 8)
               | ((src & 0xFF00) >> 8) ) >> (16 - n);
    }
    else
    {
        return src;
    }
}

/* ************************************************************************** */

/*!
 * \brief flip endianness variable content.
 * \param src The source variable to flip.
 * \return The destination variable, with flipped endianness.
 *
 * Only useful for variable bigger than 1 byte!
 */
uint32_t DataStream::endian_flip_32(uint32_t src)
{
    return ( ((src & 0x000000FF) << 24)
           | ((src & 0x0000FF00) <<  8)
           | ((src & 0x00FF0000) >>  8)
           | ((src & 0xFF000000) >> 24) );
}

/* ************************************************************************** */

/*!
 * \brief Flip endianness variable content.
 * \param src: The source variable to flip.
 * \param n: The size in bits of the wanted value.
 * \return The destination variable, with flipped endianness.
 *
 * Only useful for variable bigger than 1 byte!
 */
uint32_t DataStream::endian_flip_cut_32(uint32_t src, const  int n)
{
    if (n > 0 && n < 32)
    {
        return ( ((src & 0x000000FF) << 24)
               | ((src & 0x0000FF00) <<  8)
               | ((src & 0x00FF0000) >>  8)
               | ((src & 0xFF000000) >> 24) ) >> (32 - n);
    }
    else
    {
        return src;
    }
}

/* ************************************************************************** */

/*!
 * \brief Flip endianness variable content.
 * \param src: The source variable to flip.
 * \return The destination variable, with flipped endianness.
 *
 * Only useful for variable bigger than 1 byte!
 */
uint64_t DataStream::endian_flip_64(uint64_t src)
{
    return ( ((src & 0x00000000000000FFULL) << 56)
           | ((src & 0x000000000000FF00ULL) << 40)
           | ((src & 0x0000000000FF0000ULL) << 24)
           | ((src & 0x00000000FF000000ULL) <<  8)
           | ((src & 0x000000FF00000000ULL) >>  8)
           | ((src & 0x0000FF0000000000ULL) >> 24)
           | ((src & 0x00FF000000000000ULL) >> 40)
           | ((src & 0xFF00000000000000ULL) >> 56) );
}

/* ************************************************************************** */

/*!
 * \brief Flip endianness variable content.
 * \param src: The source variable to flip.
 * \param n: The size in bits of the wanted value.
 * \return The destination variable, with flipped endianness.
 *
 * Only useful for variable bigger than 1 byte!
 */
uint64_t DataStream::endian_flip_cut_64(uint64_t src, const int n)
{
    if (n > 0 && n < 64)
    {
        return ( ((src & 0x00000000000000FFULL) << 56)
               | ((src & 0x000000000000FF00ULL) << 40)
               | ((src & 0x0000000000FF0000ULL) << 24)
               | ((src & 0x00000000FF000000ULL) <<  8)
               | ((src & 0x000000FF00000000ULL) >>  8)
               | ((src & 0x0000FF0000000000ULL) >> 24)
               | ((src & 0x00FF000000000000ULL) >> 40)
               | ((src & 0xFF00000000000000ULL) >> 56) ) >> (64 - n);
    }
    else
    {
        return src;
    }
}

/* ************************************************************************** */
