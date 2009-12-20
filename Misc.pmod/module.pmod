/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Misc. modules@}
//!
//! Copyright © 2009, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Misc.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Misc.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Misc.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

import Parser.XML.Tree;

//! Turns an XML tree into an object
//! 
//! @xml{<code lang="xml" detab="3">
//!   <arist name="Dream Theater">
//!    <album>
//!     <name>When dream and day unite</name>
//!     <year>1989</year>
//!    </album>
//!    <album>
//!     <name>Images and words</name>
//!     <year>1992</year>
//!    </album>
//!   </artist>
//! </code>@}
//!
//! @xml{<code lang="pike" detab="3">
//!   SimpleXML sxml = SimpleXML(xml);
//!   werror("%O\n", sxml->album->name->get_value())
//!   ({ /* 2 elements */
//!       "When dream and day unite",
//!       "Images and words"
//!   })
//! </code>@}
class SimpleXML
{
  string raw_xml;
  SimpleXML parent;
  
  //! Full name of the node, including the namespace
  protected string fullname;

  //! Node name
  protected string name;

  //! Child nodes
  protected array(SimpleXML) children = ({});

  //! Text value
  protected string value = "";

  //! Node attributes
  protected mapping(string:string) attributes;

  //! Node types
  protected int type;

  //! Temporary storage for stray text nodes
  private array(string) svalues = ({});

  //! Creates a new insance of @[SimpleXML]
  //!
  //! @throws 
  //!  An error if @[xml] is a string and XML parsing fails
  //!
  //! @param xml
  void create(string|Node xml, void|SimpleXML _parent)
  {
    if (stringp(xml))
      raw_xml = xml;

    if (_parent)
      parent = _parent;

    Node root;
    if (stringp(xml))
      root = parse_input(xml);
    else
      root = xml;

    if (!root) error("Unable to parse XML\n");

    // Lets find the first element node
    if (root->get_node_type() != XML_ELEMENT) {
      foreach (root->get_children(), Node cn) {
	if (cn->get_node_type() == XML_ELEMENT) {
	  root = cn;
	  break;
	}
      }
    }

    parse(root);
  }
  
  //! Returns the node name
  string get_name()
  {
    return name;
  }
  
  //! Returns the full node name, including the namespace
  string get_fullname()
  {
    return fullname;
  }

  //! Returns the node's text value
  string get_value()
  {
    return value;
  }

  //! Returns the child nodes
  array(SimpleXML) get_children()
  {
    return children;
  }
  
  //! Returns the node attributes
  mapping(string:string) get_attributes()
  {
    return attributes;
  }

  //! Index arrow lookup.
  //! Will look for child nodes of name @[key]. If multiple child nodes exists
  //! an array of child nodes will be returned. If only one node is found that
  //! object will be returned.
  //!
  //! @param key
  mixed `->(string key)
  {
    if ( this[key] && functionp( this[key] ))
      return this[key];

    object|array(object) r;

    foreach (children, SimpleXML s) {
      if (s->get_name() == key) {
	if (r) {
	  if (!arrayp(r))
	    r = ({ r });
	  r += ({ s });
	}
	else r = s;
      }
    }

    return r;
  }

  //! Casting method
  //!
  //! @param how
  //!  @ul
  //!   @item 
  //!    string: returns the node text value
  //!   @item
  //!    array: returns the child nodes
  //!   @item
  //!    mapping: returns the node attributes
  //!   @item
  //!    int: returns the node type
  //!  @endul
  mixed cast(string how)
  {
    switch (how)
    {
      case "string":  return value;
      case "array":   return children;
      case "mapping": return attributes;
      case "int":     return type;
    }
  }

  //! @tt{sizeof()@} method overloader
  int _sizeof()
  {
    return sizeof(children);
  }

  //! Parses the node
  //!
  //! @param n
  private void parse(Node n)
  {
    type       = n->get_node_type();
    name       = n->get_tag_name();
    fullname   = n->get_full_name();
    attributes = n->get_attributes();

    Node f;

    if ((f = n->get_first_element()) && f->get_node_type() == XML_ELEMENT) {
      foreach (n->get_children(), Node cn) {
	switch (cn->get_node_type())
	{
	  case XML_ELEMENT: 
	    children += ({ object_program(this)(cn, this) });
	    break;

	  case XML_TEXT:
	    string s = String.trim_all_whites(cn->value_of_node());
	    if (sizeof(s))
	      svalues += ({ s });
	    break;
	}
      }
    }
    else
      value = n->value_of_node();

    if (sizeof(svalues))
      value = (({ value }) + svalues)*" ";
  }

  //! String format method
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%s)", object_program(this), name);
  }
}

//! Subprocess class
//!
//! @note
//!  I take no credit for this class. It's mainly from the Roxen tag
//!  @tt{emit#exec@} by Marcus Wellhardt at Roxen Internet Sowftware AB
//!  @url{http://roxen.com@}
class Proc
{
  //! The result from the sub process
  string result = "";
  
  //! Did we end up with a timeout?
  int(0..1) is_timeout = 0;

  protected Process.create_process p;
  protected int           timeout;
  protected int           retval;
  protected int(0..1)     done;
  protected array(string) args;

  private Pike.Backend backends = Thread.Local();

  //! Creates a new @[Proc] class
  //!
  //! @param _args
  //!  Array of arguments. The first index should be the program to run and
  //!  there after argument to pass to the program. 
  //! @param _timeout
  //!  Maximimum number of seconds the process can run. Default is @tt{30@}
  void create(array(string) _args, void|int _timeout)
  {
    args = _args;
    timeout = _timeout||30;
  }

  protected void on_data(int id, string data)
  {
    result += data;
  }

  protected void on_close(int id)
  {
    done = 1;
  }

  protected void on_timeout()
  {
    is_timeout = 1;
    p->kill(9);
    done = 1;
  }

  //! Run the process
  //!
  //! @throws
  //!  An error if the creation of a subprocess fails
  //!
  //! @returns
  //!  The return value of the subprocess. To get the data from the process
  //!  use @[Proc()->result].
  int run()
  {
    is_timeout = 0;
    done = 0;
    result = "";

    Stdio.File stdout = Stdio.File();

    if (mixed e = catch(p = Process.create_process(args, 
                            ([ "stdout" : stdout->pipe() ]))))
    {
      error("Unable to create process: %s\n", describe_error(e));
    }

    Pike.Backend backend = backends->get();

    if (!backend)
      backends->set(backend = Pike.Backend());

    backend->add_file(stdout);
    mixed to = backend->call_out(on_timeout, timeout);
    stdout->set_nonblocking(on_data, 0, on_close);

    while (!done)
      float time = backend(0);

    int rv = p->wait();
    stdout->close();
    backend->remove_call_out(on_timeout);

    return rv;
  }
}

