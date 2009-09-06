#define SOAP_DEBUG

import Parser.XML.Tree;

constant URI_NS_SOAP_ENCODING   = "http://schemas.xmlsoap.org/soap/encoding/";
constant URI_NS_SOAP_ENVELOPE   = "http://schemas.xmlsoap.org/soap/envelope/";
constant URI_NS_SOAP_ACTOR_NEXT = "http://schemas.xmlsoap.org/soap/actor/next";


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
constant PIKE_NIL       = 1<<12;

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
	    PIKE_NIL      : "nil" ])[t]||PIKE_NIL;
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

  return PIKE_NIL;
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

class SimpleClient
{
  string username;
  string password;
  string endpoint;
  string method;
  
  void create(string url, string _method)
  {
    endpoint = url;
    method = _method;
  }
  
  string call(Envelope env)
  {
    mapping headers = ([]);

    if (username && password) {
      headers["Authorization"] = "Basic " + MIME.encode_base64(username + ":" +
                                                               password);
    }

    string soapaction = (endpoint[-1] == '/' ? endpoint : endpoint + "/") + method;
    headers += ([
      "SOAPAction" : soapaction,
      "Content-Type" : "text/xml; charset=utf-8"
    ]);

    werror("%s\n", env->to_xml());

    Protocols.HTTP.Query q = Protocols.HTTP.do_method("POST", endpoint, 0, headers,
                                                      0, env->to_xml());
						      
    werror("%O\n", q->data());
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

protected class Part
{
  protected array(QName) namespaces = ({});
  
  protected string ns_as_attributes()
  {
    array out = ({});
    mapping assigned = ([]);

    foreach (namespaces, QName ns) {
      string name = ns->get_local_part();
      string prefix = ns->get_prefix();
      string uri = ns->get_namespace_uri();

      string prefixed_name, fullname;

      prefixed_name = ns->get_full_name();
      fullname = prefixed_name;

      if ( assigned[prefixed_name] )
	fullname += (string)((assigned[prefixed_name]++)-1);
      else
	assigned[prefixed_name] = 1;
      
      out += ({ fullname + "=\"" + uri + "\"" });
    }
    
    return out * " ";
  }
}

class Envelope
{
  inherit Part;

  protected Body body;
  protected string enc_style_uri;

  protected array(QName) namespaces = ({
    QName("xmlns:xsi",  "http://www.w3.org/2001/XMLSchema-instance"),
    QName("xmlns:xsd",  "http://www.w3.org/2001/XMLSchema"),
    QName("xmlns:soap", "http://schemas.xmlsoap.org/soap/envelope/")
  });
  
  void set_encoding_style_uri(string uri)
  {
    enc_style_uri = uri;
  }

  void set_body(Body _body)
  {
    body = _body;
  }

  array get_namespaces()
  {
    return namespaces;
  }

  void add_namespace(QName value)
  {
    namespaces += ({ value });
  }

  string to_xml(void|Body _body)
  {
    string s = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
    return string_to_utf8(
      s + sprintf("<soap:Envelope %s>%s</soap:Envelope>",
                  ns_as_attributes(), (_body||body)->to_xml())
    );
  }
}

class Body
{
  protected QName        ns;
  protected string       method;
  protected array(Param) params;

  void create(QName _namespace, string _method, array(Param) _params)
  {
    ns     = _namespace;
    method = _method;
    params = _params;
  }
  
  QName get_namespace()
  {
    return ns;
  }
  
  string get_method()
  {
    return method;
  }

  string to_xml()
  {
    string body = method;

    if (ns->get_prefix())
      body = ns->get_local_part() + ":" + body;

    string s = "<soap:Body>";

    s += sprintf("<%s %s=%O>%s</%s>",
                 body, ns->get_full_name(),
		 ns->get_namespace_uri(),
		 (params && params->serialize()*"")||"",
		 body);

    return s + "</soap:Body>";
  }
}

class Param
{
  string name;
  mixed value;
  mixed converter;

  void create(string _name, mixed _value, object type)
  {
    name = _name;
    value = _value;
    converter = type;
  }

  string serialize()
  {
    object o = converter(value);
    string s = "<" + name + " xsi:type=\"xsd:" + o->get_type()->get_local_part() +
               "\">" + o->get() + "</" + name + ">";
    return s;
  }
}

class QName
{
  //! The QName namepace
  protected string namespace;
  
  //! The QName name
  protected string name;
  
  //! The QName source
  protected string prefix;
  
  //! Creates a new QName.
  //! 
  //! @param name
  //!  If @[name] contains the namspace, e.g. @tt{{namespace}name@}, the 
  //!  namespace will be substracted from the name.
  //! @param namespace
  void create(void|string _name, void|string _namespace)
  {
    if (_name && _name[0] == '{')
      sscanf(_name, "{%s}%s", namespace, name);
    else if (_name && search(_name, ":") > -1 && search(_name, "://") == -1) {
      sscanf(_name, "%s:%s", prefix, name);
      namespace = _namespace;
    }
    else {
      name      = _name;
      namespace = _namespace;
    }
  }

  //! Returns the namespace URI
  string get_namespace_uri()
  {
    return namespace;
  }
  
  //! Returns the local name
  string get_local_part()
  {
    return name;
  }
  
  //! Returns the prefix
  string get_prefix()
  {
    return prefix;
  }

  //! Returns the name prefixed if @[prefix] is set
  string get_full_name()
  {
    string s = "";
    if (prefix) s = prefix + ":";
    return s + name;
  }
  
  //! Returns the fully qualified name
  string fqn()
  {
    if (name && prefix)
      return sprintf("%s:%s", prefix, name);
  
    return namespace ? sprintf("{%s}%s", namespace, name) : name;
  }
  
  int(0..1) `==(QName qn)
  {
    return name      == qn->get_local_part()    &&
	   namespace == qn->get_namespace_uri() &&
	   prefix    == qn->get_prefix();
  }
  
  //! Cast method
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how)
    {
      case "string": return fqn();
    }
    
    error("Can't cast %O() to %O\n", object_program(this), how);
  }
  
  string _sprintf(int t)
  {
    switch (t)
    {
      case 's': return fqn();
      case 'O': 
	return 
	sprintf("%O(%O, %O, %O)", object_program(this), name, namespace, prefix);
    }
  }
}