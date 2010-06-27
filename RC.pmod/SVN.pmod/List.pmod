/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This module executes the @tt{svn list|ls@} command.
//!
//! @fixme
//!  Find out what typ a specific file is, if it's binary or not...
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| ============================================================================
//|
//|     GNU GPL version 3
//|
//| ============================================================================
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

import Parser.XML.Tree;

// Hidden module constructor
protected void create(mixed ... args) {}

//! Constructor for the @[List] class
//!
//! @param path
List `()(void|string path)
{
  return List(path);
}

//! Base class for @[Dir] and @[File]
class List
{
  inherit .AbstractSVN;

  //! Array of @[Dir] and @[File] objects
  array(Dir|File) entries = ({});

  //! Constrcutor
  //!
  //! @param path
  void create(void|string path)
  {
    ::create(0, path);
    string xml = exec("list", path, 0, "--xml");
    xml && ::parse_xml(xml);
  }
  
  //! Returns the list of @[Dir] and @[File] objects
  array(Dir|File) _values()
  {
    return entries;
  }
  
  // Callback for the list node
  void _handle_list(Node n)
  {
    ::parse_xml(n);
  }
  
  // Callback for the entry node
  void _handle_entry(Node n)
  {
    object e;
    switch ( n->get_attributes()["kind"] )
    {
      case "file": e = File()->set_from_xml(n); break;
      case "dir":  e = Dir()->set_from_xml(n);  break;
    }

    entries += ({ e });
  }
}

//! Class representing a version controlled directory
class Dir
{
  inherit .AbstractEntry;

  protected string type;
  protected string name;

  // Populates this object from an XML node
  object_program set_from_xml(Node n)
  {
    type = n->get_attributes()["kind"];
    ::parse_xml(n);
    return this;
  }

  //! Returns the type
  string get_type()
  {
    return type;
  }

  //! Returns the name
  string get_name()
  {
    return name;
  }

  // Callback for the commit node
  void _handle_commit(Node n)
  {
    revision = (int)n->get_attributes()["revision"];
    ::parse_xml(n);
  }
  
  // Callback for the name node
  void _handle_name(Node n)
  {
    name = n->value_of_node();
  }
  
  string _sprintf(int t)
  {
    return sprintf("%O(%s)", object_program(this), name);
  }
}

//! Class representing a version controlled file
class File
{
  inherit Dir;

  //! The file size
  int size;

  //! Returns the file size
  int get_size()
  {
    return size;
  }

  // Callback for the size node
  void _handle_size(Node n)
  {
    size = (int)n->value_of_node();
  }
}

