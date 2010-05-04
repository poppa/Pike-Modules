/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Google Chart module@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Chart.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Chart.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Chart.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

//! URL at Google that generates the charts
constant BASE_URL   = "http://chart.apis.google.com/chart";

//! Fix colors: @tt{36a@} will become @tt{3366AA@}, @tt{#aaff99@} will become
//! @tt{aaff99@}.
//!
//! @param c
string normalize_color(string c)
{
  if (!c || sizeof(c) < 3)
    error("Color %O is not a valid hexadecimal color! ", c);

  if (c[0] == '#')
    c = c[1..];

  switch (sizeof(c))
  {
    case 3:
    case 4: // For transparency
      c = map( c/1, lambda(string s) { return s*2; } )*"";
      break;
  }

  return upper_case(c);
}

//! Rounds @[x] to the nearest @[base]
//! 
//! @xml{<code detab='3'>
//!   round_to_nearest(1430,  100); // 1400
//!   round_to_nearest(1430, 1000); // 1000
//! </code>@}
//!
//! @param x
//! @param base
float round_to_nearest(float|int x, float|int base)
{
  x = (float)x;
  base = (float)base;

  if (x > 0.0 && base > 0.0) {
    float sign = x > 0 ? 1.0 : -1.0;
    x *= sign;
    x /= base;
    int point = (int)floor(x+0.5);
    x = point*base;
    x *= sign;
  }

  return x;
}

//! Same as @[round_to_nearest()] except this ceils @[x] to the nearest @[base].
//!
//! @param x
//! @param base
float ceil_to_nearest(float|int x, float|int base)
{
  x = (float)x;
  base = (float)base;
  if (x > 0.0 && base > 0.0) {
    float sign = x > 0 ? 1.0 : -1.0;
    x *= sign;
    x /= base;
    int point = (int)ceil(x+0.5);
    x = point*base;
    x *= sign;
  }

  return x;
}
