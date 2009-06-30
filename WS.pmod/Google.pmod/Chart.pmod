/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{WS.Google.Chart module@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Google.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Google.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Google.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}


/* NOTE! Very much work in progress 
 * Documentation is to follow shortly 
 */


//! URL at Google that generates the charts
constant BASE_URL   = "http://chart.apis.google.com/chart";

constant TYPE       = "cht";
constant DATA       = "chd";
constant LABEL      = "chl";
constant SIZE       = "chs";
constant MIN_MAX    = "chds";
constant AXIS_RANGE = "chxr";


//! Base class for all types of charts
protected class Base // {{{
{
  protected int width   = 400;
  protected int height  = 300;
  protected string type;
  protected string orientation = "y";
  protected array(Axis) axes = ({});

  mapping title = ([
    "text"  : 0,
    "color" : 0,
    "size"  : 0
  ]);

  int y_axis_granularity = 10;
  int x_axis_granularity = 0;

  void create(string _type, void|int _width, void|int _height)
  {
    type = _type;
    if (_width) width = _width;
    if (_height) height = _height;
  }
  
  void add_axis(Axis axis)
  {
    axes += ({ axis });
  }

  string render_url(Data data)
  {
    array(Param) args = ({
      Param(SIZE, width, "x", height),
      Param(TYPE, type),
      Param((string)data),
    });

    if (title->text)
      args += ({ 
	Param("chtt", replace(title->text, ({" ","\n"}), ({"+","|" })))
      });

    if (title->color || title->size) {
      Param p = Param("chts");

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
      );
      i = 0;
      array label_pos  = axes->get_label_position();
      array axis_range = map(
	axes->get_range(),
	lambda (string s) {
	  if (sizeof(s))
	    return (i++) + "," + s;
	  i++;
	}
      );

      args += ({ Param("chxt", axis_type*",") });

      if (sizeof(axis_range)) 
	args += ({ Param("chxr", axis_range*"|") });

      if (sizeof(label_text))
	args += ({ Param("chxl", label_text*"") });
    }
    
    return BASE_URL + "?" + args->cast("string")*"&amp;";
  }
} // }}}

//! Base class for @[Line] and @[Bar] charts.
class BaseSimple // {{{
{
  inherit Base;

  Grid grid;

  string render_url(Data data)
  {
    string url = ::render_url(data);
    if (grid)
      url += "&amp;" + (string)grid;

    return url;
  }
} // }}}

class Line // {{{
{
  inherit BaseSimple;

  constant LINES      = "lc";
  constant SPARKLINES = "ls";
  constant POINTS     = "lxy";

  void create(string type, void|int width, void|int height)
  {
    if ( !(< LINES, SPARKLINES, POINTS >)[type] )
      error("Unknown line chart type \"%s\"!\n", type);

    ::create(type, width, height);
  }
} // }}}

class Bar // {{{
{
  inherit BaseSimple;

  constant HORIZONTAL_STACK = "bhs";
  constant VERTICAL_STACK   = "bvs";
  constant HORIZONTAL_GROUP = "bhg";
  constant VERTICAL_GROUP   = "bvg";
  
  int(0..1) auto_size = 1;
  array bar_params;

  void create(void|string type, void|int width, void|int height)
  {
    if (!type)
      type = VERTICAL_STACK;

    if ( !(< HORIZONTAL_STACK, VERTICAL_STACK, 
             HORIZONTAL_GROUP, VERTICAL_GROUP >)[type] )
      error("Unknown bar chart type %O!\n", type);

    ::create(type, width, height);
    
    if ( (< HORIZONTAL_STACK >)[type] )
      orientation = "x";
  }

  void set_bar_params(int|string width, int|string bar_space,
                      int|string group_space)
  {
    bar_params = ({ (string)width, (string)bar_space, (string)group_space });
  }
  
  string render_url(Data data)
  {
    string url = ::render_url(data);
    
    if (bar_params)
      url += "&amp;chbh=" + bar_params*",";
    else if (auto_size)
      url += "&amp;chbh=a";

    return url;
  }
} // }}}

class Pie
{
  inherit Base;
  
  constant BASIC             = "p";
  constant THREE_DIMENTIONAL = "p3";
  constant CONCENTRIC        = "pc";
  
  //float(0.0..1.0) orientation = 0.0;

  void create(void|string type, void|int width, void|int height)
  {
    if ( type && !(< BASIC, THREE_DIMENTIONAL, CONCENTRIC >)[type] )
      error("Unknown pie chart type \"%s\"!\n", type);

    ::create(type||BASIC, width, height);
  }
}

class Legend
{
  constant HORIZONTAL_BOTTOM = "b";
  constant HORIZONTAL_TOP    = "t";
  constant VERTICAL_BOTTOM   = "bv";
  constant VERTICAL_TOP      = "tv";
  constant VERTICAL_LEFT     = "l";
  constant VERTICAL_RIGHT     = "r";
  
  string text;
  string position;// = VERTICAL_RIGHT;
  
  void create(void|string _text, void|string _position)
  {
    text = _text;
    if (_position)
      position = _position;
  }
  
  mixed cast(string how)
  {
    string r = "chdl=" + text;
    if (position)
      r += "&amp;chldp=" + position;
    return r;
  }
}

class Axis // {{{
{
  constant BOTTOM = "x";
  constant TOP    = "t";
  constant LEFT   = "y";
  constant RIGHT  = "r";

  protected string type;
  protected Range  range;
  protected array(Label) labels = ({});

  void create(string _type)
  {
    type = _type;
  }

  void set_labels(array(string) _labels)
  {
    foreach (_labels, string label)
      add_label(label);
  }
  
  void add_label(string text, void|int|string position)
  {
    labels += ({ Label(text, (int)position) });
  }

  void set_range(int|float|string start, int|float|string end, 
                void|int interval)
  {
    range = Range(start, end, interval);
  }

  string get_type()
  {
    return type;
  }

  string get_label_text()
  {
    string s = (labels->text)*"|";
    if (sizeof(s))
      return "|" + s;
    return "";
  }

  string get_label_position()
  {
    return (labels->position)*"|";
  }
  
  string get_range()
  {
    return range && range->get()||"";
  }

  protected class Label
  {
    string text;
    string position;

    void create(string _text, int|float|string _position)
    {
      text = _text;
      position = (string)_position;
    }
    
    string _sprintf(int t)
    {
      return t == 'O' && sprintf("%O(%O, %O)", object_program(this),
                                               text, position);
    }
  }

  protected class Range
  {
    int start;
    int end;
    int interval;

    void create(int|float|string _start, int|float|string _end, 
                void|int _interval)
    {
      start = (int)_start;
      end = (int)_end;
      interval = (int)_interval;
    }
    
    string get()
    {
      string s = sprintf("%d,%d", start, end);
      if (interval)
	s += "," + (string)interval;
      return s;
    }
  }
  
  protected class Style
  {
    
  }
} // }}}

class Grid // {{{
{
  int x_axis_size;
  int y_axis_size;
  int line_length;
  int blank_length;
  int x_offset;
  int y_offset;
  
  void create(int x_axis, int y_axis, void|int line_len, void|int blank_len)
  {
    x_axis_size = x_axis;
    y_axis_size = y_axis;

    if (line_len != UNDEFINED)
      line_length = line_len;

    if (blank_len != UNDEFINED)
      blank_length = blank_len;
  }
  
  mixed cast(string how)
  {
    switch (how)
    {
      case "string":
	array v = ({ x_axis_size, y_axis_size });
	if (line_length != UNDEFINED)
	  v += ({ line_length });
    
	if (blank_length != UNDEFINED)
	  v += ({ blank_length });
	
	if (x_offset != UNDEFINED)
	  v += ({ x_offset });
	
	if (y_offset != UNDEFINED)
	  v += ({ y_offset });

	return "chg=" + map(v, lambda(int s) { return (string)s; } )*",";
	break;
    }

    error("Can't cast Grid to %O!\n", how);
  }
} // }}}

protected class Param // {{{
{
  string name;
  string value;

  void create(string _name, mixed ... rest)
  {
    name = _name;
    value = rest && map( rest, lambda(string s){ return (string)s; } )*"";
  }
  
  object_program `+(mixed val)
  {
    if (!value) value = "";
    value += (string)val;

    return this;
  }

  mixed cast(string how)
  {
    string r = name;
    if (value && sizeof(value))
      r += "=" + value;
    return r;
  }
  
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("Param(%O, %O)", name, value);
  }
} // }}}

class Data // {{{
{
  protected constant ALNUMS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                              "abcdefghijklmnopqrstuvwxyz"
                              "0123456789"/1;

  protected array(float)   values = ({});
  protected array(Data) group  = ({});

  int min_value  = 0;
  int max_value  = 100;
  string color   = "FFCC33";
  Legend legend  = Legend();
  array labels   = ({});

  void create(int|float|string ... args)
  {
    values = map( args, lambda (int|float|string v){ return (float)v; } );
  }

  object `+(int|float|string|object value)
  {
    if (objectp(value)) {
      if (object_program(value) == object_program(this)) {
	value->scale(min_value, max_value);
	group += ({ value });
      }
    }
    else
      values += ({ (float)value });

    return this;
  }

  void clear_group()
  {
    group = ({});
  }

  void scale(int _min, int _max)
  {
    min_value = _min;
    max_value = _max;
  }

  string simple_encode()
  {
    return "s:" + low_simple_encode();
  }
  
  string low_simple_encode(void|int _max)
  {
    int vlen = sizeof(ALNUMS)-1;
    _max = _max || max_value;
    array(string) all_data = ({});
    array(string) data = ({});

    foreach (values, float value) {
      if (value >= 0.0)
	data += ({ ALNUMS[ (int)round(vlen * (value/_max)) ] });
      else
	data += ({ "_" });
    }

    all_data += ({ data*"" });

    if (sizeof(group))
      all_data += group->low_simple_encode();

    return all_data*",";
  }

  int(0..1) is_group()
  {
    return sizeof(group) > 0;
  }

  string get_scale()
  {
    array(string) data = ({ low_get_scale() });

    if (sizeof(group))
      data += group->low_get_scale();

    return "chds=" + (data*"|");
  }

  string low_get_scale()
  {
    return sprintf("%d,%d", min_value, max_value);
  }
  
  string get_color()
  {
    array clr = ({ color });
    if (sizeof(group))
      clr += group->color;
    return "chco=" + (clr*",");
  }
  
  string get_labels()
  {
    if (sizeof(labels))
      return "chl=" + labels*"|";
    
    return "";
  }
  
  string get_legend()
  {
    array l = ({ legend->text });
    if (sizeof(group))
      l += group->legend->text;

    string p = "";
    if (legend->position)
      p = "&amp;chdlp=" + legend->position;

    return "chdl=" + l*"|" + p;
  }

  void set_legend(string text, void|string position)
  {
    legend->text = text;
    if (position)
      legend->position = position;
  }

  mixed cast(string how)
  {
    array vals = map(values,
      lambda(float v) {
	return sprintf("%.1f", v); 
      }
    );

    switch (how)
    {
      case "string":
	string s = simple_encode() + "&amp;" +
	           get_scale()     + "&amp;" +
	           get_color();

	if (legend && legend->text)
	  s += "&amp;" + get_legend();
	
	if (sizeof(labels))
	  s += "&amp;" + get_labels();

	return "chd=" + s;

      case "array":
	return values;
    }
    
    error("Can't cast Data() to \"%s\"!\n", how);
  }

  string _sprintf(int t)
  {
    return t == 'O' && sprintf("Data(%s)", cast("string"));
  }
} // }}}
