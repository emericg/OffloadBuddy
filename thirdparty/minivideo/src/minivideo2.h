/*!
 * COPYRIGHT (C) 2010-2020 Emeric Grange - All Rights Reserved
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

#ifndef MINIVIDEO2_H
#define MINIVIDEO2_H
/* ************************************************************************** */

#include "minivideo_export.h"

#include "minivideo_codecs.h"
#include "minivideo_containers.h"
#include "minivideo_twocc.h"
#include "minivideo_fourcc.h"
#include "minivideo_uuid.h"

#include "minivideo_mediafile.h"
#include "minivideo_mediastream.h"

/* ************************************************************************** */

/*!
 * \brief Print information about the library (version, date of the build, ...) into standard output.
 */
minivideo_EXPORT void minivideo_print_infos(void);

/*!
 * \brief Print information about the library (enabled features, traces levels, ...) into standard output.
 */
minivideo_EXPORT void minivideo_print_features(void);

/*!
 * \brief Get information about the library (version and build date/time).
 *
 * The date and time strings are static data and do not need to be freed.
 */
minivideo_EXPORT void minivideo_get_infos(int *minivideo_major,
                                          int *minivideo_minor,
                                          int *minivideo_patch,
                                          const char **minivideo_builddate,
                                          const char **minivideo_buildtime,
                                          bool *minivideo_builddebug);

/*!
 * \brief Print endianness of the current system.
 * \return 4321 for big endian, 1234 for little endian, -1 if unable to determine endianness.
 *
 * To determine endianness, we use a character pointer to the bytes of an int,
 * and then check its first byte to see if it is 0 (meaning big endianness)
 * or 1 (meaning little endianness).
 */
minivideo_EXPORT int minivideo_endianness(void);

/* ************************************************************************** */
#endif // MINIVIDEO2_H
