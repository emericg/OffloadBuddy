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

// Library public header
#include "minivideo2.h"

// Library privates headers
#include "io/datasource.h"
#include "io/datasource_file.h"
//#include "io/datasource_curl.h"
#include "thirdparty/portable_endian.h"
#include "minitraces.h"

// Demuxers
#include "demuxer/avi/avi.h"
#include "demuxer/asf/asf.h"
//#include "demuxer/caf/caf.h"
#include "demuxer/mkv/mkv.h"
#include "demuxer/mp4/mp4.h"
#include "demuxer/mp3/mp3.h"
#include "demuxer/wave/wave.h"
#include "demuxer/mpeg/ps/ps.h"
#include "demuxer/esparser/esparser.h"
#include "demuxer/idr_filter.h"

// Decoder
#include "decoder/h264/h264.h"

// Muxer
#include "muxer/muxer.h"

// C standard libraries
#include <cstdio>
#include <cstdlib>
#include <cstring>

/* ************************************************************************** */

Media2::Media2()
{
    //
}

Media2::~Media2()
{
    delete mediaUri;
    delete mediaDatas;
    delete mediaParser;

    // delete chapters
    for (auto c: tracks_video)
        delete c;

    // delete tracks
    for (auto t: tracks_video)
        delete t;
    for (auto t: tracks_audio)
        delete t;
    for (auto t: tracks_subt)
        delete t;
    for (auto t: tracks_others)
        delete t;
}

/* ************************************************************************** */

bool Media2::open(std::string &str)
{
    bool status = false;

    if (str.empty() == false)
    {
        if (mediaUri == nullptr && mediaDatas == nullptr && mediaParser == nullptr)
        {
            mediaUri = new MediaUrl(str);
            if (mediaUri)
            {
                mediaUri->print();

                if (mediaUri->isSupported())
                {
                    if (mediaUri->getProtocol() == "file")
                        mediaDatas = new DataSource_file();
                }
                else
                {
                    TRACE_ERROR(MAIN, "* Unsupported media protocol: '%s'...",
                                mediaUri->getProtocol().c_str());
                }

                if (mediaDatas)
                {
                    if (mediaDatas->open(*mediaUri))
                    {
                        mediaDatas->print();

                        ////////////////////////////////////////////////////////////

                        // Fallback: detect container format using file extension
                        container_ext = getContainerUsingExtension(mediaUri->getExtension());
                        if (container_ext == CONTAINER_UNKNOWN)
                        {
                            TRACE_ERROR(MAIN, "* Unknown container format: file extension detection failed...");
                        }

                        // Detect container format using start codes
                        uint8_t file_header[16];
                        if (mediaDatas->read(file_header, 0, 16))
                        {
                            container_sc = getContainerUsingStartcodes(file_header);
                            if (container_sc == CONTAINER_UNKNOWN)
                            {
                                TRACE_WARNING(MAIN, "* Unknown container format: startcodes detection failed...");
                            }
                        }

                        ////////////////////////////////////////////////////////////

//                      // Enable the container mapping
//                      if (extract_metadata == true)
//                      {
//                          input_media->container_mapper = true;
//                      }

                        ////////////////////////////////////////////////////////////

                        // Start container parsing
                        switch (getContainer())
                        {
                        case CONTAINER_CAF:
                        {
                            //caf_fileParse(this->mediaDatas, this);
                            mediaParser = new CafParser(this->mediaDatas, this);
                        }
                        break;

                        default:
                            TRACE_ERROR(MAIN, "Unable to parse given container format '%s': no parser available!",
                                        getContainerString(getContainer(), 0));
                            break;
                        }

                        if (mediaParser)
                            mediaParser->parse();

                        ////////////////////////////////////////////////////////////

//                      // Compute some additional metadata
//                      if (extract_metadata == true)
//                      {
//                          computeCodecs(input_media);
//                          computeAspectRatios(input_media);
//                          computeSamplesDatas(input_media);

//                          computeMediaMemory(input_media);
//                      }
                    }
                    else
                    {
                        TRACE_ERROR(MAIN, "* DataSource cannot be opened...");
                    }
                }
                else
                {
                    TRACE_ERROR(MAIN, "* DataSource is invalid...");
                }
            }
            else
            {
                TRACE_ERROR(MAIN, "* MediaUri is invalid...");
            }
        }
        else
        {
            TRACE_ERROR(MAIN, "* Media seems already opened...");
        }
    }
    else
    {
        TRACE_ERROR(MAIN, "* Media cannot be opened with empty URI...");
    }

    return  status;
}

bool Media2::index()
{
    if (mediaParser)
        return mediaParser->index();

    return false;
}

bool Media2::extract_metadata()
{
    return false;
}

/* ************************************************************************** */
