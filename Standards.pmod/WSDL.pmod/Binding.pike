import Parser.XML.Tree;
import Standards.XML.Namespace;
inherit .BaseObject;

enum BindingType {
  NONE,
  WSDL,
  SOAP,
  HTTP
};

int binding_type = NONE;
string name;
QName  type;
string transport;
string verb;
string style;
mapping(string:.Operation) operations = ([]);

protected void decode(Node n)
{
  string wsdl, soap, http;
  wsdl = owner_document->get_wsdl_namespace()->get_local_name();
  soap = owner_document->get_wsdl_soap_namespace()->get_local_name();
  http = owner_document->get_wsdl_http_namespace()->get_local_name();

  if (ns_name == wsdl)
    binding_type = WSDL;
  else if (ns_name == soap)
    binding_type = SOAP;
  else if (ns_name == http)
    binding_type = HTTP;

  mapping a = n->get_attributes();
  name = a->name;
  type = a->type && QName("", a->type);

  if (type) {
    if (QName p = owner_document->get_namespace(type->get_prefix()))
      type->set_namespace_uri(p->get_namespace_uri());
  }

  foreach (n->get_children(), Node cn) {
    if (cn->get_node_type() == XML_ELEMENT) {
      switch (cn->get_tag_name())
      {
	case "operation":
	  operations[cn->get_attributes()->name] = 
	    .Operation(cn, owner_document);
	  break;

	case "binding":
	  mapping ca = cn->get_attributes();
	  style = ca->style;
	  transport = ca->transport;
	  verb = ca->verb;
	  break;
      }
    }
  }
}
