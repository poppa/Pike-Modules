/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! OAuth module
//!
//! @b{Example@}
//!
//! @code
//!  import Security.OAuth;
//!
//!  string endpoint = "http://twitter.com/users/show.xml";
//!
//!  Consumer consumer = Consumer(my_consumer_key, my_consumer_secret);
//!  Token    token    = Token(my_access_token_key, my_access_token_secret);
//!  Params   params   = Params(Param("user_id", 12345));
//!  Request  request  = request(consumer, token, params);
//!
//!  request->sign_request(Signature.HMAC_SHA1, consumer, token);
//!  Protocols.HTTP.Query query = request->submit();
//!
//!  if (query->status != 200)
//!    error("Bad response status: %d\n", query->status);
//!
//!  werror("Data is: %s\n", query->data());
//! @endcode

//! Verion
constant VERSION = "1.0";

//! Query string variable name for the consumer key
constant CONSUMER_KEY_KEY = "oauth_consumer_key";

//! Query string variable name for a callback URL
constant CALLBACK_KEY = "oauth_callback";

//! Query string variable name for the version
constant VERSION_KEY = "oauth_version";

//! Query string variable name for the signature method
constant SIGNATURE_METHOD_KEY = "oauth_signature_method";

//! Query string variable name for the signature
constant SIGNATURE_KEY = "oauth_signature";

//! Query string variable name for the timestamp
constant TIMESTAMP_KEY = "oauth_timestamp";

//! Query string variable name for the nonce
constant NONCE_KEY = "oauth_nonce";

//! Query string variable name for the token key
constant TOKEN_KEY = "oauth_token";

//! Query string variable name for the token secret
constant TOKEN_SECRET_KEY = "oauth_token_secret";

//! Chars that shouldn't be URL encoded
constant UNRESERVED_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUV"
                            "WXYZ0123456789-_.~"/1;

#include "oauth.h"

//! Helper method to create a @[Request] object
//!
//! @throws
//!  An error if @[consumer] is null
//!
//! @param consumer
//! @param token
//! @param uri
//! @param params
//! @param http_method
//!  Defaults to GET
Request request(string|Standards.URI uri, Consumer consumer, Token token,
                void|Params params, void|string http_method)
{
  if (!consumer)
    ARG_ERROR("consumer", "Can not be NULL.");

  Params dparams = get_default_params(consumer, token);

  if (params) dparams += params;

  return Request(uri, http_method||"GET", dparams);
}

//! Returns the default params for authentication/signing
//!
//! @param consumer
//! @param token
Params get_default_params(Consumer consumer, Token token)
{
  Params p = Params(
    Param(VERSION_KEY, VERSION),
    Param(NONCE_KEY, nonce()),
    Param(TIMESTAMP_KEY, time(1)),
    Param(CONSUMER_KEY_KEY, consumer->key)
  );

  if (token)
    p += Param(TOKEN_KEY, token->key);

  return p;
}


//! Converts a query string, or a mapping, into a @[Params] object.
//!
//! @param q
Params query_to_params(string|Standards.URI|mapping q)
{
  if (objectp(q))
    q = (string)q;

  Params ret = Params();

  if (!q || !sizeof(q))
    return ret;

  if (mappingp(q)) {
    foreach(q; string n; string v)
      ret += Param(n, v);

    return ret;
  }

  int pos = 0, len = sizeof(q);
  if ((pos = search(q, "?")) > -1)
    q = ([string]q)[pos+1..];

  foreach (q/"&", string p) {
    sscanf(p, "%s=%s", string n, string v);
    if (n && v)
      ret += Param(n, v);
  }

  return ret;
}

//! Class for building a signed request and querying the remote service
class Request
{
  //! The remote endpoint
  protected Standards.URI uri;

  //! The signature basestring
  protected string base_string;

  //! String representation of the HTTP method
  protected string method;

  //! The parameters to send
  protected Params params;

  //! Creates a new @[Request]
  //!
  //! @seealso
  //!  @[request()]
  //!
  //! @param _uri
  //!  The uri to request
  //! @param _http_method
  //!  The HTTP method to use. Either @[Request.GET] or @[Request.POST]
  //! @param _params
  void create(string|Standards.URI _uri, string http_method,
              void|Params _params)
  {
    uri    = ASSURE_URI(_uri);
    method = upper_case(http_method);
    params = query_to_params(uri);

    if (_params) params += _params;

    if ( !(< "GET", "POST" >)[method] )
      ARG_ERROR("http_method", "Must be one of \"GET\" or \"POST\".");

  }

  //! Add a param
  //!
  //! @param name
  //! @param value
  //!
  //! @returns
  //!  The object being called
  object add_param(Param|string name, void|string value)
  {
    if (objectp(name))
      params += name;
    else
      params += Param(name, value);

    return this_object();
  }

  //! Add a @[Params] object.
  //!
  //! @param _params
  void add_params(Params _params)
  {
    params += _params;
  }

  //! Get param with name @[name]
  //!
  //! @param name
  Param get_param(string name)
  {
    foreach (values(params), Param p)
      if ( p[name] )
        return p;

    return 0;
  }

  //! Returns the @[Params] collection
  Params get_params()
  {
    return params;
  }

  //! Signs the request
  //!
  //! @param signature_type
  //!  One of the types in @[Signature]
  //! @param consumer
  //! @param token
  void sign_request(int signature_type, Consumer consumer, Token token)
  {
    object sig = .Signature.get_object(signature_type);
    params += Param(SIGNATURE_METHOD_KEY, sig->get_method());
    params += Param(SIGNATURE_KEY, sig->build_signature(this, consumer, token));
  }

  //! Generates a signature base
  string get_signature_base()
  {
    TRACE("\n\n+++ get_signature_base(%s, %s, %s)\n\n",
          method, (normalize_uri(uri)), (params->get_signature()));

    return ({
      method,
      uri_encode(normalize_uri(uri)),
      uri_encode(params->get_signature())
    }) * "&";
  }

  //! Send the request to the remote endpoint
  //!
  //! @param extra_headers
  Protocols.HTTP.Query submit(void|mapping extra_headers)
  {
    mapping args = params->get_variables();
    foreach (args; string k; string v)
      if (String.width(v) == 8)
        catch (args[k] = utf8_to_string(v));

    if (!extra_headers)
      extra_headers = ([]);

    string realm = uri->scheme + "://" + uri->host;
    extra_headers["Authorization"] = "OAuth realm=\"" + realm + "\"," +
                                     params->get_auth_header();

    TRACE("submit(%O, %O, %O, %O)\n", method, uri, args, extra_headers);

    return Protocols.HTTP.do_method(method, uri, args, extra_headers);
  }

  //! Casting method
  //!
  //! @param how
  //!  Only supports @tt{string@}
  mixed cast(string how)
  {
    if (how != "string") {
      ARG_ERROR("how", "%O can not be casted to \"%s\", only to \"string\"\n",
                this, how);
    }

    return (method == "GET" ? normalize_uri(uri) + "?" : "")+(string)params;
  }

  //! String format
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O, %O)", object_program(this),
                               (string)uri, base_string, params);
  }
}

//! An OAuth user
class Consumer
{
  //! Consumer key
  string key;

  //! Consumer secret
  string secret;

  //! Callback url that the remote verifying page will return to.
  string|Standards.URI callback;

  //! Creates a new @[Consumer] object
  //!
  //! @param _key
  //! @param _secret
  //! @param _callback
  //!  NOTE: Has no effect in this implementation
  void create(string _key, string _secret, void|string|Standards.URI _callback)
  {
    key      = _key;
    secret   = _secret;
    callback = ASSURE_URI(_callback);
  }

  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O, %O)", object_program(this),
                               key, secret, callback);
  }
}

//! Token class.
class Token
{
  //! The token key
  string key;

  //! The token secret
  string secret;

  //! Creates a new @[Token]
  //!
  //! @param key
  //! @param secret
  void create(string _key, string _secret)
  {
    key = _key;
    secret = _secret;
  }

  //! Casting method.
  //! NOTE! Only supports casting to string wich will return a query string
  //! of the object
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how) {
      case "string":
        return "oauth_token=" + key + "&"
               "oauth_token_secret=" + secret;
    }

    error("Can't cast %O() to %O\n", object_program(this), how);
  }

  //! String format.
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O)", object_program(this),
                               key, secret);
  }
}

//! Represents a query string parameter, i.e. @tt{key=value@}
class Param
{
  //! Param name
  protected string name;

  //! Param value
  protected string value;

  //! Creates a new @[Param]
  //!
  //! @param _name
  //! @param _value
  void create(string _name, mixed _value)
  {
    name = _name;
    value = (string)_value;
  }

  //! Getter for the name attribute
  string get_name() { return name; }

  //! Setter for the value attribute
  void set_name(string value) { name = value; }

  //! Getter for the value attribute
  string get_value() { return value; }

  //! Setter for the value attribute
  void set_value(mixed _value) { value = (string)_value; }

  //! Returns the value encoded
  string get_encoded_value() { return uri_encode(value); }

  //! Returns the name and value for usage in a signature string
  string get_signature() { return uri_encode(name) + "=" + uri_encode(value); }

  //! Comparer method. Checks if @[other] equals this object
  //!
  //! @param other
  int(0..1) `==(mixed other)
  {
    if (object_program(other) != Param) return 0;
    if (name == other->get_name())
      return value == other->get_value();

    return 0;
  }

  //! Checks if this object is greater than @[other]
  //!
  //! @param other
  int(0..1) `>(mixed other)
  {
    if (object_program(other) != Param) return 0;
    if (name == other->get_name())
      return value > other->get_value();

    return name > other->get_name();
  }

  //! Index lookup
  //!
  //! @param key
  object `[](string key)
  {
    if (key == name)
      return this;

    return 0;
  }

  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O)", object_program(this), name, value);
  }
}


//! Collection of @[Param]
class Params
{
  //! Storage for @[Param]s of this object
  private array(Param) params;

  //! Create a new @[Params]
  //!
  //! @param _params
  //!  Arbitrary number of @[Param] objects
  void create(Param ... _params)
  {
    params = _params||({});
  }

  //! Returns the params for usage in an authentication header
  string get_auth_header()
  {
    array a = ({});
    foreach (params, Param p) {
      if (has_prefix(p->get_name(), "oauth_"))
        a += ({ p->get_name() + "=\"" + p->get_encoded_value() + "\"" });
    }

    return a*",";
  }

  //! Returns the parameters as a mapping
  mapping get_variables()
  {
    mapping m = ([]);

    foreach (params, Param p)
      if (!has_prefix(p->get_name(), "oauth_"))
        m[p->get_name()] = p->get_value();

    return m;
  }

  //! Returns the parameters as a query string
  string get_query_string()
  {
    array s = ({});
    foreach (params, Param p)
      if (!has_prefix(p->get_name(), "oauth_"))
        s += ({ p->get_name() + "=" + uri_encode(p->get_value()) });

    return s*"&";
  }

  //! Returns the parameters as a mapping with encoded values
  //!
  //! @seealso
  //!  @[get_variables()]
  mapping get_encoded_variables()
  {
    mapping m = ([]);

    foreach (params, Param p)
      if (!has_prefix(p->get_name(), "oauth_"))
        m[p->get_name()] = uri_encode(p->get_value());

    return m;
  }

  //! Returns the parameters for usage in a signature base string
  string get_signature()
  {
    return sort(params)->get_signature()*"&";
  }

  //! Casting method. Only supports casting to @tt{mapping@}.
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how)
    {
      case "mapping":
        mapping m = ([]);
        foreach (params, Param p)
          m[p->get_name()] = p->get_value();

        return m;
        break;
    }
  }

  //! Append mapping @[args] as @[Param] objects
  //!
  //! @param args
  //!
  //! @returns
  //!  The object being called
  object add_mapping(mapping args)
  {
    foreach (args; string k; string v)
      params += ({ Param(k, v) });

    return this_object;
  }

  //! Append @[p] to the internal array
  //!
  //! @param p
  //!
  //! @returns
  //!  The object being called
  object `+(Param|Params p)
  {
    params += object_program(p) == Params ? values(p) : ({ p });
    return this_object();
  }

  //! Removes @[p] from the internal array
  //!
  //! @param p
  //!
  //! @returns
  //!  The object being called
  object `-(Param p)
  {
    foreach (params, Param pm) {
      if (pm == p) {
        params -= ({ pm });
        break;
      }
    }

    return this_object();
  }

  //! Index lookup
  //!
  //! @param key
  //!
  //! @returns
  //!  If no @[Param] is found returns @tt{0@}.
  //!  If multiple @[Param]s with name @[key] is found a new @[Params] object
  //!  with the found params will be retured.
  //!  If only one @[Param] is found that param will be returned.
  mixed `[](string key)
  {
    array(Param) p = params[key]-({0});
    if (!p) return 0;
    return sizeof(p) == 1 ? p[0] : Params(@p);
  }

  //! Returns the @[params]
  mixed _values()
  {
    sort(params);
    return params;
  }

  //! Returns the size of the @[params] array
  int _sizeof()
  {
    return sizeof(params);
  }

  //! String format
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O)", object_program(this), params);
  }
}

//! Encode string according to OAuth specs
//!
//! @param s
string uri_encode(string s)
{
  if (String.width(s) < 8)
    s = string_to_utf8(s);

  String.Buffer b = String.Buffer();
  function add = b->add;
  foreach (s/1, string c) {
    if (has_value(UNRESERVED_CHARS, c))
      add(c);
    else {
#if constant(String.string2hex)
      add("%" + upper_case(String.string2hex(c)));
#else /* Pike 7.4 compat cludge */
      add("%" + upper_case(Crypto.string_to_hex(c)));
#endif
    }
  }

  return b->get();
}

//! Normalizes @[uri]
//!
//! @param uri
//!  A @tt{string@} or @[Standards.URI]
string normalize_uri(string|Standards.URI uri)
{
  uri = ASSURE_URI(uri);
  string nuri = sprintf("%s://%s", uri->scheme, uri->host);

  if ( !(<"http","https">)[uri->scheme] || !(<80,443>)[uri->port] )
    nuri += ":" + uri->port;

  return nuri + uri->path;
}

//! Generates a @tt{nonce@}
string nonce()
{
#if constant(Standards.UUID)
  return ((string)Standards.UUID.make_version4())-"-";
#else
  return (string)time();
#endif
}

