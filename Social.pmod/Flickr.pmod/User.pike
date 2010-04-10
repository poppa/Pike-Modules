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

protected string id;
protected string username;
protected string fullname;

void set_id(string _id)
{
  id = _id;
}

string get_id()
{
  return id;
}

void set_username(string _username)
{
  username = _username;
}

string get_username()
{
  return username;
}

void set_fullname(string _fullname)
{
  fullname = _fullname;
}

string get_fullname()
{
  return fullname;
}

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
