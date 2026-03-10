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
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2014
 */

#ifndef MINIVIDEO_MEDIASTREAM_H
#define MINIVIDEO_MEDIASTREAM_H
/* ************************************************************************** */

// minivideo headers
#include "minivideo_codecs.h"
#include "minivideo_codecs_private_struct.h"

// C standard libraries
#include <cstdint>

// C++ standard libraries
#include <string>
#include <vector>

/* ************************************************************************** */

/*!
 * \struct MediaStream_t
 * \brief Infos on stream payload data & metadata extracted from a container file.
 *
 * \todo split into 'per container' metadata structures
 * \todo split into 'per codec' metadata structures
 *
 * This structure basically represent an audio or a video track. It contains
 * general information about the track type and the positions of all the samples
 * of the track inside the bitstream.
 */
typedef struct MediaStream_t
{
    StreamType_e stream_type;               //!< Is this an audio / video / subtitles stream?
    Codecs_e stream_codec;                  //!< Codec used by this stream
    CodecProfiles_e stream_codec_profile;   //!< Codec profile (if applicable)

    uint32_t stream_fcc;                    //!< FourCC
    char *stream_codec_name;                //!< Encoder used to generate the stream's data

    unsigned int stream_duration_ms;        //!< Stream duration (rounded in ms)
    int stream_delay;                       //!< Stream initial delay (in µs)

    // Generic metadata
    char *stream_encoder;                   //!< Encoder used to generate the stream's data
    unsigned int creation_time;             //!< Stream creation time (in ms)
    unsigned int modification_time;         //!< Stream modification time (in ms)
    uint8_t time_reference[4];              //!< SMPTE timecode reference (hh:mm:ss-fff)

    // Track metadata (if the container supports them)
    unsigned int track_id;                  //!< Id of the track (as set by the container)
    bool track_default;                     //!<
    bool track_forced;                      //!<
    char *track_title;                      //!< Title
    char *track_languagecode;               //!< Language code (ISO 639-1 or ISO 639-2 format) (C string)

    // Bitrate infos
    BitrateMode_e bitrate_mode;             //!< Bitrate mode
    unsigned int bitrate_avg;               //!< Average bitrate (in bit/s)
    unsigned int bitrate_min;               //!< Minimum bitrate (in bit/s)
    unsigned int bitrate_max;               //!< Maximum bitrate (in bit/s)

    // Video metadata
    unsigned int width;                     //!< Horizontal size (in pixels)
    unsigned int height;                    //!< Vertical size (in pixels)
    unsigned int width_encoded;             //!< Encoded buffer width, in pixels, ignoring crop/padding/orientation
    unsigned int height_encoded;            //!< Encoded buffer height, in pixels, ignoring crop/padding/orientation
    unsigned int width_display;             //!< Display width, in pixels, including crop/padding/orientation
    unsigned int height_display;            //!< Display height, in pixels, including crop/padding/orientation

    double video_aspect_ratio;              //!< Video / Storage aspect ratio (from video geometry, ignore crop/padding/orientation)
        unsigned int video_aspect_ratio_h;
        unsigned int video_aspect_ratio_v;
    double display_aspect_ratio;            //!< Display aspect ratio (if set directly by the container, otherwise computed)
        unsigned int display_aspect_ratio_h;
        unsigned int display_aspect_ratio_v;
    double pixel_aspect_ratio;              //!< Pixel aspect ratio (if set directly by the container, otherwise computed)
        unsigned int pixel_aspect_ratio_h;
        unsigned int pixel_aspect_ratio_v;

    unsigned int crop_top;
    unsigned int crop_left;
    unsigned int crop_right;
    unsigned int crop_bottom;

    double framerate;                       //!< Framerate (in frame/s)
        double framerate_num;               //!< Framerate numerator
        double framerate_base;              //!< Framerate denominator
    double frame_duration;                  //!< Frame duration (in ms)
    FramerateMode_e framerate_mode;         //!< Framerate mode

    unsigned int color_planes;              //!< Number of encoded planes (ex: 1 for monochrome, 3 for YUV or 4 for RGBA)
    unsigned int color_depth;               //!< Color resolution per channel
    unsigned int color_range;               //!< Colors are in restricted or full range
    unsigned int chroma_subsampling;        //!< Chroma sub-sampling
    unsigned int chroma_location;           //!< Chroma location
    unsigned int color_space;               //!< Internal color encoding
    unsigned int color_primaries;           //!< Color primaries
    unsigned int color_transfer;            //!< Color transfer function
    unsigned int color_matrix;              //!< Color matrix

    HdrMode_e hdr_mode;                     //!< HDR mode
    ScanType_e scan_mode;                   //!< Scan type
    StereoMode_e stereo_mode;               //!< Stereo mode
    Rotation_e video_rotation;              //!< Rotation
    Projection_e video_projection;          //!< Projection

    double video_level;                     //!< Codec video profile/level set by the encoder
    unsigned int max_ref_frames;            //!< Maximum reference frames

    bool h264_feature_cabac;                //!< CABAC compression (for H.264 only)
    bool h264_feature_8x8_blocks;           //!< 8x8 blocks (for H.264 only)
    bool h264_feature_b_frames;             //!< B frames (for H.264 only)
    bool h265_feature_parallelization;      //!< TODO (for H.265 only)

    // Codec specific parameters (video)
    codecprivate_avcC_t *avcC = nullptr;
    codecprivate_hvcC_t *hvcC = nullptr;
    codecprivate_vvcC_t *vvcC = nullptr;
    codecprivate_vpcC_t *vpcC = nullptr;
    codecprivate_av1C_t *av1C = nullptr;

    // Codec specific parameters (other)
    codecprivate_dvcC_t *dvcC = nullptr;
    codecprivate_mvcC_t *mvcC = nullptr;

    // Audio metadata
    unsigned int channel_count;             //!< Number of audio channels
    ChannelMode_e channel_mode;             //!< Channels configuration
    unsigned int sampling_rate;             //!< Sampling rate (in Hz)
    unsigned int bit_per_sample;            //!< Bit per sample (in bits)
    unsigned int sample_per_frames;         //!< Audio samples per audio frame
    double sample_duration;                 //!< Audio sample duration (in µs)

    // Subtitles specific metadata
    char *subtitles_name;                   //!< Subtitles name?
    unsigned int subtitles_encoding;        //!< Text encoding

    // Datas infos
    uint64_t stream_size;                   //!< Size (in bytes) of the raw data of this stream
    bool stream_intracoded;                 //!< True if the stream is intra coded
    bool stream_packetized;                 //!< True if a container sample isn't a complete audio/video/... frame

    // "Parameter sets" arrays
    uint32_t parameter_count;               //!< The total number of parameter set in this stream
    uint32_t *parameter_type;               //!< Parameter set type
    uint32_t *parameter_size;               //!< Size (in bytes)
    int64_t *parameter_offset;              //!< Offset (in bytes)

    // Samples arrays
    uint32_t sample_count;                  //!< The total number of samples in this stream
    uint32_t *sample_type;                  //!< Sample type
    uint32_t *sample_size;                  //!< Size (in bytes)
    int64_t *sample_offset;                 //!< Offset (in bytes)
    int64_t *sample_pts;                    //!< Presentation timestamp (in µs)
    int64_t *sample_dts;                    //!< Decoding timestamp (in µs)

    // FIXME (frame stats)
    uint32_t frame_count;                   //!< Number of audio/video frames
    uint32_t frame_count_idr;               //!< Number of audio/video IDR frames

} MediaStream_t;

typedef struct MediaSample_t
{
    uint32_t type;          //!< Sample type
    uint32_t size;          //!< Size (in bytes)
    int64_t offset;         //!< Offset (in bytes)
    int64_t pts;            //!< Presentation timestamp (in µs)
    int64_t dts;            //!< Decoding timestamp (in µs)

    uint8_t *data = nullptr;

} MediaSample_t;

typedef struct Chapter_t
{
    char *name;
    uint64_t pts;

} Chapter_t;

/* ************************************************************************** */

class Parameter
{
    uint32_t type;          //!< Parameter set type
    uint32_t size;          //!< Size (in bytes)
    int64_t offset;         //!< Offset (in bytes)
};

class Sample
{
    uint32_t type;          //!< Sample type
    uint32_t size;          //!< Size (in bytes)
    int64_t offset;         //!< Offset (in bytes)
    int64_t pts;            //!< Presentation timestamp (in µs)
    int64_t dts;            //!< Decoding timestamp (in µs)

    uint8_t *data = nullptr;
};

class SampleIndex
{
    uint32_t type;          //!< Sample type
    uint32_t size;          //!< Size (in bytes)
    int64_t offset;         //!< Offset (in bytes)
    int64_t pts;            //!< Presentation timestamp (in µs)
    int64_t dts;            //!< Decoding timestamp (in µs)
};

class Chapters
{
    std::string name;
    uint64_t pts;
};

/*!
 * \brief Infos on stream payload data & metadata extracted from a container file.
 *
 * \todo split into 'per container' metadata structures
 * \todo split into 'per codec' metadata structures
 *
 * This structure basically represent an audio or a video track. It contains
 * general information about the track type and the positions of all the
 * samples of the track inside the bitstream.
 */
class Stream
{
    //StreamType_e type;                    //!< Is this an audio / video / subtitles stream?

    Codecs_e codec;                         //!< Codec used by this stream
    CodecProfiles_e codec_profile;          //!< Codec profile (if applicable)
    uint32_t codec_fcc;                     //!< FourCC (if applicable)
    uint32_t codec_tcc;                     //!< TwoCC (if applicable)

    std::string codec_string;               //!<
    std::string codec_profile_string;       //!<

    int64_t stream_duration;                //!< Stream duration (rounded in µs)
    int64_t stream_delay;                   //!< Stream initial delay (in µs)

    // Generic metadata ////////////////////////////////////////////////////////

    std::string stream_encoder;             //!< Encoder used to generate the stream's data (if available)
    int64_t creation_time;                  //!< Stream creation time (in ms)
    int64_t modification_time;              //!< Stream modification time (in ms)

    // Track metadata (if the container supports them)
    unsigned track_id;                      //!< Id of the track (as set by the container)
    bool track_default;                     //!<
    bool track_forced;                      //!<
    std::string track_title;                //!< Title
    std::string track_languagecode;         //!< Language code (ISO 639-1 or ISO 639-2 format) (C string)

    // Bitrate infos
    BitrateMode_e bitrate_mode;             //!< Bitrate mode
    unsigned int bitrate_avg;               //!< Average bitrate (in bit/s)
    unsigned int bitrate_min;               //!< Minimum bitrate (in bit/s)
    unsigned int bitrate_max;               //!< Maximum bitrate (in bit/s)

    // Video metadata
    unsigned int width;                     //!< Horizontal size (in pixels)
    unsigned int height;                    //!< Vertical size (in pixels)
    unsigned int visible_width;             //!< Horizontal size (in pixels, without alignment)
    unsigned int visible_height;            //!< Vertical size (in pixels, without alignment)
    unsigned int max_ref_frames;            //!< Maximum reference frames
    unsigned int color_depth;               //!< Color resolution per channel
    unsigned int color_subsampling;         //!< Chroma sub-sampling
    unsigned int color_encoding;            //!< Internal color encoding
    unsigned int color_matrix;              //!< Internal color encoding
    unsigned int color_range;               //!< Colors are in restricted or full range
    Projection_e video_projection;          //!< Projection
    Rotation_e video_rotation;              //!< Rotation
    StereoMode_e stereo_mode;               //!< Stereo mode
    ScanType_e scan_mode;                   //!< Scan type

    double display_aspect_ratio;            //!< Display aspect ratio (if set directly by the container, otherwise computed)
        unsigned int display_aspect_ratio_h;
        unsigned int display_aspect_ratio_v;
    double video_aspect_ratio;              //!< Video aspect ratio (from video size)
        unsigned int video_aspect_ratio_h;
        unsigned int video_aspect_ratio_v;
    double pixel_aspect_ratio;              //!< Pixel aspect ratio (if set directly by the container)
        unsigned int pixel_aspect_ratio_h;
        unsigned int pixel_aspect_ratio_v;

    double framerate;               //!< Framerate (in frame/s)
        double framerate_num;       //!< Framerate numerator
        double framerate_base;      //!< Framerate denominator
    double frame_duration;          //!< Frame duration (in ms)
    FramerateMode_e framerate_mode; //!< Framerate mode

    // Audio metadata
    unsigned int channel_count;     //!< Number of audio channels
    ChannelMode_e channel_mode;     //!< Channels configuration
    unsigned int sampling_rate;     //!< Sampling rate (in Hz)
    unsigned int bit_per_sample;    //!< Bit per sample (in bits)
    unsigned int sample_per_frames; //!< Audio samples per audio frame

    // Subtitles metadata
    char *subtitles_name;           //!< Subtitles name?
    unsigned int subtitles_encoding;//!< Text encoding

    // Timecode Reference metadata
    uint8_t timecode_reference[4];  //!< SMPTE timecode reference (hh:mm:ss-fff)

    // Datas infos /////////////////////////////////////////////////////////////

    uint64_t stream_size;           //!< Size (in bytes) of the raw data of this stream
    bool stream_intracoded;         //!< True if the stream is intra coded
    bool stream_packetized;         //!< True if a container sample isn't a complete audio/video/... frame

    // "Parameter sets" array
    std::vector <Parameter *> parameters;

    // Samples array
    std::vector <SampleIndex *> samples;

    // FIXME (frame stats)
    uint32_t frame_count;           //!< Number of audio/video frames
    uint32_t frame_count_idr;       //!< Number of audio/video IDR frames

public:

    ////////////////////////////////////////////////////////////////////////////

    Codecs_e getCodec();
    std::string getCodecName();
    CodecProfiles_e getCodecProfile();
    uint32_t getCodecFcc();
    uint32_t getCodecTcc();

    int64_t getStreamDuration();
    int64_t getStreamDelay();

    // Generic metadata

    std::string getStreamEncoder();
    int64_t getStreamCreationTime();
    int64_t getStreamModificationTime();

    // Track metadata (if the container supports them)

    unsigned getTrackId();
    bool isTrackDefault();
    bool isTrackForced();
    std::string getTrackName();
    std::string getTrackLanguage();
    std::string getTrackLanguageCode();

    // Bitrate infos

    BitrateMode_e getBitrateMode();
    unsigned getBitrateAverage();
    unsigned getBitrateMin();
    unsigned getBitrateMax();

    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////

    bool isStreamIdr();
    bool isStreamPacketized();

    uint32_t getParameterCount();
    uint32_t getSampleCount();
    uint32_t getFrameCount();

    void getSampleInfos_sid(int sampleId);
    char *getSampleDatas_sid(int sampleId);

    void getSampleInfos_pts(int samplePts);
    char *getSampleDatas_pts(int samplePts);
};

/* ************************************************************************** */
#endif // MINIVIDEO_MEDIASTREAM_H
