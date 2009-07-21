import Parser.XML.Tree;
import Standards.XML.Namespace;
inherit .BaseObject;

string namespace;
Standards.URI location;
.Schema schema;

protected void decode(Node n)
{
  mapping a = n->get_attributes();
  namespace = a->namespace;
  if (a->location) {
    string xml;
    if (!catch(location = Standards.URI(a->location))) {
      if (mixed e = catch(xml = .get_cache(location)))
	werror("Import error: %s\n", describe_error(e));
      else {
	if (!catch(Node n = parse_input(xml))) {
	  if (n = .find_root(n))
	    schema = .Schema(n, owner_document);
	}
      }
    }
  }
}