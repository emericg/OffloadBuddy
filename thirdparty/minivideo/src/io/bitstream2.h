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

#ifndef BITSTREAM2_H
#define BITSTREAM2_H
/* ************************************************************************** */

// minivideo
#include "datastream.h"

// C standard libraries
#include <cstdint>

/* ************************************************************************** */

class Bitstream: public DataStream
{
public:
    // Bits operations /////////////////////////////////////////////////////////

    uint32_t read_bit(int &status);
    uint32_t read_bits(const unsigned n, int &status);
    uint64_t read_bits_64(const unsigned n, int &status);

    uint32_t next_bit(int &status);
    uint32_t next_bits(const unsigned n, int &status);

    void skip_bits(const unsigned n, int &status);
    void rewind_bits(const unsigned n, int &status);

    // H.264 specifics /////////////////////////////////////////////////////////

    bool h264_rbsp_trailing_bits();
    bool h264_more_rbsp_data();
    bool h264_more_rbsp_trailing_data();
};

/* ************************************************************************** */
#endif // BITSTREAM2_H
