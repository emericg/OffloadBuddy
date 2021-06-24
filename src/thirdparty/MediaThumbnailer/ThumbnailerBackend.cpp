/*!
 * COPYRIGHT (C) 2021 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2021
 */

/* ************************************************************************** */

#include "ThumbnailerBackend_gstreamer.h"
#include "ThumbnailerBackend_ffmpeg.h"
#include "ThumbnailerBackend_minivideo.h"

/* ************************************************************************** */

ThumbnailerBackend::ThumbnailerBackend()
{
#if defined(ENABLE_FFMPEG)
    m_backend = new ThumbnailerBackend_ffmpeg();
#elif defined(ENABLE_MINIVIDEO)
    m_backend = new ThumbnailerBackend_minivideo();
#endif
}

/* ************************************************************************** */
