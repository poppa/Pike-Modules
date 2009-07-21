import Parser.XML.Tree;
import Standards.XML.Namespace;

constant TYPE_ANY             = 1<<0;
constant TYPE_ALL             = 1<<1;
constant TYPE_ATTRIBUTE       = 1<<2;
constant TYPE_CHOISE          = 1<<3;
constant TYPE_COMPLEX_CONTENT = 1<<4;
constant TYPE_COMPLEX_TYPE    = 1<<5;
constant TYPE_CONTENT         = 1<<6;
constant TYPE_ELEMENT         = 1<<7;
constant TYPE_RESTRICTION     = 1<<8;
constant TYPE_SEQUENCE        = 1<<9;
constant TYPE_SIMPLE_TYPE     = 1<<10;

protected object resolv_class(Parser.XML.Tree.Node n)
{
  switch (n->get_tag_name())
  {
    case "any":            return Any;
    case "all":            return All;
    case "complexType":    return ComplexType;
    case "choise":         return Choise;
    case "element":        return Element;
    case "sequence":       return Sequence;
    case "complexContent": return ComplexContent;
    case "attribute":      return Attribute;
    case "restriction":    return Restriction;
    default:               return Type;
  }
}

class Type
{
  inherit Standards.WSDL.BaseObject;

  int TYPE = TYPE_CONTENT;
  string id;
  string name;
  string minoccures = "1";
  string maxoccures = "1";
  array(object) elements = ({});
  int(0..1) is_sequence = 0;

  void add_element(object /* Standards.WSDL.Types.* */ element)
  {
    elements += ({ element });
  }

  int(0..1) has_children()
  {
    return !!sizeof(elements);
  }

  int(0..1) is_complex()
  {
    return TYPE == TYPE_COMPLEX_TYPE || (
           has_children && elements[0]->TYPE == TYPE_COMPLEX_TYPE);
    
  }

  array(Type) get_elements()
  {
    array(Type) eles = ({});
    foreach (elements, Type ele) {
      if (ele->TYPE == TYPE_ELEMENT) {
	werror("Element found: %O\n", ele->name);
	eles += ({ ele });
      }
      
      if (ele->has_children())
	eles += ele->get_elements();
    }
    
    return eles;
  }
  
  int _sizeof()
  {
    return sizeof(elements);
  }
  
  protected void set_defaults(mapping a)
  {
    id   = a->id;
    name = a->name;
  
    if (a->minOccures)
      minoccures = a->minOccures;
    if (a->maxOccures)
      maxoccures = a->maxOccures;  
  }
  
  protected void set_children(Node n)
  {
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT)
	elements += ({ resolv_class(cn)(cn, owner_document) }); 
    }
  }
  
  protected void decode(Node n)
  {
    set_defaults(n->get_attributes());
    set_children(n);
  }
}

class All
{
  inherit Type;
  int TYPE = TYPE_ALL;
}

class Any
{
  inherit Type;
  int TYPE = TYPE_ANY;
}

class Attribute
{
  inherit Type;
  int TYPE = TYPE_ATTRIBUTE;
  QName ref;
  QName array_type;
}

class Choise
{
  inherit Type;
  int TYPE = TYPE_CHOISE;
}

class ComplexContent
{
  inherit Type;
  int TYPE = TYPE_COMPLEX_CONTENT;
}

class ComplexType
{
  inherit Type;

  int TYPE = TYPE_COMPLEX_TYPE;
  int(0..1) is_mixed = 0;
  int(0..1) is_abstract = 0;
  
  protected void decode(Node n)
  {
    mapping a = n->get_attributes();
    set_defaults(a);
    is_mixed = a->mixed && a->mixed == "true";
    is_abstract = a->abstract && a->abstract == "true";
    set_children(n);
  }
}

class Element
{
  inherit Type;

  int TYPE = TYPE_ELEMENT;
  QName type;
  
  protected void decode(Node n)
  {
    mapping a = n->get_attributes();
    set_defaults(a);
    type = a->type && QName("", a->type);
    set_children(n);
  }
}

class Restriction
{
  inherit Type;
  int TYPE = TYPE_RESTRICTION;
}

class Sequence
{
  inherit Type;

  int TYPE = TYPE_SEQUENCE;
  array(string) order = ({});
  int(0..1) is_sequence = 1;

  protected void set_children(Node n)
  {
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT) {
	object o = resolv_class(cn)(cn, owner_document);
	order += ({ o->name||o->get_node_name() });
	elements += ({ o }); 
      }
    }
  }
}

class SimpleType
{
  inherit Type;
  int TYPE = TYPE_SIMPLE_TYPE;
}