import Parser.XML.Tree;
import Standards.XML.Namespace;
inherit .BaseObject;

string  name;
QName   binding;
Address address;

protected void decode(Node n)
{
  mapping a = n->get_attributes();
  name = a && a->name;
  binding = a && a->binding && QName("", a->binding);

  foreach (n->get_children(), Node cn) {
    if (cn->get_tag_name() == "address") 
      address = Address(cn, owner_document);
  }
}

class Address
{
  inherit .BaseObject;
  string location;

  protected void decode(Node n)
  {
    location = n->get_attributes()->location;
  }
}
