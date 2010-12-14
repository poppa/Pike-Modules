/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! A Facebook Graph API module.
//!
//! See the Facebook Graph API reference at
//! @url{http://developers.facebook.com/docs/reference/api/@} for what methods
//! are available.
//!
//! In short this is how the Graph API works.
//!
//! First the user need to authenticate it self which is done with the
//! @[Authorization] class. In the @[Authorization] class you specify the
//! application id, application secret and redirect URI - wich is where
//! the Facebook authorization page will redirect the user. For a more
//! detailed example of authorization see @[Authorization].
//!
//! @xml{<code detab="2">
//!  import Social.Facebook.Graph;
//!
//!  Authorization auth = Authorization("app-id", "app-secret", 
//!                                     "http://domain.com/fb_callback/");
//!
//!  if (auth->is_expired()) {
//!    // Handle authorization
//!  }
//!
//!  auth->set_from_cookie("my_auth_cookie_string");
//!
//!  Api api = Api(auth);
//!  // This will return the currently logged on users home news feed
//!  mixed home = api->call("me/home");
//!
//!  foreach (home->data, mapping row) {
//!    werror("Do the salsa\n");
//!  }
//! </code>@}
//!
//! So this module doesn't implement any of the Graph API methods but provides
//! an interface for handling authentication, via the @[Authorization] class,
//! and requests and responses, via the @[Api()->call()] method.
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Graph.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Graph.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Graph.pmod. If not, see <http://www.gnu.org/licenses/>.

#define FB_DEBUG

#ifdef FB_DEBUG
# define TRACE(X...) werror("%s:%d: %s", basename(__FILE__),__LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

//! The base uri to the Graph API
constant API_URI = "https://graph.facebook.com";

//! User Agent string for this API implementation
constant USER_AGENT = "Pike Facebook Graph Client 0.1 (Pike "+__VERSION__+")";

//! No privacy, available to everyone
constant PRIVACY_EVERYONE = "EVERYONE";

//! Custom privacy
constant PRIVACY_CUSTOM = "CUSTOM";

//! Available to all friends
constant PRIVACY_ALL_FRIENDS = "ALL_FRIENDS";

//! Available to network friends
constant PRIVACY_NETWORK_FRIENDS = "NETWORK_FRIENDS";

//! Available to friends of friends
constant PRIVACY_FRIENDS_OF_FRIENDS = "FRIENDS_OF_FRIENDS";

#if constant(Standards.JSON.decode)
protected function json_decode = Standards.JSON.decode;
#else
protected function json_decode = lambda (string s) {
  error("No JSON decode function available. You can set an arbitrary JSON "
        "decode function via Graph.set_json_decode().\n");
};
#endif

//! Set JSON decoding function
//!
//! @param func
void set_json_decode(function func)
{
  json_decode = func;
}

//! Creates a URI to a Facebook Graph method.
//!
//! @param method
//!  The Facebook Graph method to call, for example: 
//!  @tt{me@}, @tt{me/home@}, @tt{[profile_id]/photos@} and so on.
//!
//! @param params
//!  Additional parameters to add to the URI
string get_uri(string method, void|mapping|Params params)
{
  if (!method)
    return API_URI;

  string q;
  if (params) {
    if (mappingp(params))
      params = Params()->add_mapping(params);

    q = params->to_query();
  }

  if (method && method[0] != '/')
    method = "/" + method;

  string uri = API_URI + method;
  if (q) uri += "?" + q;
  return uri;
}

//! This is the main class for communicating with the Facebook Graph API.
class Api
{
  //! Authorization object.
  //!
  //! @seealso
  //!  @[Authorization]
  protected Authorization auth;

  //! Creates a new Api instance
  //!
  //! @param _auth
  //!  Athorization object. See also @[Authorization] and
  //!  @[Api()->set_authorization]
  void create(Authorization _auth)
  {
    auth = _auth;
  }

  //! Setter for the authorization object.
  //!
  //! @seealso
  //!  @[Authorization]
  //!
  //! @param _auth
  void set_authorization(Authorization _auth)
  {
    auth = _auth;
  }

  //! Issues a call with a GET method
  //!
  //! @param fb_method
  //!  The Facebook Graph API method to call
  //! @param params
  mixed get(string fb_method, void|mapping|Params params)
  {
    return call(fb_method, params);
  }

  //! Issues a call with a POST method
  //!
  //! @param fb_method
  //!  The Facebook Graph API method to call
  //! @param params
  //! @param data
  //!  Eventual inline data to send
  mixed post(string fb_method, void|mapping|Params params, void|string data)
  {
    return call(fb_method, params, "POST", data);
  }

  //! Issues a call with a DELETE method
  //!
  //! @param fb_method
  //!  In most cases this will be the ID of what to delete
  //! @param params
  mixed delete(string fb_method, void|mapping|Params params)
  {
    return call(fb_method, params, "DELETE");
  }

  //! Calls a Facebook Graph method.
  //!
  //! @throws
  //!  An exception is thrown if the response status code is other than
  //!  @tt{200@}, @tt{301@} or @tt{302@}.
  //!
  //! @param fb_method
  //!  The Facebook method to call: @tt{me@}, @tt{me/home@},
  //!  @tt{[user_id]/photos@} and so on.
  //!
  //! @param params
  //!  Additional params to send in the request
  //!
  //! @param http_method
  //!  HTTP method to use. @tt{GET@} is default
  //!
  //! @param data
  //!  Inline data to send in a @tt{POST@} request for instance.
  //!
  //! @returns
  //!  If JSON is available the JSON response from Facebook will be decoded
  //!  and returned. If not the raw response (e.g a JSON string) will be
  //!  returned.
  //!  The exception to this is if the status code in the response is a 
  //!  @tt{30x@} (a redirect), then the response headers mapping will be 
  //!  returned.
  mixed call(string fb_method, void|mapping|Params params,
             void|string http_method, void|string data)
  {
    http_method = http_method || "GET";
    mapping headers = ([ "User-Agent" : USER_AGENT ]);
    Params p = Params();
    
    if (params) {
      if (mappingp(params))
	p->add_mapping(params);
      else
	p += params;
    }

    if (auth && !auth->is_expired()) {
      if (string a = auth->get_access_token())
	p += Param("access_token", a);
    }

    string uri = get_uri(fb_method);

    TRACE("%s %s %O\n", http_method, uri, p->to_mapping());

    if (upper_case(http_method) != "GET") {
      data = p->to_query();
      params = 0;
    }
    else
      params = p->to_mapping();

    Protocols.HTTP.Query q;
    q = Protocols.HTTP.do_method(http_method, uri, params, headers, 0, data);

    if ( (< 301, 302 >)[q->status] )
      return q->headers;

    if (q->status != 200) {
      string d = q->data();
      if (has_value(d, "error")) {
	mapping e = json_decode(d);
	if (e->error)
	  error("%s: %s. ", e->error->type, e->error->message);
      }

      error("Bad status (%d) in HTTP response! ", q->status);
    }

    string jdata = unescape_forward_slashes(q->data());

    TRACE("Json result: %s\n", jdata||"");

    return json_decode(jdata);
  }

  protected string unescape_forward_slashes(string s)
  {
    return replace(s, "\\/", "/");
  }
}

//! The Authorization class is used for doing the OAuth authorization to
//! Facebook. The Authorization works in two steps:
//!
//!   1. First you call @[Authorization()->get_auth_uri()] which will give you
//!      a URI to the Facebook application login page. When the user clicks on
//!      that link it will be asked to either allow or deny the application
//!      to access the users data.
//! 
//!      Facebook will redirect the user back to the @tt{redirect_uri@} you
//!      specified for your Authorization object. If the user accepted the
//!      application a query string parameter named @tt{code@} will be added
//!      to the redirect
//!
//!   2. Take the @tt{code@} query string parameter and pass that to 
//!      @[Authorization()->request_access_token()]. If this works fine
//!      that method will return a Pike encoded mapping (i.e. a string) that
//!      constains the members of the object.
//!
//!      This string can then be saved in a cookie or something like that
//!      and if that cookie exists you can populate your @[Authorization] 
//!      object with that string via @[Authorization()->set_from_cookie()].
//!
//! This is what a authorization could look like. Note! Much here is psuedo
//! code just to show the idea.
//!
//! @example
//!  @xml{<codify detab="3">
//!   Authorization auth = Authorization(MY_APP_ID, MY_APP_SECRET,
//!                                      "http://domain.com/fb_callback/",
//!                                      "publish_stream,user_photos");
//!
//!   if (id->cookie["my_fb_cookie"])
//!     auth->set_from_cookie(id->cookie["my_fb_cookie"]);
//!   else if (id->variables->code) {
//!     string auth_value = auth->request_access_token(id->variables->code);
//!     save_cookie("my_fb_cookie", auth_value);
//!   }
//!   else {
//!     string login_url = auth->get_auth_uri();
//!     write("<a href='%s'>Log in with Facebook</a>", login_uri);
//!     return;
//!   }
//!
//!   if (auth->is_expired()) {
//!     remove_cookie("my_fb_cookie");
//!     redirect("/this/page");
//!   }
//!
//!   Api api = Api(auth);
//!  </code>@}
class Authorization
{
  //! The application ID
  private string app_id;

  //! The application secret
  private string app_secret;

  //! Where the authorization page should redirect to
  private string redirect_uri;

  //! The authorization's access token
  private string access_token;

  //! Unix timestamp when the authorization explires
  private int expires;

  //! When the authorization was created
  private int created;

  //! The extended permissions
  private string permissions;

  //! Creates an Authorization object
  //!
  //! @param client_id
  //!  The Facebook application ID
  //!
  //! @param client_secret
  //!  The Facebook application secret
  //!
  //! @param _redirect_uri
  //!  Where the authorization page should redirect back to. This must be
  //!  fully qualified domain name.
  //!
  //! @param _permissions
  //!  Extended permissions to use for this authorization.
  //!  @url{http://developers.facebook.com/docs/authentication/permissions@}.
  void create(string client_id, string client_secret, string _redirect_uri,
              void|string _permissions)
  {
    app_id = client_id;
    app_secret = client_secret;
    redirect_uri = _redirect_uri;
  }

  //! Returns the application ID
  string get_application_id()
  {
    return app_id;
  }

  //! Returns the application secret.
  string get_application_secret()
  {
    return app_secret;
  }

  //! Returns the redirect uri
  string get_redirect_uri()
  {
    return redirect_uri;
  }

  //! Setter for the redirect uri
  //!
  //! @param uri
  void set_redirect_uri(string uri)
  {
    redirect_uri = uri;
  }

  //! Returns an authorization URI.
  //!
  //! @param cancel_uri
  //!  URI to redirect to when the user cancels the authorization process
  string get_auth_uri(void|string cancel_uri)
  {
    Params p = Params(Param("client_id", app_id),
                      Param("redirect_uri", redirect_uri));

    if (permissions)
      p += Param("scope", permissions);

    if (cancel_uri)
      p += Param("cancel", cancel_uri);

    return get_uri("/oauth/authorize", p);
  }

  //! Returns the access token
  string get_access_token()
  {
    return access_token;
  }

  //! Requests an access token
  //!
  //! @throws
  //!  An error if the access token request fails.
  //!
  //! @param code
  //!  The code returned from the authorization page.
  //!
  //! @returns
  //!  If OK a Pike encoded mapping (i.e it's a string) is returned which can 
  //!  be used to populate an @[Authorization] object at a later time.
  //!
  //!  The mapping looks like
  //!  @mapping
  //!   @member string "access_token"
  //!   @member int    "expires"
  //!   @member int    "created"
  //!   @member string "code"
  //!  @endmapping
  string request_access_token(void|string code)
  {
    Params p = Params(Param("client_id", app_id),
                      Param("redirect_uri", redirect_uri),
                      Param("client_secret", app_secret),
                      Param("code", code));

    Protocols.HTTP.Query q;
    q = Protocols.HTTP.get_url(get_uri("/oauth/access_token"),
                               p->to_mapping(),
                               ([ "User-Agent" : USER_AGENT ]));

    if (q->status != 200)
      error("Bad status (%d) in HTTP response! ", q->status);

    string c = q->data();

    if (c && has_prefix(c, "access_token")) {
      mapping v = ([]);
      foreach (c/"&", string pair) {
	sscanf (pair, "%s=%s", string key, string val);
	v[key] = val;
      }

      created = time();
      access_token = v->access_token;
      expires = v->expires && created + (int)v->expires;

      return encode_value(([ "access_token" : access_token,
                             "expires"      : expires,
                             "created"      : created ]));
    }
    else
      error("Failed getting access token!");
  }

  //! Checks if the authorization is renewable. This is true if the 
  //! @[Authorization] object has been populated from 
  //! @[Authorization()->set_from_cookie()], i.e the user has been authorized
  //! but the session has expired.
  int(0..1) is_renewable()
  {
    return !!created;
  }

  //! Checks if this authorization has expired
  int(0..1) is_expired()
  {
    return expires ? time() > expires : 1;
  }

  //! Populate this object with the result from 
  //! @[Authorization->request_access_token()].
  //!
  //! @param encoded_value
  object_program set_from_cookie(string encoded_value)
  {
    mixed e = catch {
      mapping m = decode_value(encoded_value);
      foreach (m; string k; mixed v) {
	switch (k) {
	  case "access_token" : access_token = v; break;
	  case "expires"      : expires      = v; break;
	  case "created"      : created      = v; break;
	}
      }
    };
  }

  //! Parses a signed request
  //!
  //! @note
  //!  This method is not tested yet!
  //!
  //! @throws
  //!  An error if the signature doesn't match the expected signature
  //!
  //! @param sign
  mapping parse_signed_request(string sign)
  {
    sscanf(sign, "%s.%s", string sig, string payload);

    function url_decode = lambda (string s) {
      return MIME.decode_base64(replace(s, ({ "-", "_" }), ({ "+", "/" })));
    };

    sig = url_decode(sig);
    mapping data = json_decode(url_decode(payload));

    if (upper_case(data->algorithm) != "HMAC-SHA256")
      error("Unknown algorithm. Expected HMAC-SHA256");

    string expected_sig;
    
#if constant(Crypto.HMAC)
# if constant(Crypto.SHA256)
    expected_sig = Crypto.HMAC(Crypto.SHA256)(payload)(app_secret);
# else
    error("No Crypto.SHA256 available in this Pike build! ");
# endif
#else
    error("Not implemented in this Pike version! ");
#endif

    if (sig != expected_sig)
      error("Badly signed signature. ");

    return data;
  }

  //! Cast method. If casted to @tt{string@} the @tt{access_token@} will be
  //! returned. If casted to @tt{int@} the @tt{expires@} timestamp will
  //! be returned.
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how) {
      case "string": return access_token;
      case "int": return expires;
    }

    error("Can't cast %O to %s! ", object_program(this), how);
  }

  string _sprintf(int t)
  {
    switch (t) {
      case 's':
	return access_token;

      default:
	return sprintf("%O(%O, %O, %O, %O)", object_program(this), access_token,
	                                     redirect_uri,
	                                     Calendar.Second("unix", created),
	                                     Calendar.Second("unix", expires));
    }
  }
}

//! Parameter collection class
class Params
{
  inherit Social.Params;

  //! Creates a new instance of @[Params]
  //!
  //! @param args
  //!  Arbitrary number of @[Param] objects.
  void create(Param ... args)
  {
    ::create(@args);
  }
}

//! Representation of a parameter
class Param
{
  inherit Social.Param;

  //! Creates a new instance of @[Param]
  //!
  //! @param name
  //! @param value
  void create(string name, mixed value)
  {
    ::create(name, value);
  }
}

#if !(constant(Crypto.HMAC) && constant(Crypto.SHA256))
// Compat class for Pike 7.4
// This is a mashup of the 7.4 Crypto.hmac and 7.8 Crypto.HMAC
class MY_HMAC
{
  function H;
  int B;
  
  void create(function h, int|void b)
  {
    H = h;
    B = b || 64;
  }

  string raw_hash(string s)
  {
    return H()->update(s)->digest();
  }

  string pkcs_digest(string s)
  {
    return Standards.PKCS.Signature.build_digestinfo(s, H());
  }

  class `()
  {
    string ikey, okey;

    void create(string passwd)
    {
      if (sizeof(passwd) > B)
	passwd = raw_hash(passwd);
      if (sizeof(passwd) < B)
	passwd = passwd + "\0" * (B - sizeof(passwd));

      ikey = passwd ^ ("6" * B);
      okey = passwd ^ ("\\" * B);
    }

    string `()(string text)
    {
      return raw_hash(okey + raw_hash(ikey + text));
    }
  }
}
#endif
