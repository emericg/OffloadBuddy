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

#include "GpmfTags.h"

#include <iostream>

/* ************************************************************************** */

int getGpmfTypeSize(const GpmfType_e type)
{
    int type_size = -1;

    switch (type)
    {
    case GPMF_TYPE_NESTED:
        type_size = 1;
        break;

    case GPMF_TYPE_HIDDEN:
    case GPMF_TYPE_COMPLEX:
    case GPMF_TYPE_STRING_UTF8:
        type_size = -1;
        break;

    case GPMF_TYPE_FOURCC:
        type_size = 4;
        break;
    case GPMF_TYPE_GUID:
        type_size = 8;
        break;
    case GPMF_TYPE_UTC_DATE_TIME:
        type_size = 16;
        break;

    case GPMF_TYPE_STRING_ASCII:
    case GPMF_TYPE_SIGNED_BYTE:
    case GPMF_TYPE_UNSIGNED_BYTE:
        type_size = 1;
        break;

    case GPMF_TYPE_SIGNED_SHORT:
    case GPMF_TYPE_UNSIGNED_SHORT:
    case GPMF_TYPE_Q15_16_FIXED_POINT:
        type_size = 2;
        break;

    case GPMF_TYPE_FLOAT:
    case GPMF_TYPE_SIGNED_LONG:
    case GPMF_TYPE_UNSIGNED_LONG:
    case GPMF_TYPE_Q31_32_FIXED_POINT:
        type_size = 4;
        break;

    case GPMF_TYPE_DOUBLE:
    case GPMF_TYPE_SIGNED_64BIT:
    case GPMF_TYPE_UNSIGNED_64BIT:
        type_size = 8;
        break;

    default: // they are many other GPMF types that we don't know about
        std::cerr << "getMetadataTypeSize(" << type << ") error: UNKNOWN TYPE" << std::endl;
        type_size = -1;
        break;
    }

    return type_size;
}

/* ************************************************************************** */
