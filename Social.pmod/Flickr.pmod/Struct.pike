//! Represents the data layer of @object]

  import ".";

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


  //! Arrow index lookup
  //!
  //! @param arg
  //!   The index to lookup
  mixed `->(string arg, mixed...rest)
  {
    if ( mixed m = this_object()["_" + arg] )
      return m;

    foreach (_children, object o) {
      if ( arg == o["_name"] )
	return o;
    }
  }

  //! @appears to_xml()
  //! Turns the @[Flickrobject] object into an XML string.
  //!
  //! @returns
  //!   A string representation in XML format of the object.
  string _to_xml()
  {
    return Deserializer(this_object())->deserialize();
  }


  //! Cast method
  //!
  //! @param t
  //!   The type to cast to
  //!
  //! @returns
  //!   If cast to @expr{string@} the @[value] will be retured.
  //!   If cast to @expr{array@} the @[children] will be returned.
  //!   If cast to @expr{mapping@} the @[attributes] will be returned.
  //!   If cast to @expr{int@} the number of @[children] will be returned.
  mixed cast(string t)
  {
    switch (t)
    {
      case "string":  return _value;
      case "array":   return _children;
      case "mapping": return _attributes;
      case "int":     return sizeof(_children);
    }

    THROW("Can't cast %O to %s", this_object(), t);
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
