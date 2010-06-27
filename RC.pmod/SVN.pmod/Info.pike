/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This module executes the @tt{svn info@} command.
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

inherit .AbstractEntry;

protected string type;
protected string url;
protected string root;
protected string uuid;

//! Creates a new @[Info] object
//!
//! @param path
//! @param revision
void create(string path, void|int revision)
{
  ::create(revision, path);
  string s = exec("info", path, revision, "--xml");
  s && ::parse_xml(s);
}

//! Returns the file type
string get_type()
{
  return type;
}

//! Returns the URL of the file
string get_url()
{
  return url;
}

//! Returns the root of the file
string get_root()
{
  return root;
}

//! Returns the @tt{uuid@} of the file
string get_uuid()
{
  return uuid;
}

// Callback for the entry node
void _handle_entry(Node n)
{
  revision = (int)n->get_attributes()["revision"];
  type = n->get_attributes()["kind"];
  ::parse_xml(n);
}

// Callback for the url node
void _handle_url(Node n)
{
  url = n->value_of_node();
}

// Callback for the repository node
void _handle_repository(Node n)
{
  ::parse_xml(n);
}

// Callback for the root node
void _handle_root(Node n)
{
  root = n->value_of_node();
}

// Callback for the uuid node
void _handle_uuid(Node n)
{
  uuid = n->value_of_node();
}

