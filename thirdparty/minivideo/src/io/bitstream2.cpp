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
#include "bitstream2.h"
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

uint32_t Bitstream::read_bit(int &status)
{
    TRACE_3(BITS, "read_bit() starting at offset %lliB + %llib", get_offset_bytes(), (m_bufferOffset % 8));
    TRACE_3(BITS, "read_bit() starting at bit offset %lli", get_offset_bits());

    uint32_t start_byte = std::floor(m_bufferOffset / 8.0);

    // Fill new data into the DataStream buffer, if needed
    ////////////////////////////////////////////////////////////////////////

    if (start_byte >= m_bufferSize)
    {
        if (feedBuffer(-1) == false)
        {
            TRACE_ERROR(BITS, "feedBuffer() FAILED ???");
            status = 0;
            return 0;
        }

        start_byte = std::floor(m_bufferOffset / 8.0);
    }

    // Read one bit
    ////////////////////////////////////////////////////////////////////////

    uint32_t backpadding_bits = 7 - (m_bufferOffset % 8);
    uint32_t bit = m_buffer[start_byte] >> backpadding_bits;
    bit &= 0x01;

    // Update bit offset
    m_bufferOffset++;

    // Return result
    ////////////////////////////////////////////////////////////////////////

    // Recap
    TRACE_2(BITS, "<b>   bit     : %i", bit);

    return bit;
}

/* ************************************************************************** */

uint32_t Bitstream::read_bits(const unsigned n, int &status)
{
    TRACE_3(BITS, "read_bits(%u) starting at offset %lliB + %llib", n, get_offset_bytes(), (m_bufferOffset % 8));
    TRACE_3(BITS, "read_bits(%u) starting at bit offset %lli", n, get_offset_bits());

    if (n == 1) return read_bit(status); // shortcut

    uint32_t bits = 0;

    uint32_t frontpadding_bits = (m_bufferOffset % 8);
    uint32_t start_byte = std::floor(m_bufferOffset / 8.0);
    uint32_t tbr = std::ceil((n + frontpadding_bits) / 8.0);
    uint32_t tbr_current = tbr;

#if ENABLE_DEBUG
    TRACE_2(BITS, "<b>   n       : %u b", n);
    TRACE_2(BITS, "<b>   fp      : %u b", frontpadding_bits);
    TRACE_2(BITS, "<b>   bo      : %u b", m_bufferOffset);
    TRACE_2(BITS, "<b>   start   : %u B", start_byte);
    TRACE_2(BITS, "<b>   tbr     : %u b", tbr);

    // Check if we can read n bits
    if (n == 0)
    {
        TRACE_WARNING(BITS, "This function cannot read 0 bits!");
        status = 0;
        return 0;
    }
    else if (n > 32)
    {
        TRACE_WARNING(BITS, "You want to read %i bits, but this function can only read up to 32 bits!", n);
        status = 0;
        return 0;
    }
#endif // ENABLE_DEBUG

    // Fill new data into the DataStream buffer, if needed
    if ((start_byte + tbr) > m_bufferSize)
    {
        if (feedBuffer(-1) == false)
        {
            TRACE_ERROR(BITS, "feedBuffer() FAILED ???");
            status = 0;
            return 0;
        }

        frontpadding_bits = (m_bufferOffset % 8);
        start_byte = std::floor(m_bufferOffset / 8.0);
        tbr = std::ceil((n + frontpadding_bits) / 8.0);
        tbr_current = tbr;
    }

    // Read data
    if (frontpadding_bits > 0)
    {
        // Read un-aligned bits
        bits += m_buffer[start_byte++];
        bits &= 0xFF >> frontpadding_bits;
        tbr_current--;

        while (tbr_current > 0)
        {
            if (tbr > 4 &&
                tbr_current == 1)
            {
                bits <<= frontpadding_bits;
                bits += m_buffer[start_byte++] & (0xFF >> frontpadding_bits);
            }
            else
            {
                bits <<= 8;
                bits += m_buffer[start_byte++];
            }

            tbr_current--;
        }

        bits >>= ((tbr*8) - n - frontpadding_bits);
    }
    else
    {
        // Read aligned bits
        while (tbr_current > 0)
        {
            bits <<= 8;
            bits += m_buffer[start_byte++];
            tbr_current--;
        }

        bits >>= (32 - n) % 8;
    }

    // Update bit offset
    m_bufferOffset += n;

    // Recap
    TRACE_2(BITS, "  content = 0d%u", bits);
    TRACE_2(BITS, "  content = 0x%08X", bits);

    // Returns actual bits read
    return bits;
}

/* ************************************************************************** */

uint64_t Bitstream::read_bits_64(const unsigned n, int &status)
{
    TRACE_3(BITS, "read_bits_64(%u) starting at offset %lliB + %llib", n, get_offset_bytes(), (m_bufferOffset % 8));
    TRACE_3(BITS, "read_bits_64(%u) starting at bit offset %lli", n, get_offset_bits());

    if (n == 1) return read_bit(status); // shortcut

    uint64_t bits = 0;

    uint32_t frontpadding_bits = (m_bufferOffset % 8);
    uint32_t start_byte = std::floor(m_bufferOffset / 8.0);
    uint32_t tbr = std::ceil((n + frontpadding_bits) / 8.0);
    uint32_t tbr_current = tbr;

#if ENABLE_DEBUG
    TRACE_2(BITS, "<b>   n       : %u b", n);
    TRACE_2(BITS, "<b>   fp      : %u b", frontpadding_bits);
    TRACE_2(BITS, "<b>   bo      : %u b", m_bufferOffset);
    TRACE_2(BITS, "<b>   start   : %u B", start_byte);
    TRACE_2(BITS, "<b>   tbr     : %u b", tbr);

    // Check if we can read n bits
    if (n == 0)
    {
        TRACE_WARNING(BITS, "This function cannot read 0 bits!");
        status = 0;
        return 0;
    }
    else if (n > 64)
    {
        TRACE_WARNING(BITS, "You want to read %i bits, but this function can only read up to 64 bits!", n);
        status = 0;
        return 0;
    }
#endif // ENABLE_DEBUG

    // Fill new data into the DataStream buffer, if needed
    if ((start_byte + tbr) > m_bufferSize)
    {
        if (feedBuffer(-1) == false)
        {
            TRACE_ERROR(BITS, "feedBuffer() FAILED ???");
            status = 0;
            return 0;
        }

        frontpadding_bits = (m_bufferOffset % 8);
        start_byte = std::floor(m_bufferOffset / 8.0);
        tbr = std::ceil((n + frontpadding_bits) / 8.0);
        tbr_current = tbr;
    }

    // Read data
    if (frontpadding_bits > 0)
    {
        // Read un-aligned bits
        bits += m_buffer[start_byte++];
        bits &= 0xFF >> frontpadding_bits;
        tbr_current--;

        while (tbr_current > 0)
        {
            if (tbr > 4 &&
                tbr_current == 1)
            {
                bits <<= frontpadding_bits;
                bits += m_buffer[start_byte++] & (0xFF >> frontpadding_bits);
            }
            else
            {
                bits <<= 8;
                bits += m_buffer[start_byte++];
            }

            tbr_current--;
        }

        bits >>= ((tbr*8) - n - frontpadding_bits);
    }
    else
    {
        // Read aligned bits
        while (tbr_current > 0)
        {
            bits <<= 8;
            bits += m_buffer[start_byte++];
            tbr_current--;
        }

        bits >>= (64 - n) % 8;
    }

    // Update bit offset
    m_bufferOffset += n;

    // Recap
    TRACE_2(BITS, "  content = 0d%LLu", bits);
    TRACE_2(BITS, "  content = 0x%16X", bits);

    // Returns actual bits read
    return bits;
}

/* ************************************************************************** */
/* ************************************************************************** */

uint32_t Bitstream::next_bit(int &status)
{
    TRACE_3(BITS, "next_bit() starting at offset %lliB + %llib", get_offset_bytes(), (m_bufferOffset % 8));
    TRACE_3(BITS, "next_bit() starting at bit offset %lli", get_offset_bits());

    uint32_t start_byte = std::floor(m_bufferOffset / 8.0);

    // Fill new data into the DataStream buffer, if needed
    ////////////////////////////////////////////////////////////////////////

    if (start_byte >= m_bufferSize)
    {
        if (feedBuffer(-1) == false)
        {
            TRACE_ERROR(BITS, "feedBuffer() FAILED ???");
            status = 0;
            return 0;
        }

        start_byte = std::floor(m_bufferOffset / 8.0);
    }

    // Read one bit
    ////////////////////////////////////////////////////////////////////////

    uint32_t backpadding_bits = 7 - (m_bufferOffset % 8);
    uint32_t bit = m_buffer[start_byte] >> backpadding_bits;
    bit &= 0x01;

    // Update bit offset
    m_bufferOffset++;

    // Return result
    ////////////////////////////////////////////////////////////////////////

    // Recap
    TRACE_2(BITS, "<b>   bit     : %i", bit);

    return bit;
}

uint32_t Bitstream::next_bits(const unsigned n, int &status)
{
    TRACE_3(BITS, "next_bits(%u) starting at offset %lliB + %llib", n, get_offset_bytes(), (m_bufferOffset % 8));
    TRACE_3(BITS, "next_bits(%u) starting at bit offset %lli", n, get_offset_bits());

    if (n == 1) return next_bit(status); // shortcut

    uint32_t bits = 0;

    uint32_t frontpadding_bits = (m_bufferOffset % 8);
    uint32_t start_byte = std::floor(m_bufferOffset / 8.0);
    uint32_t tbr = std::ceil((n + frontpadding_bits) / 8.0);
    uint32_t tbr_current = tbr;

#if ENABLE_DEBUG
    TRACE_2(BITS, "<b>   n       : %u b", n);
    TRACE_2(BITS, "<b>   fp      : %u b", frontpadding_bits);
    TRACE_2(BITS, "<b>   bo      : %u b", m_bufferOffset);
    TRACE_2(BITS, "<b>   start   : %u B", start_byte);
    TRACE_2(BITS, "<b>   tbr     : %u b", tbr);

    // Check if we can read n bits
    if (n == 0)
    {
        TRACE_WARNING(BITS, "This function cannot read 0 bits!");
        status = 0;
        return 0;
    }
    else if (n > 32)
    {
        TRACE_WARNING(BITS, "You want to read %i bits, but this function can only read up to 32 bits!", n);
        status = 0;
        return 0;
    }
#endif // ENABLE_DEBUG

    // Fill new data into the DataStream buffer, if needed
    if ((start_byte + tbr) > m_bufferSize)
    {
        if (feedBuffer(-1) == false)
        {
            TRACE_ERROR(BITS, "feedBuffer() FAILED ???");
            status = 0;
            return 0;
        }

        frontpadding_bits = (m_bufferOffset % 8);
        start_byte = std::floor(m_bufferOffset / 8.0);
        tbr = std::ceil((n + frontpadding_bits) / 8.0);
        tbr_current = tbr;
    }

    // Read data
    if (frontpadding_bits > 0)
    {
        // Read un-aligned bits
        bits += m_buffer[start_byte++];
        bits &= 0xFF >> frontpadding_bits;
        tbr_current--;

        while (tbr_current > 0)
        {
            if (tbr > 4 &&
                tbr_current == 1)
            {
                bits <<= frontpadding_bits;
                bits += m_buffer[start_byte++] & (0xFF >> frontpadding_bits);
            }
            else
            {
                bits <<= 8;
                bits += m_buffer[start_byte++];
            }

            tbr_current--;
        }

        bits >>= ((tbr*8) - n - frontpadding_bits);
    }
    else
    {
        // Read aligned bits
        while (tbr_current > 0)
        {
            bits <<= 8;
            bits += m_buffer[start_byte++];
            tbr_current--;
        }

        bits >>= (32 - n) % 8;
    }

    // Recap
    TRACE_2(BITS, "  content = 0d%u", bits);
    TRACE_2(BITS, "  content = 0x%08X", bits);

    // Returns actual bits read
    return bits;
}

void Bitstream::skip_bits(const unsigned n, int &status)
{
    // Check if destination is outside the current buffer
    if (n > bitsLeftBuffer())
    {
        move_offset_bits(get_offset_bits() + n);
    }
    else
    {
        // Skip n bits
        m_bufferOffset += n;
    }
}

void Bitstream::rewind_bits(const unsigned n, int &status)
{
    // Check if destination is outside the current buffer
    if (n > m_bufferOffset)
    {
        move_offset_bits(get_offset_bits() - n);
    }
    else
    {
        // Rewind n bits
        m_bufferOffset -= n;
    }
}

/* ************************************************************************** */
