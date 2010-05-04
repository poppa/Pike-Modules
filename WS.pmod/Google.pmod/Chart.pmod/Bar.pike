/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Google Chart Base class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! Class for creating bar charts
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Bar.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Bar.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Bar.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

inherit .BaseSimple;

//! Horizontally stacked chart
constant HORIZONTAL_STACK = "bhs";

//! Vertically stacked chart
constant VERTICAL_STACK = "bvs";

//! Horizontally grouped chart
constant HORIZONTAL_GROUP = "bhg";

//! vertically grouped chart
constant VERTICAL_GROUP = "bvg";

//! Auto size the width of the bars or not
int(0..1) auto_size = 1;

//! Style parameters of the bars
array(string) bar_params;

//! Creates a new @[Bar] chart
//!
//! @param type
//! @param width
//! @param height
void create(void|string _type, void|int width, void|int height)
{
  type = _type||VERTICAL_STACK;

  if ( !(< HORIZONTAL_STACK, VERTICAL_STACK,
	   HORIZONTAL_GROUP, VERTICAL_GROUP >)[type] )
    error("Unknown bar chart type %O!\n", type);

  ::create(type, width, height);
}

//! Set the style of the bars
//!
//! @param width
//! @param bar_space
//!  The space between each bar
//! @param group_space
//!  The space between each group of bars
void set_bar_params(int|string width, int|string bar_space,
		    int|string group_space)
{
  bar_params = ({ (string)width, (string)bar_space, (string)group_space });
}

//! Render the chart url
//!
//! @param data
string render_url(.Data data)
{
  string url = ::render_url(data);

  if (bar_params) {
    string a = "&amp;chbh=";
    a += ( (int)bar_params[0] ? bar_params[0] : "a" );
    if  ( bar_params[1] || bar_params[2] )
      a += "," + (bar_params[1..]*",");

    url += a;
  }
  else if (auto_size)
    url += "&amp;chbh=a";

  return url;
}
