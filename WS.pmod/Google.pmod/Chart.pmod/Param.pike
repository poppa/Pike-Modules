/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//| Class for creating pie charts
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| This file is part of Google.pmod
//|
//| Google.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Google.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Google.pmod. If not, see <http://www.gnu.org/licenses/>.

string name;
string value;

protected void create(string _name, mixed ... rest)
{
  name = _name;
  value = rest && map( rest, lambda(string s){ return (string)s; } )*"";
}

object_program `+(mixed val)
{
  if (!value) value = "";
  value += (string)val;

  return this;
}

mixed cast(string how)
{
  string r = name;
  if (value && sizeof(value))
    r += "=" + value;
  return r;
}

string _sprintf(int t)
{
  return t == 'O' && sprintf("Param(%O, %O)", name, value);
}
