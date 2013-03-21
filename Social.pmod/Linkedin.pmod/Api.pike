/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

import Parser.XML.Tree;
import Security.OAuth;
 
#define LINKEDIN_DEBUG

#ifdef LINKEDIN_DEBUG
# define TRACE(X...) werror("%s:%d: %s",basename(__FILE__),__LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

protected string request_token_url =  "https://api.linkedin.com/uas/oauth/requestToken";
protected string access_token_url = "https://api.linkedin.com/uas/oauth/accessToken";
protected string user_auth_url = "https://www.linkedin.com/uas/oauth/authorize";

private Consumer consumer;
private Token token;

void create(Consumer _consumer, Token _token)
{
  consumer = _consumer;
  token = _token;
}

Token get_request_token()
{
  mapping p = ([]);
  string ctoken = call(request_token_url, p, "POST");
  TRACE("Token: %O\n", ctoken);
  exit(0);
}

string get_auth_url()
{
  get_request_token();
}

//! Does the low level HTTP call to Twitter.
//!
//! @throws
//!  An error if HTTP status != 200
//!
//! @param url
//!  The full address to the Twitter service e.g:
//!  @tt{http://twitter.com/direct_messages.xml@}
//! @param args
//!  Arguments to send with the request
//! @param mehod
//!  The HTTP method to use
string call(string|Standards.URI url, void|mapping|Params args,
            void|string method)
{
  method = normalize_method(method);

  if (mappingp(args)) {
    mapping m = copy_value(args);
    args = Params();
    args->add_mapping(m);
  }
  
  Request r = request(url, consumer, token, args, method);
  r->sign_request(Signature.HMAC_SHA1, consumer, token);

  Protocols.HTTP.Query q = r->submit();

  if (q->status != 200) {
    //TRACE("%O (%d)\n", q->data(), q->status);
    mapping e = parse_error_xml(q->data());
    if (e && e->error) 
      error("Error in %O: %s\n", e->request, e->error||"???");
    else if (e && e->oauth_problem) { 
      error("OAuth error (%s): %s\n", e->oauth_problem, 
            e->oauth_problem_advice || "Unknown problem");
    }
    else
      error("Bad status, %d, from HTTP query!\n", q->status);
  }

  return q->data();
}

//! Normalizes and verifies the HTTP method to be used in a HTTP call
//!
//! @param method
protected string normalize_method(string method)
{
  method = upper_case(method||"GET");
  if ( !(< "GET", "POST", "DELETE", "PUT" >)[method] )
    error("HTTP method must be GET, POST, PUT or DELETE! ");

  return method;
}

//! Parses an error xml tree
//!
//! @param xml
//!
//! @returns
//!  A mapping:
//!  @mapping
//!   @member string "request"
//!   @member string "error"
//!  @endmapping
mapping parse_error_xml(string xml)
{
  mapping m;
  if (Node n = get_xml_root(xml)) {
    m = ([]);
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT)
      	m[cn->get_tag_name()] = cn->value_of_node();
    }
  }
  else
    m = Social.query_to_mapping(xml);

  return m;
}

//! Returns the first @tt{XML_ELEMENT@} node in an XML tree.
//!
//! @param xml
//!  Either an XML tree as a string or a node object.
private Node get_xml_root(string|Node xml)
{
  catch {
    if (stringp(xml))
      xml = parse_input(xml);
    
    foreach (xml->get_children(), Node n) {
      if (n->get_node_type() == XML_ELEMENT) {
	xml = n;
	break;
      }
    }

    return objectp(xml) && xml;
  };
}