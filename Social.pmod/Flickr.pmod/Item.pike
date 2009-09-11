//! Copyright @ 2008, Pontus Östlund - @url{www.poppa.se@}
//!
//! The Item class serializes an XML tree to Pike datatypes. An @[Item] will 
//! have the members @[Item.name] which is the node name of the XML tree,
//! @[Item.attributes] which is the attributes of the XML node, @[Item.children] 
//! which are the child nodes of the XML node, @[Item.value] which is the value 
//! of the XML node and @[Item.type] which is the node type - doh - of the XML 
//! node.
//!
//! An @[Item] object can be casted to either a string, array, mapping or int
//! where a cast to @expr{string@} will give the node value, @expr{array@} will 
//! return the child nodes, @expr{mapping@} will return the attributes and 
//! @expr{int@} will return the number of child nodes.
//! 
//! @xml{<code lang="pike" detab="3" tabsize="2">
//!   string xml =
//!     "<my id='2'>\n"
//!     "  <name>My Name</name>\n"
//!     "  <born country='Sweden' city='Södertälje' year='1973' />\n"
//!     "</my>";
//!   
//!   Flickr.Item item = Flickr.Item(xml);
//!   write("My name is %s and I was born in %s %s in the year of %s\n\n",
//!         (string)item->my->name, ((mapping)my->born)->country,
//!         ((mapping)my->born)->city, ((mapping)my->born)->year);
//!   
//!   write("item has %d children\n\n", (int)my);
//!   foreach((array)my, Flickr.Item child)
//!     write("  %s\n", child->name);
//! </code>@}
//! 
//! Worth noticing is that all values are strings.

#include "flickr.h"
import Parser.XML.Tree;
//inherit .Struct;

//! The @[Parser.XML.Tree.Node]
protected Node root = 0;

//! @appears name
//! The name of the XML node
string _name = "";

//! @appears value
//! The text content of the XML node
string _value = "";

//! @appears children
//! The childnodes of the XML node
array(object) _children = ({});

//! @appears attributes
//! The attributes of the XML node
mapping(string:string) _attributes = ([]);

//! @appears type
//! The type of the XML node
int _type = 0;


//! Returns the number of child nodes
int _sizeof()
{
  return sizeof(_children);
}


//! Creates a new @[Item] object
//!
//! @param xml_data
//!   Either an XML tree in string format or a @[Parser.XML.Tree.Node] object.
void create(string|Node xml_data)
{
  if (stringp(xml_data)) {
    root = parse_input(xml_data);
    root = sizeof(root) && root[0];
  }
  else
    root = xml_data;

  parse();
}


//! Serializes the XML to a set of @[Item]s.
protected void parse()
{
  if (!root || !sizeof(root))
    return;

  _type = root->get_node_type();
  _name = root->get_tag_name();
  _attributes = root->get_attributes();

  if (_type == XML_ELEMENT && root->count_children() > 1) {
    foreach (root->get_children(), Node n) {
      switch (n->get_node_type())
      {
	case XML_ELEMENT:
	  _children += ({ object_program(this)(n) });
	  break;

	case XML_TEXT:
	  string s = TRIM(n->value_of_node());
	  if (sizeof(s)) _children += ({ s });
	  break;
      }
    }
  }
  else _value = String.trim_all_whites(root->value_of_node());
}


//! Returns the original @[Parser.XML.Tree.Node] object
Parser.XML.Tree.Node get_xml()
{
  return root;
}

//! Formated string otuput
string _sprintf(int t)
{
  switch (t) {
    case 'O':
      return sprintf(
	"%s\n"
	"  Name: %O,\n"
	"  Value: %s,\n"
	"  Attributes: %O,\n"
	"  Children: %O\n)",
	sprintf("%O", this_object()) - ")",
	_name, _value, _attributes, _children
      );
      break;

    case 's': return _value;
    case 'd': return (string)sizeof(_children);
  }
}

//! This class turns an @[object] back to plain old XML.
protected class Deserializer
{
  //! The @object] to deserialize
  protected object item;

  //! The XML root node
  protected Node root = RootNode();


  //! Creates a new @[Deserializer] object.
  //!
  //! @param item
  //!   The @object] to deserialize
  void create(object _item)
  {
    item = _item;
  }


  //! Run the deserializer
  //!
  //! @returns
  //!   The object as an XML representation
  string deserialize()
  {
    low_deserialize(item, root);
    return root->render_xml();
  }


  //! Does the creation of the XML nodes.
  //!
  //! @param i
  //!   The @object] to deserialize
  //! @param n
  //!   The @[Parser.XML.Tree.Node] to add the deserialized node to.
  private void low_deserialize(object i, Node n)
  {
    Node nn;
    switch (i->type)
    {
      case XML_ELEMENT:
	nn = ElementNode(i->name, i->attributes);
	break;

      case XML_TEXT:
        nn = TextNode(i->value);
	break;
    }

    n->add_child(nn);

    if ((int)i > 0)
      foreach ((array)i, object ci)
	low_deserialize(ci, nn);
  }
}
