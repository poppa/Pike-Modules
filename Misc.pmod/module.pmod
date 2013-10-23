/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Various modules and classes

import Parser.XML.Tree;

//! Turns an XML tree into an object
//!
//! @xml{
//!   <artist name="Dream Theater">
//!    <album>
//!     <name>When dream and day unite</name>
//!     <year>1989</year>
//!    </album>
//!    <album>
//!     <name>Images and words</name>
//!     <year>1992</year>
//!    </album>
//!   </artist>
//! @}
//!
//! @code
//!   SimpleXML sxml = SimpleXML(xml);
//!   werror("%O\n", sxml->album->name->get_value());
//!   ({ /* 2 elements */
//!       "When dream and day unite",
//!       "Images and words"
//!   })
//! @endcode
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

  private int depth = 0;

  //! Creates a new insance of @[SimpleXML]
  //!
  //! @throws
  //!  An error if @[xml] is a string and XML parsing fails
  //!
  //! @param xml
  //!  Either a @tt{Parser.XML.Tree.Node@} object or an XML string.
  //! @param _parent
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
      case "xml":     return to_xml();
    }
  }

  //! Turns the object into an XML tree
  string to_xml()
  {
    depth = -1;
    return low_dump(this);
  }

  private string low_dump(object o)
  {
    depth++;
    string name = o->get_name();
    string value = o->get_value();
    array children = o->get_children();
    string s = (" "*depth) + "<" + name;

    foreach (o->get_attributes(); string k; string v)
      s += sprintf(" %s=\"%s\"", k, v);

    s += ">" + value;

    if (sizeof(children)) s += "\n";

    foreach (children, object c)
      s += low_dump(c);


    if (sizeof(children)) s += " "*depth;

    s += "</" + name + ">\n";

    depth--;

    return s;
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
