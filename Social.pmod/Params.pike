/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Parameter collection class
//!
//! @seealso
//!  @[Param]

#include "social.h"
#define Self this_program

//! The parameters.
protected array(.Param) params;

//! Creates a new instance of @[Params]
//!
//! @param args
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

string to_unencoded_query()
{
  return params->name_value()*"&";
}

//! Turns the parameters into a query string
string to_query()
{
  array o = ({});
  foreach (params, .Param p)
    o += ({ .urlencode(p->get_name()) + "=" + .urlencode(p->get_value()) });

  return o*"&";
}

//! Turns the parameters into a mapping
mapping(string:mixed) to_mapping()
{
  return mkmapping(params->get_name(), params->get_value());
}

//! Add a mapping of key/value pairs to the current instance
//!
//! @param value
//!
//! @returns
//!  The object being called
Self add_mapping(mapping value)
{
  foreach (value; string k; mixed v)
    params += ({ .Param(k, (string)v) });

  return this;
}

//! Add @[p] to the array of @[Param]eters
//!
//! @param p
//!
//! @returns
//!  A new @[Params] object
Self `+(.Param|Self p)
{
  Self pp = object_program(this)(@params);
  pp += p;

  return pp;
}

//! Append @[p] to the @[Param]eters array of the current object
//!
//! @param p
Self `+=(.Param|Self|mapping p)
{
  if (mappingp(p)) {
    Self pp = Self();
    pp->add_mapping(p);
    p = pp;
  }

  if (INSTANCE_OF(p, this))
    params += p->get_params();
  else
    params += ({ p });

  return this;
}

//! Remove @[p] from the @[Param]eters array of the current object.
//!
//! @param p
Self `-(.Param|Self p)
{
  if (!p) return this;

  array(.Param) the_params;
  if (INSTANCE_OF(p, this))
    the_params = p->get_params();
  else
    the_params = ({ p });

  return object_program(this)(@(params-the_params));
}

//! Index lookup
//!
//! @param key
//! The name of a @[Param]erter to find.
.Param `[](string key)
{
  foreach (params, .Param p)
    if (p->get_name() == key)
      return p;

  return 0;
}

//! Clone the current instance
Self clone()
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

//! Casting method
//!
//! @param how
mixed cast(string how)
{
  switch (how) {
    case "mapping": return to_mapping();
    case "string": return to_query();
  }
}
