//! Base class for @[Line] and @[Bar] charts.
inherit .Base;

//! Chart grid
protected .Grid grid;

//! Set a chart grid
//!
//! @param grid
//!  A @[Grid] object
void set_grid(.Grid _grid)
{
  grid = _grid;
}

//! Render the chart url
//!
//! @param data
string render_url(.Data data)
{
  string url = ::render_url(data);
  if (grid) url += "&amp;" + (string)grid;

  return url;
}
