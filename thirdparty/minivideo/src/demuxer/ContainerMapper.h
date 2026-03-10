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
 * \file      ContainerMapper.h
 * \author    Emeric Grange <emeric.grange@gmail.com>
 * \date      2018
 */

#ifndef CONTAINER_MAPPER_H
#define CONTAINER_MAPPER_H

// minivideo headers
#include "../minivideo_mediafile.h"

// C standard libraries
#include <cstdio>

/* ************************************************************************** */

/*!
 * \brief The ContainerMapper class
 */
class ContainerMapper
{
    //

public:
    /*!
     * \brief Open the xmlMapper file and write header content.
     * \param *media[in]: A pointer to a MediaFile_t structure.
     * \param **xml[in,out]: Mapping file.
     */
    bool open();

    /*!
     * \brief Finalize the xmlMapper file and write footer content.
     * \param *xml[in]: Mapping file.
     */void close();

    void spacer();
};

/* ************************************************************************** */
/*
// xmlMapper format v3

add for headers:
    tp=raw
    ct=track

add for values:
    unit="bit"
    note="unreliable"
    meaning="QRTSERT"
    off="12" (relatif to header offset ???)
    sz="1" (-1 for bit aligned)
*/
/* ************************************************************************** */
/*
// xmlMapper format v2

<?xml version="1.0"?>
<file xmlMapper="0.2" minivideo="0.8-1">
<header>
  <format>WAVE</format>
  <size>3211820</size>
  <path>/path/to/this/file.wav</path>
</header>
<structure>
  <a fcc="WAVE" tp="RIFF header" off="0" sz="3211812">
    <a fcc="fmt " tp="RIFF chunk" off="12" sz="16">
          <wFormatTag>1</wFormatTag>
          <nChannels>4</nChannels>
          <nSamplesPerSec>48000</nSamplesPerSec>
          <nAvgBytesPerSec note="unreliable">384000</nAvgBytesPerSec>
          <nBlockAlign>8</nBlockAlign>
          <wBitsPerSample unit="bit">16</wBitsPerSample>
    </a>
    <a fcc="data" tp="RIFF chunk" off="36" sz="3211776">
      <dataOffset>44</dataOffset>
      <dataSize>3211776</dataSize>
    </a>
  </a>
</structure>
</file>
*/
/* ************************************************************************** */
#endif // CONTAINER_MAPPER_H
