//! Class representing a chart legend

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
