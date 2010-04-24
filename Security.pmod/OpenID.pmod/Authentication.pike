/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Authentication.pike@}
//!
//! This class represents a successful authentication returned from an OpenID
//! provider.
//! 
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Authentication.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Authentication.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License along 
//! with Authentication.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

private string identity;
private string email;
private string fullname;
private string firstname;
private string lastname;
private string language;
private string gender;

//! Returns the identity of the authentication. Most likely an URL.
string get_identity()
{
  return identity;
}

//! Sets the identity of the authentication
//!
//! @param _identity
void set_identity(string _identity)
{
  if (!_identity)
    error("Identity can not be null! ");
  identity = _identity;
}

//! Returns the email of the authentication
string get_email()
{
  return email;
}

//! Sets the email of the authentication
void set_email(string _email)
{
  email = _email;
}

//! Returns the full name of the authenticated user
string get_fullname()
{
  return fullname;
}

//! Sets the full name of the authentication
//!
//! @param _fullname
void set_fullname(string _fullname)
{
  fullname = _fullname;
}

//! Returns the given name of the authenticated user
string get_firstname()
{
  return firstname;
}

//! Sets the given name of the authentication
//!
//! @param _firstname
void set_firstname(string _firstname)
{
  firstname = _firstname;
}

//! Returns the last name of the authenticated user
string get_lastname()
{
  return lastname;
}

//! Sets the last name of the authentication
//!
//! @param _lastname
void set_lastname(string _lastname)
{
  lastname = _lastname;
}

//! Returns the locale of the authentication
string get_language()
{
  return language;
}

//! Sets the locale of the authentication
//!
//! @param _language
void set_language(string _language)
{
  language = _language;
}

//! Returns the gender of the authenticated user
string get_gender()
{
  return gender;
}

//! Sets the gender of the authentication
//!
//! @param _gender
void set_gender(string _gender)
{
  gender = _gender;
}

//! Turns the object members into a mapping and encodes it with Pike's
//! @[predef::encode_value()]
string encode_cookie()
{
  return encode_value(to_mapping());
}

//! Populates the object from a cookie created with @[encode_cookie()]
//!
//! @param cookie
object_program decode_cookie(string cookie)
{
  return from_mapping(decode_value(cookie));
}

//! Populates the object from a mapping with the same indices as this object
//!
//! @param m
//!
//! @returns
//!  The instance of self
object_program from_mapping(mapping m)
{
  mixed e = catch {
    foreach (m; string k; string v) {
      switch (k)
      {
      	case "identity":  identity  = v; break;
      	case "gender":    gender    = v; break;
      	case "language":  language  = v; break;
      	case "email":     email     = v; break;
      	case "fullname":  fullname  = v; break;
      	case "firstname": firstname = v; break;
      	case "lastname":  lastname  = v; break;
      }
    }
  };

  if (e) error("Failed to decode mapping: %s\n", describe_error(e));
  return this;  
}

//! Casting method. Only supports mapping
//!
//! @param how
mixed cast(string how)
{
  if (how == "mapping")
    return to_mapping();
  
  error("Can't cast %O to %O\n", object_program(this), how);
}

//! Turns the object members into a mapping
mapping to_mapping()
{
  return ([
    "identity"  : identity,
    "gender"    : gender,
    "language"  : language,
    "email"     : email,
    "fullname"  : fullname,
    "firstname" : firstname,
    "lastname"  : lastname
  ]);
}

string _sprintf(int t)
{
  return t == 'O' && sprintf("%O(identity: %O, "
                             "email: %O, "
                             "fullname: %O, "
                             "firstname: %O, "
                             "lastname: %O, "
                             "language: %O, "
                             "gender: %O)",
                             object_program(this),
                             identity,
                             email,
                             fullname,
                             firstname,
                             lastname,
                             language,
                             gender);
}
