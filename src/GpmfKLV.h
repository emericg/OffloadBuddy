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

#ifndef GPMF_KLV_H
#define GPMF_KLV_H
/* ************************************************************************** */

#include <cstdint>

class GpmfBuffer;

/* ************************************************************************** */

/*!
 * The GPMF metadata format is a modified "Key, Length, Value" solution, with
 * a 32-bit aligned payload.
 *
 * From https://github.com/gopro/gpmf-parser.
 */
typedef struct GpmfKLV
{
    uint64_t offset_begin = 0;
    uint64_t offset_end = 0;

    uint32_t fcc = 0;           //! Standard FourCC style key

    uint8_t type = 0;           //! Base data unit type (see GpmfType_e)
    uint8_t structsize = 0;     //! The structure size for a single sample (in bytes)
    uint16_t repeat = 0;        //! The number of times the current structure will be repeated

    uint64_t datasize = 0;      //!< (klv.structsize * klv.repeat) (in bytes)
    uint64_t datacount = 0;     //!< (klv.structsize / getMetadataTypeSize(klv.type)) * klv.repeat

} GpmfKLV;

/*!
 * \brief Read a GPMF KLV structure from raw data
 * \param klv: Structure to fill
 * \param buf: Data source
 * \return 0 if success
 */
int readKLV(GpmfKLV &klv, GpmfBuffer &buf);

/*!
 * \brief Print a GPMF KLV structure
 * \param klv: Structure to print
 */
void printKLV(GpmfKLV &klv);

/* ************************************************************************** */
#endif // GPMF_KLV_H
