/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents a service node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Service.pike is part of WSDL.pmod
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

//! The service ports. The key is the name attribute of the port node
mapping(string:.Port) ports = ([]);

//! Returns the SOAP port, i.e. the port with a namespace prefix corresponding
//! to the wsdl soap namespace uri
.Port get_soap_port()
{
  return get_port_by_type(owner_document->get_wsdl_soap_namespace()
                                        ->get_local_name());
}

//! Returns the port with the namepspace prefix @[type].
//!
//! @param type
//!  A namespace prefix. If, for instance, there's a HTTP port that port would
//!  most likely be resolved by @tt{service->get_port_by_type("http")@}.
.Port get_port_by_type(string type)
{
  foreach (values(ports), .Port p)
    if (p->address->get_ns_name() == type)
      return p;
}

//! Returns the port with the name attribute value @[name]
//!
//! @param name
.Port get_port(string name)
{
  return ports[name];
}

protected void decode(Node n)
{
  name = n->get_attributes()->name;
  foreach (n->get_children(), Node cn)
    if (cn->get_tag_name() == "port")
      ports[cn->get_attributes()->name] = .Port(cn, owner_document);
}
