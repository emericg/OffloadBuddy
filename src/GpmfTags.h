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

#ifndef GPMF_TAGS_H
#define GPMF_TAGS_H
/* ************************************************************************** */

#include "minivideo_fourcc.h"

/*!
 * \brief GPMF metadata tags
 *
 * From https://github.com/gopro/gpmf-parser.
 */
typedef enum
{
    // Reserved structural tags
    GPMF_TAG_DEVICE         = fourcc_be("DEVC"),    //!< Nested device data to speed the parsing of multiple devices in post
    GPMF_TAG_DEVICE_NAME    = fourcc_be("DVNM"),    //!< Human readable device type/name (char string)
    GPMF_TAG_DEVICE_ID      = fourcc_be("DVID"),    //!< Unique id per stream for a metadata source (in camera or external input) (single 4 byte int)
    GPMF_TAG_STREAM         = fourcc_be("STRM"),    //!< Nested channel/stream of telemetry data
    GPMF_TAG_STREAM_NAME    = fourcc_be("STNM"),    //!< Human readable stream type/name (char string)
    GPMF_TAG_SI_UNITS       = fourcc_be("SIUN"),    //!< Display string for metadata units where inputs are in SI units "uT","rad/s","km/s","m/s","mm/s" etc
    GPMF_TAG_UNITS          = fourcc_be("UNIT"),    //!< Freeform display string for metadata units (char sting like "RPM", "MPH", "km/h", etc)
    GPMF_TAG_SCALE          = fourcc_be("SCAL"),    //!< Divisor for input data to scale to the correct units
    GPMF_TAG_TYPE           = fourcc_be("TYPE"),    //!< Type define for complex data structures
    GPMF_TAG_TSMP           = fourcc_be("TSMP"),    //!< Total Sample Count including the current payload
    GPMF_TAG_REMARK         = fourcc_be("RMRK"),    //!< Adding comments to the bitstream (debugging)

    // Function tags
    GPMF_TAG_FREE           = fourcc_be("FREE"),    //!< Bytes reserved for more metadata.
    GPMF_TAG_EMPTY          = fourcc_be("EMPT"),    //!< Payloads that are empty since the device start (e.g. BLE disconnect.)
    GPMF_TAG_END            = fourcc_be("\0\0\0\0"),//!< (null)

    // Timestamps
    GPMF_TAG_TICK = fourcc_be("TICK"),        //!< Used for slow data. Beginning of data timing in milliseconds.
    GPMF_TAG_TOCK = fourcc_be("TOCK"),        //!< Used for slow data. End of data timing in milliseconds.
    // Image
    GPMF_TAG_SHUT = fourcc_be("SHUT"),        //!< Shutter/exposure time (in seconds)
    GPMF_TAG_ISOG = fourcc_be("ISOG"),        //!< Sensor gain combined (analog + digital)
    GPMF_TAG_ROLL = fourcc_be("ROLL"),        //!< Rolling shutter time from the first to last scan line
    GPMF_TAG_WBAL = fourcc_be("WBAL"),        //!< White Balance (R, G, B gains)

    // Sensors telemetry
    GPMF_TAG_ACCL = fourcc_be("ACCL"),        //!< 3 axis accelerometer (Z, X, Y)
    GPMF_TAG_GYRO = fourcc_be("GYRO"),        //!< 3 axis gyroscope (X, Y, Z)
    GPMF_TAG_MAGN = fourcc_be("MAGN"),        //!< 3 axis magnometer (X, Y, Z in µT)
    GPMF_TAG_TMPC = fourcc_be("TMPC"),        //!< Sensor Temp (in degrees C)

    // GPS telemetry
    GPMF_TAG_GPSC = fourcc_be("GPSC"),        //!< GPS satellite count
    GPMF_TAG_GPST = fourcc_be("GPST"),        //!< GPS Time & Date (Date + UTC Time format yymmddhhmmss.sss)
    GPMF_TAG_GPSL = fourcc_be("GPSL"),        //!< GPS Lock (0: none, 2: 2D lock, 3: 3D lock)

    GPMF_TAG_GPSF = fourcc_be("GPSF"),        //!< GPS Fix / Status of lock
    GPMF_TAG_GPSU = fourcc_be("GPSU"),        //!< GPS Time & Date / UTC Time as an ASCII string e.g. "160602192211.620"
    GPMF_TAG_GPSP = fourcc_be("GPSP"),        //!< GPS Precision / DOP
    GPMF_TAG_GPS5 = fourcc_be("GPS5"),        //!< Latitude, Longitude, Altitude, 2D Speed, 3D Speed

    GPMF_TAG_GPRI = fourcc_be("GPRI"),        //!< GPS field from Karma, undocumented
    GPMF_TAG_GPLI = fourcc_be("GPLI"),        //!< GPS field from Karma, undocumented

    // Camera data
    GPMF_TAG_CAME = fourcc_be("CAME"),        //!< Camera GUID?

} GpmfTag_e;

/* ************************************************************************** */

/*!
 * \brief GPMF metadadata types
 *
 * From https://github.com/gopro/gpmf-parser.
 */
typedef enum
{
    GPMF_TYPE_NESTED                =  0,   //!< Used to nest more GPMF formatted metadata
    GPMF_TYPE_HIDDEN                = 'h',  //!< Internal data not displayed
    GPMF_TYPE_COMPLEX               = '?',  //!< Complex data structures, base size in bytes. Data is either opaque, or the stream has a TYPE structure field for the sample.

    GPMF_TYPE_FOURCC                = 'F',  //!< 32-bit four character code
    GPMF_TYPE_GUID                  = 'G',  //!< 128-bit ID (like UUID)
    GPMF_TYPE_UTC_DATE_TIME         = 'U',  //!< Date + UTC Time format yymmddhhmmss.sss - 16 bytes ASCII (years 20xx covered)

    GPMF_TYPE_STRING_ASCII          = 'c',  //!< Single byte 'c' style character string
    GPMF_TYPE_STRING_UTF8           = 'u',  //!< UTF-8 formatted text string. As the character storage size varies, the size is in bytes, not UTF characters.

    GPMF_TYPE_SIGNED_BYTE           = 'b',  //!<  8-bit signed integer
    GPMF_TYPE_UNSIGNED_BYTE         = 'B',  //!<  8-bit unsigned integer
    GPMF_TYPE_SIGNED_SHORT          = 's',  //!< 16-bit signed integer
    GPMF_TYPE_UNSIGNED_SHORT        = 'S',  //!< 16-bit unsigned integer
    GPMF_TYPE_SIGNED_LONG           = 'l',  //!< 32-bit signed integer
    GPMF_TYPE_UNSIGNED_LONG         = 'L',  //!< 32-bit unsigned integer
    GPMF_TYPE_SIGNED_64BIT          = 'j',  //!< 64-bit signed integer
    GPMF_TYPE_UNSIGNED_64BIT        = 'J',  //!< 64-bit unsigned integer

    GPMF_TYPE_FLOAT                 = 'f',  //!< 32-bit single precision float (IEEE 754)
    GPMF_TYPE_DOUBLE                = 'd',  //!< 64-bit double precision float (IEEE 754)
    GPMF_TYPE_Q15_16_FIXED_POINT    = 'q',  //!< Q number Q15.16 - 16-bit signed integer (A) with 16-bit fixed point (B) for A.B value (range -32768.0 to 32767.99998).
    GPMF_TYPE_Q31_32_FIXED_POINT    = 'Q',  //!< Q number Q31.32 - 32-bit signed integer (A) with 32-bit fixed point (B) for A.B value.

} GpmfType_e;

/* ************************************************************************** */

/*!
 * \brief Get the size of a data field according to its GPMF metadadata 'type'.
 * \param type: A GpmfType_e value.
 * \return The size of a data field (in bytes) or -1 if type unknown/unapplicable.
 */
int getGpmfTypeSize(const GpmfType_e type);

/* ************************************************************************** */
#endif // GPMF_TAGS_H
