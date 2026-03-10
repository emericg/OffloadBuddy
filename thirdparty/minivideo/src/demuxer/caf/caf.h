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
 * \file      caf.h
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2018
 */

#ifndef PARSER_CAF_H
#define PARSER_CAF_H

// minivideo headers
#include "../../io/datasource.h"
#include "../../minivideo_mediafile.h"
#include "caf_struct.h"

/* ************************************************************************** */

/*!
 * \brief Parse CAF files.
 * \param *media[in,out]: A pointer to a Media structure.
 * \param video_codec: docme.
 * \return 1 if succeed, 0 otherwise.
 */
/* ************************************************************************** */

/*!
 * \brief CAF file parser.
 *
 * https://developer.apple.com/library/content/documentation/MusicAudio/Reference/CAFSpec/CAF_overview/CAF_overview.html#//apple_ref/doc/uid/TP40001862-CH209-TPXREF101
 * https://developer.apple.com/library/content/documentation/MusicAudio/Reference/CAFSpec/CAF_spec/CAF_spec.html#//apple_ref/doc/uid/TP40001862-CH210-SW1
 */
class CafParser: public Parser
{
    Bitstream b;

    //
    CafFileHeader h;

    CAFAudioFormat af;
    //Audio Data
    CAFPacketTableHeader pth;

    CAFChannelLayout cl;
    //Magic Cookie
    //Strings Chunk

public:
    CafParser(DataSource *data, Media2 *media);
    ~CafParser();

    bool parse();
    bool index();
};

/* ************************************************************************** */
#endif // PARSER_CAF_H
