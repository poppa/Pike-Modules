/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  This is a Pike port of:

    Author: Arnold Andreasson, info@mellifica.se
    Copyright (c) 2007-2013 Arnold Andreasson
    License: MIT License as follows:

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  =============================================================================
  JavaScript-implementation of "Gauss Conformal Projection
  (Transverse Mercator), Krügers Formulas".
  - Parameters for SWEREF99 lat-long to/from RT90 and SWEREF99
    coordinates (RT90 and SWEREF99 are used in Swedish maps).
  Source: http://www.lantmateriet.se/geodesi/
*/

//! Usage:
//!
//! @code
//!  // X and Y is coordinats according to SWEREF 99:15 00
//!  array(float) latlng = grid_to_geodetic(6477479.207031, 186714.648438,
//!                                         PROJECTION_sweref_99_1500);
//! @endcode

private float axis;             // Semi-major axis of the ellipsoid.
private float flattening;       // Flattening of the ellipsoid.
private float central_meridian; // Central meridian for the projection.
private float lat_of_origin;    // Latitude of origin.
private float scale;            // Scale on central meridian.
private float false_northing;   // Offset for origo.
private float false_easting;    // Offset for origo.

constant PROJECTION_rt90_75_gon_v = "rt90_7.5_gon_v";
constant PROJECTION_rt90_50_gon_v = "rt90_5.0_gon_v";
constant PROJECTION_rt90_25_gon_v = "rt90_2.5_gon_v";
constant PROJECTION_rt90_00_gon_v = "rt90_0.0_gon_v";
constant PROJECTION_rt90_25_gon_o = "rt90_2.5_gon_o";
constant PROJECTION_rt90_50_gon_o = "rt90_5.0_gon_o";
constant PROJECTION_bessel_rt90_75_gon_v = "bessel_rt90_7.5_gon_v";
constant PROJECTION_bessel_rt90_50_gon_v = "bessel_rt90_5.0_gon_v";
constant PROJECTION_bessel_rt90_25_gon_v = "bessel_rt90_2.5_gon_v";
constant PROJECTION_bessel_rt90_00_gon_v = "bessel_rt90_0.0_gon_v";
constant PROJECTION_bessel_rt90_25_gon_o = "bessel_rt90_2.5_gon_o";
constant PROJECTION_bessel_rt90_50_gon_o = "bessel_rt90_5.0_gon_o";
constant PROJECTION_sweref_99_tm = "sweref_99_tm";
constant PROJECTION_sweref_99_1200 = "sweref_99_1200";
constant PROJECTION_sweref_99_1330 = "sweref_99_1330";
constant PROJECTION_sweref_99_1500 = "sweref_99_1500";
constant PROJECTION_sweref_99_1630 = "sweref_99_1630";
constant PROJECTION_sweref_99_1800 = "sweref_99_1800";
constant PROJECTION_sweref_99_1415 = "sweref_99_1415";
constant PROJECTION_sweref_99_1545 = "sweref_99_1545";
constant PROJECTION_sweref_99_1715 = "sweref_99_1715";
constant PROJECTION_sweref_99_1845 = "sweref_99_1845";
constant PROJECTION_sweref_99_2015 = "sweref_99_2015";
constant PROJECTION_sweref_99_2145 = "sweref_99_2145";
constant PROJECTION_sweref_99_2315 = "sweref_99_2315";

//! Parameters for RT90 and SWEREF99TM.
//! Note: Parameters for RT90 are choosen to eliminate the
//! differences between Bessel and GRS80-ellipsoides.
//! Bessel-variants should only be used if lat/long are given as
//! RT90-lat/long based on the Bessel ellipsoide (from old maps).
//! Parameter: projection (string). Must match if-statement.
//!
//! @param projection
//!  Any one of the @tt{PROJECTION_*@} constants
void swedish_params(string projection)
{
  if (projection == "rt90_7.5_gon_v") {
    grs80_params();
    central_meridian = 11.0 + 18.375/60.0;
    scale = 1.000006000000;
    false_northing = -667.282;
    false_easting = 1500025.141;
  }
  else if (projection == "rt90_5.0_gon_v") {
    grs80_params();
    central_meridian = 13.0 + 33.376/60.0;
    scale = 1.000005800000;
    false_northing = -667.130;
    false_easting = 1500044.695;
  }
  else if (projection == "rt90_2.5_gon_v") {
    grs80_params();
    central_meridian = 15.0 + 48.0/60.0 + 22.624306/3600.0;
    scale = 1.00000561024;
    false_northing = -667.711;
    false_easting = 1500064.274;
  }
  else if (projection == "rt90_0.0_gon_v") {
    grs80_params();
    central_meridian = 18.0 + 3.378/60.0;
    scale = 1.000005400000;
    false_northing = -668.844;
    false_easting = 1500083.521;
  }
  else if (projection == "rt90_2.5_gon_o") {
    grs80_params();
    central_meridian = 20.0 + 18.379/60.0;
    scale = 1.000005200000;
    false_northing = -670.706;
    false_easting = 1500102.765;
  }
  else if (projection == "rt90_5.0_gon_o") {
    grs80_params();
    central_meridian = 22.0 + 33.380/60.0;
    scale = 1.000004900000;
    false_northing = -672.557;
    false_easting = 1500121.846;
  }

  // RT90 parameters, Bessel 1841 ellipsoid.
  else if (projection == "bessel_rt90_7.5_gon_v") {
    bessel_params();
    central_meridian = 11.0 + 18.0/60.0 + 29.8/3600.0;
  }
  else if (projection == "bessel_rt90_5.0_gon_v") {
    bessel_params();
    central_meridian = 13.0 + 33.0/60.0 + 29.8/3600.0;
  }
  else if (projection == "bessel_rt90_2.5_gon_v") {
    bessel_params();
    central_meridian = 15.0 + 48.0/60.0 + 29.8/3600.0;
  }
  else if (projection == "bessel_rt90_0.0_gon_v") {
    bessel_params();
    central_meridian = 18.0 + 3.0/60.0 + 29.8/3600.0;
  }
  else if (projection == "bessel_rt90_2.5_gon_o") {
    bessel_params();
    central_meridian = 20.0 + 18.0/60.0 + 29.8/3600.0;
  }
  else if (projection == "bessel_rt90_5.0_gon_o") {
    bessel_params();
    central_meridian = 22.0 + 33.0/60.0 + 29.8/3600.0;
  }

  // SWEREF99TM and SWEREF99ddmm  parameters.
  else if (projection == "sweref_99_tm") {
    sweref99_params();
    central_meridian = 15.00;
    lat_of_origin = 0.0;
    scale = 0.9996;
    false_northing = 0.0;
    false_easting = 500000.0;
  }
  else if (projection == "sweref_99_1200") {
    sweref99_params();
    central_meridian = 12.00;
  }
  else if (projection == "sweref_99_1330") {
    sweref99_params();
    central_meridian = 13.50;
  }
  else if (projection == "sweref_99_1500") {
    sweref99_params();
    central_meridian = (15.00);
  }
  else if (projection == "sweref_99_1630") {
    sweref99_params();
    central_meridian = 16.50;
  }
  else if (projection == "sweref_99_1800") {
    sweref99_params();
    central_meridian = 18.00;
  }
  else if (projection == "sweref_99_1415") {
    sweref99_params();
    central_meridian = 14.25;
  }
  else if (projection == "sweref_99_1545") {
    sweref99_params();
    central_meridian = 15.75;
  }
  else if (projection == "sweref_99_1715") {
    sweref99_params();
    central_meridian = 17.25;
  }
  else if (projection == "sweref_99_1845") {
    sweref99_params();
    central_meridian = 18.75;
  }
  else if (projection == "sweref_99_2015") {
    sweref99_params();
    central_meridian = 20.25;
  }
  else if (projection == "sweref_99_2145") {
    sweref99_params();
    central_meridian = 21.75;
  }
  else if (projection == "sweref_99_2315") {
    sweref99_params();
    central_meridian = 23.25;
  }
  else {
    central_meridian = 0.0;
  }
}

//! Conversion from grid coordinates to geodetic coordinates.
//!
//! @param x
//! @param y
//! @param type
//!  Any of the @tt{PROJECTION_*@} constants
array(float) grid_to_geodetic(float x, float y, void|string type)
{
  if (type) swedish_params(type);

  array(float) lat_lon = allocate(2, 0.0);

  if (central_meridian == 0.0)
    return lat_lon;

  float e2 = flattening * (2.0 - flattening);
  float n = flattening / (2.0 - flattening);

  float a_roof = axis / (1.0 + n) * (1.0 + n*n/4.0 + n*n*n*n/64.0);
  float delta1 = n/2.0 - 2.0*n*n/3.0 + 37.0*n*n*n/96.0 - n*n*n*n/360.0;
  float delta2 = n*n/48.0 + n*n*n/15.0 - 437.0*n*n*n*n/1440.0;
  float delta3 = 17.0*n*n*n/480.0 - 37*n*n*n*n/840.0;
  float delta4 = 4397.0*n*n*n*n/161280.0;

  float Astar = e2 + e2*e2 + e2*e2*e2 + e2*e2*e2*e2;
  float Bstar = -(7.0*e2*e2 + 17.0*e2*e2*e2 + 30.0*e2*e2*e2*e2) / 6.0;
  float Cstar = (224.0*e2*e2*e2 + 889.0*e2*e2*e2*e2) / 120.0;
  float Dstar = -(4279.0*e2*e2*e2*e2) / 1260.0;

  // Convert.
  float deg_to_rad = Math.pi / 180;
  float lambda_zero = central_meridian * deg_to_rad;
  float xi = (x - false_northing) / (scale * a_roof);
  float eta = (y - false_easting) / (scale * a_roof);
  float xi_prim = xi -
          delta1*sin(2.0*xi) * cosh(2.0*eta) -
          delta2*sin(4.0*xi) * cosh(4.0*eta) -
          delta3*sin(6.0*xi) * cosh(6.0*eta) -
          delta4*sin(8.0*xi) * cosh(8.0*eta);
  float eta_prim = eta -
          delta1*cos(2.0*xi) * sinh(2.0*eta) -
          delta2*cos(4.0*xi) * sinh(4.0*eta) -
          delta3*cos(6.0*xi) * sinh(6.0*eta) -
          delta4*cos(8.0*xi) * sinh(8.0*eta);
  float phi_star = asin(sin(xi_prim) / cosh(eta_prim));
  float delta_lambda = atan(sinh(eta_prim) / cos(xi_prim));
  float lon_radian = lambda_zero + delta_lambda;
  float lat_radian = phi_star + sin(phi_star) * cos(phi_star) *
          (Astar +
           Bstar*pow(sin(phi_star), 2) +
           Cstar*pow(sin(phi_star), 4) +
           Dstar*pow(sin(phi_star), 6));

  lat_lon[0] = lat_radian * 180.0 / Math.pi;
  lat_lon[1] = lon_radian * 180.0 / Math.pi;

  return lat_lon;
}

//! Conversion from geodetic coordinates to grid coordinates.
//!
//! @param x
//! @param y
//! @param type
//!  Any of the @tt{PROJECTION_*@} constants
array(float) geodetic_to_grid(float latitude, float longitude, void|string type)
{
  if (type) swedish_params(type);

  array(float) x_y = allocate(2, 0.0);

  if (central_meridian == 0.0) {
    return x_y;
  }

  // Prepare ellipsoid-based stuff.
  float e2 = flattening * (2.0 - flattening);
  float n = flattening / (2.0 - flattening);
  float a_roof = axis / (1.0 + n) * (1.0 + n*n/4.0 + n*n*n*n/64.0);
  float A = e2;
  float B = (5.0*e2*e2 - e2*e2*e2) / 6.0;
  float C = (104.0*e2*e2*e2 - 45.0*e2*e2*e2*e2) / 120.0;
  float D = (1237.0*e2*e2*e2*e2) / 1260.0;
  float beta1 = n/2.0 - 2.0*n*n/3.0 + 5.0*n*n*n/16.0 + 41.0*n*n*n*n/180.0;
  float beta2 = 13.0*n*n/48.0 - 3.0*n*n*n/5.0 + 557.0*n*n*n*n/1440.0;
  float beta3 = 61.0*n*n*n/240.0 - 103.0*n*n*n*n/140.0;
  float beta4 = 49561.0*n*n*n*n/161280.0;

  // Convert.
  float deg_to_rad = Math.pi / 180.0;
  float phi = latitude * deg_to_rad;
  float _lambda = longitude * deg_to_rad;
  float lambda_zero = central_meridian * deg_to_rad;

  float phi_star = phi - sin(phi) * cos(phi) * (A +
          B*pow(sin(phi), 2) +
          C*pow(sin(phi), 4) +
          D*pow(sin(phi), 6));
  float delta_lambda = _lambda - lambda_zero;
  float xi_prim = atan(tan(phi_star) / cos(delta_lambda));
  float eta_prim = atanh(cos(phi_star) * sin(delta_lambda));
  float x = scale * a_roof * (xi_prim +
          beta1 * sin(2.0*xi_prim) * cosh(2.0*eta_prim) +
          beta2 * sin(4.0*xi_prim) * cosh(4.0*eta_prim) +
          beta3 * sin(6.0*xi_prim) * cosh(6.0*eta_prim) +
          beta4 * sin(8.0*xi_prim) * cosh(8.0*eta_prim)) +
          false_northing;
  float y = scale * a_roof * (eta_prim +
          beta1 * cos(2.0*xi_prim) * sinh(2.0*eta_prim) +
          beta2 * cos(4.0*xi_prim) * sinh(4.0*eta_prim) +
          beta3 * cos(6.0*xi_prim) * sinh(6.0*eta_prim) +
          beta4 * cos(8.0*xi_prim) * sinh(8.0*eta_prim)) +
          false_easting;
  x_y[0] = round(x * 1000.0) / 1000.0;
  x_y[1] = round(y * 1000.0) / 1000.0;

  return x_y;
}

// Sets of default parameters.
private void grs80_params()
{
  axis = 6378137.0; // GRS 80.
  flattening = 1.0 / 298.257222101; // GRS 80.
  central_meridian = 0.0;
  lat_of_origin = 0.0;
}

private void bessel_params()
{
  axis = 6377397.155; // Bessel 1841.
  flattening = 1.0 / 299.1528128; // Bessel 1841.
  central_meridian = 0.0;
  lat_of_origin = 0.0;
  scale = 1.0;
  false_northing = 0.0;
  false_easting = 1500000.0;
}

private void sweref99_params()
{
  axis = 6378137.0; // GRS 80.
  flattening = 1.0 / 298.257222101; // GRS 80.
  central_meridian = 0.0;
  lat_of_origin = 0.0;
  scale = 1.0;
  false_northing = 0.0;
  false_easting = 150000.0;
}
