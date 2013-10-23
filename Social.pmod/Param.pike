/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Representation of a parameter.
//!
//! Many Social web services use a RESTful communication and have similiar
//! API's. This class is suitable for many RESTful web services and if this
//! class doesn't suite a particular service, just inherit this class and
//! rewrite the behaviour where needed.
//!
//! @seealso
//!  @[Params]

#include "social.h"
#define Self this_program

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
    if (mixed e = catch(value = string_to_utf8(value))) {
      werror("Warning: string_to_utf8() failed. Already encoded?\n%s\n",
	           describe_error(e));
    }
  }
}
