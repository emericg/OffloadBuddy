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
 * \date      2017
 */

#ifndef DATASTREAM_H
#define DATASTREAM_H
/* ************************************************************************** */

class DataSource;

// C standard libraries
#include <cstdint>

//namespace minivideo
//{

/* ************************************************************************** */

enum StreamErrors {
    NO_ERROR   =   0,

    ERR_BITCOUNT    = 1,
    ERR_OFFSET,
    ERR_EOF,
    ERR_DATAS,
    ERR_FEED,
    ERR_ALLOC,
};

/* ************************************************************************** */

/*!
 * \brief DataStream class.
 *
 * max cache buffer size: x
 * max file size: x
 *
 ** Design:
 * - cached design
 *  - can use a DataSource (data will be cached)
 *  - can use a buffer (with or without ownership)
 *
 * - split byte / bit classes (for perf/convenience)
 *  - can read bits in BE byte order
 *  - can read bytes in BE/LE byte order
 *
 * - budget system?
 * - error reporting
 */
class DataStream
{
    const uint32_t m_cacheSize_default = 1024;  //!< Cache buffer default size (in bytes) // 1kB by default
    const uint32_t m_cacheSize_max = 524288;    //!< Cache buffer maximum size (in bytes) // 512kB
    const uint32_t m_bufferSize_max = 536870911;//!< Data buffer maximum size (in bytes)  // 512MB ???

    // Settings
    uint32_t m_cacheSize_saved = 0;     //!< Cache buffer size if changed by the user (in bytes)

    // DataSource (if available)
    DataSource *m_data = nullptr;
    int64_t m_dataSize = 0;            //!< DataSource size (in byte)
    int64_t m_dataOffset = 0;          //!< Current offset into the DataSource (in bytes)
    bool m_dataFreeRun = false;        //!<

protected:
    // Data buffer
    bool m_bufferOwnership = true;      //!< True if the buffer is handled by this class
    uint8_t *m_buffer = nullptr;        //!< Current data buffer
    uint32_t m_bufferSize = 0;          //!< Current data buffer size (in bytes)
    uint32_t m_bufferCapacity = 0;      //!< Current data buffer capacity / allocated size (in bytes)
    uint32_t m_bufferOffset = 0;        //!< Current offset into the buffer (in bits)
    uint32_t m_bufferDiscardedBytes = 0;//!< FIXME Current number of byte(s) removed during NAL Unit read ahead

    // utils
    bool feedBuffer(int64_t offset);
    uint32_t bitsLeftBuffer();          //!< bits left unread in the current cache buffer
    uint32_t bytesLeftBuffer();         //!< bytes left unread in the current cache buffer

    void closeDataSource();
    void closeBuffer();
    void deleteBuffer();

public:
    DataStream();
    ~DataStream();

    /*!
     * \brief Set cache size; will only be effective for the next data loading/feeding.
     * \param cacheSize: new cache size (in bytes).
     * \return true if new cache size has been validated.
     */
    bool setCacheSize(uint32_t cacheSize);

    /*!
     * \brief Load a file through a DataSource.
     * \param datasource[in]:
     * \param offset:
     * \param cacheSize:
     * \return true if the file has been successully opened and loaded.
     */
    bool loadFile(DataSource *datasource,
                  int64_t offset = 0, uint32_t cacheSize = 0);

    /*!
     * \brief Load an existing data buffer by copying its data.
     * \param buffer[in]:
     * \param bufferSize: (max size check against m_bufferSize_max)
     * \return
     */
    bool loadBuffer(uint8_t *buffer, uint32_t bufferSize);

    /*!
     * \brief Wrap an existing data buffer.
     * \param buffer[in]:
     * \param bufferSize:
     * \param bufferOwnership:
     * \return
     */
    bool wrapBuffer(uint8_t *buffer, uint32_t bufferSize, bool bufferOwnership);

    // Status //////////////////////////////////////////////////////////////////

    /*!
     * \brief Returns the full size of the datastream (file or buffer).
     * \return Size of the datastream (in bytes).
     */
    int64_t get_size_bytes();

    /*!
     * \brief Returns the current byte offset inside the datastream.
     * \return Current offset (in bytes).
     */
    int64_t get_offset_bytes();

    /*!
     * \brief Returns the current bit offset inside the datastream.
     * \return Current offset (in bits).
     */
    int64_t get_offset_bits();

    //! Prints the full size of the datastream (file or buffer).
    void print_size_bytes();

    //! Prints the current byte offset inside the datastream.
    void print_offset_bytes();

    //! Prints the current bit offset inside the datastream.
    void print_offset_bits();

    // Seeking /////////////////////////////////////////////////////////////////
    bool move_offset_bits(const int64_t n);
    bool move_offset_bytes(const int64_t n);

    // Data access /////////////////////////////////////////////////////////////



    // Data boundaries /////////////////////////////////////////////////////////
    bool bitstream_check_alignment();
    bool bitstream_force_alignment();
    bool more_bitstream_data(); // == isEOF ?
    bool isEOF(); // == more_bitstream_data ?

    // Debug operations ////////////////////////////////////////////////////////
    void bitstream_print_stats();
    void bitstream_print_buffer();

    // Endianness //////////////////////////////////////////////////////////////
    static uint16_t endian_flip_16(uint16_t src);
    static uint16_t endian_flip_cut_16(uint16_t src, const int n);
    static uint32_t endian_flip_32(uint32_t src);
    static uint32_t endian_flip_cut_32(uint32_t src, const int n);
    static uint64_t endian_flip_64(uint64_t src);
    static uint64_t endian_flip_cut_64(uint64_t src, const int n);
};

/* ************************************************************************** */
//} // namespace minivideo
#endif // DATASTREAM_H
