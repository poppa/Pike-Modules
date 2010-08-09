/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents a port node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Port.pike is part of WSDL.pmod
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
import Standards.XML.Namespace;
inherit .BaseObject;

//! The name attribute of the node
string name;

//! The corresponding WSDL bidning
QName binding;

//! The port address
Address address;

//! Decodes the port node
protected void decode(Node n)
{
  mapping a = n->get_attributes();
  name = a && a->name;
  binding = a && a->binding && QName("", a->binding);

  foreach (n->get_children(), Node cn) {
    if (cn->get_tag_name() == "address") 
      address = Address(cn, owner_document);
  }
}

//! Class representing the address child node of a port node
class Address
{
  inherit .BaseObject;
  
  //! The service endpoint
  string location;

  //! Decodes the address node
  protected void decode(Node n)
  {
    location = n->get_attributes()->location;
  }
}
