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
//!  Request  request  = request(consumer, token, params);
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

//! Chars that shouldn't be URL encoded
constant UNRESERVED_CHARS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUV"
                            "WXYZ0123456789-_.~"/1;

#include "oauth.h"

//! Helper method to create a @[Request]
//!
//! @param consumer
//! @param token
//! @param uri
//!  A @tt{string@} or @[Standards.URI]
//! @param params
//! @param http_method
//!  Defaults to GET
Request request(STRURI uri, Consumer consumer, Token token,
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
Params query_to_params(STRURI|mapping q)
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
  //! @param _uri
  //!  A @tt{string@} or @[Standards.URI]
  //! @param _http_method
  //!  The HTTP method to use. Either @[Request.GET] or @[Request.POST]
  //! @param _params
  void create(STRURI _uri, string http_method, void|Params _params)
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

    if (!extra_headers)
      extra_headers = ([]);

    string realm = uri->scheme + "://" + uri->host;
    extra_headers["Authorization"] = "OAuth realm=\"" + realm + "\"," +
                                     params->get_auth_header();

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
  STRURI callback;

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

  //! String format.
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O, %O, %O)", object_program(this),
                               key, secret, callback);
  }
}

//! Token class.
class Token
{
  string key;
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

  //! Formatting method
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

  //! Casting method
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
  //!  The current instance
  object add_mapping(mapping args)
  {
    foreach (args; string k; string v)
      params += ({ Param(k, v) });
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
    return t == 'O' && sprintf("%O(%O)", object_program(this), params);
  }
}

//! Encode string according to OAuth specs
//!
//! @param s
string uri_encode(string s)
{
  if (String.width(s) != 8)
    s = string_to_utf8(s);

  String.Buffer b = String.Buffer();
  function add = b->add;
  foreach (s/1, string c) {
    if (has_value(UNRESERVED_CHARS, c))
      add(c);
    else 
      // NOTE: String.string2hex isn't Pike 7.4 compatible
      add("%" + upper_case(String.string2hex(c)));
  }

  return b->get();
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
