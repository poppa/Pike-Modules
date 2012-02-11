/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Representation of a parameter.
//!
//! Many Social web services use a RESTful communication and have similiar 
//! API's. This class is suitable for many RESTful web services and if this 
//! class doesn't suite a particular service, just inherit this class and 
//! rewrite the behaviour where needed.
//!
//! @seealso
//!  @[Params]
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

#include "social.h"
#define Self Social.Param

//! The name of the parameter
protected string name;

//! The value of the parameter
protected string value;

//! Creates a new instance of @[Param]
//!
//! @param _name
//! @param _value
void create(string _name, mixed _value)
{
  name = _name;
  low_set_value((string)_value);
}

//! Getter for the parameter name
string get_name()
{
  return name;
}

//! Setter for the parameter name
//!
//! @param _name
void set_name(string _name)
{
  name = _name;
}

//! Getter for the parameter value
string get_value()
{
  return value;
}

//! Setter for the parameter value
//!
//! @param _value
void set_value(mixed _value)
{
  low_set_value((string)_value);
}

//! Returns the name and value as querystring key/value pair
string name_value()
{
  return name + "=" + value;
}

//! Same as @[name_value()] except this URL encodes the value.
string name_value_encoded()
{
  return .urlencode(name) + "=" + .urlencode(value);
}

//! Comparer method. Checks if @[other] equals this object
//!
//! @param other
int(0..1) `==(mixed other)
{
  //if (object_program(other) != object_program(this)) return 0;
  if (!INSTANCE_OF(this, other)) return 0;
  if (name == other->get_name())
    return value == other->get_value();

  return 0;
}

//! Checks if this object is greater than @[other]
//!
//! @param other
int(0..1) `>(mixed other)
{
  //if (object_program(other) != object_program(this)) return 0;
  if (!INSTANCE_OF(this, other)) return 0;
  if (name == other->get_name())
    return value > other->get_value();

  return name > other->get_name();
}

//! Checks if this object is less than @[other]
//!
//! @param other
int(0..1) `<(mixed other)
{
  //if (object_program(other) != object_program(this)) return 0;
  if (!INSTANCE_OF(this, other)) return 0;
  if (name == other->get_name())
    return value < other->get_value();

  return name < other->get_name();
}

//! String format method
//!
//! @param t
string _sprintf(int t)
{
  return t == 'O' && sprintf("%O(%O,%O)", object_program(this), name, value);
}

//! Makes sure @[v] to set as @[value] is in UTF-8 encoding
//!
//! @param v
private void low_set_value(string v)
{
  value = v;
  if (String.width(value) < 8) {
    werror(">>> UTF-8 encoding value in Param(%O, %O)\n", name, value);
    if (mixed e = catch(value = string_to_utf8(value))) {
      werror("Warning: string_to_utf8() failed. Already encoded?\n%s\n",
	     describe_error(e));
    }
  }
}
