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
 * \file      caf_struct.h
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2018
 */

#ifndef PARSER_CAF_STRUCT_H
#define PARSER_CAF_STRUCT_H

// minivideo headers
#include "../../io/bitstream2.h"
#include "../../minivideo_fourcc.h"
#include "../../minitraces.h"
#include "../ContainerParser.h"

#include <vector>

/* ************************************************************************** */

enum {
    kCAFChannelBit_Left = (1<<0),
    kCAFChannelBit_Right = (1<<1),
    kCAFChannelBit_Center = (1<<2),
    kCAFChannelBit_LFEScreen = (1<<3),
    kCAFChannelBit_LeftSurround = (1<<4), // WAVE: "Back Left"
    kCAFChannelBit_RightSurround = (1<<5), // WAVE: "Back Right"
    kCAFChannelBit_LeftCenter = (1<<6),
    kCAFChannelBit_RightCenter = (1<<7),
    kCAFChannelBit_CenterSurround = (1<<8), // WAVE: "Back Center"
    kCAFChannelBit_LeftSurroundDirect = (1<<9), // WAVE: "Side Left"
    kCAFChannelBit_RightSurroundDirect = (1<<10), // WAVE: "Side Right"
    kCAFChannelBit_TopCenterSurround = (1<<11),
    kCAFChannelBit_VerticalHeightLeft = (1<<12),
    // WAVE: "Top Front Left"
    kCAFChannelBit_VerticalHeightCenter = (1<<13), // WAVE: "Top Front Center"
    kCAFChannelBit_VerticalHeightRight = (1<<14), // WAVE: "Top Front Right"
    kCAFChannelBit_TopBackLeft = (1<<15),
    kCAFChannelBit_TopBackCenter = (1<<16),
    kCAFChannelBit_TopBackRight = (1<<17)
};
enum {
    kAudioFormatLinearPCM      = fourcc_be("lpcm"),
    kAudioFormatAppleIMA4      = fourcc_be("ima4"),
    kAudioFormatMPEG4AAC       = fourcc_be("aac "),
    kAudioFormatMACE3          = fourcc_be("MAC3"),
    kAudioFormatMACE6          = fourcc_be("MAC6"),
    kAudioFormatULaw           = fourcc_be("ulaw"),
    kAudioFormatALaw           = fourcc_be("alaw"),
    kAudioFormatMPEGLayer1     = fourcc_be(".mp1"),
    kAudioFormatMPEGLayer2     = fourcc_be(".mp2"),
    kAudioFormatMPEGLayer3     = fourcc_be(".mp3"),
    kAudioFormatAppleLossless  = fourcc_be("alac")
};
enum {
    kCAF_SMPTE_TimeTypeNone = 0,
    kCAF_SMPTE_TimeType24 = 1,
    kCAF_SMPTE_TimeType25 = 2,
    kCAF_SMPTE_TimeType30Drop = 3,
    kCAF_SMPTE_TimeType30 = 4,
    kCAF_SMPTE_TimeType2997 = 5,
    kCAF_SMPTE_TimeType2997Drop = 6,
    kCAF_SMPTE_TimeType60 = 7,
    kCAF_SMPTE_TimeType5994 = 8
};
enum {
    kCAFRegionFlag_LoopEnable = 1,
    kCAFRegionFlag_PlayForward = 2,
    kCAFRegionFlag_PlayBackward = 4
};

/* ************************************************************************** */
/* ************************************************************************** */

//! CAF file header
class CafFileHeader
{
public:
    uint32_t m_FileType;
    uint16_t m_FileVersion;
    uint16_t m_FileFlags;

    int read(Bitstream &b)
    {
        int s = 0;
        m_FileType = b.read_bits(32, s);
        m_FileVersion = b.read_bits(16, s);
        m_FileFlags = b.read_bits(16, s);

        return s;
    }

    void print()
    {
        char fcc[5];
        TRACE_1(CAF, "mFileType: '%s'", getFccString_le(m_FileType, fcc));
        TRACE_1(CAF, "mFileVersion: %u", m_FileVersion);
        TRACE_1(CAF, "mFileFlags: 0x%X", m_FileFlags);
    }
};

//! CAF chunk header
class CafChunk
{
public:
    int64_t offset_start;   //!< Absolute position of the first byte of this chunk
    int64_t offset_end;     //!< Absolute position of the last byte of this chunk

    int error_code = 0;     //!< 0 if no error found during parsing

    // Chunk parameters
    uint32_t m_ChunkType;   //!< A FourCC identifying the chunk type
    int64_t m_ChunkSize;    //!< Chunk size in bytes, not including the header

    int parseHeader(Bitstream &b)
    {
        int s = 0;

        // Set box offset
        offset_start = b.get_offset_bytes();

        // Read box type
        m_ChunkType = b.read_bits(32, s);

        // Read box size
        m_ChunkSize = b.read_bits_64(64, s);

        // Set end offset
        offset_end = offset_start + 12 + m_ChunkSize;
        // TODO wrong end

        return s;
    }

    void printHeader()
    {
        char fcc[5];
        TRACE_1(CAF, "mChunkType: '%s'", getFccString_le(m_ChunkType, fcc));
        TRACE_1(CAF, "mChunkSize: %lli", m_ChunkSize);
    }
};

/* ************************************************************************** */
/* ************************************************************************** */

/*!
 * \brief Jumpy protect your parsing - CAF edition.
 * \param bitstr: Our bitstream reader.
 * \param parent: The box containing the current element we're in.
 * \param current: The current element we're in.
 * \return False if the jump could not be done.
 *
 * 'Jumpy' is in charge of checking your position into the stream after your
 * parser finish parsing a box / list / chunk / element, never leaving you
 * stranded  in the middle of nowhere with no easy way to get back on track.
 * It will check available information to known if the current element has been
 * fully parsed, and if not perform a jump (or even a rewind) to the next known
 * element.
 */
bool jumpy_caf(Bitstream *b, CafChunk *current);

/* ************************************************************************** */
/* ************************************************************************** */

// Audio Description Chunk
struct CAFAudioFormat {
    double mSampleRate;
    uint32_t mFormatID;
    uint32_t mFormatFlags;
    uint32_t mBytesPerPacket;
    uint32_t mFramesPerPacket;
    uint32_t mChannelsPerFrame;
    uint32_t mBitsPerChannel;
};

struct CAFPacketTableHeader {
    int64_t mNumberPackets;
    int64_t mNumberValidFrames;
    int32_t mPrimingFrames;
    int32_t mRemainderFrames;
};

struct CAFChannelDescription {
    uint32_t mChannelLabel;
    uint32_t mChannelFlags;
    float mCoordinates[3];
};
struct CAFChannelLayout {
    uint32_t mChannelLayoutTag;
    uint32_t mChannelBitmap;
    uint32_t mNumberChannelDescriptions;
    std::vector <CAFChannelDescription> mChannelDescriptions;
};

struct CAF_SMPTE_Time {
    int8_t mHours;
    int8_t mMinutes;
    int8_t mSeconds;
    int8_t mFrames;
    uint32_t mSubFrameSampleOffset;
};
struct CAFMarker {
    uint32_t mType;
    double mFramePosition;
    uint32_t mMarkerID;
    CAF_SMPTE_Time mSMPTETime;
    uint32_t mChannel;
};
struct CAFMarkerChunk {
    uint32_t mSMPTE_TimeType;
    uint32_t mNumberMarkers;
    std::vector <CAFMarker> mMarkers;
};

struct CAFStringID {
    uint32_t mStringID;
    int64_t mStringStartByteOffset;
};
struct CAFStrings {
    uint32_t mNumEntries;
    std::vector <CAFStringID> mStringsIDs;
    std::vector <uint8_t> mStrings;
};
struct CAFCommentStringsChunk {
    uint32_t mNumEntries;
    std::vector <CAFStringID> mStrings;
};
struct CAFStringsChunk {
    uint32_t mNumEntries;
    std::vector <CAFStringID> mStrings;
};

struct CAFRegion {
    uint32_t mRegionID;
    uint32_t mFlags;
    uint32_t mNumberMarkers;
    std::vector <CAFMarker> mMarkers;
};
struct CAFRegionChunk {
    uint32_t mSMPTE_TimeType;
    uint32_t mNumberRegions;
    std::vector <CAFRegion> mRegions;
};

struct CAFInstrumentChunk {
    float mBaseNote;
    uint8_t mMIDILowNote;
    uint8_t mMIDIHighNote;
    uint8_t mMIDILowVelocity;
    uint8_t mMIDIHighVelocity;
    float mdBGain;
    uint32_t mStartRegionID;
    uint32_t mSustainRegionID;
    uint32_t mReleaseRegionID;
    uint32_t mInstrumentID;
};

struct CAFOverviewSample {
    int16_t mMinValue;
    int16_t mMaxValue;
};
struct CAFOverview {
    uint32_t mEditCount;
    uint32_t mNumFramesPerOVWSample;
    std::vector <CAFOverviewSample> mData;
};

struct CAFPositionPeak {
    float mValue;
    uint64_t mFrameNumber;
};
struct CAFPeakChunk {
    uint32_t mEditCount;
    std::vector <CAFPositionPeak> mPeaks;
};

struct editCommment {
    std::vector <uint8_t> mKey;
    std::vector <uint8_t> mValue;
};
struct CAFInformation {
    std::vector <uint8_t> mKey;
    std::vector <uint8_t> mValue;
};
struct CAFUMIDChunk {
    uint8_t mBytes[64];
};
/*
struct CAF_UUID_ChunkHeader {
    CAFChunkHeader mHeader;
    uint8_t mUUID[16];
};
*/
/* ************************************************************************** */
#endif // PARSER_CAF_STRUCT_H
