/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents an import node of a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Import.pike is part of WSDL.pmod
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

//! The namespace attribute
string namespace;

//! The location attribute
Standards.URI location;

//! The imported schema
.Schema schema;

.Definitions definitions;

//! Decodes an import node
protected void decode(Node n)
{
  mapping a = n->get_attributes();
  namespace = a->namespace;
  string loc = a->location || a->schemaLocation;
  if (loc) {
    string xml;
    if (!catch(location = Standards.URI(loc))) {
      if (mixed e = catch(xml = .get_cache(location)))
	werror("Import error: %s\n", describe_error(e));
      else {
	if (!catch(Node n = parse_input(xml))) {
	  if (n = .find_root(n)) {
	    switch (n->get_tag_name())
	    {
	      case "schema":
		schema = .Schema(n, owner_document);
		break;

	      case "definitions":
		definitions = Standards.WSDL.Definitions(n);
		break;

	      default:
		error("Unhandled node in %O->decode()\n", object_program(this));
	    }
	  }
	}
	else {
	  error("Failed parsing XML input\n");
	}
      }
    }
  }
}