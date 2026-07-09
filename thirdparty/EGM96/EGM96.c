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

#include "EGM96.h"
#include "EGM96_data.h"

#include <math.h>

/* ************************************************************************** */

// Thread-local storage, without requiring the optional C11 <threads.h> header
#if defined(_MSC_VER)
#define EGM96_THREAD_LOCAL __declspec(thread)
#elif defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 202311L)
#define EGM96_THREAD_LOCAL thread_local
#elif defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 201112L)
#define EGM96_THREAD_LOCAL _Thread_local
#elif defined(__GNUC__)
#define EGM96_THREAD_LOCAL __thread
#else
#define EGM96_THREAD_LOCAL
#endif

// Provide a fallback for M_PI, which is a POSIX extension, not standard C
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/* ************************************************************************** */

#define _coeffs (65341) //!< Size of correction and harmonic coefficients arrays (361*181)
#define _nmax   (360)   //!< Maximum degree and orders of harmonic coefficients.
#define _361    (361)

/* ************************************************************************** */

static double hundu(const double p[_coeffs+1], const double sinml[_361+1], const double cosml[_361+1],
                    const double gr, const double re)
{
    // WGS84 gravitational constant in m³/s² (mass of Earth’s atmosphere included)
    const double GM = 0.3986004418e15;
    // WGS84 datum surface equatorial radius
    const double ae = 6378137.0;

    const double ar = ae / re;
    double arn = ar;
    double ac = 0;
    double a = 0;

    unsigned k = 3;
    for (unsigned n = 2; n <= _nmax; n++)
    {
        arn *= ar;
        k++;
        double sumc = p[k] * egm96_data[k][0];
        double sum  = p[k] * egm96_data[k][2];

        for (unsigned m = 1; m <= n; m++)
        {
            k++;
            double tempc = (egm96_data[k][0] * cosml[m]) + (egm96_data[k][1] * sinml[m]);
            double temp  = (egm96_data[k][2] * cosml[m]) + (egm96_data[k][3] * sinml[m]);
            sumc += p[k] * tempc;
            sum  += p[k] * temp;
        }
        ac += sumc;
        a += sum * arn;
    }
    ac += egm96_data[1][0] + (p[2] * egm96_data[2][0]) + (p[3] * ((egm96_data[3][0] * cosml[1]) + (egm96_data[3][1] * sinml[1])));

    // Add haco = ac/100 to convert height anomaly on the ellipsoid to the undulation
    // Add -0.53m to make undulation refer to the WGS84 ellipsoid

    return ((a * GM) / (gr * re)) + (ac / 100.0) - 0.53;
}

static void dscml(const double rlon, double sinml[_361+1], double cosml[_361+1])
{
    const double a = sin(rlon);
    const double b = cos(rlon);

    sinml[1] = a;
    cosml[1] = b;
    sinml[2] = (2 * b * a);
    cosml[2] = (2 * b * b) - 1;

    for (unsigned m = 3; m <= _nmax; m++)
    {
        sinml[m] = (2 * b * sinml[m-1]) - sinml[m-2];
        cosml[m] = (2 * b * cosml[m-1]) - cosml[m-2];
    }
}

/*!
 * \param m: order.
 * \param theta: Colatitude (in radians).
 * \param rleg: Normalized legendre function.
 *
 * This subroutine computes all normalized legendre function in 'rleg'.
 * The dimensions of array 'rleg' must be at least equal to nmax+1.
 * All calculations are in double precision.
 *
 * Original programmer: Oscar L. Colombo, Dept. of Geodetic Science the Ohio State University, August 1980.
 * ineiev: I removed the derivatives, for they are never computed here.
 */
static void legfdn(const unsigned m, const double theta, double rleg[_361+1])
{
    static EGM96_THREAD_LOCAL double drts[(2 * _nmax) + 2], dirt[(2 * _nmax) + 2];
    static EGM96_THREAD_LOCAL int ir = 0;

    const unsigned nmax1 = _nmax + 1;
    const unsigned nmax2p = (2 * _nmax) + 1;
    const unsigned m1 = m + 1;
    const unsigned m2 = m + 2;
    const unsigned m3 = m + 3;

    unsigned n, n1, n2;

    if (ir == 0)
    {
        ir = 1;
        for (n = 1; n <= nmax2p; n++)
        {
            drts[n] = sqrt(n);
            dirt[n] = 1 / drts[n];
        }
    }

    const double cothet = cos(theta);
    const double sithet = sin(theta);

    // Compute the legendre functions
    double rlnn[_361+1];
    rlnn[1] = 1;
    rlnn[2] = sithet * drts[3];
    for (n1 = 3; n1 <= m1; n1++)
    {
        n = n1 - 1;
        n2 = 2 * n;
        rlnn[n1] = drts[n2 + 1] * dirt[n2] * sithet * rlnn[n];
    }

    switch (m)
    {
        case 1:
            rleg[2] = rlnn[2];
            rleg[3] = drts[5] * cothet * rleg[2];
            break;
        case 0:
            rleg[1] = 1;
            rleg[2] = cothet * drts[3];
            break;
    }
    rleg[m1] = rlnn[m1];

    if (m2 <= nmax1)
    {
        rleg[m2] = drts[(2 * m1) + 1] * cothet * rleg[m1];
        if (m3 <= nmax1)
        {
            for (n1 = m3; n1 <= nmax1; n1++)
            {
                n = n1 - 1;
                if ((!m && n < 2) || (m == 1 && n < 3)) continue;
                n2 = 2 * n;
                rleg[n1] = drts[n2+1] * dirt[n+m] * dirt[n-m] *
                            ((drts[n2-1] * cothet * rleg[n1-1]) - (drts[n+m-1] * drts[n-m-1] * dirt[n2-3] * rleg[n1-2]));
            }
        }
    }
}

/*!
 * \brief Compute the geocentric latitude, geocentric radius, normal gravity.
 * \param lat: Latitude (in radians).
 * \param lon: Longitude (in radians).
 * \param re: Geocentric radius.
 * \param rlat: Geocentric latitude.
 * \param gr: Normal gravity (m/sec²).
 *
 * This subroutine computes geocentric distance to the point, the geocentric
 * latitude, and an approximate value of normal gravity at the point based the
 * constants of the WGS84(g873) system are used.
 */
static void radgra(const double lat, const double lon, double *rlat, double *gr, double *re)
{
    const double a = 6378137.0;
    const double e2 = 0.00669437999013;
    const double geqt = 9.7803253359;
    const double k = 0.00193185265246;
    const double t1 = sin(lat) * sin(lat);
    const double n = a / sqrt(1.0 - (e2 * t1));
    const double t2 = n * cos(lat);
    const double x = t2 * cos(lon);
    const double y = t2 * sin(lon);
    const double z = (n * (1 - e2)) * sin(lat);

    // Compute the geocentric radius
    *re = sqrt((x * x) + (y * y) + (z * z));

    // Compute the geocentric latitude
    *rlat = atan2(z, sqrt((x * x) + (y * y)));

    // Compute normal gravity (m/sec²)
    *gr = geqt * (1 + (k * t1)) / sqrt(1 - (e2 * t1));
}

/*!
 * \brief Compute the geoid undulation from the EGM96 potential coefficient model, for a given latitude and longitude.
 * \param lat: Latitude (in radians).
 * \param lon: Longitude (in radians).
 * \return The geoid undulation (in meters).
 */
static double undulation(const double lat, const double lon)
{
    static EGM96_THREAD_LOCAL double p[_coeffs+1], sinml[_361+1], cosml[_361+1], rleg[_361+1];
    double rlat, gr, re;

    // Compute the geocentric latitude, geocentric radius, normal gravity
    radgra(lat, lon, &rlat, &gr, &re);
    rlat = (M_PI / 2) - rlat;

    const unsigned nmax1 = _nmax + 1;
    for (unsigned j = 1; j <= nmax1; j++)
    {
        unsigned m = j - 1;
        legfdn(m, rlat, rleg);
        for (unsigned i = j ; i <= nmax1; i++)
        {
            p[(((i - 1) * i) / 2) + m + 1] = rleg[i];
        }
    }
    dscml(lon, sinml, cosml);

    return hundu(p, sinml, cosml, gr, re);
}

/* ************************************************************************** */

double egm96_compute_altitude_offset(const double latitude, const double longitude)
{
    // Non-finite inputs (NaN, ±inf) have no meaningful undulation
    if (!isfinite(latitude) || !isfinite(longitude)) return 0.0;

    // Clamp latitude to the valid [-90, 90] range
    double lat = latitude;
    if (lat >  90.0) lat =  90.0;
    if (lat < -90.0) lat = -90.0;

    // Wrap longitude into [-180, 180] (it is periodic)
    double lon = fmod(longitude, 360.0);
    if (lon >  180.0) lon -= 360.0;
    else if (lon < -180.0) lon += 360.0;

    const double rad = (180.0 / M_PI);
    return undulation(lat / rad, lon / rad);
}

/* ************************************************************************** */
