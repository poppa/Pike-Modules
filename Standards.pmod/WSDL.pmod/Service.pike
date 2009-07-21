import Parser.XML.Tree;
inherit .BaseObject;

string name;
mapping(string:.Port) ports = ([]);

.Port get_soap_port()
{
  return get_port_by_type(owner_document->get_wsdl_soap_namespace()
                                        ->get_local_name());
}

.Port get_port_by_type(string type)
{
  foreach (values(ports), .Port p)
    if (p->address->get_ns_name() == type)
      return p;
}

.Port get_port(string name)
{
  return ports[name];
}

protected void decode(Node n)
{
  name = n->get_attributes()->name;
  foreach (n->get_children(), Node cn)
    if (cn->get_tag_name() == "port")
      ports[cn->get_attributes()->name] = .Port(cn, owner_document);
}
