/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [PROG-NAME].pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [PROG-NAME].pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [PROG-NAME].pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "flickr.h"

inherit Social.Params;

void create(.Param ... args)
{
  ::create(@args);
}

//! Sign the parameters
//!
//! @param secret
//!  The API secret
string sign(string secret)
{
  return Social.md5(secret + sort(params)->name_value()*"");
}

object_program add_mapping(mapping value)
{
  foreach (value; string k; mixed v)
    params += ({ .Param(k, (string)v) });

  return this;
}
