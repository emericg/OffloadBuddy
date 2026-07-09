/*
 * Copyright (c) 2006 D.Ineiev <ineiev@yahoo.co.uk>
 * Copyright (c) 2020 Emeric Grange <emeric.grange@gmail.com>
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

/*
 * This program is designed for the calculation of a geoid undulation at a point
 * whose latitude and longitude is specified.
 *
 * This program is designed to be used with the constants of EGM96 and those of
 * the WGS84(g873) system. The undulation will refer to the WGS84 ellipsoid.
 *
 * It's designed to use the potential coefficient model EGM96 and a set of
 * spherical harmonic coefficients of a correction term.
 * The correction term is composed of several different components, the primary
 * one being the conversion of a height anomaly to a geoid undulation.
 *
 * The principles of this procedure were initially described in the paper:
 * - use of potential coefficient models for geoid undulation determination using
 *   a spherical harmonic representation of the height anomaly/geoid undulation
 *   difference by R.H. Rapp, Journal of Geodesy, 1996.
 *
 * This program is a modification of the program described in the following report:
 * - a fortran program for the computation of gravimetric quantities from high
 *   degree spherical harmonic expansions, Richard H. Rapp, report 334, Department
 *   of Geodetic Science and Surveying, the Ohio State University, Columbus, 1982.
 */

#ifndef EGM96_H
#define EGM96_H

#ifdef __cplusplus
extern "C" {
#endif

/* ************************************************************************** */

/*!
 * \brief Compute the geoid undulation from the EGM96 potential coefficient model, for a given latitude and longitude.
 * \param latitude: Latitude (in degrees). Valid range is [-90, 90].
 * \param longitude: Longitude (in degrees). Valid range is  [-180, 180].
 * \return The geoid undulation N (in meters). Roughly −105 m to +85 m depending on the input coordinates.
 *
 * Using the geoid undulation N:
 * orthometric "Mean Sea Level" altitude = "GPS" altitude − N
 */
double egm96_compute_altitude_offset(double latitude, double longitude);

/* ************************************************************************** */

#ifdef __cplusplus
}
#endif

#endif // EGM96_H
