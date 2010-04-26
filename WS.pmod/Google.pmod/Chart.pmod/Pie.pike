/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Google Chart Base class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! Class for creating pie charts
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Pie.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Pie.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Pie.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

inherit .Base;

//! Two dimentional pie chart
constant BASIC = "p";

//! Three dimentional pie chart
constant THREE_DIMENTIONAL = "p3";

//! Concentric pie chart
constant CONCENTRIC = "pc";

//! Rotation of the pie chart
float orientation = 0.0;

//! Creates new pie chart
//!
//! @param type
//! @param width
//! @param height
void create(void|string _type, void|int width, void|int height)
{
  type = _type || BASIC;
  if ( type && !(< BASIC, THREE_DIMENTIONAL, CONCENTRIC >)[type] )
    error("Unknown pie chart type \"%s\"!\n", type);

  ::create(type, width, height);
}

//! Render the chart URL
//!
//! @param data
string render_url(.Data data)
{
  string url = ::render_url(data);

  if (orientation != 0.0)
    url += sprintf("&amp;chp=%.1f", orientation);

  return url;
}

