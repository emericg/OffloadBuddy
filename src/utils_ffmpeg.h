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

#ifndef UTILS_FFMPEG_H
#define UTILS_FFMPEG_H
#ifdef ENABLE_FFMPEG
/* ************************************************************************** */

#ifdef __cplusplus
extern "C"
{
#include "libavformat/avformat.h"
}
#endif // __cplusplus

#include <QString>

/* ************************************************************************** */

#undef av_err2str
#ifdef _MSC_VER
//! to work around av_err2str() in C++
#define av_err2str(errnum) av_make_error_string((char*)_alloca(AV_ERROR_MAX_STRING_SIZE), AV_ERROR_MAX_STRING_SIZE, errnum)
#else
#define av_err2str(errnum) av_make_error_string((char*)__builtin_alloca(AV_ERROR_MAX_STRING_SIZE), AV_ERROR_MAX_STRING_SIZE, errnum)
#endif

/* ************************************************************************** */

/*!
 * \brief Print versions of libavformat, libavcodec and libavutil.
 */
void ffmpeg_version();

/*!
 * \brief List decoders available through linked version of ffmpeg.
 * \param hw_only: List HW decoders only.
 */
void ffmpeg_list_decoders(bool hw_only = false);

/*!
 * \brief List encoders available through linked version of ffmpeg.
 * \param hw_only: List HW encoders only.
 */
void ffmpeg_list_encoders(bool hw_only = false);

/*!
 * \brief Find keyframes around a target timecode.
 * \param stream: AVStream we want to seek.
 * \param target: Target timecode (relative to stream unit)
 * \param prev[out]: Keyframe preceding target (relative to stream unit).
 * \param next[out]: Keyframe following target (relative to stream unit).
 * \return true if both prev and next keyframes have been found.
 */
bool ffmpeg_get_keyframes(const AVStream *stream, const int64_t target,
                          int64_t &prev, int64_t &next);

/* ************************************************************************** */
#endif // ENABLE_FFMPEG
#endif // UTILS_FFMPEG_H
