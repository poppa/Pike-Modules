/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! SVN entry base class
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| AbstractEntry.pike free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| AbstractEntry.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with AbstractEntry.pike. If not, see <http://www.gnu.org/licenses/>.

import Parser.XML.Tree;

inherit .AbstractSVN;

protected string author;
protected Calendar.Fraction date;

//! Returns the author
string get_author()
{
  return author;
}

//! Returns the date
Calendar.Fraction get_date()
{
  return date;
}

// This abstract method should populate the object from an XML node
void set_from_xml(Node n);

// Callback for the author node
void _handle_author(Node n)
{
  author = n->value_of_node();
}

//! Handle date node
void _handle_date(Node n)
{
  date = Calendar.parse("%Y-%M-%DT%h:%m:%s.%f%z", n->value_of_node());
}

//! Handle the commit node
void _handle_commit(Node n)
{
  revision = (int)n->get_attributes()["revision"];
  ::parse_xml(n);
}

