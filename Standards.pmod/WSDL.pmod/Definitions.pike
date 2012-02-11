/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This class represents the root of a WSDL file
//|
//| Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//|
//| This class represents be root of a WSDL file
//|
//| License GNU GPL version 3
//|
//| Definitions.pike is part of WSDL.pmod
//|
//| WSDL.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| WSDL.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with WSDL.pmod. If not, see <http://www.gnu.org/licenses/>.

#define TRACE_DEBUG
#include "wsdl.h"

// Contains QName
import Standards.XML.Namespace;
import Standards.SOAP.Constants;
import Parser.XML.Tree;
import ".";

//! The name attribute if any
string name;

//! The WSDL target namespace
protected QName target_namespace;

//! The raw XML of the WSDL file
protected string wsdl_xml;

//! Namespace container. The key is the local name of the namespace attribute.
//! I.e. @tt{xmlns:tns="someNsURI"@} will have the key @tt{tns@}.
protected mapping(string:QName) ns = ([]);

//! Container for the WSDL messages
//! The key is the name attribute of the message node.
protected mapping(string:Message) messages = ([]);

//! Container for the WSDL port types.
//! The key is the name attribute of the porttype node
protected mapping(string:PortType) porttypes = ([]);

//! Container for the WSDL bindings
//! The key is the name attribute of the binding node
protected mapping(string:Binding) bindings = ([]);

//! Container for the WSDL services (in most cases only one)
//! The key is the name attribute of the service node
protected mapping(string:Service) services = ([]);

//! Container for the WSDL imports (only the imports directly under the 
//! definitions node, not eventuals imports in the schema node)
protected mapping(string:Import) imports = ([]);

//! Container for the WSDL scemas
protected array(Schema) schemas = ({});

//! Creates a new Definitions object
//!
//! @param xml
//!  The raw XML of a WSDL file
void create(void|string|Node xml)
{
  if (xml) {
    if (stringp(xml)) {
      wsdl_xml = xml;
      parse(wsdl_xml);
    }
    else low_parse(xml);
  }
}

//! Returns the target namespace
QName get_target_namespace()
{
  return target_namespace;
}

//! Sets the target namespace
//!
//! @param namespace
void set_target_namespace(string|QName namespace)
{
  if (objectp(namespace))
    target_namespace = namespace;
  else 
    target_namespace = QName(namespace, "targetNamespace");
}

//! Returns the namespace with local name @[local_name]
//!
//! @param local_name
QName get_namespace(string local_name)
{
  return ns[local_name];
}

//! Returns all namespaces
mapping(string:QName) get_namespaces()
{
  return ns;
}

//! Returns all schemas
array(Schema) get_schemas()
{
  return schemas;
}

//! Add a schema
//!
//! @param schema
void add_schema(Schema schema)
{
  schemas += ({ schema });
}

//! Returns the WSDL imports
array(Import) get_imports()
{
  return values(imports);
}

//! Returns the import with namespace @[namespace]
Import get_import(string namespace)
{
  return imports[namespace];
}

//! Returns all port types
array(PortType) get_porttypes()
{
  return values(porttypes);
}

//! Returns the port type with name @[name]
PortType get_porttype(string name)
{
  return porttypes[name];
}

//! Returns all bindings
array(Binding) get_bindings()
{
  return values(bindings);
}

//! Returns the bidning with name @[name]
Binding get_binding(string name)
{
  return bindings[name];
}

//! Returns all services
array(Service) get_services()
{
  return values(services);
}

//! Returns the service with name @[name]
Service get_service(string name)
{
  return services[name];
}

//! Returns all messages
array(Message) get_messages()
{
  return values(messages);
}

//! Returns the message with name @[name]
Message get_message(string name)
{
  return messages[name];
}

//! Returns all types from all schemas
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

//! Returns the @[Types.Type] with name @[name]
//!
//! @param name
object get_type(string name)
{
  foreach (get_types(), object o)
    if (o->name && o->name == name)
      return o;
  
  return 0;
}

//! Returns the first SOAP port found in the first service
Port get_first_soap_port()
{
  Service s = values(services)[0];
  return s->get_soap_port();
}

//! Returns the WSDL SOAP namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_wsdl_soap_namespace()
{
  return get_namespace_from_uri(WSDLSOAP_NAMESPACE_URI)||
         QName(WSDLSOAP_NAMESPACE_URI, WSDLSOAP_NAMESPACE_PREFIX, "xmlns");
}

//! Returns the WSDL SOAP 1.2 namespace used in the WSDL document or the 
//! standard namespace if none is found.
QName get_wsdl_soap12_namespace()
{
  return get_namespace_from_uri(WSDLSOAP12_NAMESPACE_URI)||
         QName(WSDLSOAP12_NAMESPACE_URI, WSDLSOAP12_NAMESPACE_PREFIX, "xmlns");
}

//! Returns the SOAP namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_soap_namespace()
{
  return get_namespace_from_uri(SOAP_NAMESPACE_URI)||
         QName(SOAP_NAMESPACE_URI, SOAP_NAMESPACE_PREFIX, "xmlns");
}

//! Returns the SOAP encoding namespace used in the WSDL document or the 
//! standard namespace if none is found.
QName get_soap_encoding_namespace()
{
  return get_namespace_from_uri(SOAP_ENCODING_URI)||
         QName(SOAP_ENCODING_URI, SOAP_ENCODING_PREFIX, "xmlns");
}

//! Returns the WSDL namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_wsdl_namespace()
{
  return get_namespace_from_uri(WSDL_NAMESPACE_URI)||
         QName(WSDL_NAMESPACE_URI, WSDL_NAMESPACE_PREFIX, "xmlns");
}

//! Returns the WSDL HTTP namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_wsdl_http_namespace()
{
  return get_namespace_from_uri(WSDLHTTP_NAMESPACE_URI)||
         QName(WSDLHTTP_NAMESPACE_URI, WSDLHTTP_NAMESPACE_PREFIX, "xmlns");
}

//! Returns the WSDL MIME namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_wsdl_mime_namespace()
{
  return get_namespace_from_uri(WSDLMIME_NAMESPACE_URI)||
         QName(WSDLMIME_NAMESPACE_URI, WSDLMIME_NAMESPACE_PREFIX, "xmlns");
}

//! Returns the XSI namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_xsi_namespace()
{
  return get_namespace_from_uri(SOAP_XSI_URI)||
         QName(SOAP_XSI_URI, SOAP_XSI_PREFIX, "xmlns");
}

//! Returns the XSD namespace used in the WSDL document or the standard
//! namespace if none is found.
QName get_xsd_namespace()
{
  return get_namespace_from_uri(SOAP_XSD_URI)||
         QName(SOAP_XSD_URI, SOAP_XSD_PREFIX, "xmlns");
}

//! Tries to find the namespace used in the document with the uri @[uri]
//!
//! @param uri
QName get_namespace_from_uri(string uri)
{
  foreach (values(ns), QName qn)
    if (qn->get_namespace_uri() == uri)
      return qn;

  return 0;
}

//! Tries to find the namespace with local name @[name]
QName get_namespace_from_local_name(string name)
{
  foreach (values(ns), QName qn)
    if (qn->get_local_name() == name)
      return qn;

  return 0;
}

//! Parses a raw WSDL document
//!
//! @param xml
void parse(string|Node xml)
{
  Node root = parse_input(xml);

  if (root && (root = find_root(root))) {
    if (root->get_tag_name() != "definitions")
      error("No WSDL document given to parse()!\n");
    low_parse(root);
  }
}

//! Low level parser
//!
//! @param n
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
      
    default:
      TRACE("Unhandled node found: %O\n", n); 
    
  }

  foreach (n->get_children(), Node cn)
    if (cn->get_node_type() == XML_ELEMENT)
      low_parse(cn);
}
