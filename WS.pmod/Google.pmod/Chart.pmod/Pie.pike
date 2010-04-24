//! Class for creating pie charts

inherit .Base;

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
void create(void|string _type, void|int width, void|int height)
{
  type = _type || BASIC;
  if ( type && !(< BASIC, THREE_DIMENTIONAL, CONCENTRIC >)[type] )
    error("Unknown pie chart type \"%s\"!\n", type);

  ::create(type, width, height);
}

//! Render the chart URL
//!
//! @param data
string render_url(.Data data)
{
  string url = ::render_url(data);

  if (orientation != 0.0)
    url += sprintf("&amp;chp=%.1f", orientation);

  return url;
}

