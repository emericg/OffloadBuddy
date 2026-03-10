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
 * \file      caf.cpp
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2018
 */

// minivideo headers
#include "caf.h"
#include "caf_struct.h"
#include "../../bitstream.h"
#include "../../bitstream_utils.h"
#include "../../minivideo_typedef.h"
#include "../../minivideo_fourcc.h"
#include "../../minitraces.h"

#include "../../io/bitstream2.h"

// C standard libraries
#include <cstdio>
#include <cstdlib>

/* ************************************************************************** */

bool jumpy_caf(Bitstream *b, CafChunk *current)
{
    bool status = false;

    // Check if we need a jump
    int64_t current_pos = b->get_offset_bytes();
    if (current_pos != current->offset_end)
    {
        int64_t file_size = b->get_size_bytes();
        int64_t offset_end = current->offset_end;

        // Check offset_end
        {
            // Validate offset_end against file's (file win)
            if (offset_end > file_size)
                offset_end = file_size;
        }

        // If the offset_end is past the last byte of the file, we do not need to jump
        // The parser will pick that fact and finish up...
        if (offset_end >= file_size)
        {
            TRACE_WARNING(CAF, "JUMPY > going EOF (%lli)", file_size);
            //b->move_offset_bytes(file_size);
            b->move_offset_bits(file_size*8);
            return true;
        }

        //TRACE_WARNING(CAF, "JUMPY > going from %lli to %lli", current_pos, offset_end);

        //b->move_offset_bytes(offset_end);
        b->move_offset_bits(offset_end*8);
    }

    return status;
}

/* ************************************************************************** */

CafParser::CafParser(DataSource *data, Media2 *media)
{
    // Init bitstream to parse container infos
    int s = 0;
    b.loadFile(data);
}

CafParser::~CafParser()
{
    //
}

/* ************************************************************************** */

//int caf_fileParse(DataSource *data, Media *media)
bool CafParser::parse()
{
    TRACE_INFO(CAF, BLD_GREEN "caf_fileParse()" CLR_RESET);
    int retcode = SUCCESS;
    int s = 0;

    {
        TRACE_INFO(CAF, "------------------------------------------------");

        // Init a CAF structure
        // A convenient way to stop the parser
        //caf.run = true;

        // xmlMapper

        char fcc[5];

        // Parse CAF header
        //CafFileHeader h;
        h.read(b);
        h.print();

        // Loop on 1st level list
        while (/*caf.run == true &&*/
               retcode == SUCCESS &&
               b.more_bitstream_data())
        {
            TRACE_INFO(CAF, "------------------------------------------------");

            // Read CAF header
            CafChunk c;
            c.parseHeader(b);
            c.printHeader();
            //c.write();

            if (c.m_ChunkType == fourcc_be("desc"))
            {
                //CAFAudioFormat af;

                char buf[8];
                for (int i = 7; i >= 0; i--)
                    buf[i] = b.read_bits(8, s);
                af.mSampleRate = *((double *)buf);

                af.mFormatID = b.read_bits(32, s);
                af.mFormatFlags = b.read_bits(32, s);
                af.mBytesPerPacket = b.read_bits(32, s);
                af.mFramesPerPacket = b.read_bits(32, s);
                af.mChannelsPerFrame = b.read_bits(32, s);
                af.mBitsPerChannel = b.read_bits(32, s);

                TRACE_ERROR(CAF, "mSampleRate: %f", af.mSampleRate);
                TRACE_ERROR(CAF, "mFormatID: '%s'", getFccString_le(af.mFormatID, fcc));
                TRACE_ERROR(CAF, "mFormatFlags: 0x%X", af.mFormatFlags);
                TRACE_ERROR(CAF, "mBytesPerPacket: %lli", af.mBytesPerPacket);
                TRACE_ERROR(CAF, "mFramesPerPacket: %lli", af.mFramesPerPacket);
                TRACE_ERROR(CAF, "mChannelsPerFrame: %lli", af.mChannelsPerFrame);
                TRACE_ERROR(CAF, "mBitsPerChannel: %lli", af.mBitsPerChannel);
            }
            else if (c.m_ChunkType == fourcc_be("free"))
            {
                //
                b.skip_bits(c.m_ChunkSize*8, s);
            }
            else if (c.m_ChunkType == fourcc_be("data"))
            {
                //
                b.skip_bits(c.m_ChunkSize*8, s);
            }
            else if (c.m_ChunkType == fourcc_be("strg"))
            {
                // Strings Chunk
                b.skip_bits(c.m_ChunkSize*8, s);
            }
            else if (c.m_ChunkType == fourcc_be("kuki"))
            {
                // Magic Cookie Chunk
                b.skip_bits(c.m_ChunkSize*8, s);
            }
            else if (c.m_ChunkType == fourcc_be("pakt"))
            {
                // Packet Table Chunk

                // Packet Table Description
                //CAFPacketTableHeader pth;
                pth.mNumberPackets = b.read_bits_64(64, s);
                pth.mNumberValidFrames = b.read_bits_64(64, s);
                pth.mPrimingFrames = b.read_bits(32, s);
                pth.mRemainderFrames = b.read_bits(32, s);

                TRACE_ERROR(CAF, "mNumberPackets: %lli", pth.mNumberPackets);
                TRACE_ERROR(CAF, "mNumberValidFrames: %lli", pth.mNumberValidFrames);
                TRACE_ERROR(CAF, "mPrimingFrames: %i", pth.mPrimingFrames);
                TRACE_ERROR(CAF, "mRemainderFrames: %i", pth.mRemainderFrames);

                if (pth.mNumberPackets == 0)
                {
                    // constant packet size:
                    // no Packet Table Data
                }
                else
                {
                    // variable packet sizes:
                    // Packet Table Data

                    // 1/ Variable bit rate, constant number of frames per packet
                    // if (mBytesPerPacket == 0 && mFramesPerPacket != 0)
                    // (packet size in bytes FIELD) * mNumberPackets

                    // 2/ Constant bit rate, variable number of frames per packet
                    // if (mBytesPerPacket != 0 && mFramesPerPacket == 0)
                    // (number of frames per packet FIELD) * mNumberPackets

                    // 3/ Variable bit rate, variable number of frames per packet
                    // if (mBytesPerPacket == 0 && mFramesPerPacket == 0)
                    // (packet size in bytes FIELD + number of frames per packet FIELD)  * mNumberPackets
                }
            }
            else if (c.m_ChunkType == fourcc_be("chan"))
            {
                // Channel Layout Chunk
                //CAFChannelLayout cl;
                cl.mChannelLayoutTag = b.read_bits(32, s);
                cl.mChannelBitmap = b.read_bits(32, s);
                cl.mNumberChannelDescriptions = b.read_bits(32, s);

                for (unsigned i = 0; i < cl.mNumberChannelDescriptions; i++)
                {
                    CAFChannelDescription cd;
                    cd.mChannelLabel = b.read_bits(32, s);
                    cd.mChannelFlags = b.read_bits(32, s);
                    cd.mCoordinates[0] = b.read_bits(32, s); // float !!!
                    cd.mCoordinates[1] = b.read_bits(32, s); // float !!!
                    cd.mCoordinates[2] = b.read_bits(32, s); // float !!!

                    cl.mChannelDescriptions.push_back(cd);
                }
            }
            else if (c.m_ChunkType == fourcc_be("umid"))
            {
                // Unique Material Identifier Chunk

                //UInt8 mBytes[64];
            }
            else if (c.m_ChunkType == fourcc_be("uuid"))
            {
                //
            }
            else if (c.m_ChunkType == fourcc_be("midi"))
            {
                //
            }
            else if (c.m_ChunkType == fourcc_be("info"))
            {
                //
            }
            else if (c.m_ChunkType == fourcc_be("ovvw"))
            {
                // Overview Chunk
            }
            else if (c.m_ChunkType == fourcc_be("inst"))
            {
                // Instrument Chunk
            }
            else if (c.m_ChunkType == fourcc_be("peak"))
            {
                // Peak Chunk
            }
            else if (c.m_ChunkType == fourcc_be("edct"))
            {
                // Edit Comments Chunk
            }
            else
            {
                TRACE_ERROR(CAF, "unknown mChunkType: '%s'", getFccString_le(c.m_ChunkType, fcc));
                TRACE_ERROR(CAF, "pos: '%lli'", b.get_offset_bytes());
                b.skip_bits(c.m_ChunkSize*8, s);

                retcode = FAILURE;
            }

            jumpy_caf(&b, &c);
            //retcode = jumpy_caf(bitstr, &RIFF_header, chunk_header.offset_end);
        }
    }

    return retcode;
}

bool CafParser::index()
{
    bool status = false;

    //

    return status;
}

/* ************************************************************************** */
