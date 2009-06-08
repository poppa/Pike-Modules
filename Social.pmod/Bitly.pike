/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Bitly class@}
//!
//! This class communicates with @url{http://bit.ly@} which is a service to
//! shorten, track and share links.
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Bitly.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Bitly.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Bitly.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}
//!
//! @b{Example@}
//!
//! @xml{<code lang="pike" detab="2" tabsize="2">
//!  // Most simple scenario
//!  Social.Bitly bit = Social.Bitly("username", "R_someApiKey876hd723");
//!  string longurl = "http://some-freaking.long/url/man/that/never/ends/";
//!  Social.Bitly.Response resp = bit->shorten(longurl);
//!  werror("%O\n", resp);
//!
//!  if (resp->success())
//!    write("Short url: %s\n", resp->result()->nodeKeyVal->shortUrl);
//!  else
//!   write("Error: %s\n", resp->error_message());
//! </code>@}

#if constant(Crypto.MD5)
# define MD5(S) String.string2hex(Crypto.MD5.hash((S)))
#else /* Compat cludge for Pike 7.4 */
# define MD5(S) Crypto.string_to_hex(Crypto.md5()->update((S))->digest())
#endif

import Parser.XML.Tree;

//! States that the argument given is a @tt{shortUrl@}.
//!
//! @seealso
//!  @[expand()], @[info()] and @[stats()]
protected constant ARG_URL  = 1;

//! States that the argument given is a @tt{hash@}.
//!
//! @seealso
//!  @[expand()], @[info()] and @[stats()]
protected constant ARG_HASH = 2;

//! Argument type to query variable name mapping
protected constant PARAM_KEY = ([ ARG_URL : "shortUrl", ARG_HASH : "hash" ]);

//! Version of Bitly to use
constant VERSION = "2.0.1";

//! Reponse format in XML
constant FORMAT_XML  = "xml";

//! Response format in JSON
constant FORMAT_JSON = "json";

//! Base URI to the Bitly API
constant BASE_URI = "http://api.bit.ly";

//! The login username
protected string handle;

//! The API key
protected string apikey;

//! The Bitly API version to use
protected string version = VERSION;

//! The reponse format to use
//!
//! @note 
//!  Only XML is supported at the moment.
protected string format  = "xml";

//! Callback method. Only useful if @[format] is @tt{JSON@} which isn't 
//! implemented yet ;)
protected string callback;

//! Request cache object.
protected DataCache cache;


//! Creates a new instance of @[Bitly].
//!
//! @param username
//! @param api_key
void create(string username, string api_key, void|int cache_dir)
{
  handle = username;
  apikey = api_key;
  cache  = DataCache(apikey, cache_dir||".");
}

//! Set the Bitly API version to use
//!
//! @param _version
void set_version(string _version)
{
  version = _version;
}

//! Set the response format
//!
//! @param _format
void set_format(string _format)
{
  if (lower_case(format) != "xml")
    error("Only XML response format is implemented\n");
  format = _format;
}

//! Set the callback for @tt{JSON@} responses
void set_callback(string _callback)
{
  error("Callback needs JSON response format but that isn't implemented\n!");
  callback = _callback;
}

//! Shortens the @[uri]
//!
//! @param uri
Response shorten(string|Standards.URI uri)
{
  return call("shorten", ([ "longUrl" : (string)uri ]));
}

//! Expands a shortened URL to it's original value
//!
//! @param url_or_hash
//!  Either the shortened URL or its hash.
Response expand(string url_or_hash)
{
  int arg_type = ARG_HASH;
  if (search(url_or_hash, "://") > -1)
    arg_type = ARG_URL;

  return call("expand", ([ PARAM_KEY[arg_type] : url_or_hash ]));
}

//! Returns info about the page of the shortened URL, page title etc...
//!
//! @param url_or_hash
//!  Either the shortened URL or its hash.
//! @param key
//!  One or more keys to limit the attributes returned about each bitly 
//!  document, eg: htmlTitle,thumbnail
Response info(string url_or_hash, void|array keys)
{
  int arg_type = ARG_HASH;
  if (search(url_or_hash, "://") > -1)
    arg_type = ARG_URL;

  mapping params = ([ PARAM_KEY[arg_type] : url_or_hash ]);
  if (keys) params += ([ "keys" : keys*"," ]);
  return call("info", params);
}

//! Returns traffic and referrer data of the shortened URL
//!
//! @param url_or_hash
//!  Either the shortened URL or its hash.
Response stats(string url_or_hash)
{
  int arg_type = ARG_HASH;
  if (search(url_or_hash, "://") > -1)
    arg_type = ARG_URL;

  return call("stats", ([ PARAM_KEY[arg_type] : url_or_hash ]));
}

//! Does the HTTP call to Bitly
//!
//! @param service
//! @param params
//! @param method
protected Response call(string service, mapping params, void|string method)
{
  mapping response;
  mapping p = default_params();
  if (params) p += params;

  method        = normalize_http_method(method||"GET");
  string url    = get_normalized_url(service);
  mapping authz = get_authz_headers();

  string cc = get_cache_key(method, url, p);
  if (response = cache->get(cc)) {
    werror("Found cache!\n");
    return Response(response);
  }

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.do_method(method, url, p, authz);

  if (q->status == 200) {
    Response resp = Response(q->data());
    if (resp->success())
      cache->set(cc, resp->get_tree())->write();
    return resp;
  }

  return 0;
}

//! Normalized a HTTP method, i.e makes sure it's either @tt{GET@} or 
//! @tt{POST@}.
protected string normalize_http_method(string method)
{
  if ( !(< "POST","GET" >)[upper_case(method)] )
    error("HTTP method must be \"GET\" or \"POST\". Got %O\n", method);

  return method;
}

//! Normalizes the API url to call.
//!
//! @param service
//!  The service to call, i.e. @tt{info@}, @tt{stat@} etc.
protected string get_normalized_url(string service)
{
  if (sizeof(service)) {
    if (service[0] != '/')  service = "/" + service;
    if (service[-1] == '/') service = service[..sizeof(service)-2];
  }

  return BASE_URI + service;
}

//! Returns a basic authentication header.
protected mapping get_authz_headers()
{
  return ([
    "Authorization" : "Basic " + MIME.encode_base64(handle + ":" + apikey)
  ]);
}

//! Returns the default parameters that's sent in every request.
protected mapping default_params()
{
  mapping p = ([
    "apiKey"  : apikey,
    "format"  : format,
    "version" : version
  ]);

  if (callback && format == "json") p += ([ "callback" : callback ]);

  return p;
}

//! Generates a cache key that's unique for a given request.
//!
//! @param method
//!  The HTTP method being used in the request
//! @param url
//!  The request endpoint
//! @param params
//!  The parameters sent in the request
protected string get_cache_key(string method, string url, mapping params)
{
  string p = sort(indices(params))*"" + sort(values(params))*"";
  return MD5(handle+apikey+method+url+p);
}

//! Response class that parses an XML response and turns it into a mapping
//! and provides methods to determine if the request was successful or not.
class Response
{
  protected int     errorcode    = 0;
  protected string  errormessage = 0;
  protected string  statuscode   = 0;
  protected mapping tree         = ([]);
  protected mixed   results;

  //! Creates a new instance of @[Response]
  //!
  //! @param response
  //!  Can either be cached response as a mapping, e.g. a result from this 
  //!  cache, or a raw XML response from a Bitly request.
  void create(string|mapping response)
  {
    if (stringp(response)) {
      Node root = parse_input(response);
      if (!root) error("Unable to parse XML response!\n");
      parse(root[0], tree);
      tree = tree->bitly;
    }
    else 
      tree = response;

    errorcode    = (int)tree->errorCode;
    errormessage = tree->errorMessage;
    statuscode   = tree->statusCode;
    results      = tree->results;
  }

  //! Was the last response successful or not?
  int(0..1) success()
  {
    return statuscode == "OK";
  }

  //! Returns the error code, if any
  int error_code()
  {
    return errorcode;
  }

  //! Returns the error message if any
  string error_message()
  {
    return errormessage;
  }

  //! Returns the status code of the last response.
  //!
  //! @note
  //!  This is not the HTTP status, but the Bitly status.
  string status_code()
  {
    return statuscode;
  }

  //! Returns the data part of the response
  mixed result()
  {
    return results;
  }

  //! Returns the entire XML tree as a mapping
  mapping get_tree()
  {
    return tree;
  }
  
  //! Parses the XML response and turns it into a mapping
  //!
  //! @param n
  //! @param p
  protected mapping parse(Node n, mapping p)
  {
    string name = n->get_tag_name();
    p[name] = ([]);
  
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() != XML_ELEMENT)
	continue;
  
      if (cn->get_first_element())
	p[name] += parse(cn, ([]));
      else
	p[name][cn->get_tag_name()] = cn->value_of_node();
    }
  
    return p;
  }
}

//! Class that stores the results of HTTP requests to Bitly so that the same
//! request doesn't have to be made twice.
class DataCache
{
  protected string  apikey;
  protected string  path;
  protected mapping cache;

  //! Creates a new instance of @[DataCache]
  //!
  //! @param api_key
  //! @param cache_path
  //!  The directory in which to store the cache files.
  void create(string api_key, string cache_path)
  {
    path = combine_path(cache_path, MD5(api_key) + ".bitly");
    if (!Stdio.exist(path))
      Stdio.write_file(path, "");

    string data = Stdio.read_file(path);
    cache = data && sizeof(data) && decode_value(data) || ([]);
  }

  //! Set cache with @[key] to @[value]
  //!
  //! @note
  //!  This method doesn't write the cache to disk. Call @[write()] to save
  //!  the cache.
  //!
  //! @param key
  //! @param value
  //!
  //! @returns
  //!  This instance, so multiple calls to this method can be chained.
  this_program set(string key, mixed value)
  {
    cache[key] = value;
    return this_object();
  }

  //! Returns the cache item with key @[key]
  //!
  //! @param key
  mixed get(string key)
  {
    return cache[key];
  }

  //! Delete cache item with key @[key]
  mixed delete(string key)
  {
    m_delete(cache, key);
  }

  //! Flushes the cache, i.e totally removes it.
  mixed flush()
  {
    cache = ([]);
    write();
  }

  //! Write the cache to disk.
  void write()
  {
    Stdio.write_file(path, encode_value(cache));
  }
}
