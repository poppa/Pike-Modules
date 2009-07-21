import Parser.XML.Tree;
import Standards.XML.Namespace;
inherit .BaseObject;

enum OperationType {
  NONE,
  WSDL,
  SOAP,
  HTTP
};

int type = NONE;
string name;
string style;
string soap_action;
string location;
array parameter_order = ({});

Documentation documentation;
Input input;
Output output;
Fault fault;

protected void decode(Node n)
{
  string wsdl, soap, http;
  wsdl = owner_document->get_wsdl_namespace()->get_local_name();
  soap = owner_document->get_wsdl_soap_namespace()->get_local_name();
  http = owner_document->get_wsdl_http_namespace()->get_local_name();

  if (ns_name == wsdl)
    type = WSDL;
  else if (ns_name == soap)
    type = SOAP;
  else if (ns_name == http)
    type = HTTP;

  mapping a = n->get_attributes();
  name      = a->name;
  if (a->parameterOrder)
    parameter_order = a->parameterOrder/" ";

  foreach (n->get_children(), Node cn) {
    if (cn->get_node_type() == XML_ELEMENT) {
      switch (cn->get_tag_name()) 
      {
	case "documentation":
	  documentation = Documentation(cn, owner_document);
	  break;

	case "input":
	  input = Input(cn, owner_document);
	  break;

	case "output":
	  output = Output(cn, owner_document);
	  break;

	case "fault":
	  fault = Fault(cn, owner_document);
	  break;

	case "operation":
	  mapping ca = cn->get_attributes();
	  soap_action = ca->soapAction;
	  style = ca->style;
	  location = ca->location;
	  break;
      }
    }
  }
}

class Documentation
{
  inherit .BaseObject;

  string text;

  protected void decode(Node n)
  {
    text = n->value_of_node();
  }
}

class Input
{
  inherit .BaseObject;
  QName message;
  //string prefix;
  string use;
  string body_prefix;
  string encoding_style;
  string namespace;

  protected void decode(Node n)
  {
    //sscanf(n->get_attributes()->message||"", "%[^:]:%s", prefix, message);
    mapping a = n->get_attributes();
    message = a->message && QName("", a->message);

    if (Node cn = n->get_first_element()) {
      if (cn->get_tag_name() == "body") {
	sscanf(cn->get_full_name(), "%[^:]:%*s", body_prefix);
	mapping a = cn->get_attributes();
	use = a->use;
	encoding_style = a->encodingStyle;
	namespace = a->namespace;
      }
    }
  }
}

class Output
{
  inherit Input;
}

class Fault
{
  inherit .BaseObject;

  string name;
  string use;
  
  protected void decode(Node n)
  {
    name = n->get_attributes()->name;
    if (n = n->get_first_element()) {
      if (n->get_tag_name() == "fault")
	use = n->get_attributes()->use;
    }
  }
}
