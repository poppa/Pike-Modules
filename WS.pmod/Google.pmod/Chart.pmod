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
//!
//!

/* NOTE! Still work in progress but works quite ok.
 */

//! URL at Google that generates the charts
constant BASE_URL   = "http://chart.apis.google.com/chart";

//! Base class for all types of charts
protected class Base // {{{
{
  protected int width   = 400;
  protected int height  = 300;
  protected string type;
  protected array(Axis) axes = ({});
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
  void create(string _type, void|int _width, void|int _height)
  {
    type = _type;
    if (_width) width = _width;
    if (_height) height = _height;
  }

  //! Add an axis to the chart
  void add_axis(Axis axis)
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
    title->text = text;
    title->size = size;
    title->color = color;
  }

  //! Render the chart url
  //!
  //! @param data
  string render_url(Data data)
  {
    array(Param) args = ({
      Param("chs", width, "x", height),
      Param("cht", type),
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

  //! Chart grid
  protected Grid grid;

  //! Set a chart grid
  //!
  //! @param x
  //!  This can be @[Grid] instance and if so the rest of the arguments
  //!  will be discarted, else the horizontal step size of the grid
  //! @param y
  //!  The vertical step size of the grid
  //! @param line_width
  //!  The width of the dashes
  //! @param space_width
  //!  The space between the dashes
  void set_grid(int|Grid x, int y, void|int line_width, void|int space_width)
  {
    if (objectp(x)) {
      grid = x;
      return;
    }

    grid = Grid(x, y, line_width, space_width);
  }

  //! Render the chart url
  //!
  //! @param data
  string render_url(Data data)
  {
    string url = ::render_url(data);
    if (grid)
      url += "&amp;" + (string)grid;

    return url;
  }
} // }}}

//! Class for creating line charts
class Line // {{{
{
  inherit BaseSimple;

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
  void create(string type, void|int width, void|int height)
  {
    if ( !(< LINES, SPARKLINES, POINTS >)[type] )
      error("Unknown line chart type \"%s\"!\n", type);

    ::create(type, width, height);
  }
} // }}}


//! Class for creating bar charts
class Bar // {{{
{
  inherit BaseSimple;

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
  array bar_params;

  //! Creates a new @[Bar] chart
  //!
  //! @param type
  //! @param width
  //! @param height
  void create(void|string type, void|int width, void|int height)
  {
    if (!type)
      type = VERTICAL_STACK;

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

//! Class for creating pie charts
class Pie
{
  inherit Base;

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
  void create(void|string type, void|int width, void|int height)
  {
    if ( type && !(< BASIC, THREE_DIMENTIONAL, CONCENTRIC >)[type] )
      error("Unknown pie chart type \"%s\"!\n", type);

    ::create(type||BASIC, width, height);
  }

  //! Render the chart URL
  //!
  //! @param data
  string render_url(Data data)
  {
    string url = ::render_url(data);

    if (orientation != 0.0)
      url += sprintf("&amp;chp=%.1f", orientation);

    return url;
  }
}

//! Class representing a chart legend
class Legend
{
  //! Places the legend horizontally at the bottom
  constant HORIZONTAL_BOTTOM = "b";

  //! Places the legend horizontally at the top
  constant HORIZONTAL_TOP = "t";

  //! Places the legend vertically at the bottom
  constant VERTICAL_BOTTOM = "bv";

  //! Places the legend vertically at the top
  constant VERTICAL_TOP = "tv";

  //! Places the legend vertically to the left
  constant VERTICAL_LEFT = "l";

  //! Places the legend vertically to the right
  constant VERTICAL_RIGHT = "r";

  //! The text of the legend
  string text;

  //! The legend position
  string position;

  //! Creates a new @[Legend] object
  //!
  //! @param _text
  //! @param _position
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

//! This class represents a chart axis
class Axis // {{{
{
  //! Places the axis at the bottom of the chart
  constant BOTTOM = "x";

  //! Places the axis at the top of the chart
  constant TOP    = "t";

  //! Places the axis at the left of the chart
  constant LEFT   = "y";

  //! Places the axis at the right of the chart
  constant RIGHT  = "r";

  //! Type of axis, @[BOTTOM], @[TOP], @[LEFT] or @[RIGHT]
  protected string type;

  //! Range
  protected Range  range;

  //! Labels
  protected array(Label) labels = ({});

  //! Creates a new @[Axis] object
  //!
  //! @param _type
  //!  Type of axis, @[BOTTOM], @[TOP], @[LEFT] or @[RIGHT]
  void create(string _type)
  {
    type = _type;
  }

  //! Set labels.
  //!
  //! @note
  //!  If you also want to set the position of the labels you have to call
  //!  @[add_label()].
  //!
  //! @param _labels
  void set_labels(array(string) _labels)
  {
    foreach (_labels, string label)
      add_label(label);
  }

  //! Add a label
  //!
  //! @param text
  //! @param position
  void add_label(string text, void|int|string position)
  {
    labels += ({ Label(text, (int)position) });
  }

  //! Set the range of the axis
  //!
  //! @param start
  //!  I.e, the minimum value
  //! @param end
  //!  I.e, the maximum value
  //! @param interval
  void set_range(int|float|string start, int|float|string end,
                void|int interval)
  {
    range = Range(start, end, interval);
  }

  //! Returns the axis type
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

//! Class for drawing chart grids
class Grid // {{{
{
  //! The distance between horizontal lines
  int x_axis_step;

  //! The distance between vertical lines
  int y_axis_step;

  //! The length of the line dashes
  int line_length;

  //! The length of the space between dashes
  int blank_length;

  //! Horizontal offset
  int x_offset;

  //! Vertical offset
  int y_offset;

  //! Creates a new @[Grid] object.
  //!
  //! @param x_step
  //! @param y_step
  //! @param line_len
  //! @param blank_len
  void create(int x_step, int y_step, void|int line_len, void|int blank_len)
  {
    x_axis_step = x_step;
    y_axis_step = y_step;

    if (line_len != UNDEFINED)
      line_length = line_len;

    if (blank_len != UNDEFINED)
      blank_length = blank_len;
  }

  //! Cast method.
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how)
    {
      case "string":
	array v = ({ x_axis_step, y_axis_step });
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

//! Chart data class
class Data // {{{
{
  //! Used to simple encode data
  protected constant ALNUMS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                              "abcdefghijklmnopqrstuvwxyz"
                              "0123456789"/1;

  //! Actual values
  protected array(float) values = ({});

  //! Data group
  protected array(Data)  group  = ({});

  //! Minimum value
  protected int min_value  = 0;

  //! Maximum value
  protected int max_value  = 100;

  //! Chart color of this data set
  protected string color   = "FFCC33";

  //! Data legend
  protected Legend legend  = Legend();

  //! Data labels
  protected array labels   = ({});


  //! Creates a new @[Data] object.
  //!
  //! @param ... args
  void create(int|float|string ... args)
  {
    values = map( args, lambda (int|float|string v){ return (float)v; } );
  }

  //! Appends to object.
  //!
  //! @param value
  //!  If @[value] is an instance of @[Data] a data group will be created.
  //!  Else @[value] will be appended to the internal data set.
  object `+(int|float|string|object value)
  {
    if (objectp(value)) {
      if (object_program(value) == object_program(this)) {
	value->set_scale(min_value, max_value);
	group += ({ value });
      }
    }
    else
      values += ({ (float)value });

    return this;
  }

  //! Set the color of the chart items this data set represents (pie slice,
  //! bar, line etc).
  //!
  //! @param _color
  //!  Hexadecimal, without #.
  void set_color(string _color)
  {
    color = _color;
  }

  //! Returns the color
  string get_color()
  {
    return color;
  }

  //! Clear the data group
  void clear_group()
  {
    group = ({});
  }

  //! Set the scale of the data values.
  //!
  //! @param _min
  //! @param _max
  void set_scale(int _min, int _max)
  {
    min_value = _min;
    max_value = _max;
  }

  //! Returns the minimum value
  int get_min()
  {
    return min_value;
  }

  //! Returns the maximum value
  int get_max()
  {
    return max_value;
  }

  //! Returns the labels
  array get_labels()
  {
    return labels;
  }


  //! Sets the legend for the data set
  //!
  //! @param text
  //! @param position
  //!  See @[Legend] for available positions
  void set_legend(string text, void|string|int position)
  {
    legend->text = text;
    if (position)
      legend->position = position;
  }

  //! Returns the legend
  Legend get_legend()
  {
    return legend;
  }

  // Simple encode the data.
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
      if (value > _max)
	value = (float)_max;

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

  //! Checks if this object is a group of @[Data] obejcts
  int(0..1) is_group()
  {
    return sizeof(group) > 0;
  }

  // Turs the @[min] and @[max] values into a query variable
  string scale_to_url()
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

  string color_to_url()
  {
    array clr = ({ color });
    if (sizeof(group))
      clr += group->get_color();
    return "chco=" + (clr*",");
  }

  string labels_to_url()
  {
    if (sizeof(labels))
      return "chl=" + labels*"|";

    return "";
  }

  string legend_to_url()
  {
    array l = ({ legend->text });
    if (sizeof(group))
      l += group->get_legend()->text;

    string p = "";
    if (legend->position)
      p = "&amp;chdlp=" + legend->position;

    return "chdl=" + l*"|" + p;
  }

  //! Cast method
  //!
  //! @param how
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
	           scale_to_url()  + "&amp;" +
	           color_to_url();

	if (legend && legend->text)
	  s += "&amp;" + legend_to_url();

	if (sizeof(labels))
	  s += "&amp;" + labels_to_url();

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
