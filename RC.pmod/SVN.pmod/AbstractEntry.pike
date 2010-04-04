/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [PROG-NAME].pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [MODULE-NAME].pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [PROG-NAME].pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

import Parser.XML.Tree;

inherit .AbstractSVN;

protected string author;
protected Calendar.Fraction date;

string get_author()
{
  return author;
}

Calendar.Fraction get_date()
{
  return date;
}

void set_from_xml(Node n);

void _handle_author(Node n)
{
  author = n->value_of_node();
}

void _handle_date(Node n)
{
  date = Calendar.parse("%Y-%M-%DT%h:%m:%s.%f%z", n->value_of_node());
}

void _handle_commit(Node n)
{
  revision = (int)n->get_attributes()["revision"];
  ::parse_xml(n);
}
