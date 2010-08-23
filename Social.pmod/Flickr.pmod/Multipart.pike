/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Simple multipart message
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Multipart.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Multipart.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Multipart.pike. If not, see <http://www.gnu.org/licenses/>.

//! Message headers
mapping headers = ([]);

//! Message boundary
string boundary;

//! Message data
string data;

//! Creates a new message object
//!
//! @param _data
void create(void|string _data)
{
  if (_data)
    data = _data;
}

//! Setter for message content type
//!
//! @param v
void set_content_type(string v)
{
  headers["Content-Type"] = v;
}

//! Setter for message content disposition
//!
//! @param v
void set_content_disposition(string v)
{
  headers["Content-Disposition"] = v;
}

//! Setter for message data
//!
//! @param v
void set_data(string v)
{
  data = v;
}

//! Setter for message boundary
//!
//! @param v
void set_boundary(string v)
{
  boundary = v;
}

//! Cast method. Only supports casting to string
//!
//! @param how
mixed cast(string how)
{
  if (how == "string") {
    string o = "";
    foreach (headers; string k; string v)
      o += k + ": " + v + "\r\n";

    o += "\r\n" + data + "\r\n";

    if (boundary)
      o += "--" + boundary + "\r\n";

    return o;
  }
  
  error("Can't cast %O to %s\n", object_program(this), how);
}
