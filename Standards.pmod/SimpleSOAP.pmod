/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! SimpleSOAP.pmod is a SOAP client that does a SOAP request to a webservice
//! by using a WSDL file. This is not a full implementation of SOAP and may
//! very well not work with more complex SOAP services.
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| SimpleSOAP.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| SimpleSOAP.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with SimpleSOAP.pmod. If not, see
//| <http://www.gnu.org/licenses/>.

//#define SOAP_DEBUG
//#define SOAP_TRACE

import Standards.WSDL;
import Parser.XML.Tree;

constant VERSION = "0.1";

//! SOAP parameter class
class Param
{
  //! The parameter name
  protected string name;

  //! The parameter value
  protected mixed value;

  //! Creates a new SOAP parameter
  //!
  //! @param _name
  //! @param _value
  void create(string _name, mixed _value)
  {
    name = _name;
    value = _value;
  }
  
  //! Returns the paramter name
  string get_name()
  {
    return name;
  }
  
  //! Returns the parameter value
  string get_value()
  {
    return value;
  }
  
  //! Sets the name of the parameter
  //!
  //! @param _name
  void set_name(string _name)
  {
    name = _name;
  }
  
  //! Sets the value of the paramter
  //!
  //! @param _value
  void set_value(mixed _value)
  {
    value = _value;
  }
  
  //! Serializes the value and creates an XML representation of the parameter
  string to_xml()
  {
    return "<" + name + ">" + serialize(value) + "</" + name + ">";
  }

  //! Cast method
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how)
    {
      case "string":
      case "xml":
	return to_xml();
    }

    error("Can't cast %O() to %O\n", object_program(this), how);
  }

  //! Serialize the value
  //!
  //! @param v
  protected string serialize(mixed v)
  {
    string s = "";
    int type = get_pike_type(v);

    switch (type)
    {
      case PIKE_STRING:
      	s += replace(v, ({ "&", "<", ">" }), ({ "&amp;", "&lt;", "&gt;" }));
	break;

      case PIKE_INT:
	s += (string)v;
	break;

      case PIKE_FLOAT:
	s += sprintf("%.2f", v);
	break;

      case PIKE_DATE:
      	s += v->format_ymd() + " " + v->format_xtod();
	break;

      case PIKE_MAPPING:
	/* Fall through */
      case PIKE_OBJECT:
      	foreach (indices(v), string key)
	  s += sprintf("<%s>%s</%s>", key, serialize( v[key] ), key);
	break;

      case PIKE_MULTISET:
	v = (array)v;
	/* Fall through */
      case PIKE_ARRAY:
	foreach (v, mixed av) {
	  string type = pike_type_to_string(get_pike_type(av));
	  s += sprintf("<%s>%s</%s>", type, serialize(av), type);
	}

	break;

      default:
	/* Nothing */
    }

    return s;
  }

  //! String format
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O)", object_program(this), name, value);
  }
}

//! A SOAP client class
//!
//! To make a basic authentication, set the public members
//! @[Client()->username] and  @[Client()->password].
class Client // {{{
{
  //! The parsed WSDL. @[Standards.WSLD.Definition]
  protected Definitions wsdl;

  //! Username for a basic authentication
  string username;

  //! Password for a basic authentication
  string password;

  //! Set to use another query object for the request
  //protected Protocols.HTTP.Query con;

  //! Invoke the SOAP call.
  //!
  //! @param url
  //!  This should be the URL to the WSDL file, not the endpoint of the
  //!  SOAP method it self.
  //! @param operation
  //!  The SOAP operation to invoke. This is the name of an @tt{operation@}
  //!  element in a @tt{binding@} element in the WSDL file.
  //! @param params
  Response invoke(string|Standards.URI url, string operation,
                  array(Param) params,
		  void|Protocols.HTTP.Query con)
  {
    return load_wsdl(url, operation, params, con);
  }

  //! Loads the WSDL file
  //!
  //! @param url
  //! @param method
  //! @param p
  protected Response load_wsdl(string|Standards.URI url, string method,
                               array(Param) p, void|Protocols.HTTP.Query con)
  {
    url = (string)url;
    if ( wsdl = wsdl_cache[url] )
      return send_soap_request(url, method, p, con);

    //if (con) Standards.WSDL.set_connection(con);
    wsdl = get_url(url, username, password, con);

    if (wsdl) {
      wsdl_cache[url] = wsdl;
      return send_soap_request(url, method, p, con);
    }
  }

  //! Sends the SOAP request
  //!
  //! @param url
  //! @param method
  //! @param p
  protected Response send_soap_request(string|Standards.URI url,
                                       string method, array(Param) p,
				       void|Protocols.HTTP.Query con)
  {
#ifdef SOAP_DEBUG
    werror("*** SOAP Request: %O, %s\n", url, method);
#endif

    string ns = wsdl->get_target_namespace()->get_namespace_uri();

    if (!ns)
      error("Unable to resolv namespace from WSDL\n");

    Port port = wsdl->get_first_soap_port();
    if (!port)
      error("Unable to resolv port from WSDL\n");
    
    Binding binding = wsdl->get_binding(port->binding->get_local_name());
    if (!binding)
      error("Unable to resolv binding from WSDL port binding\n");

    Operation operation = binding->operations[method];
    if (!operation)
      error("Unable to resolv operation from WSDL binding\n");

    PortType porttype = wsdl->get_porttype(binding->type->get_local_name());
    if (!porttype)
      error("Unable to resolv porttype from WSDL binding\n");

    Operation port_op = porttype->operations[method];
    if (!port_op)
      error("Unable to resolv operation from WSDL porttype\n");

    string soapaction = operation->soap_action;
    string endpoint = port->address->location;

    Standards.XML.Namespace.QName in_msg_name = port_op->input->message;
    Standards.XML.Namespace.QName out_msg_name = port_op->output->message;

    Message in_msg = wsdl->get_message(in_msg_name->get_local_name());
    Message out_msg = wsdl->get_message(out_msg_name->get_local_name());

    Body body = Body(ns, in_msg->parts[0]->element->get_local_name(), p);
    Envelope env = Envelope();

    mapping headers = ([]);

    if (username && password) {
      headers["Authorization"] = "Basic " + MIME.encode_base64(username + ":" +
                                                               password);
    }

    headers += ([
      "SOAPAction"   : soapaction,
      "Content-Type" : "text/xml; charset=utf-8",
      "User-Agent"   : "Pike SimpleSOAP Client " + VERSION
    ]);

#ifdef SOAP_DEBUG
    Stdio.write_file(method+"Envelope.xml", env->to_xml(body));
#endif

    Protocols.HTTP.Query q;

#define TRACE_MESSAGE() do                                         \
  {                                                                \
    String.Buffer b = String.Buffer();                             \
    b->add("\n>> ",              endpoint,                  "\n"); \
    b->add("> ",                 query,                     "\n"); \
    b->add("> Host: ",           host,                      "\n"); \
    b->add("> Content-Type: ",   headers["Content-Type"],   "\n"); \
    b->add("> Content-Length: ", headers["Content-Length"], "\n"); \
    b->add("> SOAPAction: ",     headers["SOAPAction"],  "\n>\n"); \
    b->add(_wrap_xml(envelope),                             "\n"); \
    werror(b->get());                                              \
  } while (0)
/* TRACE_MESSAGE() */

    url = Standards.URI(endpoint);

    string host = url->host;
    string query = url->path;
    if (url->query) query += "?" + url->query;
    string envelope = env->to_xml(body);
    headers["Content-Length"] = (string)sizeof(envelope);

    if (con) {
      if (con->con->query_address())
	host = (con->con->query_address()/" ")[0];

      query = sprintf("POST %s HTTP/1.0", query);
#ifdef SOAP_DEBUG
      werror("+++ SimpleSOAP()->Client()->con->sync_request(%O,%d,%O,%O)\n", 
             host, url->port, query, headers);
#endif

#ifdef SOAP_TRACE
      TRACE_MESSAGE();
#endif

      q = con->sync_request(host, url->port, query, headers, envelope);
    }
    else {
#ifdef SOAP_TRACE
      TRACE_MESSAGE();
#endif
      q = Protocols.HTTP.do_method("POST", endpoint, 0, headers, 0, envelope);
    }

    if (q->status != 200) {
      werror("Bad status (%d) in SOAP call %O\n", q->status, (string)url);
      if (q->status != 500)
	return 0;
    }

    return Response(wsdl, out_msg, q->data());
  }

#ifdef SOAP_TRACE
  private string _wrap_xml(string xml) {
    xml = String.trim_all_whites(Standards.XML.indent(xml));
    String.Buffer b = String.Buffer();
    foreach (xml/"\n", string l)
      b->add("> ", l, "\n");

    return b->get();
  }
#endif
} // }}}

//! Class representing a response from a SOAP call
class Response // {{{
{
  //! The WSDL file
  protected Definitions wsdl;

  //! The root node of the response
  protected Node response;

  //! Eventual SOAP fault
  protected Fault fault;

  //! The name of the response node
  protected string response_name;

  //! The name of the result node
  protected string result_name;

  //! The response element type. @[Standards.WSDL.Types.Type]
  protected Types.Type response_element;

  //! The result types: @tt{name : xsi:type@}
  protected mapping(string:string) wsdl_types = ([]);

  //! The end result
  protected mapping(string:mixed) result;

  //! Creats a new Result object
  //!
  //! @param _wsdl
  //! @param out
  //!  The output message from the WSDL file. @[Standards.WSDL.Message]
  //! @param _response
  //!  The raw SOAP XML response to parse
  void create(Definitions _wsdl, Message out, string _response)
  {
    wsdl     = _wsdl;
    response = parse_input(_response);

    if (out->parts[0]->element)
      response_name = out->parts[0]->element->get_local_name();

    response_element = wsdl->get_schemas()[0]->get_element(response_name);
    result_name = get_result_element_name(response_element->elements);

#ifdef SOAP_DEBUG
    Stdio.write_file(response_name + ".xml", _response);
#endif

    get_wsdl_types();
    parse();
  }

  //! Did a SOAP fault occure or not?
  int(0..1) is_fault()
  {
    return !!fault;
  }

  //! Returns the SOAP fault object if one exists.
  //!
  //! @seealso
  //!  @[Fault]
  Fault get_fault()
  {
    return fault;
  }

  //! Returns the parsed result
  mapping(string:mixed) get_result()
  {
    return result;
  }

  //! Tries to find all result items with the name @[name]
  //!
  //! @param name
  array get_named_items(string name)
  {
    array a = low_get_named_item(result[result_name], name);
    return a;
  }

  //! Searches for @[name] in @[m]
  protected array low_get_named_item(array|mapping m, string name)
  {
    array c = ({});

    if (mappingp(m)) {
      foreach (m; string key; mixed v) {
	if (key == name)
	  c += ({ v });
	else {
	  if (mappingp(v) || arrayp(v))
	    c += low_get_named_item(v, name);
	}
      }
    }
    else if (arrayp(m))
      foreach (m, mixed v)
	if (mappingp(v) || arrayp(v))
	  c += low_get_named_item(v, name);

    return c;
  }

  //! Parses the raw SOAP response
  protected void parse()
  {
    Node res = find_node_by_name(response, result_name);
    if (!res)
      res = find_node_by_name(response, "return");

    if (!res) {
      res = find_node_by_name(response, "Fault");
      if (res) {
	Node code = find_node_by_name(res, "faultcode");
	Node str  = find_node_by_name(res, "faultstring");
	Node det  = find_node_by_name(res, "detail");
	fault = Fault(code->value_of_node(), str->value_of_node(), det);
	return;
      }
    }

    result = res && extract(res, ([]));
  }

  //! Tries to find the name of the result node from the types resolved from
  //! the WSDL file
  //!
  //! @param types
  protected string get_result_element_name(array(Types.Type) types)
  {
    Types.Type t;
    foreach (types, Types.Type ele) {
      if (ele->name) {
	t = ele;
	break;
      }
      else
	return get_result_element_name(ele->elements);
    }

    return t && t->name;
  }

  //! Find the first XML node with name @[name] in node @[n].
  //!
  //! @param n
  //! @param name
  //! @param full
  //!  If @expr{1@} @[name] only matches nodes with the same namespace prefix
  protected Node find_node_by_name(Node n, string name, int(0..1)|void full)
  {
    Node r;
    n->walk_inorder(
      lambda(Node n) {
	if (n->get_node_type() != XML_ELEMENT)
	  return;

	if (full && n->get_full_name() == name) {
	  r = n;
	  return STOP_WALK;
	}
	else if (n->get_tag_name() == name) {
	  r = n;
	  return STOP_WALK;
	}
      }
    );

    return r;
  }

  //! Collects all nodes with name @[name] in node @[n]
  //!
  //! @param n
  //! @param name
  //! @param full
  //!  If @expr{1@} @[name] only matches nodes with the same namespace prefix
  protected array(Node) get_nodes_by_tag_name(Node n, string name,
                                              void|int(0..1) full)
  {
    array(Node) nds = ({});
    n->walk_inorder(
      lambda (Node nn) {
	if (nn->get_node_type() == XML_ELEMENT) {
	  if (full && nn->get_full_name() == name)
	    nds += ({ nn });
	  else if (nn->get_tag_name() == name)
	    nds += ({ nn });
	}
      }
    );

    return nds;
  }

  //! Resolv result types
  protected void get_wsdl_types()
  {
    array(Node) nds;
    if (find_node_by_name(response, "schema"))
      nds = get_nodes_by_tag_name(response, "element");

    // Resolv types from response
    if (nds && sizeof(nds)) {
      foreach (nds, Node n) {
	mapping attr = shorten_attributes(n->get_attributes());
	if (attr->name && attr->type)
	  wsdl_types[attr->name] = attr->type;
      }
    }
    // Resolv types from WSDL
    else {
      array(Types.Type) els = response_element->get_element_elements();
      foreach (els||({}), Types.Type t) {
	if (!t->type) {
	  array(Types.Type) ct = t->find_children(Types.TYPE_RESTRICTION);
	  if (ct && sizeof(ct) == 1)
	    wsdl_types[t->name] = ct[0]->base->get_local_name();
	}
	else
	  wsdl_types[t->name] = t->type->get_local_name();
      }
    }
  }

  //! Parses node @[n] recursivley for result elements and populates @[p]
  //!
  //! @param n
  //! @param p
  protected mapping extract(Node n, mapping p)
  {
    string name = n->get_tag_name();
    p[name] = ([]);

    if (!n->get_first_element()) {
      p[name] = extract_value(n);
      return p;
    }

    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() != XML_ELEMENT)
	continue;

      if (cn->get_first_element()) {
	if (cn->count_children() > 1) {
	  if (!arrayp( p[name] ))
	    p[name] = ({});
#ifdef SOAP_DEBUG
//	  werror("Extract to array: %s\n", cn->get_tag_name());
#endif
	  p[name] += ({ extract(cn, ([])) });
	}
	else {
#ifdef SOAP_DEBUG
//	  werror("Extract to mapping: %s\n", cn->get_tag_name());
#endif
	  if (sizeof( p[name] )) {
	    if (!arrayp( p[name] ))
	      p[name] = ({ p[name] });

	    p[name] += ({ extract(cn, ([])) });
	  }
	  else
	    p[name] += extract(cn, ([]));
	}
      }
      else {
	string cname = cn->get_tag_name();
	if ( p[name][cname] ) {
	  if (!arrayp( p[name][cname] ))
	    p[name][cname] = ({ p[name][cname] });

	  p[name][cname] += ({ extract_value(cn) });
	}
	else
	  p[name][cname] = extract_value(cn);
      }
    }

    return p;
  }

  //! Extracts the value from node @[n] and tries to encode the value to the
  //! proper Pike type.
  //!
  //! TODO: Most XSI types are represented in @[Standards.XSD.Types], perhaps
  //! implement that here
  //!
  //! @param n
  protected mixed extract_value(Node n)
  {
    string type = wsdl_types[n->get_full_name()]||"undefined";
    sscanf(type, "%*s:%s", type);
    string v = n->value_of_node();
    switch (lower_case(type))
    {
      default:
      case "string":
	return (string)v;

      case "long":
      case "int":
	return (int)v;

      case "boolean":
	return v == "true";

      case "double":
	return (float)v;

      case "date":
	Calendar.Day d;
	if (mixed e = catch(d = .XSD.Types.Date(v)->get())) {
	  werror("Unable to parse date: %O\n", v);
	  return (string)v;
	}
	return d;

      case "time":
	Calendar.Second s;
	if (mixed e = catch(s = .XSD.Types.Date(v)->get())) {
	  werror("Unable to parse time: %O\n", v);
	  return (string)v;
	}
	return s;

      case "datetime":
	Calendar.Hour t;
	if (mixed e = catch(t = .XSD.Types.DateTime(v)->get())) {
	  werror("Unable to parse dateTime: %O\n", v);
	  return (string)v;
	}
	return t;
    }
  }
} // }}}

//! A SOAP fault class
class Fault // {{{
{
  //! The SOAP fault code
  protected string faultcode;

  //! The SOAP fault message
  protected string faultstring;

  //! The SOAP fault details
  protected mixed  detail;

  //! Create a new SOAP Fault object
  //!
  //! @param code
  //! @param
  void create(string code, string message, void|mixed details)
  {
    faultcode = code;
    faultstring = message;
    detail = details;
  }

  //! Returns the fault code
  string get_code()
  {
    return faultcode;
  }

  //! Returns the fault string
  string get_string()
  {
    return faultstring;
  }

  //! Returns the fault details
  mixed get_details()
  {
    return detail;
  }
} // }}}

//! A SOAP envelope
class Envelope // {{{
{
  //! The SOAP body
  protected Body body;

  //! Default namespaces
  protected mapping(string:string) namespaces = ([
    "xmlns:xsi"  : "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:xsd"  : "http://www.w3.org/2001/XMLSchema",
    "xmlns:soap" : "http://schemas.xmlsoap.org/soap/envelope/"
  ]);

  //! Set the SOAP body
  //!
  //! @param _body
  void set_body(Body _body)
  {
    body = _body;
  }

  //! Returns the namespaces
  mapping get_namespaces()
  {
    return namespaces;
  }

  //! Add a namespace
  //!
  //! @param ns
  //!  The name of the namespace. Since this class doesn't have any mechanism
  //!  for assigning namespaces this argument should be a prefixed namespace
  //!  name, i.e. @expr{prefix:name@}.
  //! @param value
  //!  The namespace URI
  void add_namespace(string ns, string value)
  {
    namespaces[ns] = value;
  }

  //! Turns the object into an XML representation of the envelope, i.e. what
  //! to send in a SOAP call.
  string to_xml(void|Body _body)
  {
    if (!_body && !body)
      error("Missing required body element in SOAP Envelope\n");

    string s = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
    return string_to_utf8(
      s + sprintf("<soap:Envelope%{ %s=\"%s\"%}>%s</soap:Envelope>",
                  (array)namespaces, (_body||body)->to_xml())
    );
  }
} // }}}

//! A SOAP body class
class Body // {{{
{
  //! The default namespace
  protected string namespace;

  //! The operation/method that is to be called
  protected string method;

  //! The SOAP parameters
  protected array(Param) params;

  //! Creates a new Body object
  //!
  //! @param _namespace
  //! @param _method
  //! @param _params
  void create(string _namespace, string _method, array(Param) _params)
  {
    namespace = _namespace;
    method    = _method;
    params    = _params;
  }

  //! Turns this object into an XML representation
  string to_xml()
  {
    string s = "<soap:Body>";
    s += sprintf("<%s xmlns=%O>%s</%s>",
                 method, namespace, params->to_xml()*"", method);
    return s + "</soap:Body>";
  }
} // }}}

constant PIKE_STRING    = 1<<0;
constant PIKE_FLOAT     = 1<<1;
constant PIKE_INT       = 1<<2;
constant PIKE_MAPPING   = 1<<3;
constant PIKE_ARRAY     = 1<<4;
constant PIKE_MULTISET  = 1<<5;
constant PIKE_OBJECT    = 1<<6;
constant PIKE_PROGRAM   = 1<<7;
constant PIKE_FUNCTION  = 1<<8;
constant PIKE_CLASS     = 1<<9;
constant PIKE_DATE      = 1<<10;
constant PIKE_NULL      = 1<<11;

private mapping wsdl_cache = ([]);

//! Check (lazy) if object @[o] is a Calendar object
//!
//! @param o
int(0..1) is_date_object(object o) // {{{
{
  return !!o->format_iso_time;
} // }}}

//! Returns a string representation of Pike type @[t]
//!
//! @param t
string pike_type_to_string(int t) // {{{
{
  return ([ PIKE_STRING   : "string",
            PIKE_FLOAT    : "float",
	    PIKE_INT      : "int",
	    PIKE_MAPPING  : "mapping",
	    PIKE_ARRAY    : "array",
	    PIKE_MULTISET : "multiset",
	    PIKE_OBJECT   : "object",
	    PIKE_PROGRAM  : "program",
	    PIKE_FUNCTION : "function",
	    PIKE_CLASS    : "class",
	    PIKE_DATE     : "DateTime",
	    PIKE_NULL     : "undefined" ])[t]||PIKE_NULL;
} // }}}

//! Tries to find the Pike type of @[v]
//!
//! @param v
int get_pike_type(mixed v) // {{{
{
  if (stringp(v))
    return PIKE_STRING;

  if (floatp(v))
    return PIKE_FLOAT;

  if (intp(v))
    return PIKE_INT;

  if (mappingp(v))
    return PIKE_MAPPING;

  if (arrayp(v))
    return PIKE_ARRAY;

  if (multisetp(v))
    return PIKE_MULTISET;

  if (objectp(v)) {
    if (is_date_object(v))
      return PIKE_DATE;

    return PIKE_OBJECT;
  }

  if (programp(v))
    return PIKE_PROGRAM;

  if (functionp(v) || callablep(v))
    return PIKE_FUNCTION;

  return PIKE_NULL;
} // }}}

//! Returns the name part of a namespaced XML attribute
//!
//! @param m
protected mapping shorten_attributes(mapping m) // {{{
{
  mapping out = ([]);
  foreach (m||([]); string k; string v) {
    sscanf(k, "%*s:%s", k);
    out[k] = v;
  }

  return out;
} // }}}

