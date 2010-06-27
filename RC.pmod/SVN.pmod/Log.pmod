/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This module executes the @tt{svn log@} command.
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| ============================================================================
//|
//|                            GNU GPL version 3
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

//! Contructor for the @[Log] class
//!
//! @param revision
//! @param file
//! @param flags
//!  Arbitrary number of the @tt{svn log@} arguments
Log `()(void|int|string revision, void|string file, mixed ... flags)
{
  return Log(revision, file, @flags);
}

//! Returns the head and previous revision numbers for @[path]
//!
//! @param path
array(int) get_head_prev(string path)
{
  Log log = Log(0, path, "-l", 2, "--with-revprop", "revision");
  return values(log)->get_revision();
}

//! Class representing an SVN log
class Log
{
  inherit .AbstractSVN;

  //! Creates a new @[Log] object
  //!
  //! @seealso
  //!  @[`()].
  //!
  //! @param revision
  //! @param _file
  //! @param flags
  void create(void|int|string revision, void|string _file, mixed ... flags)
  {
    ::create(revision, _file);
    string xml = exec("log", _file, revision, "--xml", @flags);
    xml && ::parse_xml(xml);
  }

  // Callback for the logentry node
  void _handle_logentry(Node n)
  {
    revisions += ({ Entry()->set_from_xml(n) });
  }
}

//! Class representing a log entry
class Entry
{
  inherit .AbstractEntry;

  protected string msg;
  protected array(mapping(string:string)) paths = ({});

  //! Creates a new @[Entry] class
  //!
  //! @param rev
  void create(void|int rev)
  {
    revision = rev;
  }

  //! Returns the log message
  string get_message()
  {
    return msg;
  }
  
  //! Returns an array of paths affected by this log
  //!
  //! @returns
  //!  An array of mappings where the mapping has the following indices:
  //!  @mapping
  //!   @member string "action"
  //!   @member string "path"
  //!  @endmapping
  array(mapping(string:string)) get_paths()
  {
    return paths;
  }

  // Popultaes the object from an XML node
  object_program set_from_xml(Node n)
  {
    revision = (int)n->get_attributes()["revision"];
    ::parse_xml(n);

    return this;
  }

  // Callback for the paths node
  void _handle_paths(Node n)
  {
    ::parse_xml(n);
  }

  // Callback for the path node
  void _handle_path(Node n)
  {
    paths += ({ ([
      "action" : n->get_attributes()["action"],
      "path"   : n->value_of_node()
    ]) });
  }

  // Callback for the msg node
  void _handle_msg(Node n)
  {
    msg = n->value_of_node();
  }
}

