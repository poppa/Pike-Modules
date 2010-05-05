//! Places the axis at the bottom of the chart
constant BOTTOM = "x";

//! Places the axis at the top of the chart
constant TOP    = "t";

//! Places the axis at the left of the chart
constant LEFT   = "y";

//! Places the axis at the right of the chart
constant RIGHT  = "r";

//!
constant DRAWING_CONTROL_LINE_ONLY            = 0;

//!
constant DRAWING_CONTROL_TICK_MARKS_ONLY      = 1;

//!
constant DRAWING_CONTROL_LINES_AND_TICK_MARKS = 2;

//!
constant STYLE_ALIGN_LEFT   = -1;

//!
constant STYLE_ALIGN_CENTER =  0;

//!
constant STYLE_ALIGN_RIGHT  =  1;

//! Hidden module constructor
protected void create(mixed ... args) { }

//! Creates a new Axis object
//!
//! @param type
//!  Where to place the axis: @[BOTTOM], @[TOP], @[LEFT] or @[RIGHT]
Axis `()(string type)
{
  return Axis(type);
}

//! This class represents a chart axis
class Axis // {{{
{
  //! Type of axis, @[BOTTOM], @[TOP], @[LEFT] or @[RIGHT]
  protected string type;

  //! Range
  protected Range range;

  //! The style of labels
  protected Style style;

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
  
  //! Returns the range object
  Range get_range_object()
  {
    return range;
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

  //! Set the style of the labels
  //!
  //! @param style_or_color
  //!  Either an entire @[Style] object, or the label color
  //! @param size
  //!  The font size of the labels
  //! @param alignment
  //!  See @[STYLE_ALIGN_LEFT], @[STYLE_ALIGN_CENTER] and @[STYLE_ALIGN_RIGHT]
  void set_style(Style|string style_or_color, void|int size,
                 void|int(-1..1) alignment)
  {
    if (objectp(style_or_color))
      style = style_or_color;
    else
      style = Style(style_or_color, size, alignment);
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
  
  string get_style()
  {
    return style && style->get()||"";
  }
  
  int get_tick_mark_length()
  {
    return style && style->get_tick_mark_length();
  }
} // }}}

//! Axis label
class Label
{
  //! The label text
  string text;
  
  //! The label position
  //! See @[STYLE_ALIGN_LEFT], @[STYLE_ALIGN_CENTER] and @[STYLE_ALIGN_RIGHT]
  string position;

  //! Creates a new Lable
  //!
  //! @param _text
  //! @param _position
  //!  See @[STYLE_ALIGN_LEFT], @[STYLE_ALIGN_CENTER] and @[STYLE_ALIGN_RIGHT]
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

//! Axis range
class Range
{
  //! Start of range
  int start;
  
  //! End of range
  int end;
  
  //! Range interval
  int interval;

  //! Creates a new Range object
  //!
  //! @param _start
  //! @param _end
  //! @param _interval
  void create(int|float|string _start, int|float|string _end,
	      void|int _interval)
  {
    start    = (int)_start;
    end      = (int)_end;
    interval = (int)_interval;
  }

  //! Returns the URL parameter value for this object
  //! Consider this a proteced method
  string get()
  {
    string s = sprintf("%d,%d", start, end);
    if (interval)
      s += "," + (string)interval;
    return s;
  }
}

//! Axis label style
class Style
{
  //! Color
  string color;
  
  //! Font size
  int size = 11;
  
  //! Alignment
  //! See @[STYLE_ALIGN_LEFT], @[STYLE_ALIGN_CENTER] and @[STYLE_ALIGN_RIGHT]
  int(-1..1) alignment = -1;
  
  //! Drawing control
  string drawing_control;
  
  //! Tick mark color
  string tick_mark_color;
  
  //! Tick mark length
  int tick_mark_length;

  //! Creates a new Style object
  //!
  //! @param _color
  //! @param _size
  //! @param _alignment
  //!  See @[STYLE_ALIGN_LEFT], @[STYLE_ALIGN_CENTER] and @[STYLE_ALIGN_RIGHT]
  void create(string _color, void|int _size, void|int(-1..1) _alignment)
  {
    color            = .normalize_color(_color);
    size             = _size||12;
    alignment        = _alignment||0;
  }

  //! Set the color of the tick marks
  //!
  //! @param color
  //!
  //! @returns
  //!  The current object
  object_program set_tick_mark_color(string color)
  {
    tick_mark_color = color;
    return this;
  }

  //! Set the length of the tick marks
  //!
  //! @param len
  //!
  //! @returns
  //!  The current object
  object_program set_tick_mark_length(int len)
  {
    tick_mark_length = len;
    return this;
  }

  //! Set the drawing contol
  //!
  //! @param type
  //!
  //! @returns
  //!  The current object
  object_program set_drawing_control(string|int type)
  {
    if (intp(type)) {
      switch (type)
      {
	case DRAWING_CONTROL_LINE_ONLY:
	  type = "l";
	  break;

	case DRAWING_CONTROL_TICK_MARKS_ONLY:
	  type = "t";
	  break;

	case DRAWING_CONTROL_LINES_AND_TICK_MARKS:
	default:
	  type = "lt";
	  break;
      }
    }

    if ( !(< "l","t","lt" >)[type] ) {
      error("Bad value to %O()->set_drawing_control(). "
	    "Got %O, expected \"l\", \"t\" or \"lt\"!\n",
	    object_program(this), type);
    }

    drawing_control = type;
    return this;
  }

  //! Getter for the tick mark length
  int get_tick_mark_length()
  {
    //werror("Get tick mark length: %d\n", tick_mark_length);
    return tick_mark_length;
  }
  
  //! Returns the URL parameter values for this object.
  //! Consider protected
  string get()
  {
    array values = map(({
      color,
      size,
      (string)alignment,
      drawing_control,
      tick_mark_color || (tick_mark_length && color)
    }) - ({ 0 }), lambda(mixed v) { return (string)v; } );

    return values*",";
  }
}
