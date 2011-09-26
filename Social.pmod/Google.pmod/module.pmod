/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! [MODULE-NAME]
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| [MODULE-NAME].pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| [MODULE-NAME].pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with [MODULE-NAME].pmod. If not, see <http://www.gnu.org/licenses/>.

#include "google.h"

constant USER_AGENT = "Pike Google Client 1.0 (Pike " + __VERSION__ + ")";

//! Parameter collection class
class Params
{
  inherit Social.Params;

  //! Creates a new instance of @[Params]
  //!
  //! @param args
  //!  Arbitrary number of @[Param] objects.
  void create(Param ... args)
  {
    ::create(@args);
  }
}

//! Representation of a parameter
class Param
{
  inherit Social.Param;

  //! Creates a new instance of @[Param]
  //!
  //! @param name
  //! @param value
  void create(string name, mixed value)
  {
    ::create(name, value);
  }
}
