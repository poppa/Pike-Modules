/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents a message node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Message.pike is part of WSDL.pmod
//|
//| WSDL.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| WSDL.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with WSDL.pmod. If not, see <http://www.gnu.org/licenses/>.

import Parser.XML.Tree;
inherit .BaseObject;

//! The name of the message
string name;

//! The message parts
array(.Part) parts = ({});

//! The order of the parts
array(string) part_order = ({});

//! Decodes a message node
//!
//! @param n
protected void decode(Node n)
{
  name = n->get_attributes()->name;
  foreach (n->get_children(), Node cn) {
    if (cn->get_tag_name() == "part") {
      .Part p = .Part(cn, owner_document);
      parts += ({ p });
      part_order += ({ p->name });
    }
  }
}
