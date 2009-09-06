//#define SOAP_DEBUG

import Parser.XML.Tree;

constant PIKE_STRING    = 1<<1;
constant PIKE_FLOAT     = 1<<2;
constant PIKE_INT       = 1<<3;
constant PIKE_MAPPING   = 1<<4;
constant PIKE_ARRAY     = 1<<5;
constant PIKE_MULTISET  = 1<<6;
constant PIKE_OBJECT    = 1<<7;
constant PIKE_PROGRAM   = 1<<8;
constant PIKE_FUNCTION  = 1<<9;
constant PIKE_CLASS     = 1<<10;
constant PIKE_DATE      = 1<<11;
constant PIKE_NULL      = 1<<12;

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
	    PIKE_DATE     : "dateTime",
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

//! SOAP parameters
class Params // {{{
{
  protected mapping container = ([]);
  
  //! Add a parameter to the object
  //!
  //! @param name
  //! @param value
  //!
  //! @returns
  //!  This object.
  Params add(string name, mixed value)
  {
    container[name] = value;
    return this;
  }
  
  //! Turns the object into an XML representation
  string to_xml()
  {
    string xml = "";
    foreach (container; string key; mixed v)
      if (!(functionp(v) && programp(v)))
	xml += sprintf("<%s>%s</%s>", key, serialize(v), key);
    
    return xml;
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
  
  //! Serializes the internal @[container] array
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
} // }}}

class Client
{
  string username;
  string password;
  
  Response invoke(string|Standards.URI url, string method, Params params)
  {
    return load_wsdl(url, method, params);
  }

  protected Response load_wsdl(string|Standards.URI url, string method, 
                                     Params p)
  {
    url = (string)url;
    string wsdl = wsdl_cache[url];
    if (wsdl)
      return on_wsdl(url, method, p, wsdl);

    Protocols.HTTP.Query q = Protocols.HTTP.get_url(url+"?wsdl");
    if (q && q->status == 200)
      return on_wsdl(url, method, p, q->data());

    error("Bad status (%d) in HTTP query to %O\n", q && q->status, (string)url);
  }
  
  protected Response on_wsdl(string|Standards.URI url, string method, 
                                   Params p, string wsdl)
  {
    wsdl_cache[(string)url] = wsdl;
    return send_soap_request(url, method, p, wsdl);
  }

  protected Response send_soap_request(string|Standards.URI url, 
                                       string method, Params p, 
                                       string wsdl)
  {

#ifdef SOAP_DEBUG
    werror("*** SOAP Request: %O, %s, %O\n", url, method, p->to_xml());
#endif

    Node wxml = parse_input(wsdl);
    wxml = find_root(wxml);
    mapping a = wxml && shorten_attributes(wxml->get_attributes());
    string ns = a && a->targetNamespace;

    if (!ns)
      error("Unable to resolv namespace from WSDL\n");

    Body body = Body(ns, method, p);
    Envelope env = Envelope();

#ifdef SOAP_DEBUG
    werror("Envelope XML:\n%s\n", env->to_xml(body));
#endif

    mapping headers = ([]);

    if (username && password) {
      headers["Authorization"] = "Basic " + MIME.encode_base64(username + ":" +
                                                               password);
    }

    string soapaction = (ns[-1] == '/' ? ns : ns + "/") + method;
    headers += ([
      "SOAPAction" : soapaction,
      "Content-Type" : "text/xml; charset=utf-8"
    ]);
    
    Protocols.HTTP.Query q = Protocols.HTTP.do_method("POST", url, 0, headers,
                                                      0, env->to_xml(body));
    if (q->status != 200)
      werror("Bad status (%d) in SOAP call %O\n", q->status, (string)url);

    return Response(method, wsdl, q->data());
  }
  
  protected Node find_root(Node n)
  {
    Node root;
    n && n->iterate_children(
      lambda (Node nn) {
	if (nn->get_node_type() == XML_ELEMENT) {
	  root = nn;
	  return STOP_WALK;
	}
      }
    );
    return root;
  }
}

class Response
{
  protected string  method;
  protected Node    wsdl;
  protected Node    response;
  protected Fault   fault; 
  protected mapping wsdl_types = ([]);
  protected mapping result;
  
  void create(string _method, string _wsdl, string _response)
  {
    method   = _method;
    wsdl     = parse_input(_wsdl);
    response = parse_input(_response);

    //Stdio.write_file("resp.xml", _response);

    get_wsdl_types();
    parse();
  }
  
  int(0..1) is_fault()
  {
    return !!fault;
  }
  
  Fault get_fault()
  {
    return fault;
  }

  mapping get_result()
  {
    return result;
  }

  array get_named_items(string name)
  {
    array a = low_get_named_item(result[method+"Result"], name);
    return a;
  }

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
  
  protected void parse()
  {
    Node res = find_node_by_name(response, method + "Result");
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

    result = extract(res, ([]));
  }

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

  protected void get_wsdl_types()
  {
    array(Node) nds = get_nodes_by_tag_name(response, "element");
    if (!nds || !sizeof(nds))
      nds = get_nodes_by_tag_name(wsdl, "element");

    foreach (nds, Node n) {
      mapping attr = shorten_attributes(n->get_attributes());
      if (attr->name && attr->type)
	wsdl_types[attr->name] = attr->type;
    }
  }

  protected mapping extract(Node n, mapping p)
  {
    string name = n->get_tag_name();
    p[name] = ([]);
    
    if (!n->count_children()) {
      p[n->get_tag_name()] = extract_value(n);
      return p;
    }

    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() != XML_ELEMENT)
	continue;
      
      if (cn->get_first_element()) {
	if (cn->count_children() > 1) {
	  p[name] = ({});
	  foreach (cn->get_children(), Node ccn)
	    p[name] += ({ extract(ccn, ([])) }); 
	}
	else
	  p[name] += extract(cn, ([]));
      }
      else {
	string cname = cn->get_tag_name();
	if ( p[name][cname] ) {
	  if (!arrayp( p[name][cname] ))
	    p[name][cname] = ({ p[name][cname] });
	  
	  p[name][cname] += ({ extract_value(cn) });
	}
	else
	  p[name][cn->get_tag_name()] = extract_value(cn);
      }
    }

    return p;
  }
  
  protected mixed extract_value(Node n)
  {
    string type = wsdl_types[n->get_full_name()]||"undefined";
    sscanf(type, "%*s:%s", type);
    string v = n->value_of_node();
    switch (lower_case(type))
    {
      default:
      case "string":
	return v;

      case "long":
      case "int":
	return (int)v;

      case "boolean":
	return v == "true";

      case "double":
	return (float)v;

      case "datetime":
#define HAS_TZ_OFFSET(V) (sscanf((V), "%*s+%*d") > 0)
#define HAS_TZ(V)        (sscanf((V), "%*sZ") > 0)
#define HAS_SECFRAC(V)   (sscanf((V), "%*sT%*2d:%*2d:%2*d.%*d") > 4)
	string fmt = "%Y-%M-%DT%h:%m:%s";
	if (v[0] == '-')      fmt = "-" + fmt;
	if (HAS_SECFRAC(v))   fmt += ".%f";
	if (HAS_TZ(v))        fmt += "%z";
	if (HAS_TZ_OFFSET(v)) fmt += "+%h:%m";
	Calendar.Second t;

	if (mixed e = catch(t = Calendar.parse(fmt, v)) || t == 0) {
	  werror("Unable to parse (%s) DateTime: %s\n", fmt, v);
	  return (string)v;
	}

	return t;
#undef HAS_SECFRAC
#undef HAS_TZ
#undef HAS_TZ_OFFSET
    }
  }
}

class Fault
{
  protected int    faultcode;
  protected string faultstring;
  protected mixed  detail;
  
  void create(int code, string message, void|mixed details)
  {
    faultcode = code;
    faultstring = message;
    detail = details;
  }
  
  int get_code()
  {
    return faultcode;
  }
  
  string get_string()
  {
    return faultstring;
  }

  mixed get_details()
  {
    return detail;
  }
}

class Envelope
{
  protected Body body;
  
  protected mapping(string:string) namespaces = ([
    "xmlns:xsi"  : "http://www.w3.org/2001/XMLSchema-instance",
    "xmlns:xsd"  : "http://www.w3.org/2001/XMLSchema",
    "xmlns:soap" : "http://schemas.xmlsoap.org/soap/envelope/"
  ]);
  
  void set_body(Body _body)
  {
    body = _body;
  }

  mapping get_namespaces()
  {
    return namespaces;
  }
  
  void add_namespace(string ns, string value)
  {
    namespaces[ns] = value;
  }
  
  string to_xml(void|Body _body)
  {
    string s = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
    return string_to_utf8(
      s + sprintf("<soap:Envelope%{ %s=\"%s\"%}>%s</soap:Envelope>",
                  (array)namespaces, (_body||body)->to_xml())
    );
  }
}

class Body
{
  protected string namespace;
  protected string method;
  protected Params params;

  void create(string _namespace, string _method, Params _params)
  {
    namespace = _namespace;
    method    = _method;
    params    = _params;
  }

  string to_xml()
  {
    string s = "<soap:Body>";
    s += sprintf("<%s xmlns=%O>%s</%s>", 
                 method, namespace, (string)params, method);
    return s + "</soap:Body>";
  }
}