/*!
 * This file is part of OffloadBuddy.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
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

#include "GpmfKLV.h"
#include "GpmfBuffer.h"
#include "GpmfTags.h"

#include <minivideo/minivideo_fourcc.h>

#include <iostream>

/* ************************************************************************** */

int readKLV(GpmfKLV &klv, GpmfBuffer &buf)
{
    int status = 0;

    klv.offset_begin = buf.getBytesIndex();

    klv.fcc = buf.read_u32(status);
    klv.type = buf.read_u8(status);
    klv.structsize = buf.read_u8(status);
    klv.repeat = buf.read_u16(status);

    klv.datasize = klv.structsize * klv.repeat;

    if (getGpmfTypeSize((GpmfType_e)klv.type) > 0)
        klv.datacount = (klv.datasize / getGpmfTypeSize((GpmfType_e)klv.type));
    else
        klv.datacount = klv.datasize;

    // offset_end is aligned on a 4 byte boundary
    klv.offset_end = klv.offset_begin + 8 + ((klv.datasize + 0x03) & ~0x03);

    return status;
}

/* ************************************************************************** */

void printKLV(GpmfKLV &klv)
{
    std::cout << "> KLV begin : " << klv.offset_begin << "\n";
    std::cout << "> KLV end   : " << klv.offset_end << "\n";

    std::cout << "> KLV fcc   : " << getFccString_be(klv.fcc) << "\n";
    std::cout << "> KLV type  : " << getFccString_be(klv.type) << "\n";
    std::cout << "> KLV str sz: " << klv.structsize << "\n";
    std::cout << "> KLV repeat: " << klv.repeat << "\n";

    std::cout << "> KLV datacount: " << klv.datacount << "\n";
    std::cout << "> KLV datasize : " << klv.datasize << "\n";

    std::cout << std::endl;
}

/* ************************************************************************** */
