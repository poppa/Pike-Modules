/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Standards.WSDL.PortType@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! This class represents a schema node of a WSDL document
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Schema.pike is part of WSDL.pmod
//!
//! WSDL.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! WSDL.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with WSDL.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "wsdl.h"

// QName
import Standards.XML.Namespace;
import Parser.XML.Tree;
inherit .BaseObject;

//! Schema target namespace
QName target_namespace;

//! The elementFormDefault attribute
string element_form_default;

//! The attributeFormDefault attribute
string attribute_form_default;

//! Complex types
array  complex_types = ({});

//! Simple types
array  simple_types = ({});

//! Elements
array  elements = ({});

//! Imports
array  imports = ({});

//! Returns the type with name @[name]
object get_element(string name)
{
  foreach (get_all_elements(), object e) {
    if (e->name && e->name == name)
      return e;
  }

  return 0;
}

//! Returns all types
array(object) get_all_elements()
{
  return complex_types + simple_types + elements + imports;
}

//! Decodes the schema node
//!
//! TODO: Handle @tt{<import/>@} nodes.
protected void decode(Node n)
{
  mapping a = n->get_attributes();

  if (a) {
    target_namespace = QName(a->targetNamespace, "targetNamespace");
    element_form_default = a->elementFormDefault;
    attribute_form_default = a->attributeFormDefault;
  }

  foreach (n->get_children(), Node cn) {
    if (cn->get_node_type() == XML_ELEMENT) {
      mapping a = cn->get_attributes();
      string tag = cn->get_tag_name();

      switch (tag)
      {
	case "complexType":
	  complex_types += ({ .Types.ComplexType(cn, owner_document) });
	  break;

	case "element":
	  elements += ({ .Types.Element(cn, owner_document) });
	  break;

	case "simpleType":
	  simple_types += ({ .Types.SimpleType(cn, owner_document) });
	  break;

	default:
	  TRACE("Unhandled node in schema: %O\n", cn);
      }
    }
  }
}
