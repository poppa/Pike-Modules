import Parser.XML.Tree;

private mapping cache = ([]);

void add_cache(string url, string wsdldata)
{
  cache[url] = wsdldata;
}

class Document
{
  string uri;
  mapping ns = ([]);
  array schemas = ({});
  string target_namespace;

  void load(string|Standards.URI _uri)
  {
    string wsdldoc;
    uri = (string)_uri;
    if ( wsdldoc = cache[uri] ) {
      parse(wsdldoc);
      return;
    }

    Protocols.HTTP.Query q = Protocols.HTTP.get_url(uri);

    if (q->status == 200)
      cache[uri] = wsdldoc = q->data();

    Stdio.write_file("definitions.wsdl", wsdldoc);

    parse(wsdldoc);
  }
  
  void parse(string xml)
  {
    Node root = parse_input(xml);
    if (root && (root = find_root(root)))
      low_parse(root);
  }

  Element get_element(string name)
  {
    foreach (Array.flatten(schemas->elements), Element e) {
      if (e->name == name)
	return e;
    }

    return 0;
  }
  
  protected void low_parse(Node n)
  {
    string name = n->get_tag_name();
    string fname = n->get_full_name();
    
    switch (name)
    {
      case "definitions":
	foreach (n->get_attributes(); string tag; string namespace) {
	  if (tag == "targetNamespace")
	    target_namespace = namespace;

	  ns[tag] = Standards.XSD.QName(tag, namespace);
	}
	break;

      case "types":
	foreach (n->get_children(), Node cn)
	  if (cn->get_tag_name() == "schema")
	    schemas += ({ get_schema_from_node(cn) });

	break;
	
      case "message":
	//werror("Parse:message\n");
	break;
    }

    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT)
	low_parse(cn);
    }
  }
  
  protected Node find_root(Node n)
  {
    foreach (n->get_children(), Node cn)
      if (cn->get_node_type() == XML_ELEMENT)
	return cn;

    return 0;
  }
}

protected Schema get_schema_from_node(Node schema)
{
  mapping attr = schema->get_attributes();
  Schema s = Schema();
  s->set_attributes(attr);
  s->target_namespace = attr->targetNamespace;
  
  foreach (schema->get_children(), Node n) {
    if (n->get_tag_name() == "element")
      s->add_element(get_element_from_node(n));
  }

  return s;
}

protected Element get_element_from_node(Node element)
{
  mapping attr = element->get_attributes();

  Element e = Element();
  if (attr) {
    e->set_attributes(attr);
    e->name = attr->name;
  
    if (attr->nillable && attr->nillable == "true")
      e->nillable = 1;
  }
  
  e->node_name = element->get_tag_name();

  if (Node cn = element->get_first_element()) {
    if (cn->get_tag_name() == "complexType") {
      e->complex = 1;
      e->type = "complexType";
      if ((cn = cn->get_first_element()) && cn->get_tag_name() == "sequence")
	foreach (cn->get_children(), Node ccn)
	  e->add_element(get_element_from_node(ccn));
    }
    else
      werror("Unknown child node to %O\n", element);
  }
  else {
    if (attr && attr->type)
      e->type = get_short_name(attr->type);
    else
      e->type = element->get_tag_name();
  }

  return e;
}

protected string get_short_name(string s)
{
  s && sscanf(s, "%*[^:]:%s", s);
  return s;
}

protected class BaseObject
{
  mapping attributes = ([]);

  void add_attribute(string name, string value)
  {
    attributes[name] = value;
  }

  void set_attributes(mapping attribs)
  {
    attributes = attribs;
  }
}

class Schema
{
  inherit BaseObject;

  string target_namespace;
  array(Element) elements = ({});
  
  void add_element(Element e)
  {
    elements += ({ e });
  }
}

class Element
{
  inherit BaseObject;

  int(0..1) complex = 0;
  int(0..1) nillable = 0;
  string name;
  string type;
  string node_name;

  array(Element) elements = ({});

  void add_element(Element e)
  {
    elements += ({ e });
  }
  
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O)", object_program(this), name, type);
  }
}

class Message
{
  string name;
  array parts = ({});
  
  void add_part(string part)
  {
    
  }
}