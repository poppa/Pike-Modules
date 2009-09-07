/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Bitly class@}
//!
//! This class communicates with @url{http://bit.ly@} which is a service to
//! shorten, track and share links.
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Social.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Social.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Social.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "Facebook.pmod/facebook.h"

#define INSTANCE_OF(A,B) (object_program((A)) == object_program((B)) || \
                          Program.inherits(object_program((A)),         \
			                   object_program(B)))

//! MD5 routine
//!
//! @param s
string md5(string s)
{
#if constant(Crypto.MD5)
  return String.string2hex(Crypto.MD5.hash(s));
#else
  return Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif
}

//! Parameter collection class
class Params
{
  //! The parameters.
  protected array(Param) params;

  //! Creates a new instance of @[Params]
  //!
  //! @param args
  void create(Param ... args)
  {
    params = args||({});
  }

  //! Sign the parameters
  //!
  //! @param secret
  //!  The API secret
  string sign(string secret)
  {
    //TRACE("@@@ Sign: %s\n", (sort(params)->name_value()*"")+secret);
    return md5(sort(params)->name_value()*"" + secret);
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
  array(Param) get_params()
  {
    return params;
  }
  
  //! Turns the parameters into a query string
  string to_query()
  {
    array o = ({});
    foreach (params, Param p)
      o += ({ p->get_name()+"="+Protocols.HTTP.uri_encode(p->get_value()) });

    return o*"&";
  }

  //! Turns the parameters into a mapping
  mapping to_mapping()
  {
    return mkmapping(params->get_name(), params->get_value());
  }
  
  //! Add @[p] to the array of @[Param]eters
  //!
  //! @param p
  Params `+(Param|Params p)
  {
    Params pp = Params(@params);
    pp += p;

    return pp;
  }

  Params `+=(Param|Params p)
  {
    if (INSTANCE_OF(p, this))
      params += p->get_params();
    else
      params += ({ p });
  }

  //! String format method
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O)", object_program(this), params);
  }
}

//! Representation of a parameter
class Param
{
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
    value = (string)_value;
    
    if (String.width(value) != 8) {
      werror("Not UTF-8 encoded value");
      catch( value = string_to_utf8(value) );
    }
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
    value = (string)_value;
  }

  //! Returns the name and value as querystring key/value pair
  string name_value()
  {
    return name + "=" + value;
  }
  
  //! Comparer method. Checks if @[other] equals this object
  //!
  //! @param other
  int(0..1) `==(mixed other)
  {
    if (object_program(other) != Param) return 0;
    if (name == other->get_name())
      return value == other->get_value();

    return 0;
  }

  //! Checks if this object is greater than @[other]
  //!
  //! @param other
  int(0..1) `>(mixed other)
  {
    if (object_program(other) != object_program(this)) return 0;
    if (name == other->get_name())
      return value > other->get_value();

    return name > other->get_name();
  }
  
  //! Checks if this object is less than @[other]
  //!
  //! @param other
  int(0..1) `<(mixed other)
  {
    if (object_program(other) != object_program(this)) return 0;
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
}