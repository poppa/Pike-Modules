/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Base class for @[Line] and @[Bar] charts.
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| This file is part of Google.pmod
//|
//| Google.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Google.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Google.pmod. If not, see <http://www.gnu.org/licenses/>.

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
