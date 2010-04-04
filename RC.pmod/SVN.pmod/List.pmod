/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{RC.SV.List@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! This module executes the @tt{svn list|ls@} command.
//!
//! @fixme
//!  Find out what typ a specific file is, if it's binary or not...
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

import Parser.XML.Tree;

protected void create(mixed ... args) {}

List `()(void|string path)
{
  return List(path);
}

class List
{
  inherit .AbstractSVN;

  array(Dir|File) entries = ({});

  void create(void|string path)
  {
    ::create(0, path);
    string xml = exec("list", path, 0, "--xml");
    xml && ::parse_xml(xml);
  }
  
  array(Dir|File) _values()
  {
    return entries;
  }
  
  void _handle_list(Node n)
  {
    ::parse_xml(n);
  }
  
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

class Dir
{
  inherit .AbstractEntry;

  protected string type;
  protected string name;

  object_program set_from_xml(Node n)
  {
    type = n->get_attributes()["kind"];
    ::parse_xml(n);
    return this;
  }

  string get_type()
  {
    return type;
  }

  string get_name()
  {
    return name;
  }

  void _handle_commit(Node n)
  {
    revision = (int)n->get_attributes()["revision"];
    ::parse_xml(n);
  }
  
  void _handle_name(Node n)
  {
    name = n->value_of_node();
  }
  
  string _sprintf(int t)
  {
    return sprintf("%O(%s)", object_program(this), name);
  }
}

class File
{
  inherit Dir;
  int size;

  int get_size()
  {
    return size;
  }

  void _handle_size(Node n)
  {
    size = (int)n->value_of_node();
  }
}
