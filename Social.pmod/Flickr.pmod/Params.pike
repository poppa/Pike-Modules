/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Collection of Flickr @[Param].
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Param.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Param.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Param.pike. If not, see <http://www.gnu.org/licenses/>.

#include "flickr.h"

inherit Social.Params;

//! Creates a new @[Params] object
//!
//! @param args
//!  Arbitrary number of @[Param] objects
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

//! Add a mapping of key/value pairs
//!
//! @param value
//!
//! @returns
//!  The object being called.
object_program add_mapping(mapping value)
{
  foreach (value; string k; mixed v)
    params += ({ .Param(k, (string)v) });

  return this;
}
