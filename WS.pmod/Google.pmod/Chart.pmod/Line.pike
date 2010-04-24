//! Class for creating line charts
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
