/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! SOAP parameter class
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| SimpleSOAP.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| SimpleSOAP.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with SimpleSOAP.pmod. If not, see
//| <http://www.gnu.org/licenses/>.

string name;
mixed value;
object|program|function type;
string encoding_style_uri;

void create(string _name, mixed _value, object|program|function _type, 
            void|string _encoding_style_uri)
{
  name = _name;
  value = _value;
  type = _type;
  encoding_style_uri = _encoding_style_uri;
}