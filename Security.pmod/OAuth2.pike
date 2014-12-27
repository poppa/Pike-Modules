/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

#ifdef SOCIAL_REQUEST_DEBUG
# define TRACE(X...) werror("%s:%d: %s", basename(__FILE__),__LINE__,sprintf(X))
#else
# define TRACE(X...) 0
#endif

/* Public API */

//! Creates an OAuth2 object
//!
//! @param client_id
//!  The application ID
//!
//! @param client_secret
//!  The application secret
//!
//! @param redirect_uri
//!  Where the authorization page should redirect back to. This must be a
//!  fully qualified domain name. This can be set/overridden in
//!  @[get_auth_uri()] and/or @[set_redirect_uri()].
//!
//! @param scope
//!  Extended permissions to use for this authorization. This can be
//!  set/overridden in @[get_auth_uri()].
void create(string client_id, string client_secret, void|string redirect_uri,
            void|string|array(string)|multiset(string) scope)
{
  _client_id     = client_id;
  _client_secret = client_secret;
  _redirect_uri  = redirect_uri || _redirect_uri;
  _scope         = scope || _scope;
}

//! Grant types
enum GrantType {
  GRANT_TYPE_AUTHORIZATION_CODE = "authorization_code",
  GRANT_TYPE_IMPLICIT           = "implicit",
  GRANT_TYPE_PASSWORD           = "password",
  GRANT_TYPE_CLIENT_CREDENTIALS = "client_credentials"
}

//! Response types
enum ResponseType {
  RESPONSE_TYPE_CODE  = "code",
  RESPONSE_TYPE_TOKEN = "token"
}

//! Object properties (read only) in an authorized object.
//!
//! @expr{OAuth2()->access_token@}  @[`access_token()]
//! @expr{OAuth2()->refresh_token@} @[`refresh_token()]
//! @expr{OAuth2()->expires@}       @[`expires()]
//! @expr{OAuth2()->created@}       @[`created()]
//! @expr{OAuth2()->token_type@}    @[`token_type()]

//! Getter for @expr{access_token@}
string `access_token()
{
  return gettable->access_token;
}

//! Can be used to set a stored access_token. Will also set creation and
//! expiration time. This can be useful in apps that support non-expiring
//! authorizations.
void `access_token=(string value)
{
  gettable->access_token = value;
  gettable->created = time();
  gettable->expires = time() + (3600);
}

//! Getter for @expr{refresh_token@}
string `refresh_token()
{
  return gettable->access_token;
}

//! Getter for @expr{token_type@}
string `token_type()
{
  return gettable->token_type;
}

//! Getter for when the authorization @expr{expires@}
Calendar.Second `expires()
{
  return gettable->expires && Calendar.Second("unix", gettable->expires);
}

//! Getter for when the authorization was @expr{created@}
Calendar.Second `created()
{
  return Calendar.Second("unix", gettable->created);
}

//! Getter for the @expr{user@} mapping which may or may not be set.
mapping `user()
{
  return gettable->user;
}

//! Returns the application ID
string get_client_id()
{
  return _client_id;
}

//! Returns the application secret.
string get_client_secret()
{
  return _client_secret;
}

//! Returns the redirect uri
string get_redirect_uri()
{
  return _redirect_uri;
}

//! Setter for the redirect uri
//!
//! @param uri
void set_redirect_uri(string uri)
{
  _redirect_uri = uri;
}

//! Returns the valid scopes
multiset list_valid_scopes()
{
  return valid_scopes;
}

//! Returns the scope/scopes set, if any.
mixed get_scope()
{
  return _scope;
}

//! Check if @[scope] exists in this object
//!
//! @param scope
int(0..1) has_scope(string scope)
{
  if (!_scope || !sizeof(_scope))
    return 0;

  string sp = search(_scope, ",") > -1 ? "," :
              search(_scope, " ") > -1 ? " " : "";
  array p = map(_scope/sp, String.trim_all_whites);

  return has_value(p, scope);
}

//! Populate this object with the result from
//! @[request_access_token()].
//!
//! @param encoded_value
//!
//! @returns
//!  The object being called
this_program set_from_cookie(string encoded_value)
{
  mixed e = catch {
    gettable = decode_value(encoded_value);
    if (gettable->scope)
      _scope = gettable->scope;
    return this;
  };

  error("Unable to decode cookie! %s. ", describe_error(e));
}

//! Returns an authorization URI.
//!
//! @param auth_uri
//!  The URI to the remote authorization page
//! @param args
//!  Additional argument.
string get_auth_uri(string auth_uri, void|mapping args)
{
  Params p = Params(Param("client_id",     _client_id),
                    Param("response_type", _response_type));

  if (args && args->redirect_uri || _redirect_uri)
    p += Param("redirect_uri", args && args->redirect_uri || _redirect_uri);

  if (STATE)
    p += Param("state", (string) Standards.UUID.make_version4());

  if (args && args->scope || _scope) {
    string sc = get_valid_scopes(args && args->scope || _scope);

    if (sc && sizeof(sc)) {
      _scope = sc;
      p += Param("scope", sc);
    }
  }

  if (args) {
    m_delete(args, "scope");
    m_delete(args, "redirect_uri");
    p += args;
  }

  TRACE("auth_uri(%s)\n", (string) p["redirect_uri"]);

  return auth_uri + "?" + p->to_query();
}

//! Requests an access token
//!
//! @throws
//!  An error if the access token request fails.
//!
//! @param oauth_token_uri
//!  An URI received from @[get_auth_url()].
//!
//! @param code
//!  The code returned from the authorization page via @[get_auth_url()].
//!
//! @returns
//!  If @expr{OK@} a Pike encoded mapping (i.e it's a string) is returned which
//!  can be used to populate an @[OAuth2] object at a later time.
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
string request_access_token(string oauth_token_uri, string code)
{
  Params p = Params(Param("client_id",     _client_id),
                    Param("redirect_uri",  _redirect_uri),
                    Param("client_secret", _client_secret),
                    Param("grant_type",    _grant_type),
                    Param("code",          code));

  if (STATE)
    p += Param("state", (string) Standards.UUID.make_version4());

  int qpos = 0;

  if ((qpos = search(oauth_token_uri, "?")) > -1) {
    string qs = oauth_token_uri[qpos..];
    oauth_token_uri = oauth_token_uri[..qpos];
  }

  TRACE("params: %O\n", p);
  TRACE("request_access_token(%s?%s)\n", oauth_token_uri, (string) p);

  Protocols.HTTP.Session sess = Protocols.HTTP.Session();
  Protocols.HTTP.Session.Request q;
  q = sess->post_url(oauth_token_uri, p->to_mapping());

  string c = q->data();

  if (q->status() != 200) {
    string emsg = sprintf("Bad status (%d) in HTTP response! ", q->status());
    if (mapping reason = try_get_error(c))
      emsg += sprintf("Reason: %O!\n", reason);

    error(emsg);
  }

  if (decode_access_token_response(c))
    return encode_value(gettable);

  error("Failed getting access token!");
}

//! Checks if the authorization is renewable. This is true if the
//! @[Authorization] object has been populated from
//! @[Authorization()->set_from_cookie()], i.e the user has been authorized
//! but the session has expired.
int(0..1) is_renewable()
{
  return !!gettable->created;
}

//! Checks if this authorization has expired
int(0..1) is_expired()
{
  // This means no expiration date was set from the API
  if (gettable->created && !gettable->expires)
    return 0;

  return gettable->expires ? time() > gettable->expires : 1;
}

//! Cast method. If casted to @tt{string@} the @tt{access_token@} will be
//! returned. If casted to @tt{int@} the @tt{expires@} timestamp will
//! be returned.
//!
//! @param how
mixed cast(string how)
{
  switch (how) {
    case "string":  return gettable->access_token;
    case "int":     return gettable->expires;
    case "mapping": return gettable;
  }

  error("Can't cast %O to %s! ", object_program(this), how);
}

//! String formatting method
string _sprintf(int t)
{
  switch (t) {
    case 's': return gettable->access_token;
  }

  return sprintf("%O(%O, %O, %O, %O)",
                 object_program(this), gettable->access_token,
                 _redirect_uri,
                 gettable->created &&
                   Calendar.Second("unix", gettable->created),
                 gettable->expires &&
                   Calendar.Second("unix", gettable->expires));
}

/*
  Internal API
  The internal API can be used by other classes inheriting this class
*/

//! A mapping of valid scopes for the API
protected multiset valid_scopes = (<>);

//! My version
protected constant VERSION = "1.0";

//! User agent string
protected constant USER_AGENT  = "Mozilla 4.0 (Pike OAuth2 Client " +
                                 VERSION + ")";

//! Some OAuth2 verifiers need the STATE parameter. If this is not @tt{0@}
//! a random string will be generated and the @tt{state@} parameter will be
//! added to the request
protected constant STATE = 0;

//! The application ID
protected string _client_id;

//! The application secret
protected string _client_secret;

//! Where the authorization page should redirect to
protected string _redirect_uri;

//! The scope of the authorization. Limits the access
protected string|array(string)|multiset(string) _scope;

//! @[GRANT_TYPE_AUTHORIZATION_CODE] for apps running on a web server
//! @[GRANT_TYPE_IMPLICIT] for browser-based or mobile apps
//! @[GRANT_TYPE_PASSWORD] for logging in with a username and password
//! @[GRANT_TYPE_CLIENT_CREDENTIALS] for application access
protected string _grant_type = GRANT_TYPE_AUTHORIZATION_CODE;

//! @[RESPONSE_TYPE_CODE] for apps running on a webserver
//! @[RESPONSE_TYPE_TOKEN] for apps browser-based or mobile apps
protected string _response_type = RESPONSE_TYPE_CODE;

//! Default request headers
protected mapping request_headers = ([
  "User-Agent"   : USER_AGENT,
  "Content-Type" : "application/x-www-form-urlencoded"
]);

protected constant json_decode = Standards.JSON.decode;
protected constant Params      = Social.Params;
protected constant Param       = Social.Param;

protected mapping gettable = ([ "access_token"  : 0,
                                "refresh_token" : 0,
                                "expires"       : 0,
                                "created"       : 0,
                                "token_type"    : 0 ]);

protected string get_valid_scopes(string|array(string)|multiset(string) s)
{
  array r = ({});

  if (stringp(s))
    s = map(s/",", String.trim_all_whites);

  if (multisetp(s))
    s = (array) s;

  if (!sizeof (valid_scopes))
    r = s;

  foreach (s, string x) {
    if (valid_scopes[x])
      r += ({ x });
  }

  return r*" ";
}

protected int(0..1) decode_access_token_response(string r)
{
  if (!r) return 0;

  mapping v = ([]);

  if (has_prefix(r, "access_token")) {
    foreach (r/"&", string s) {
      sscanf(s, "%s=%s", string key, string val);
      v[key] = val;
    }
  }
  else {
    if (catch(v = json_decode(r)))
      return 0;
  }

  if (!v->access_token)
    return 0;

  gettable->scope = _scope;
  gettable->created = time();

  foreach (v; string key; string val) {
    if (search(key, "expires") > -1)
      gettable->expires = gettable->created + (int)val;
    else
      gettable[key] = val;
  }

  return 1;
}

private mixed try_get_error(string data)
{
  catch {
    mixed x = json_decode(data);
    return x->error;
  };
}

//! Parses a signed request
//!
//! @throws
//!  An error if the signature doesn't match the expected signature
//!
//! @param sign
protected mapping parse_signed_request(string sign)
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
  expected_sig = Crypto.HMAC(Crypto.SHA256)(payload)(_client_secret);
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
