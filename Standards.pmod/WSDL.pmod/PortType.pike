import Parser.XML.Tree;
inherit .BaseObject;

string name;
mapping(string:.Operation) operations = ([]);

protected void decode(Node n)
{
  mapping a = n->get_attributes();
  name = a && a->name;

  foreach (n->get_children(), Node cn)
    if (cn->get_tag_name() == "operation")
      operations[cn->get_attributes()->name] = .Operation(cn, owner_document);
}
