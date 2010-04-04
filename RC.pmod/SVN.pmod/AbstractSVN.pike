/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{AbstractSVN@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! This is the base class which pretty much all other SVN related modules and
//! programs inherits.
//|
//| ============================================================================
//|
//|     GNU GPL version 3
//|
//! ============================================================================
//|
//| This file is part of SVN.pmod
//|
//| SVN.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| SVN.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with SVN.pmod. If not, see <http://www.gnu.org/licenses/>.

#include "svn.h"
import Parser.XML.Tree;

//! @note
//!  Some members here are probably named badly since their names doesn't fit 
//!  in inheriting classes - or maybe the shouldn't be here at all.
//!  I'll move them or rename them when we're getting more stable
//!
//! @note
//!  This is how it works: When some sub class is instantiated an SVN command
//!  is executetd - in most cases with the @tt{--xml@} flag. The sub classes
//!  then pass the XML tree to @[parse_xml()] in this class which iterates
//!  over the child nodes and if the sub class has a method - prefixed with
//!  @tt{_handle_@} - that corresponds to the XML node name that method will be
//!  called with the node as argument. Like: 
//!
//!  @xml{<code detab="3">
//!   // Will be called when AbstractSVN()->parse_xml() finds a <date/> node
//!   void _handle_date(Node n) 
//!   {
//!     date = Calendar.parse("%Y-%M-%D", n->value_of_node());
//!   }
//!  </code>@}
//!
//!  So it is up to the sub class to collect the contents of the XML tree.

protected int revision; /* Not always needed */
protected string file;  /* Should probably be "path" instead */
protected array(object_program) revisions = ({}); /* Same as revision */

int get_revision()
{
  return revision;
}

array(object_program) get_revisions()
{
  return revisions;
}

array(object_program) _values()
{
  return revisions;
}

string get_path()
{
  return file;
}

string _sprintf(int t)
{
  return sprintf("%O(rev:%d)", object_program(this), revision);
}

protected void create(void|int _revision, void|string _file) 
{
  revision = _revision;
  file = _file||.get_repository_base();
}

protected void parse_xml(string|Node xml)
{
  Node root;
  if (stringp(xml)) {
    root = parse_input(xml);
    foreach (root->get_children(), Node n) {
      if (n->get_node_type() == XML_ELEMENT) {
	root = n;
	break;
      }
    }
  }
  else
    root = xml;

  if (root) {
    foreach (root->get_children(), Node child) {
      if (child->get_node_type() == XML_ELEMENT) {
	if ( function f = this["_handle_" + child->get_tag_name()] )
	  call_function(f, child);
      }
    }
  }
}

//! Executes a Subversion command
protected string exec(string cmd, void|string file, void|int|string rev, 
                      mixed ... args)
{
  ASSERT_BASE_SET();
  array(string) command = ({ "svn", cmd });

  if (rev) command += ({ "--revision", (string)rev });

  if (sizeof(args))
    command += map(args, lambda(mixed v) { return (string)v; } );

  if (file)
    command += ({ .join_paths(.get_repository_base(), file) });
  else
    command += ({ .get_repository_base() });

  //werror("Command: %O\n", command);

  .Proc p = .Proc(command);
  if (p->run() == 0) 
    return p->result;

  return 0;
}
