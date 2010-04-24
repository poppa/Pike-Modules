//! Class for drawing chart grids

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
void create(int x_step, int y_step, void|int line_len, void|int blank_len,
	    void|int xoffset, void|int yoffset)
{
  x_axis_step = x_step;
  y_axis_step = y_step;

  if (line_len != UNDEFINED)
    line_length = line_len;

  if (blank_len != UNDEFINED)
    blank_length = blank_len;

  if (xoffset != UNDEFINED)
    x_offset = xoffset;

  if (yoffset != UNDEFINED)
    y_offset = yoffset;
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

      string s = "chg=" + map(v, lambda(int s) { return (string)s; } )*",";

      return s;
  }

  error("Can't cast Grid to %O!\n", how);
}
