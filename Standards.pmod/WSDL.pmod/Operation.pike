/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents an operation node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Operation.pike is part of WSDL.pmod
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

//! Operation types
enum OperationType {
  NONE,
  WSDL,
  SOAP,
  HTTP
};

//! Type of operation
int type = NONE;

//! The operation name
string name;

//! The operation style
string style;

//! The SOAP action
string soap_action;

//! The location
string location;

//! Parameter order
array parameter_order = ({});

//! The input node of the operation
Input input;

//! The output node of the operation
Output output;

//! The fault node of the operation
Fault fault;

//! Decodes an operation node
//!
//! @param n
protected void decode(Node n)
{
  string wsdl, soap, http;
  wsdl = owner_document->get_wsdl_namespace()->get_local_name();
  soap = owner_document->get_wsdl_soap_namespace()->get_local_name();
  http = owner_document->get_wsdl_http_namespace()->get_local_name();

  if (ns_name == wsdl)
    type = WSDL;
  else if (ns_name == soap)
    type = SOAP;
  else if (ns_name == http)
    type = HTTP;

  mapping a = n->get_attributes();
  name      = a->name;
  if (a->parameterOrder)
    parameter_order = a->parameterOrder/" ";

  foreach (n->get_children(), Node cn) {
    if (cn->get_node_type() == XML_ELEMENT) {
      switch (cn->get_tag_name()) 
      {
	case "input":
	  input = Input(cn, owner_document);
	  break;

	case "output":
	  output = Output(cn, owner_document);
	  break;

	case "fault":
	  fault = Fault(cn, owner_document);
	  break;

	case "operation":
	  mapping ca = cn->get_attributes();
	  soap_action = ca->soapAction;
	  style = ca->style;
	  location = ca->location;
	  break;
      }
    }
  }
}

//! Class representing an input node
//!
//! TODO: Document this better!
class Input
{
  inherit .BaseObject;

  //! The message
  QName message;
  
  //string prefix;

  //! The use attribute
  string use;
  
  //! The body prefix
  string body_prefix;
  
  //! The encoding style
  string encoding_style;
  
  //! The namespace
  string namespace;

  protected void decode(Node n)
  {
    //sscanf(n->get_attributes()->message||"", "%[^:]:%s", prefix, message);
    mapping a = n->get_attributes();
    message = a->message && QName("", a->message);

    if (Node cn = n->get_first_element()) {
      if (cn->get_tag_name() == "body") {
	sscanf(cn->get_full_name(), "%[^:]:%*s", body_prefix);
	mapping a = cn->get_attributes();
	use = a->use;
	encoding_style = a->encodingStyle;
	namespace = a->namespace;
      }
    }
  }
}

//! Class representing an output node
class Output
{
  inherit Input;
}

//! Class representing a fault node
class Fault
{
  inherit .BaseObject;

  //! The node name attribute
  string name;
  
  //! The use attribute
  string use;
  
  protected void decode(Node n)
  {
    name = n->get_attributes()->name;
    if (n = n->get_first_element()) {
      if (n->get_tag_name() == "fault")
	use = n->get_attributes()->use;
    }
  }
}
