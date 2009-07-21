#define TRACE_DEBUG
#include "wsdl.h"

// Contains QName
import Standards.XML.Namespace;
import Standards.Constants;
import Parser.XML.Tree;
import ".";

string name;

protected QName target_namespace;
protected string wsdl_xml;
protected mapping(string:QName)    ns        = ([]);
protected mapping(string:Message)  messages  = ([]);
protected mapping(string:PortType) porttypes = ([]);
protected mapping(string:Binding)  bindings  = ([]);
protected mapping(string:Service)  services  = ([]);
protected mapping(string:Import)   imports   = ([]);
protected array(Schema)            schemas   = ({});

void create(void|string xml)
{
  if (xml) {
    wsdl_xml = xml;
    parse(wsdl_xml);
  }
}

QName get_target_namespace()
{
  return target_namespace;
}

void set_target_namespace(string|QName namespace)
{
  if (objectp(namespace))
    target_namespace = namespace;
  else 
    target_namespace = QName(namespace, "targetNamespace");
}

QName get_namespace(string local_name)
{
  return ns[local_name];
}

mapping(string:QName) get_namespaces()
{
  return ns;
}

array(Schema) get_schemas()
{
  return schemas;
}

void add_schema(Schema schema)
{
  schemas += ({ schema });
}

array(Import) get_imports()
{
  return values(imports);
}

Import get_import(string namespace)
{
  return imports[namespace];
}

array(PortType) get_porttypes()
{
  return values(porttypes);
}

PortType get_porttype(string name)
{
  return porttypes[name];
}

array(Binding) get_bindings()
{
  return values(bindings);
}

Binding get_binding(string name)
{
  return bindings[name];
}

array(Service) get_services()
{
  return values(services);
}

Service get_service(string name)
{
  return services[name];
}

array(Message) get_messages()
{
  return values(messages);
}

Message get_message(string name)
{
  return messages[name];
}

array(object) get_types()
{
  array(object) ret = ({});
  foreach (schemas, Schema s)
    ret += s->get_all_elements();
  foreach (values(imports), Import imp)
    if (imp->schema)
      ret += imp->schema->get_all_elements();
  return ret;
}

object get_type(string name)
{
  foreach (get_types(), object o)
    if (o->name && o->name == name)
      return o;
  
  return 0;
}

QName get_wsdl_soap_namespace()
{
  return get_namespace_from_uri(WSDLSOAP_NAMESPACE_URI)||
         QName(WSDLSOAP_NAMESPACE_URI, WSDLSOAP_NAMESPACE_PREFIX, "xmlns");
}

QName get_soap_namespace()
{
  return get_namespace_from_uri(SOAP_NAMESPACE_URI)||
         QName(SOAP_NAMESPACE_URI, SOAP_NAMESPACE_PREFIX, "xmlns");
}

QName get_soap_encoding_namespace()
{
  return get_namespace_from_uri(SOAP_ENCODING_URI)||
         QName(SOAP_ENCODING_URI, SOAP_ENCODING_PREFIX, "xmlns");
}

QName get_wsdl_namespace()
{
  return get_namespace_from_uri(WSDL_NAMESPACE_URI)||
         QName(WSDL_NAMESPACE_URI, WSDL_NAMESPACE_PREFIX, "xmlns");
}

QName get_wsdl_http_namespace()
{
  return get_namespace_from_uri(WSDLHTTP_NAMESPACE_URI)||
         QName(WSDLHTTP_NAMESPACE_URI, WSDLHTTP_NAMESPACE_PREFIX, "xmlns");
}

QName get_wsdl_mime_namespace()
{
  return get_namespace_from_uri(WSDLMIME_NAMESPACE_URI)||
         QName(WSDLMIME_NAMESPACE_URI, WSDLMIME_NAMESPACE_PREFIX, "xmlns");
}

QName get_xsi_namespace()
{
  return get_namespace_from_uri(SOAP_XSI_URI)||
         QName(SOAP_XSI_URI, SOAP_XSI_PREFIX, "xmlns");
}

QName get_xsd_namespace()
{
  return get_namespace_from_uri(SOAP_XSD_URI)||
         QName(SOAP_XSD_URI, SOAP_XSD_PREFIX, "xmlns");
}

QName get_namespace_from_uri(string uri)
{
  foreach (values(ns), QName qn)
    if (qn->get_namespace_uri() == uri)
      return qn;

  return 0;
}

void parse(string xml)
{
  Node root = parse_input(xml);

  if (root && (root = find_root(root))) {
    if (root->get_tag_name() != "definitions")
      error("No WSDL document given to parse()!\n");
    low_parse(root);
  }
}

protected void low_parse(Node n)
{
  string tname = n->get_tag_name();
  string fname = n->get_full_name();

  switch (tname)
  {
    case "definitions":
      foreach (n->get_attributes(); string tag; string nsuri) {
	QName qn = QName(nsuri, tag);
	if (tag == "targetNamespace")
	  target_namespace = qn;

	if (tag != "name")
	  ns[qn->get_local_name()] = qn;
	else
	  name = nsuri;
      }
      break;

    case "types":
      foreach (n->get_children(), Node cn)
	if (cn->get_tag_name() == "schema") {
	  Schema s = Schema(cn, this);
	  schemas += ({ s });
	}

      return; /* Skip children here, taken care of in Schema */

    case "message":
      messages[n->get_attributes()->name] = Message(n, this);
      return;

    case "portType":
      porttypes[n->get_attributes()->name] = PortType(n, this);
      return;

    case "binding":
      bindings[n->get_attributes()->name] = Binding(n, this);
      return;

    case "service":
      services[n->get_attributes()->name] = Service(n, this);
      return;

    case "import":
      imports[n->get_attributes()->namespace] = Import(n, this);
      return;
  }

  foreach (n->get_children(), Node cn)
    if (cn->get_node_type() == XML_ELEMENT)
      low_parse(cn);
}
