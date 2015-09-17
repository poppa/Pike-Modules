/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

inherit Protocols.HTTP.Session : sess;

#if defined(SOCIAL_REQUEST_DEBUG) || defined(SOCIAL_REQUEST_DATA_DEBUG)
# define TRACE(X...) werror("%s:%d: %s", basename(__FILE__),__LINE__,sprintf(X))
#else
# define TRACE(X...) 0
#endif

//! The URI to the remote API
constant API_URI = 0;

//! In some API's (LinkedIn f ex) this is named something else so it needs
//! to be overridden i cases where it has a different name than the
//! standard one
constant ACCESS_TOKEN_PARAM_NAME = "access_token";

//! Typedef for the async callback method signature.
typedef function(mapping|Request:void) Callback;

//! Typef for a parameter argument
typedef mapping|Social.Params ParamsArg;

//! Authorization object.
//!
//! @seealso
//!  @[Authorization]
protected Authorization auth;

//! Creates a new Api instance
//!
//! @param client_id
//!  The application ID
//!
//! @param client_secret
//!  The application secret
//!
//! @param redirect_uri
//!  Where the authorization page should redirect back to. This must be
//!  fully qualified domain name.
//!
//! @param scope
//!  Extended permissions to use for this authorization.
void create(string client_id, string client_secret, void|string redirect_uri,
            void|string|array(string)|multiset(string) scope)
{
  sess::follow_redirects = 0;
  sess::default_headers  = ([ "User-Agent" : .USER_AGENT ]);
  sess::hostname_cache   = ([]);

  auth = Authorization(client_id, client_secret, redirect_uri, scope);
}

//! Getter for the authorization object
//!
//! @seealso
//!  @[Authorization]
Authorization `authorization()
{
  return auth;
}

//! Invokes a call with a GET method
//!
//! @param api_method
//!  The remote API method to call
//! @param params
//! @param cb
//!  Callback function when in async mode
mixed get(string api_method, void|ParamsArg params, void|Callback cb)
{
  return call(api_method, params, "GET", 0, cb);
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
  return call(api_method, params, "POST", data, cb);
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
  return call(api_method, params, "DELETE", 0, cb);
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
  return call(api_method, params, "PUT", 0, cb);
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
  return call(api_method, params, "PATCH", 0, cb);
}

//! Calls a remote API method.
//!
//! @throws
//!  An exception is thrown if the response status code is other than
//!  @expr{200@}, @expr{301@} or @expr{302@}.
//!
//! @param api_method
//!  The remote API method to call!
//!  This should be a Fully Qualified Domain Name
//!
//! @param params
//!  Additional params to send in the request
//!
//! @param http_method
//!  HTTP method to use. @expr{GET@} is default
//!
//! @param data
//!  Inline data to send in a @expr{POST@} request for instance.
//!
//! @param cb
//   Callback function when in async mode
//!
//! @returns
//!  If JSON is available the JSON response from will be decoded
//!  and returned. If not the raw response (e.g a JSON string) will be
//!  returned. The exception to this is if the status code in the response is a
//!  @expr{30x@} (a redirect), then the response headers mapping will be
//!  returned.
mixed call(string api_method, void|ParamsArg params,
	         void|string http_method, void|string data, void|Callback cb)
{
  http_method = upper_case(http_method || "get");
  Social.Params p = Social.Params();
  p->add_mapping(default_params());

  if (params) p += params;

  if (auth && !auth->is_expired()) {
    if (string a = auth->access_token)
      p += .Param(ACCESS_TOKEN_PARAM_NAME, a);
  }

  if (http_method == "POST") {
    if (!data) data = (string) p;
    params = 0;
  }
  else
    params = (mapping) p;

  Request req;

#ifdef SOCIAL_REQUEST_DEBUG
  TRACE("\n> Request: %s?%s\n", api_method, (string) p);
  if (data) TRACE("> data: %s\n", data);
#endif

  if (cb) {
    req = _async(http_method, api_method, params, data, default_headers,
                 lambda (Request r) {
                   if (string x = r->data()) {
                     r->unset_data_callback();
                     if (cb) cb(handle_response(r));
                   }
                 },
                 lambda (Request r) {
                   TRACE("async data: %O\n", r);
                   if (cb) cb(handle_response(r));
                 },
                 lambda (Request r) {
                   TRACE("Async fail: %O\n", r);
                   if (cb) cb(0);
                 });
    return 0;
  }

  req = do_method_url(http_method, api_method, params, data, default_headers);
  return req && handle_response(req);
}

private mixed handle_response(Request req)
{
  if ((< 301, 302 >)[req->status()])
    return req->headers();

#ifdef SOCIAL_REQUEST_DATA_DEBUG
  TRACE("Data: [%s]\n\n", req->data()||"(empty)");
#endif

  if (req->status() != 200) {
    string d = req->data();

    TRACE("Bad resp[%d]: %s\n\n%O\n",
          req->status(), req->data(), req->headers());

    if (has_value(d, "error")) {
      mapping e;
      mixed err = catch {
        e = Social.json_decode(d);
      };

      if (e) {
        if (e->error)
          error("Error %d: %s. ", e->error->code, e->error->message);
        else if (e->meta && e->meta->code)
          error("Error %d: %s. ", e->meta->code, e->meta->error_message);
      }

      error("Error: %s", "Unknown");
    }

    error("Bad status (%d) in HTTP response! ", req->status());
  }

  return Social.json_decode(unescape_forward_slashes(req->data()));
}

//! String format
//!
//! @param t
string _sprintf(int t)
{
  return sprintf("%O(authorized:%O)", this_program,
                 (auth && !!auth->access_token));
}

//! Convenience method for getting the URI to a specific API method
//!
//! @param method
protected string get_uri(string method)
{
  if (has_suffix(API_URI, "/")) {
    if (has_prefix(method, "/"))
      method = method[1..];
  }
  else {
    if (!has_prefix(method, "/"))
      method = "/" + method;
  }

  return API_URI + method;
}

//! Returns the encoding from a request
//!
//! @param h
//!  The headers mapping from a HTTP respose
protected string get_encoding(mapping h)
{
  if (h["content-type"]) {
    sscanf(h["content-type"], "%*scharset=%s", string s);
    return s && lower_case(String.trim_all_whites(s)) || "";
  }

  return "";
}

//! Unescapes escaped forward slashes in a JSON string
protected string unescape_forward_slashes(string s)
{
  return replace(s, "\\/", "/");
}

//! Return default params
protected mapping default_params()
{
  return ([]);
}

//! Authorization class.
//!
//! This is basically just an @[Security.OAuth2]. The purpose of it ís to be
//! able to set some defaults for the particular API being implemented
class Authorization
{
  inherit Security.OAuth2;

  //! Authorization URI
  constant OAUTH_AUTH_URI = 0;

  //! Request access token URI
  constant OAUTH_TOKEN_URI = 0;

  //! Scope to set if none is set
  protected constant DEFAULT_SCOPE = 0;

  //! Make an JWT (JSON Web Token) authentication
  mapping get_token_from_jwt(string jwt, void|string sub)
  {
    return ::get_token_from_jwt(jwt, OAUTH_TOKEN_URI, sub);
  }

  //! Returns an authorization URI.
  //!
  //! @param args
  //!  Additional argument.
  string get_auth_uri(void|mapping args)
  {
    if ((args && !args->scope || !args) && DEFAULT_SCOPE) {
      if (!args) args = ([]);
      args->scope = DEFAULT_SCOPE;
    }

    return ::get_auth_uri(OAUTH_AUTH_URI, args);
  }

  //! Requests an access token
  //!
  //! @throws
  //!  An error if the access token request fails.
  //!
  //! @param code
  //!  The code returned from the authorization page via @[get_auth_url()].
  //!
  //! @returns
  //!  If @expr{OK@} a Pike encoded mapping (i.e it's a string) is returned
  //!  which can be used to populate an @[Authorization] object at a later time.
  //!
  //!  The mapping looks like
  //!  @mapping
  //!   @member string "access_token"
  //!   @member int    "expires"
  //!   @member int    "created"
  //!   @member string "refresh_token"
  //!   @member string "token_type"
  //!  @endmapping
  //!
  //!  Depending on the authorization service it might also contain more
  //!  members.
  string request_access_token(string code)
  {
    return ::request_access_token(OAUTH_TOKEN_URI, code);
  }

  //! Refreshes the access token, if a refresh token exists in the object
  string refresh_access_token()
  {
    return ::refresh_access_token(OAUTH_TOKEN_URI);
  }
}

//! Internal class ment to be inherited by implementing Api's classes that
//! corresponds to a given API endpoint.
class Method
{
  //! API method location within the API
  //!
  //! @code
  //!  https://api.instagram.com/v1/media/search
  //!  ............................^^^^^^^
  //! @endcode
  protected constant METHOD_PATH = 0;

  //! Hidden constructor. This class can not be instantiated directly
  protected void create()
  {
    if (this_program == Social.Api.Method)
      error("This class can not be instantiated directly! ");
  }

  //! Internal convenience method
  protected mixed _get(string s, void|ParamsArg p, void|Callback cb);

  //! Internal convenience method
  protected mixed _put(string s, void|ParamsArg p, void|Callback cb);

  //! Internal convenience method
  protected mixed _post(string s, void|ParamsArg p, void|string data,
                        void|Callback cb);

  //! Internal convenience method
  protected mixed _delete(string s, void|ParamsArg p, void|Callback cb);

  //! Internal convenience method
  protected mixed _patch(string s, void|ParamsArg p, void|Callback cb);
}

//! Sole purpose is to be able to unset the data callback
private local class MyRequest
{
  inherit Request;

  void unset_data_callback()
  {
    data_callback = 0;
  }

  void dump()
  {
    werror("%O\n", this->con->headers);
  }
}

private local MyRequest _async(string method, URL url, void|mapping qv,
                               void|string|mapping data, void|mapping eh,
                               function cbh, function cbd, function cf)
{
   if (stringp(url))
     url = Standards.URI(url);

   MyRequest p = MyRequest();

   p->set_callbacks(cbh, cbd, cf, p, ({}));

   if (mappingp(data)) {
     data = Protocols.HTTP.http_encode_query(data);
     eh = (["content-type" : "application/x-www-form-urlencoded"]) + (eh||([]));
   }

   p->do_async(p->prepare_method(method, url, qv, eh, data));
   return p;
}
