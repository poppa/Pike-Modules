/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! This class maps an XML tree onto an inheriting class. Object members that
//! have a corresponding XML node in the tree will get their values from the
//! XML node. To handle child nodes - or nodes that should be mapped to anything
//! other than simple data types like strings and ints - can be handled by 
//! creating a method of the same name as a node but prefixed with 
//! @tt{handle_@}. So @tt{handle_created_at(Node n)@} will be called when an
//! XML node named @tt{created_at@} is being found in the XML tree
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [PROG-NAME].pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [MODULE-NAME].pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [PROG-NAME].pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "twitter.h"
import Parser.XML.Tree;

//! Creates a new instance of @[XmlMapper]
//!
//! @param xml
protected void create(void|Node xml)
{
  if (xml) {
    foreach (xml->get_children(), Node n) {
      if (n->get_node_type() != XML_ELEMENT)
	continue;

      string name = n->get_tag_name();

      if ( function f = this["handle_" + name] )
	f(n);
      else if ( object_variablep(this, name) ) {
	if (objectp( this[name] ))
	  error("Unhandled complex node \"%s\". ", name);
	else {
	  string value = n->value_of_node();
	  if (stringp( this[name] ))
	    this[name] = NULLIFY(value);
	  else if (intp( this[name] ))  {
	    if (value == "true")
	      this[name] = true;
	    else if (value == "false")
	      this[name] = false;
	    else 
	      this[name] = (int)value;
	  }
	}
      }
    }
  }
}


mixed cast(string how)
{
  switch (how)
  {
    case "mapping":
      mapping m = ([]);
      foreach (indices(this), string key) {
      	if (object_variablep(this, key)) {
      	  mixed v = this[key];
      	  if (stringp(v))
	    m[key] = v;
	  else if (intp(v))
	    m[key] = (string)v;
	  else if (objectp(v)) {
	    if (Program.inherits(v, Social.Twitter.XmlMapper))
	      m[key] = (mapping)v;
	    else  if (object_program(v) == Calendar.Second)
	      m[key] = v->format_time();
	  }
      	}
      }

      return m;
  }

  error("Can't cast %O to %O! ", object_program(this), how);
}
