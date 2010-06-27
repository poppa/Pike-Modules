/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This module executes the @tt{svn cat@} command which returns the content
//! of a version controlled file.
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//|
//| ============================================================================
//|
//|     GNU GPL version 3
//|
//| ============================================================================
//|
//| This file is part of SVN.pmod
//|
//| SVN.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| SVN.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with SVN.pmod. If not, see <http://www.gnu.org/licenses/>.

inherit .AbstractSVN;

private string contents;

//! Constructor
//!
//! @param path
//! @param revision
void create(string path, void|int revision)
{
  ::create(revision, path);
  contents = exec("cat", path, revision);
}

//! Returns the file contents
string get_contents()
{
  return contents;
}

