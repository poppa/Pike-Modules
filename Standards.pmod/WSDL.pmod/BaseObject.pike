/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This is the base class that all classes implementing a WSDL node (or type)
//! should inherit from.
//|
//| Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//|
//| License GNU GPL version 3
//|
//| BaseObject.pike is part of WSDL.pmod
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

//! The main WSDL object in which this instance recides
protected .Definitions owner_document;

//! The raw node attributes
protected mapping attributes = ([]);

//! The full node name, namespace prefix included
protected string ns_node_name;

//! The namespace prefix of the node
protected string ns_name;

//! The local name of the node
protected string node_name;

//! Documentation if any.
protected string documentation;

//! Create a new instance
//!
//! @param node
//! @param parent
protected void create(void|Parser.XML.Tree.Node node, void|.Definitions parent)
{
  owner_document = parent;

  if (node) {
    attributes = node->get_attributes();
    ns_node_name = node->get_full_name();
    node_name = node->get_tag_name();
    sscanf(ns_node_name, "%[^:]:%*s", ns_name);
    try_set_documentation(node);
    decode(node);
  }
}

//! Add an attribute
//!
//! @param name
//! @param value
void add_attribute(string name, string value)
{
  attributes[name] = value;
}

//! Add many attributes at once
//!
//! @param attr
void set_attributes(mapping attr)
{
  attributes = attr;
}

//! Returns the attributes
mapping get_attributes()
{
  return attributes;
}

//! Returns the full node name, namespace prefix included
string get_ns_node_name()
{
  return ns_node_name;
}

//! Returns the local node name
string get_node_name()
{
  return node_name;
}

//! Returns the namespace prefix
string get_ns_name()
{
  return ns_name;
}

//! Returns the documentation
string get_documentation()
{
  return documentation;
}

//! Returns the @[Definitions] object in which this instance recides
.Definitions get_owner_document()
{
  return owner_document;
}

protected void try_set_documentation(Parser.XML.Tree.Node n)
{
  foreach (n->get_children(), Parser.XML.Tree.Node cn)
    if (cn->get_tag_name() == "documentation")
      documentation = cn->value_of_node();
}

//! Decode an XML node
//!
//! @param node
protected void decode(Parser.XML.Tree.Node node)
{
  error("decode() not implemented in %O\n", object_program(this));
}

