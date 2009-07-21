import Parser.XML.Tree;
inherit .BaseObject;

string name;
array(.Part) parts = ({});
array(string) part_order = ({});

protected void decode(Node n)
{
  name = n->get_attributes()->name;
  foreach (n->get_children(), Node cn) {
    if (cn->get_tag_name() == "part") {
      .Part p = .Part(cn, owner_document);
      parts += ({ p });
      part_order += ({ p->name });
    }
  }
}
