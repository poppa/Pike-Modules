protected .Definitions owner_document;
protected mapping attributes = ([]);
protected string ns_node_name;
protected string ns_name;
protected string node_name;

protected void create(void|Parser.XML.Tree.Node node, void|.Definitions parent)
{
  owner_document = parent;

  if (node) {
    attributes = node->get_attributes();
    ns_node_name = node->get_full_name();
    node_name = node->get_tag_name();
    sscanf(ns_node_name, "%[^:]:%*s", ns_name);
    decode(node);
  }
}

void add_attribute(string name, string value)
{
  attributes[name] = value;
}

void set_attributes(mapping attr)
{
  attributes = attr;
}

mapping get_attributes()
{
  return attributes;
}

string get_ns_node_name()
{
  return ns_node_name;
}

string get_node_name()
{
  return node_name;
}

string get_ns_name()
{
  return ns_name;
}

.Definitions get_owner_document()
{
  return owner_document;
}

protected void decode(Parser.XML.Tree.Node node)
{
  error("decode() not implemented in %O\n", object_program(this));
}
