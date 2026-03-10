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
 * \file      ContainerParser.h
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2018
 */

#ifndef CONTAINER_PARSER_H
#define CONTAINER_PARSER_H

#include "../minivideo_containers.h"

#include <cstdint>

/* ************************************************************************** */

class Parser
{
    bool parsed = false;
    bool indexed = false;

    bool running = false;
    bool eof = false; // ?


    //bool container_mapper = false;          //!< Enables the xml container mapper
    //FILE *container_mapper_fd = nullptr;    //!< Direct access to xml map without the need of an actual file


    // Container generic metadata
    ContainerProfiles_e container_profile = PROF_UNKNOWN;   //!< Container profile (if applicable)

    uint64_t duration;                      //!< Content global duration (in ms)

    uint64_t creation_time = 0;             //!< Container creation time (Unix time, UTC) (if available)
    uint64_t modification_time = 0;         //!< Container modification time (Unix time, UTC) (if available)
    std::string creation_app;               //!< Container creation application (C string) (if available)
    std::string creation_lib;               //!< Container creation library (C string) (if available)
/*
    // Container content
    uint8_t timecode_reference[4];          //!< SMPTE timecode reference (hh:mm:ss-fff) ????
    std::vector <Chapters *> chapters;      //!< A list of chapters

    // Parsed A/V track(s) data and infos
    std::vector <Stream *> tracks_audio;     //!< A list of parsed audio tracks
    std::vector <Stream *> tracks_video;     //!< A list of parsed video tracks
    std::vector <Stream *> tracks_subt;      //!< A list of parsed subtitles tracks
    std::vector <Stream *> tracks_others;    //!< Other / Unknown tracks found in the container (metadata, timecodes, ...)
*/
    // Parsing statistics
    uint64_t parsingTime = 0;               //!< Parsing time (in milliseconds) (only available in debug mode)
    uint64_t parsingMemory = 0;             //!< Parsing memory (in bytes) (only available in debug mode)
public:
    Parser() = default;
    virtual ~Parser() = default;

    virtual bool parse() = 0;
    virtual bool index() = 0;

    ContainerProfiles_e getContainerProfile()
    {
        return container_profile;
    }
};

/* ************************************************************************** */
#endif // CONTAINER_PARSER_H
