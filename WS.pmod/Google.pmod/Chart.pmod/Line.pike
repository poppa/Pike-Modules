/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Class for creating line charts
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| This file is part of Google.pmod
//|
//| Google.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Google.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Google.pmod. If not, see <http://www.gnu.org/licenses/>.

inherit .BaseSimple;

//! Basic line chart
constant LINES = "lc";

//! Sparkline line chart
constant SPARKLINES = "ls";

//! Pointed chart
constant POINTS = "lxy";

//! Creates a new @[Line] chart
//!
//! @param _type
//!  Type of line chart. See the constants in @[Line]. Default is
//!  @tt{LINES@}.
//! @param width
//! @param height
void create(void|string _type, void|int width, void|int height)
{
  type = _type || LINES;
  if ( !(< LINES, SPARKLINES, POINTS >)[type] )
    error("Unknown line chart type \"%s\"!\n", type);

  ::create(type, width, height);
}

