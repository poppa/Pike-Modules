/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Parameter collection class
//!
//! @seealso
//!  @[Param]
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Params.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Params.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Params.pike. If not, see <http://www.gnu.org/licenses/>.

#include "social.h"
#define Self Social.Params

//! The parameters.
protected array(.Param) params;

//! Creates a new instance of @[Params]
//!
//! @param args
//!  Arbitrary number of arguments.
void create(.Param ... args)
{
  params = args||({});
}

//! Sign the parameters
//!
//! @param secret
//!  The API secret
string sign(string secret)
{
  return .md5(sort(params)->name_value()*"" + secret);
}

//! Parameter keys
array _indices()
{
  return params->get_name();
}

//! Parameter values
array _values()
{
  return params->get_value();
}

//! Returns the array of @[Param]eters
array(.Param) get_params()
{
  return params;
}

//! Turns the parameters into a query string
string to_query()
{
  array o = ({});
  foreach (params, .Param p)
    o += ({ p->get_name() + "=" + .urlencode(p->get_value()) });

  return o*"&";
}

//! Turns the parameters into a mapping
mapping to_mapping()
{
  return mkmapping(params->get_name(), params->get_value());
}

Self add_mapping(mapping value)
{
  foreach (value; string k; mixed v)
    params += ({ .Param(k, (string)v) });

  return this;
}

//! Add @[p] to the array of @[Param]eters
//!
//! @param p
//!  Either a @[Param] or @[Params] object.
//!
//! @returns
//!  A new @[Params] object
object_program `+(.Param|object_program p)
{
  Self pp = object_program(this)(@params);
  pp += p;

  return pp;
}

//! Append @[p] to the @[Param]eters array of the current object
//!
//! @param p
//!  Either a @[Param] or @[Params] object.
object_program `+=(.Param|object_program p)
{
  if (INSTANCE_OF(p, this))
    params += p->get_params();
  else
    params += ({ p });
}

//! Index lookup
//!
//! @param key
//!  The name of a @[Param]erter to find.
.Param `[](string key)
{
  foreach (params, .Param p)
    if (p->get_name() == key)
      return p;
}

//! Clone the current instance
object_program clone()
{
  return object_program(this)(@params);
}

//! String format method
//!
//! @param t
string _sprintf(int t)
{
  return t == 'O' && sprintf("%O(%O)", object_program(this), params);
}

