/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

inherit Social.Api : parent;
import Security.OAuth;

typedef mapping|Security.OAuth.Params ParamsArg;

//! Invokes a call with a GET method
//!
//! @param api_method
//!  The remote API method to call
//! @param params
//! @param cb
//!  Callback function when in async mode
mapping get(string api_method, void|ParamsArg params, void|Callback cb)
{
  catch {
    return Standards.JSON.decode(auth->call(api_method, params, "GET", 0, cb));
  };

  return 0;
}

//! Invokes a call with a POST method
//!
//! @param api_method
//!  The remote API method to call
//! @param params
//! @param data
//!  Eventual inline data to send
//! @param cb
//!  Callback function when in async mode
mixed post(string api_method, void|ParamsArg params, void|string data,
           void|Callback cb)
{
  return auth->call(api_method, params, "POST", data, cb);
}

//! Invokes a call with a DELETE method
//!
//! @param api_method
//!  The remote API method to call
//! @param params
//! @param cb
//!  Callback function when in async mode
mixed delete(string api_method, void|ParamsArg params, void|Callback cb)
{
  return auth->call(api_method, params, "DELETE", 0, cb);
}

//! Invokes a call with a PUT method
//!
//! @param api_method
//!   The remote API method to call
//! @param params
//! @param cb
//!  Callback function when in async mode
mixed put(string api_method, void|ParamsArg params, void|Callback cb)
{
  return auth->call(api_method, params, "PUT", 0, cb);
}

//! Invokes a call with a PATCH method
//!
//! @param api_method
//!   The remote API method to call
//! @param params
//! @param cb
//!  Callback function when in async mode
mixed patch(string api_method, void|ParamsArg params, void|Callback cb)
{
  return auth->call(api_method, params, "PATCH", 0, cb);
}

class Authorization
{
  inherit Social.Api.Authorization : api;
  inherit Security.OAuth.Client : oauth;

  //! The endpoint to send request for a request token
  constant REQUEST_TOKEN_URL = 0;

  //! The endpoint to send request for an access token
  constant ACCESS_TOKEN_URL = 0;

  //! The enpoint to redirect to when authorize an application
  constant USER_AUTH_URL = 0;

  void create(string client_id, string client_secret, void|string redir,
              void|string|array(string)|multiset(string) scope)
  {
    api::create(client_id, client_secret, redir, scope);
    oauth::create(Security.OAuth.Consumer(client_id, client_secret),
                  Security.OAuth.Token(0, 0));
  }

  void set_authentication(string key, string secret)
  {
    token->key = key;
    token->secret = secret;
  }

  //! Fetches a request token
  //!
  //! @param callback_uri
  //!  Overrides the callback uri in the application settings
  //! @param force_login
  //!  If @tt{1@} forces the user to provide its credentials at the Twitter
  //!  login page.
  Token get_request_token(void|string|Standards.URI callback_uri,
                          void|int(0..1) force_login)
  {
    mapping p = ([]);

    if (callback_uri)
      p->oauth_callback = (string)callback_uri;

    if (force_login)
      p->force_login = "true";

    string ctoken = call(REQUEST_TOKEN_URL, p, "POST");
    mapping res = ctoken && (mapping)query_to_params(ctoken);

    token = Token(res[TOKEN_KEY],
                  res[TOKEN_SECRET_KEY]);
    return token;
  }

  //! Fetches an access token
  //!
  //! @param oauth_verifier
  Token get_access_token(void|string oauth_verifier)
  {
    if (!token)
      error("Can't fetch access token when no request token is set!\n");

    Security.OAuth.Params pm;

    if (oauth_verifier) {
      pm = Security.OAuth.Params(Security.OAuth.Param("oauth_verifier",
                                                      oauth_verifier));
    }

    string ctoken = call(ACCESS_TOKEN_URL, pm, "POST");
    mapping p = (mapping)query_to_params(ctoken);
    token = Token(p[Security.OAuth.TOKEN_KEY],
                  p[Security.OAuth.TOKEN_SECRET_KEY]);

    return token;
  }

  string get_auth_uri(void|string|Standards.URI callback_uri,
                      void|int(0..1) force_login)
  {
    get_request_token(callback_uri||api::_redirect_uri, force_login);
    return sprintf("%s?%s=%s", USER_AUTH_URL, Security.OAuth.TOKEN_KEY,
                   (token && token->key)||"");
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
  string call(string|Standards.URI url, void|mapping|Security.OAuth.Params args,
              void|string method)
  {
    method = normalize_method(method);

    if (mappingp(args)) {
      mapping m = copy_value(args);
      args = Security.OAuth.Params();
      args->add_mapping(m);
    }

    Request r = request(url, consumer, token, args, method);
    r->sign_request(Signature.HMAC_SHA1, consumer, token);

    Protocols.HTTP.Query q = r->submit();

    if (q->status != 200) {

      if (mapping e = parse_error_xml(q->data()))
        error("Error in %O: %s\n", e->request, e->error);
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

  import Parser.XML.Tree;

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
}