/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents a porttype node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| PortType.pike is part of WSDL.pmod
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

//! The name attribute of the node
string name;

//! The operations. The key is the name attribute of the operation node
mapping(string:.Operation) operations = ([]);

//! Decodes the porttype node
protected void decode(Node n)
{
  mapping a = n->get_attributes();
  name = a && a->name;

  foreach (n->get_children(), Node cn)
    if (cn->get_tag_name() == "operation")
      operations[cn->get_attributes()->name] = .Operation(cn, owner_document);
}
