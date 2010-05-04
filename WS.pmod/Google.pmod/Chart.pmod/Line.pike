/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Google Chart Base class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! Class for creating line charts
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Line.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Line.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Line.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

inherit .BaseSimple;

//! Basic line chart
constant LINES = "lc";

//! Sparkline line chart
constant SPARKLINES = "ls";

//! Pointed chart
constant POINTS = "lxy";

//! Creates a new @[Line] chart
//!
//! @param type
//! @param width
//! @param height
void create(void|string _type, void|int width, void|int height)
{
  type = _type || LINES;
  if ( !(< LINES, SPARKLINES, POINTS >)[type] )
    error("Unknown line chart type \"%s\"!\n", type);

  ::create(type, width, height);
}

