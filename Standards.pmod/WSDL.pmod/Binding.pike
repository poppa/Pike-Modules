/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents a binding node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| This class represents a binding node of a WSDL document
//|
//| License GNU GPL version 3
//|
//| Binding.pike is part of WSDL.pmod
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

//! Binding types
enum BindingType {
  NONE,
  WSDL,
  SOAP,
  HTTP
};

//! Type of binding
int binding_type = NONE;

//! The name of the binding
string name;

//! The type attribute of the binding
QName  type;

//! The transport attribute of the binding
string transport;

//! The verb attribute of the binding
string verb;

//! The style attribute of the binding
string style;

//! The operations of the binding
mapping(string:.Operation) operations = ([]);

string get_transport_type()
{
  werror("get_transport_type(%O)\n", type);
  switch (binding_type)
  {
    case WSDL: return "WSDL";
    case SOAP: return "SOAP";
    case HTTP: return "HTTP/S";
  }
}

//! Decodes a binding node
protected void decode(Node n)
{
  string wsdl, soap, http;
  wsdl = owner_document->get_wsdl_namespace()->get_local_name();
  soap = owner_document->get_wsdl_soap_namespace()->get_local_name();
  http = owner_document->get_wsdl_http_namespace()->get_local_name();

  mapping a = n->get_attributes();
  name = a->name;
  type = a->type && QName("", a->type);

  if (type) {
    if (QName p = owner_document->get_namespace(type->get_prefix()))
      type->set_namespace_uri(p->get_namespace_uri());
  }

  foreach (n->get_children(), Node cn) {
    if (cn->get_node_type() == XML_ELEMENT) {
      switch (cn->get_tag_name())
      {
	case "operation":
	  operations[cn->get_attributes()->name] = 
	    .Operation(cn, owner_document);
	  break;

	case "binding":
	  mapping ca = cn->get_attributes();
	  style = ca->style;
	  transport = ca->transport;
	  verb = ca->verb;
	  string _ns = .get_ns_from_uri(transport);
	  if (_ns == wsdl)
	    binding_type = WSDL;
	  else if (_ns == soap)
	    binding_type = SOAP;
	  else if (_ns == http)
	    binding_type = HTTP;
	  break;
      }
    }
  }
}
