/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{OAuth module@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! OAuth.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! OAuth.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with OAuth.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}
//!
//! @b{Example@}
//!
//! @xml{<code lang="pike" detab="2" tabsize="2">
//!  import Social.OAuth;
//!
//!  string endpoint = "http://twitter.com/users/show.xml";
//!
//!  Consumer consumer = Consumer(my_consumer_key, my_consumer_secret);
//!  Token    token    = Token(my_access_token_key, my_access_token_secret);
//!  Params   params   = Params(Param("user_id", 12345));
//!  Request  request  = request(consumer, token, params, Request.GET);
//!
//!  request->sign_request(Signature.HMAC_SHA1, consumer, token);
//!  Protocols.HTTP.Query query = request->submit();
//!
//!  if (query->status != 200)
//!    error("Bad response status: %d\n", query->status);
//!
//!  werror("Data is: %s\n", query->data());
//! </code>@}

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

#include "oauth.h"

#if constant(roxen)
constant uri_encode = Roxen.http_encode_url;
#else
constant uri_encode = Protocols.HTTP.uri_encode;
#endif

//! Helper method to create a @[Request]
//!
//! @param consumer
//! @param token
//! @param uri
//!  A @tt{string@} or @[Standards.URI]
//! @param params
//! @param http_method
//!  Either @[Request.GET] or @[Request.POST]
Request request(Consumer consumer, Token token, STRURI uri,
                Params params, int http_method)
{
  if (!consumer)
    ARG_ERROR("consumer", "Can not be NULL.");

  Params dparams = Params(
    Param(VERSION_KEY,      VERSION),
    Param(NONCE_KEY,        nonce()),
    Param(TIMESTAMP_KEY,    time()),
    Param(CONSUMER_KEY_KEY, consumer->key)
  );

  if (token)  dparams += Param(TOKEN_KEY, token->key);
  if (params) dparams += params;

  return Request(uri, http_method, dparams);
}

//! Converts a query string, or a mapping, into a @[Params] object.
//!
//! @param q
Params query_to_params(string|mapping q)
{
  Params ret = Params();

  if (!q || !sizeof(q))
    return ret;

  if (mappingp(q)) {
    foreach(q; string n; string v)
      ret += Param(n, v);

    return ret;
  }

  q = (q[0] == '?') ? q[1..] : q;

  foreach (q/"&", string p) {
    sscanf(p, "%s=%s", string n, string v);
    ret += Param(n, v);
  }

  return ret;
}

//! An OAuth user
class Consumer
{
  protected constant KEY_KEY    = CONSUMER_KEY_KEY;
  protected constant KEY_SECRET = 0;

  //! Consumer key
  string key;

  //! Consumer secret
  string secret;

  //! Callback url that the remote verifying page will return to.
  optional Standards.URI callback;

  //! Creates a new @[Consumer]
  //!
  //! @param _key
  //! @param _secret
  //! @param _callback
  //!  Can be a @tt{string@} or a @[Standards.URI]
  void create(string _key, string _secret, void|STRURI _callback)
  {
    key      = _key;
    secret   = _secret;
    callback = ASSURE_URI(_callback);
  }

  //! Casting method.
  //! Only handle casting to @tt{string@} which will turn the object into
  //! a query string.
  //!
  //! @param how
  mixed cast(string how)
  {
    if (how == "string") {
      string r = sprintf("%s=%s", KEY_KEY, key);
      if (KEY_SECRET) r += sprintf("&%s=%s", KEY_SECRET, secret);
      if (callback)   r += sprintf("&%s=%s", CALLBACK_KEY, (string)callback);
      return r;
    }

    error("Can't cast OAuth.Consumer to %s\n", how);
  }

  //! String format.
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%s(%O,%O,%O)", CLASS_NAME(this), key, secret,
                               callback);
  }
}

//! Token class.
class Token
{
  inherit Consumer;

  protected constant KEY_KEY    = TOKEN_KEY;
  protected constant KEY_SECRET = TOKEN_SECRET_KEY;

  //! Creates a new @[Token]
  //!
  //! @param key
  //! @param secret
  void create(string key, string secret)
  {
    ::create(key, secret);
  }
}

//! Represents a query string parameter, i.e. @tt{key=value@}
class Param
{
  //! Param name
  private string name;

  //! Param value
  private string value;

  //! Creates a new @[Param]
  //!
  //! @param _name
  //! @param _value
  void create(string _name, mixed _value)
  {
    name = _name;
    value = (string)_value;
  }

  //! Getters for the @[name] and @[value]
  string get_name()  { return name; }
  string get_value() { return value; }

  //! Comparer method. Checks if @[other] equals this object
  //!
  //! @param other
  int(0..1) `==(mixed other)
  {
    if (!is_comparable(other)) return 0;
    if (name == other->get_name())
      return value == other->get_value();

    return 0;
  }

  //! Checks if this object is greater than @[other]
  //!
  //! @param other
  int(0..1) `>(mixed other)
  {
    if (!is_comparable(other)) return 0;
    if (name == other->get_name())
      return value > other->get_value();

    return name > other->get_name();
  }

  //! Concatenates this obejct with @[other]. This creates a query string
  //!
  //! @param other
  string `+(object other)
  {
    if (!is_comparable(other))
      error("Can't concatenate %O with %O\n", other, this);
    return this->cast("string") + "&" + other->cast("string");
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

  //! Creates a query string variable and url encodes the @[name] and @[value]
  string encode()
  {
    return uri_encode(name) + "=" + uri_encode(value);
  }

  //! Same as @[encode()] except creates a mapping of the @[name] and @[value]
  mapping encode_mapping()
  {
    return ([ uri_encode(name) : uri_encode(value) ]);
  }

  //! Returns the @[name]
  mixed indices()
  {
    return name;
  }

  //! Returns the @[value]
  mixed values()
  {
    return value;
  }

  //! Casting method
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how)
    {
      case "string":  return sprintf("%s=%s", name, value);
      case "mapping": return ([ name : value ]);
    }

    error("Can't cast QueryParam to \"%s\"!", how);
  }

  //! String format
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%s(%s=%s)", CLASS_NAME(this), name, value);
  }

  //! Checks if this object is comparable to @[o]
  private int(0..1) is_comparable(mixed o)
  {
    return (objectp(o) && o->get_name && o->get_value);
  }
}

//! Collection of @[Param]
class Params
{
  //! Storage for @[Param]s of this object
  private array(Param) params;

  //! Create a new @[Params]
  void create(Param ... args)
  {
    params = args||({});
  }

  //! Casting method
  //!
  //! @param how
  mixed cast(string how)
  {
    sort(params);
    switch (how)
    {
      case "array":  return params;
      case "string": return params->cast("string")*"&";
      case "url":    return params->encode()*"&";

      case "mapping":
	mapping r = ([]);
	foreach (sort(values(params)), Param p) {
	  string name = p->get_name();
	  if ( r[name] ) {
	    if (!arrayp( r[name] )) r[name] = ({ r[name] });
	    r[name] += ({ p->get_value() });
	  }
	  else r[name] = p->get_value();
	}
	return r;

      default: /* nothing */
    }

    error("Can't cast \"%s\" to \"%s\".\n", CLASS_NAME(this), how);
  }

  //! Append @[p] to the internal array
  //!
  //! @param p
  object `+(Param|Params p)
  {
    params += object_program(p) == Params ? values(p) : ({ p });
    return this_object();
  }

  //! Removes @[p] from the internal array
  //!
  //! @param p
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
    return t == 'O' && sprintf("%s(%O)", CLASS_NAME(this), params);
  }
}

//! Class for building a signed request and querying the remote service
class Request
{
  //! GET method
  constant GET  = 1;

  //! POST method
  constant POST = 2;

  //! Method type to string mapping
  constant TYPE_MAPPING = ([ GET : "GET", POST : "POST" ]);

  //! The remote endpoint
  protected Standards.URI uri;

  //! The signature basestring
  protected string base_string;

  //! The HTTP method to use for this call
  protected int http_method;

  //! String representation of the HTTP method
  protected string method;

  //! The parameters to send
  protected Params params;

  //! Creates a new @[Request]
  //!
  //! @param _uri
  //!  A @tt{string@} or @[Standards.URI]
  //! @param _http_method
  //!  The HTTP method to use. Either @[Request.GET] or @[Request.POST]
  //! @param _params
  void create(STRURI _uri, int _http_method, void|Params _params)
  {
    uri         = ASSURE_URI(_uri);
    http_method = _http_method;
    params      = query_to_params(uri->query||"");

    if (_params) params += _params;

    switch (http_method)
    {
      case GET:
      case POST:
      	method = TYPE_MAPPING[http_method];
	break;

      default:
      	ARG_ERROR("http_method", "Must be one of \"GET\" or \"POST\".");
    }
  }

  //! Add a param
  //!
  //! add_param(Param parameter)
  //! add_param(string name, string value)
  //!
  //! @param name
  //! @param value
  //!
  //! @returns
  //!  The instance of self.
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
    add_param(SIGNATURE_METHOD_KEY, sig->get_method());
    add_param(SIGNATURE_KEY, sig->build_signature(this, consumer, token));
  }

  //! Generates a signature base
  string get_signature_base()
  {
    return ({
      uri_encode(method),
      uri_encode(normalize_uri(uri)),
      uri_encode(get_signed_params())
    }) * "&";
  }

  string get_signed_params()
  {
    Param p;
    if ( p = params[SIGNATURE_KEY] )
      params -= p;

    return (string)params;
  }

  //! Send the request to the remote endpoint
  //!
  //! @param extra_headers
  Protocols.HTTP.Query submit(void|mapping extra_headers)
  {
    mapping args = (mapping)params;
    TRACE("submit(%O, %O, %O, %O)\n", method, uri, args, extra_headers);
    return Protocols.HTTP.do_method(method, uri, args, extra_headers);
  }

  //! Casting method
  mixed cast(string how)
  {
    if (how != "string") {
      ARG_ERROR("how", "%O can not be casted to \"%s\", only to \"string\"\n",
                this, how);
    }

    return (http_method == GET ? normalize_uri(uri) + "?" : "")+(string)params;
  }
}

//! Normalizes @[uri]
//!
//! @param uri
//!  A @tt{string@} or @[Standards.URI]
string normalize_uri(STRURI uri)
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
  return ((string)Standards.UUID.make_version4())-"-";
}
