/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Google Chart Base class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! Base class for all types of charts
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Base.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Base.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Base.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

//! The width of the chart
protected int width = 400;

//! The height of the chart
protected int height = 300;

//! Type of chart
protected string type;

//! The axes  of the chart
protected array(.Axis) axes = ({});

//! Chart title parameters
protected mapping title = ([
  "text"  : 0,
  "color" : 0,
  "size"  : 0
]);

//! Creates a new instance
//!
//! @param _type
//! @param _width
//! @param _height
protected void create(string _type, void|int _width, void|int _height)
{
  type = _type;
  if (_width) width = _width;
  if (_height) height = _height;

  if ((width*height) > 300000) {
    error("Charts can not be larger than 300000 pixels: %d*%d=%d\n",
          width, height, width*height);
  }
}

//! Add an axis to the chart
void add_axis(.Axis axis)
{
  axes += ({ axis });
}

//! Set a title for the chart
//!
//! @param text
//! @param size
//! @param color
//!  Hexadecimal color
void set_title(string text, void|string|int size, void|string color)
{
  //if (catch(title->text = string_to_utf8(text)))
  title->text = text;
  title->size = size;
  title->color = color && .normalize_color(color);
}

//! Render the chart url
//!
//! @param data
string render_url(.Data data)
{
  array(.Param) args = ({
    .Param("chs", width, "x", height),
    .Param("cht", type),
    .Param((string)data)
  });

  if (title->text) {
    args += ({
      .Param("chtt", replace(title->text, ({ " ", "\n"}), ({ "+", "|" })))
    });
  }

  if (title->color || title->size) {
    .Param p = .Param("chts");

    if (title->color)
      p += title->color;

    if (title->color && title->size)
      p += ",";

    if (title->size)
      p += title->size;

    args += ({ p });
  }

  if (sizeof(axes)) {
    int i = 0;
    array axis_type  = axes->get_type();
    array label_text = map(
      axes->get_label_text(),
      lambda (string s) {
	if (sizeof(s))
	  return (i++) + ":" + s;
	i++;
      }
    ) - ({ 0 });

    i = 0;
    array label_pos  = axes->get_label_position();
    array axis_range = map(
      axes->get_range(),
      lambda (string s) {
	if (sizeof(s))
	  return (i++) + "," + s;
	i++;
      }
    ) - ({ 0 });

    i = 0;
    array axis_style = map(
      axes->get_style(),
      lambda (string s) {
	if (sizeof(s))
	  return (i++) + "," + s;
	i++;
      }
    ) - ({ 0 });

    args += ({ .Param("chxt", axis_type*",") });

    if (sizeof(axis_range))
      args += ({ .Param("chxr", axis_range*"|") });

    if (sizeof(label_text))
      args += ({ .Param("chxl", label_text*"|") });

    if (sizeof(axis_style)) {
      args += ({ .Param("chxs", axis_style*"|") });
      i = 0;
      array tick_lengths = map(
	axes->get_tick_mark_length(),
	lambda (int j) {
	  if (j > 0)
	    return (i++) + "," + j;
	  i++;
	}
      ) - ({ 0 });

      if (sizeof(tick_lengths)) 
	args += ({ .Param("chxtc", tick_lengths*"|") });
    }
  }

  return .BASE_URL + "?" + args->cast("string")*"&amp;";
}

//! Same as @[render_url()] execpt this replaces the @tt{&amp;@} with
//! @tt{&@}.
//!
//! @param data
string render_url_nice(.Data data)
{
  return replace(render_url(data), "&amp;", "&");
}
