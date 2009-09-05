/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Standards.WSDL.Types.pmod@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! This module handles WSDL types, i.e the child nodes of a schema node
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Types.pmod is part of WSDL.pmod
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

import Parser.XML.Tree;
import Standards.XML.Namespace;

//! Node is @tt{<any/>@}
constant TYPE_ANY = 1<<0;

//! Node is @tt{<all/>@}
constant TYPE_ALL = 1<<1;

//! Node is @tt{<attribute/>@}
constant TYPE_ATTRIBUTE = 1<<2;

//! Node is @tt{<choise/>@}
constant TYPE_CHOISE = 1<<3;

//! Node is @tt{<complexContent/>@}
constant TYPE_COMPLEX_CONTENT = 1<<4;

//! Node is @tt{<complexType/>@}
constant TYPE_COMPLEX_TYPE = 1<<5;

//! Node is @tt{<.../>@}
constant TYPE_CONTENT = 1<<6;

//! Node is @tt{<element/>@}
constant TYPE_ELEMENT = 1<<7;

//! Node is @tt{<restriction/>@}
constant TYPE_RESTRICTION = 1<<8;

//! Node is @tt{<sequence/>@}
constant TYPE_SEQUENCE = 1<<9;

//! Node is @tt{<simpleType/>@}
constant TYPE_SIMPLE_TYPE = 1<<10;

//! Resolves the class that should be used to decode the node @[n]
//!
//! @param n
protected object resolv_class(Parser.XML.Tree.Node n)
{
  switch (n->get_tag_name())
  {
    case "any":            return Any;
    case "all":            return All;
    case "complexType":    return ComplexType;
    case "choise":         return Choise;
    case "element":        return Element;
    case "sequence":       return Sequence;
    case "complexContent": return ComplexContent;
    case "attribute":      return Attribute;
    case "restriction":    return Restriction;
    case "simpleType":     return SimpleType;
    default:               return Type;	
  }
}

//! Cache of namespaces resolved from 
//! @[Standards.WSDL.BaseObject()->owner_document] which is an instance of 
//! @[Standards.WSDL.Definitions]
protected mapping(string:QName) ns_cache = ([]);

//! Base class for all types
class Type
{
  inherit Standards.WSDL.BaseObject;

  //! Type of node
  int TYPE = TYPE_CONTENT;
  
  //! The id attribute of the node, if any
  string id;
  
  //! The name attribute of the node
  string name;
  
  //! The minOccures attribute
  string minoccures = "1";
  
  //! The maxOccures attribute
  string maxoccures = "1";
  
  //! Child elements
  array(object) elements = ({});
  
  //! Add a child element
  //!
  //! @param element
  void add_element(object /* Standards.WSDL.Types.* */ element)
  {
    elements += ({ element });
  }
  
  //! Returns the @tt{element@} elements.
  array(Element) get_element_elements()
  {
    return low_find_children(elements, TYPE_ELEMENT);
  }

  //! Find child of type @[type]
  //! 
  //! @param type
  //!  Any of the @tt{TYPE_*@} constants
  array(Type) find_children(int type)
  {
    return low_find_children(elements, type);
  }

  //! Low level method that searches for child elements of type @[type]
  //!
  //! @param eles
  //! @param type
  protected array(Type) low_find_children(array(object) eles, int type)
  {
    array(Type) out = ({});

    foreach (eles, Type t) {
      if (t->TYPE == type) {
	out += ({ t });
      }

      if (sizeof(t->elements))
	out += low_find_children(t->elements, type);
    }

    return out;
  }

  //! Sets som defaults from the nodes attributes
  //!
  //! @param a
  //!  Node attributes
  protected void set_defaults(mapping a)
  {
    id   = a->id;
    name = a->name;

    if (a->minOccures)
      minoccures = a->minOccures;
    if (a->maxOccures)
      maxoccures = a->maxOccures;
  }
  
  //! Decode child nodes of node @[n]
  //!
  //! @param n
  protected void set_children(Node n)
  {
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT)
	elements += ({ resolv_class(cn)(cn, owner_document) }); 
    }
  }

  //! Decodes the node
  //!
  //! @param n
  protected void decode(Node n)
  {
    set_defaults(n->get_attributes());
    set_children(n);
  }
}

//! Class representing a @tt{<all/>@} node
class All
{
  inherit Type;
  int TYPE = TYPE_ALL;
}

//! Class representing a @tt{<any/>@} node
class Any
{
  inherit Type;
  int TYPE = TYPE_ANY;
}

//! Class representing a @tt{<attribute/>@} node
class Attribute
{
  inherit Type;
  int TYPE = TYPE_ATTRIBUTE;
  
  //! The @tt{ref@} attribute
  QName ref;
  
  //! The @tt{arrayType@} attribute, if any.
  QName array_type;   
}

//! Class representing a @tt{<choise/>@} node
class Choise
{
  inherit Type;
  int TYPE = TYPE_CHOISE;
}

//! Class representing a @tt{<complexContent/>@} node
class ComplexContent
{
  inherit Type;
  int TYPE = TYPE_COMPLEX_CONTENT;
}

//! Class representing a @tt{<complexType/>@} node
class ComplexType
{
  inherit Type;
  int TYPE = TYPE_COMPLEX_TYPE;
  
  //! Attribute @tt{mixed@}
  int(0..1) is_mixed = 0;
  
  //! Attribute @tt{abstract@}
  int(0..1) is_abstract = 0;
  
  //! Decodes the node
  //!
  //! @param n
  protected void decode(Node n)
  {
    mapping a = n->get_attributes();
    set_defaults(a);
    is_mixed = a->mixed && a->mixed == "true";
    is_abstract = a->abstract && a->abstract == "true";
    set_children(n);
  }
}

//! Class representing a @tt{<element/>@} node
class Element
{
  inherit Type;

  int TYPE = TYPE_ELEMENT;

  //! The XSI type
  QName type;
  
  //! Is the type nillable or not
  int(0..1) nillable = 0;

  //! Decode the node @[n]
  protected void decode(Node n)
  {
    mapping a = n->get_attributes();
    set_defaults(a);
    type = a->type && QName("", a->type);
    nillable = a->nillable && a->nillable == "true";
    
    if (type) {
      QName nsq;
      if ( nsq = ns_cache[type->get_prefix()] )
	type->set_namespace_uri(nsq->get_namespace_uri());
      else {
	nsq = owner_document->get_namespace_from_local_name(type->get_prefix());
	if (nsq) {
	  ns_cache[type->get_prefix()] = nsq;
	  type->set_namespace_uri(nsq->get_namespace_uri());
	}
      }
    }
    
    set_children(n);
  }
}

//! Class representing a @tt{<restriction/>@} node
class Restriction
{
  inherit Type;
  int TYPE = TYPE_RESTRICTION;
  
  //! The base attribute
  QName base;

  protected void decode(Node n)
  {
    mapping a = n->get_attributes();
    base = a->base && QName("", a->base);
    if (base) {
      QName nsq;
      if ( nsq = ns_cache[base->get_prefix()] )
	base->set_namespace_uri(nsq->get_namespace_uri());
      else {
	nsq = owner_document->get_namespace_from_local_name(base->get_prefix());
	if (nsq) {
	  ns_cache[base->get_prefix()] = nsq;
	  base->set_namespace_uri(nsq->get_namespace_uri());
	}
      }
    }
  }
}

//! Class representing a @tt{<sequence/>@} node
class Sequence
{
  inherit Type;
  int TYPE = TYPE_SEQUENCE;
  
  //! Element order
  array(string) order = ({});

  protected void set_children(Node n)
  {
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT) {
	object o = resolv_class(cn)(cn, owner_document);
	order += ({ o->name||o->get_node_name() });
	elements += ({ o }); 
      }
    }
  }
}

//! Class representing a @tt{<simpleType/>@} node
class SimpleType
{
  inherit Type;
  int TYPE = TYPE_SIMPLE_TYPE;
}