/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Representation of a Flickr user
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

protected string id;
protected string username;
protected string fullname;

//! Setter for the user id
//!
//! @param _id
void set_id(string _id)
{
  id = _id;
}

//! Getter for the user id.
string get_id()
{
  return id;
}

//! Setter for the user name
//! 
//! @param _username
void set_username(string _username)
{
  username = _username;
}

//! Getter for the user name
string get_username()
{
  return username;
}

//! Setter for the user's full name
//!
//! @param _fullname
void set_fullname(string _fullname)
{
  fullname = _fullname;
}

//! Getter for the user's fullname
string get_fullname()
{
  return fullname;
}

//! Populates this object from the mapping @[m]
//! 
//! @param m
//!  The mapping should look like
//!  @mapping
//!   @member string "id"
//!    User's id. Same as nsid
//!   @member string "nsid"
//!    User's id
//!   @member string "username"
//!   @member string "fullname"
//!  @endmapping
//!
//! @returns
//!  The object being called
object_program from_mapping(mapping m)
{
  foreach (m||([]); string k; string v) {
    switch (k)
    {
      case "id": /* fall through */
      case "nsid":     id       = v; break;
      case "username": username = v; break;
      case "fullname": fullname = v; break;
    }
  }

  return this;
}

//! Casting method.
//!
//! @note
//!  Only supports casting to @tt{mapping@}.
mixed cast(string how)
{
  if (how != "mapping")
    error("Can't cast %O to %O! ", object_program(this), how);
  
  return ([
    "id" : id,
    "username" : username,
    "fullname" : fullname
  ]);
}

string _sprintf(int t)
{
  return t == 'O' && sprintf("%O(%O, %O, \"%s\")", object_program(this),
                             id, username, fullname||"");
}
