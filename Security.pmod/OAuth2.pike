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
  GRANT_TYPE_CLIENT_CREDENTIALS = "client_credentials",
  GRANT_TYPE_JWT                = "urn:ietf:params:oauth:grant-type:jwt-bearer",
  GRANT_TYPE_REFRESH_TOKEN      = "refresh_token"
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
  return gettable->refresh_token;
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

//! Get an @code{access_token@} from a JWT.
//! @link{http://jwt.io/@}
//!
//! @param jwt
//!  JSON string
//! @param token_endpoint
//!  URI to the request access_token endpoint
//! @param sub
//!  Email/id of the requesting user
mapping get_token_from_jwt(string jwt, string token_endpoint, string|void sub)
{
  mapping j = Standards.JSON.decode(jwt);
  mapping header = ([ "alg" : "RS256", "typ" : "JWT" ]);

  int now = time();
  int exp = now + 3600;

  mapping claim = ([
    "iss"   : j->client_email,
    "scope" : get_valid_scopes(_scope),
    "aud"   : token_endpoint,
    "exp"   : exp,
    "iat"   : now
  ]);

  if (sub) {
    claim->sub = sub;
  }

  string s = base64url_encode(Standards.JSON.encode(header));
  s += "." + base64url_encode(Standards.JSON.encode(claim));

  string key = Standards.PEM.simple_decode(j->private_key);
  object x = [object(Standards.ASN1.Types.Sequence)]
                Standards.ASN1.Decode.simple_der_decode(key);
  Crypto.RSA.State state;
  state = Standards.PKCS.RSA.parse_private_key(x->elements[-1]->value);

  string ss = state->pkcs_sign(s, Crypto.SHA256);
  s += "." + base64url_encode(ss);

  string body = "grant_type=" + Protocols.HTTP.uri_encode(GRANT_TYPE_JWT)+"&"+
                "assertion=" + Protocols.HTTP.uri_encode(s);

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.do_method("POST", token_endpoint, 0, request_headers, 0,
                               body);

  if (q->status == 200) {
    mapping res = Standards.JSON.decode(q->data());
    if (!decode_access_token_response(q->data())) {
      error("Bad result! Expected an access_token but none were being found!"
            "\nData: %s.\n", q->data());
    }

    return gettable;
  }

  string ee = try_get_error(q->data());
  error("Bad status (%d) in response: %s! ", q->status, ee||"Unknown error");
}

protected string base64url_encode(string s)
{
  s = MIME.encode_base64(s, 1);
  s = replace(s, ([ "==" : "", "+" : "-", "-" : "_" ]));
  return s;
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

//! Set access_type explicilty
//!
//! @param access_type
//!  Like: offline
void set_access_type(string access_type)
{
  _access_type = access_type;
}

//! Getter for the access type, if any
string get_access_type()
{
  return _access_type;
}

//! Set scopes
void set_scope(string scope)
{
  _scope = scope;
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

    if (gettable->access_type)
      _access_type = gettable->access_type;

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

  if (args && args->access_type || _access_type) {
    p += Param("access_type", args && args->access_type || _access_type);

    if (!_access_type && args && args->access_type)
      _access_type = args->access_type;
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
  TRACE("request_access_token: %O, %O\n", oauth_token_uri, code);

  Params p = get_default_params();
  p += Param("code", code);

  if (string s = do_query(oauth_token_uri, p))
    return s;

  error("Failed getting access token! ");
}

//! Refreshes the access token, if a refresh token exists in the object
//!
//! @param oauth_token_uri
//!  Endpoint of the authentication service
string refresh_access_token(string oauth_token_uri)
{
  TRACE("Refresh: %s @ %s\n", gettable->refresh_token, oauth_token_uri);

  if (!gettable->refresh_token)
    error("No refresh_token in object! ");

  Params p = get_default_params(GRANT_TYPE_REFRESH_TOKEN);
  p += Param("refresh_token", gettable->refresh_token);

  if (string s = do_query(oauth_token_uri, p)) {
    TRACE("Got result: %O\n", s);
    return s;
  }

  error("Failed refreshing access token! ");
}

//! Send a request to @[oauth_token_uri] with params @[p]
//!
//! @param oauth_token_uri
//! @param p
protected string do_query(string oauth_token_uri, Params p)
{
  int qpos = 0;

  if ((qpos = search(oauth_token_uri, "?")) > -1) {
    //string qs = oauth_token_uri[qpos..];
    oauth_token_uri = oauth_token_uri[..qpos];
  }

  TRACE("params: %O\n", p);
  TRACE("request_access_token(%s?%s)\n", oauth_token_uri, (string) p);

  Protocols.HTTP.Session sess = Protocols.HTTP.Session();
  Protocols.HTTP.Session.Request q;
  q = sess->post_url(oauth_token_uri, p->to_mapping());

  TRACE("Query OK: %O : %O : %s\n", q, q->status(), q->data());

  string c = q->data();

  if (q->status() != 200) {
    string emsg = sprintf("Bad status (%d) in HTTP response! ", q->status());
    if (mapping reason = try_get_error(c))
      emsg += sprintf("Reason: %O!\n", reason);

    error(emsg);
  }

  TRACE("Got data: %O\n", c);

  if (decode_access_token_response(c))
    return encode_value(gettable);
}

//! Returns a set of default parameters
//!
//! @param grant_type
protected Params get_default_params(void|string grant_type)
{
  Params p = Params(Param("client_id",     _client_id),
                    Param("redirect_uri",  _redirect_uri),
                    Param("client_secret", _client_secret),
                    Param("grant_type",    grant_type || _grant_type));
  if (STATE) {
    p += Param("state", (string)Standards.UUID.make_version4());
  }

  return p;
}

//! Checks if the authorization is renewable. This is true if the
//! @[Authorization] object has been populated from
//! @[Authorization()->set_from_cookie()], i.e the user has been authorized
//! but the session has expired.
int(0..1) is_renewable()
{
  return !!gettable->refresh_token;
}

//! Checks if this authorization has expired
int(0..1) is_expired()
{
  // This means no expiration date was set from the API
  if (gettable->created && !gettable->expires)
    return 0;

  return gettable->expires ? time() > gettable->expires : 1;
}

//! Do we have a valid authentication
int(0..1) is_authenticated()
{
  return !!gettable->access_token && !is_expired();
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

//! Access type of the request.
protected string _access_type;

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

//! Returns a space separated list of all valid scopes in @[s].
//! @[s] can be a comma or space separated string or an array or multiset of
//! strings. Each element in @[s] will be matched against the valid scopes
//! set in the module inheriting this class.
//!
//! @param s
protected string get_valid_scopes(string|array(string)|multiset(string) s)
{
  if (!s) return "";

  array r = ({});

  if (stringp(s))
    s = map(s/",", String.trim_all_whites);

  if (multisetp(s))
    s = (array) s;

  if (!sizeof(valid_scopes))
    r = s;

  foreach (s, string x) {
    if (valid_scopes[x])
      r += ({ x });
  }

  return r*" ";
}

//! Decode the response from an authentication call. If the response was ok
//! the internal mapping @[gettable] will be populated with the
//! members/variables in @[r].
//!
//! @param r
//!  The response from @[do_query()]
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

  if (_access_type) {
    gettable->access_type = _access_type;
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

#if 0
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
#endif