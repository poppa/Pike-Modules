import Parser.XML.Tree;
import Standards.XML.Namespace;
inherit .BaseObject;

string name;
QName type;
QName element;

protected void decode(Node n)
{
  mapping a = n->get_attributes();
  name = a->name;
  element = a->element && QName("", a->element);
  type = a->type && QName("", a->type);
}
