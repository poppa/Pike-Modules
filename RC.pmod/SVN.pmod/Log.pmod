/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{RC.SVN.Log@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! This module executes the @tt{svn log@} command.
//|
//| ============================================================================
//|
//|                            GNU GPL version 3
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

Log `()(void|int|string revision, void|string file, mixed ... flags)
{
  return Log(revision, file, @flags);
}

array(int) get_head_prev(string path)
{
  Log log = Log(0, path, "-l", 2, "--with-revprop", "revision");
  return values(log)->get_revision();
}

class Log
{
  inherit .AbstractSVN;

  void create(void|int|string revision, void|string _file, mixed ... flags)
  {
    ::create(revision, _file);
    string xml = exec("log", _file, revision, "--xml", @flags);
    xml && ::parse_xml(xml);
  }

  void _handle_logentry(Node n)
  {
    revisions += ({ Entry()->set_from_xml(n) });
  }
}

class Entry
{
  inherit .AbstractEntry;

  protected string msg;
  protected array(mapping(string:string)) paths = ({});

  void create(void|int rev)
  {
    revision = rev;
  }

  string get_message()
  {
    return msg;
  }
  
  array(mapping(string:string)) get_paths()
  {
    return paths;
  }

  object_program set_from_xml(Node n)
  {
    revision = (int)n->get_attributes()["revision"];
    ::parse_xml(n);

    return this;
  }

  void _handle_paths(Node n)
  {
    ::parse_xml(n);
  }

  void _handle_path(Node n)
  {
    paths += ({ ([
      "action" : n->get_attributes()["action"],
      "path"   : n->value_of_node()
    ]) });
  }

  void _handle_msg(Node n)
  {
    msg = n->value_of_node();
  }
}
