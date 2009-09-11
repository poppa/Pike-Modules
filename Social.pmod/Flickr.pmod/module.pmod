//! A Pike Flickr API implementation.
//! Copyright @ 2008, Pontus Östlund - @url{www.poppa.se@}
//!
//! For an explaination of the Flickr API see:
//! @url{http://www.flickr.com/services/api/@}
//!
//! @xml{<code lang="pike" detab="3" tabsize="2">
//!   // Download the 100 most recent public photos on Flickr
//!
//!   string key     = "c7da40e37420g147b12b8dca2f9d6e46";
//!   string secret  = "3c7b7f812fcf0e5d";
//!   string token   = "72151608102366049-65479g2df271232d-27525982";
//!
//!   Flickr.Api api = Flickr.Api(key, secret, token, "./Flickr.pmod/cache");
//! 
//!   api->use_cache(0);
//! 
//!   Flickr.Photos   ph = Flickr.Photos(api);
//!   Flickr.Response rs = ph->get_recent();
//!   array(string)   rc = ({});
//!
//!   foreach ((array)rs->photos||({}), Flickr.Item photo)
//!     rc += ({ ph->get_photo_src(photo) });
//!
//!   Flickr.download(rc, "/Users/pontusostlund/temp/flickr/recent/");
//! </code>@}
 
#include "flickr.h"
import ".";
import Parser.XML.Tree;

// =================================================== Constants and globals {{{

//! This Flickr APIs version
constant VERSION = "0.1";

//! String used as user agent in HTTP requests
constant HTTP_USER_AGENT = "Pike Flickr Agent v" + VERSION;

//! Default extra HTTP headers used in HTTP requests
constant HTTP_HEADERS = ([ "User-Agent" : HTTP_USER_AGENT ]);

//! The query param for the API key
constant API_KEY = "api_key";

//! The query param for the API secret
constant API_SECRET = "api_secret";

//! The query param for the API signature
constant API_SIG = "api_sig";

//! The query param for the auth token
constant AUTH_TOKEN = "auth_token";

//! The query param for the frob
constant FROB = "frob";

//! The query param for the permisson
constant PERMS = "perms";

//! The query param for the method
constant METHOD = "method";

//! The query param for the response format
constant FORMAT = "format";

//! The query param for the privacy filter
constant PRIVACY_FILTER = "privacy_filter";

//! Read permission
constant PERM_READ = "read";

//! Write permission
constant PERM_WRITE = "write";

//! Delete permission
constant PERM_DELETE = "delete";

//! Bitmask value of read permission
constant BIT_PERM_READ = 1;

//! Bitmask value of write permission
constant BIT_PERM_WRITE = 2;

//! Bitmask permisson of delete permission
constant BIT_PERM_DELETE = 4;

//! String permission to bitmask map
constant BIT_PERM_MAP = ([
  PERM_READ   : BIT_PERM_READ,
  PERM_WRITE  : BIT_PERM_WRITE,
  PERM_DELETE : BIT_PERM_DELETE
]);

//! Default response format
constant RESPONSE_FORMAT = "xmlrpc";

//! Default API endpoint url
constant ENDPOINT_URL = "http://www.flickr.com/services/rest/";

//! Default authentication endpoint url
constant AUTH_ENDPOINT_URL = "http://www.flickr.com/services/auth/";

//! Default upload endpoint url
constant UPLOAD_ENDPOINT_URL = "http://api.flickr.com/services/upload/";

//! Flickr method parameters signed by @[sign_params()]
typedef mapping(string:string|int) SignedParams;

// =========================================================== End constants }}}
// ========================================================== Module methods {{{

//! Sign the parameters for a Flicker request
//!
//! @param secret
//!  The @[Flickr.Api] secret
//! @param params
//!  The parameters to send to the Flickr method
//!
//! @returns
//!  It's just a @tt{mapping(string:string)@} but for clarity it has it's own
//!  typedef.
SignedParams sign_params(string secret, mapping|SignedParams params) // {{{
{
  string sig = "";
  mapping values = ([]);

  foreach (sort(indices(params)), string k) {
    string v = (string)params[k];
    if (String.width(v) < 8)
      if (mixed e = catch(v = string_to_utf8(v)))
	werror("Couldn't UTF8 encode \"%s\" in Flickr.sign_params()\n", k);

    sig += k + v;
    values[k] = v;
  }

#ifdef FLICKR_DEBUG2
  DDEBUG("SIGPARM: %s\n\n", secret+sig);
#endif

  values[API_SIG] = MD5(secret + sig);

  return values;
} // }}}


//! Utility method for creating a unique cachekey suffix for Flickr method
//! calls. Creates an MD5 sum of the values in @[params]
//!
//! @param params
//!  The params to create a MD5 sum of.
//!
//! @returns
//!  Returns an MD5 sum of all the values in @[params]
string mk_cache_suffix(SignedParams|mapping params)
{
  string out = "";
  foreach (values(params), mixed v)
    out += (string)v;
  
  return MD5(out);
}


//! Builds a query string from @[m]
string http_build_query(mapping|SignedParams m) // {{{
{
  array a = ({});
  foreach (sort(indices(m)), string k)
    a += ({ k + "=" + m[k] });

  return a*"&";
} // }}}


//! Downloads the URL in @[src] to the directory @[save_to]
//!
//! @param src
//!  Either a single URL to an image or an array of URLs.
//! @param save_to
//!  The path to a directory where to save the downloaded images
//!
//! @returns
//!  Returns the path(s) to the downloaded image(s)
string|array download(string|array src, string save_to)
{
  if (!Stdio.is_dir(save_to))
    THROW("Download directory \"%s\" doesn't exist!", save_to);

  string path;

  if (arrayp(src)) {
    array out = ({});
    DownloadManager.ThreadPool tp = DownloadManager.ThreadPool(5,3);
    foreach (src, string s) {
      path = combine_path(save_to, basename(s));
      tp->add(DownloadManager.download, s, path);
      out += ({ path });
    }

    tp->run();
    return out;
  }

  path = combine_path(save_to, basename(src));
  DownloadManager.download(src, path);
  return path;
}

// ====================================================== End module methods }}}

//! The core Flickr API class.
//!
//! This class provides authentication mechanisms and other default settings
//! for how a particular Flickr application can be used.
class Api // {{{
{
  //! All available Flickr permissions. Use for easy verification of
  //! permission settings.
  private multiset  _all_perms = (< PERM_READ, PERM_WRITE, PERM_DELETE >);

  //! The Flickr application key
  private string _key;

  //! The flickr application secret
  private string _secret;

  //! The flickr application token
  private string _token;

  //! The URL to the Flickr services
  private string _endpoint_url = ENDPOINT_URL;

  //! The response format of the Flickr services.
  private string _response_format = RESPONSE_FORMAT;

  //! The cache object if cache is being used
  private Cache _cache;

  //! The ID of the authenticated user of a particular Flickr service.
  private string _userid;

  //! The username of the authenticated user of a particular Flickr service.
  private string _username;

  //! The full name of the authenticated user of a particular Flickr service.
  private string _fullname;

  //! The permission to use for the Flickr service
  private string _perms;

  //! The bitmask representation of the permission
  private int _bit_perms;

  //! Use cacheability or not
  private int(0..1) _use_cache = 0;

  //! Create a new @[Flickr.Api] instance
  //!
  //! @param key
  //!  The API key of the service
  //! @param secret
  //!  The API secret of the service
  //! @param token
  //!  The API token of the service
  //! @param cachedir
  //!  The path where to save cache files. If (void) no cache will be used.
  void create(string key, string secret, void|string token,
              void|string cachedir) // {{{
  {
    _key    = key;
    _secret = secret;

    if (token)
      _token = token;

    if (cachedir) {
      if (!Stdio.exist(cachedir)) {
	THROW("The cache directory \"%s\" given to Flickr.Api doesn't exist!",
              cachedir);
      }
      _use_cache = 1;
      _cache = Cache(this, cachedir);
    }
  } // }}}


  //! Getter for the API key. The API key can only be set through
  //! @[Flickr.create()]
  string key()
  {
    return _key;
  }


  //! Getter/setter for the @[Api._response_format]
  //!
  //! @param format
  //!  The format to set
  //!
  //! @returns
  //!  Always returns the @[Api._response_format].
  string response_format(void|string format)
  {
    if (format)
      _response_format = format;
    
    return _response_format;
  }


  //! Getter/setter for cacheability
  //!
  //! @param use_cache
  //!  Enable/disable cacheing. Only useful if the @[Flickr.Api] object was
  //!  created with the @tt{cachedir@} argument.
  int(0..1) use_cache(void|int use_cache)
  {
    if (!zero_type(use_cache))
      _use_cache = use_cache;

    return _use_cache;
  }


  //! Getter for the @[Flickr.Cache] object if cacheing is enabled.
  Cache cache()
  {
    return _use_cache && _cache;
  }


  //! Removes the cache key @[method]+@[suffix] where @[suffix] is some kind
  //! of Flickr method ID like a photoset ID, photo ID, comment ID or such.
  //! So if you want to remove the cache for a photoset photo list where the
  //! photoset ID is @tt{52157103864358594@} do like this:
  //!
  //! @example
  //!  api->remove_cache("flickr.photosets.getPhotos", "52157103864358594");
  //!
  //! @param method
  //!  The Flickr method that wrote the cache
  //! @param suffix
  //!  Cache key suffix.
  void remove_cache(string method, void|string suffix)
  {
    if (suffix) method += "_" + suffix;
    _cache && _cache->remove(method)->write();
  }


  //! Clears the cache for the current @[Flickr.Api] instance.
  void clear_cache()
  {
    _cache && _cache->clear()->write();
  }


  //! Returns default parameters needed for a Flickr method call
  SignedParams get_default_params()
  {
    SignedParams p = ([]);
    p[API_KEY] = _key;
    p[FORMAT]  = _response_format;
    p[PERMS]   = _perms;
    if (_token) p[AUTH_TOKEN] = _token;
    return p;
  }


  //! Getter/setter for the @[Flickr.Api] secret
  //!
  //! @param secret
  //!
  //! @returns
  //!  Returns the API secret
  string secret(void|string secret)
  {
    if (secret) _secret = secret;
    return _secret;
  }


  //! Getter/setter for the endpoint url
  //!
  //! @param ep
  //!  If not empty the endpoint where to send the method calls to.
  //! @seealso
  //!  @[Flickr.ENDPOINT_URL]
  //!
  //! @returns
  //!  Always returns the endpoint url.
  string endpoint(string|void ep) // {{{
  {
    if (ep) _endpoint_url = ep;
    return _endpoint_url;
  } // }}}


  //! Creates an authentication URL.
  //!
  //! @param perm
  //!  The permisson to use for this API.
  //!
  //! @seealso
  //!  @[Flickr.PERM_READ], @[Flickr.PERM_WRITE] or @[Flickr.PERM_DELETE]
  string get_auth_url(string perm) // {{{
  {
    permission(perm);

    SignedParams params = ([
      API_KEY : _key,
      PERMS   : perm,
      FORMAT  : _response_format
    ]);

    params = sign_params(_secret, params);
    return AUTH_ENDPOINT_URL + "?" + http_build_query(params);
  } // }}}


  //! Getter/setter for the permisson of this API
  //!
  //! @param perm
  //!  The permisson to use for this API.
  //!
  //! @seealso
  //!  @[Flickr.PERM_READ], @[Flickr.PERM_WRITE] or @[Flickr.PERM_DELETE]
  //!
  //! @returns
  //!  Returns the permission of the API
  string permission(string|void perm) // {{{
  {
    if ( perm && _all_perms[perm] ) {
      _perms = perm;
      _bit_perms = BIT_PERM_MAP[perm];
    }

    return _perms;
  } // }}}


  //! Returns the bitmask representation of the permission
  int bitperm()
  {
    return _bit_perms;
  }


  //! Returns a Flickr token
  //!
  //! @param perms
  //!  The permisson to use for this API
  //! @param frob
  //!  The frob of this API.
  string get_token(string perms, string frob) // {{{
  {
    permission(perms);
    mapping params = ([ FROB : frob ]);
    Response res;
    if (mixed e = catch(res = execute("flickr.auth.getToken", params)))
      THROW("Error in \"flickr.auth.getToken\": %s", describe_error(e));

    werror(" ### get_token: %O\n", res);
    
    return _token;
  } // }}}


  //! Checks if the current instance is authenticated or not!
  int(0..1) is_authenticated() // {{{
  {
    return userid() && 1;
  } // }}}


  //! Returns the user ID. If not set a Flickr method call to
  //! "flickr.auth.checkToken" will be made to fetch the user info.
  //!
  //! @returns
  //!  Returns the user ID
  string userid() // {{{
  {
    if (!_userid) {
      Response res;
      if (mixed e = catch(res = execute("flickr.auth.checkToken")))
	THROW("Error in \"flickr.auth.checkToken\": %s", describe_error(e));

      if (Item auth = res->auth) {
	_userid   = auth->user->attributes->nsid;
	_username = auth->user->attributes->username;
	_fullname = auth->user->attributes->fullname;
	if (!_token)
	  _token = auth->token->value;

	permission(auth->perms->value);
      }
    }

    return _userid;
  } // }}}


  //! Returns the username. If not set a call to @[Flickr.userid()] will be
  //! made to fetch the user info.
  //!
  //! @returns
  //!  The username
  string username()
  {
    if (!_username) userid();
    return _username;
  }


  //! Returns the users full name. If not set a call to @[Flickr.userid()] will
  //! be made to fetch the user info.
  //!
  //! @returns
  //!  The username
  string fullname()
  {
    if (!_fullname) userid();
    return _fullname;
  }


  //! Wrapper for a Flickr method call if there's no API for it. This method
  //! will handle signing of params and such.
  //!
  //! @param method
  //!  The Flickr method to call
  //! @param params
  //!  The parameters to send to the method
  //! @param use_cache
  //!  Override the default cacheability setting in @[Flickr.Api]. This will 
  //!  only disable cacheing if set in @[Flickr.Api] it won't enable it if it 
  //!  isn't set.
  //! @param cache_suffix
  //!  If cacheing is enabled this value will be appended to the cache key.
  Response execute(string method, void|mapping|SignedParams params,
                   void|int(0..1) use_cache, void|string cache_suffix) // {{{
  {
    if (zero_type(use_cache)) 
      use_cache = _use_cache;

    if ( !params          ) params          = ([]);
    if ( !params[API_KEY] ) params[API_KEY] = _key;
    if ( !params[METHOD]  ) params[METHOD]  = method;
    if ( !params[FORMAT]  ) params[FORMAT]  = _response_format;
    if ( !params[PERMS]   ) params[PERMS]   = permission();
    if ( _token && !params[AUTH_TOKEN] )
      params[AUTH_TOKEN] = _token;

    params = sign_params(_secret, params);

#ifdef FLICKR_DEBUG2
    DDEBUG("Exec params: %O", params);
#endif

    return Request(this, method, params, cache_suffix)->query(use_cache);
  } // }}}


  //! Print formated string
  string _sprintf(int t) // {{{
  {
    return t == 'O' && sprintf(
      "Flickr.Api(\"Key: %s\",\"Secret: %s\",\"Token: %s\")",
      _key, _secret, _token||"0"
    );
  } // }}}
} // }}}


//! A class for handling requests to Flickr methods.
//!
//! This is a low level class and should not be needed to be instantiated 
//! manually,unless you really need and want to of course ;)
class Request // {{{
{
  //! The @[Flickr.Api] used for the request
  protected Api api;

  //! The method the request will call
  protected string method;

  //! The cache key for the method call. Only used if cacheability is on.
  protected string cache_key;

  //! The parameters to send with the request.
  protected SignedParams params;


  //! Creates a new @[Flickr.Request] object
  //!
  //! @param api
  //!  The @[Flickr.Api] object to use for the request
  //! @param method
  //!  The Flickr method to call
  //! @param params
  //!  The parameters to send with the request
  //! @param cache_suffix
  //!  If cacheing is enabled calls to the same method but with different
  //!  parameters need to be separable. This argument will be appended to
  //!  the cache key. If for example an ID of a Flickr photoset is given here
  //!  in a call to @tt{flickr.photosets.getPhotos@} the cache key will look 
  //!  like @tt{flickr.photosets.getPhotos_72137653846297156@}.
  //!
  //!  See also @[Flickr.mk_cache_suffix()].
  void create(Api _api, string _method, SignedParams _params,
              void|string cache_suffix)
  {
    api       = _api;
    method    = _method;
    params    = _params;
    cache_key = method;

    if (cache_suffix)
      cache_key += "_" + cache_suffix;
  }


  //! Does the actual HTTP request to the @[Flickr.Request.method].
  //!
  //! @param use_cache
  //!  Use cacheing or not.
  //!
  //! @returns
  //!  A @[Flickr.Response] object
  Response query(void|int use_cache)
  {
    if (zero_type(use_cache))
      use_cache = api->use_cache();

    if (use_cache)
      if (string c = api->cache()->get(cache_key))
	return Response(c);

    string url = api->endpoint();

#ifdef FLICKR_DEBUG2
    DDEBUG("Query: %s?%s", url, http_build_query(params));
#endif

    Protocols.HTTP.Query q = Protocols.HTTP.post_url(url, params, HTTP_HEADERS);

    if (q->status != 200)
      THROW("Bad response code (%d) in query (%s)", q->status, method);

    werror("--- Request DONE\n");

    string data = q->data();
    Response resp = Response(data);

    if (use_cache)
      api->cache()->save(cache_key, data)->write();

    return resp;
  }
}// }}}


//! A class reprsenting a response to a @[Flickr.Request].
//!
//! This is a low level class and should not be needed to be instantiated 
//! manually,unless you really need and want to of course ;)
class Response // {{{
{
  //! The raw XML form a @[Flickr.Request] query.
  protected string xml_data;

  //! The serialized result of the XML.
  protected .Item result;


  //! Creates a new @[Flickr.Response] object
  //!
  //! @throws
  //!  An exception if an XML-RPC fault object is returned when decoding
  //!  the XML response.
  //!
  //! @param xml
  //!  The raw XML from a @[Flickr.Request].
  void create(string xml)
  {
    xml_data = xml;
    mixed response = Protocols.XMLRPC.decode_response(xml);

    if (objectp(response)) {
      THROW("Error (%d) in Flickr.Response: %s",
	    response->fault_code, response->fault_string);
    }
    else
      result = Item( response && response[0] );
  }


  //! Returns the @[Flickr.Item] of this object
  .Item get_item()
  {
    return result;
  }


  //! Arrow index lookup
  //!
  //! @param arg
  //!  The member to look for.
  //!
  //! @returns
  //!  Always returns the @[Flickr.Item] of this object
  mixed `->(string arg)
  {
    return result;
  }


  //! Print formated output
  string _sprintf(int t)
  {
    switch (t)
    {
      case 'O': return sprintf("%O", result);
    }
  }
} // }}}


//! Handles cacheing of Flickr method calls.
//!
//! This is a low level class and should not be needed to be instantiated 
//! manually,unless you really need and want to of course ;)
class Cache // {{{
{
  //! The @[Flickr.Api] the cache is valid for
  protected Api api;

  //! The path to the cache directory
  protected string dir;

  //! The name of the cache file
  protected string file;

  //! The full path to the cache file.
  protected string path;

  //! The cache container.
  protected mapping __cache = ([]);


  //! Creates a new instance of @[Flickr.Cache].
  //!
  //! @param api
  //!  The @[Flickr.Api] this cache is valid for
  //! @param directory
  //!  The directory in which to save all cache files
  void create(Api _api, string directory)
  {
    api  = _api;
    dir  = directory;
    file = api->key() + ".flickr.cache";
    path = combine_path(dir, file);

    if (!Stdio.exist(path)) {
      if (mixed e = catch(Stdio.write_file(path, "")))
	THROW("Couldn't write cache file: %s\n", path);
    }
    else {
      string d = Stdio.read_file(path);
      if (d && sizeof(d))
	__cache = decode_value(d);
    }
  }


  //! Saves to the cache container.
  //!
  //! @note
  //!  This will not write the cache to disk. Use @[Flickr.Cache.write()]
  //!  for that.
  //!
  //! @param id
  //!  The ID or key of the cache in the cache container. Most likely this
  //!  should be the name of the Flickr method the cache is for and for calls
  //!  to methods with varying results the method name is likely to be
  //!  suffixed by a unique string like an ID of a photoset or similar.
  //! @param xml
  //!  The data to store in the cache container. This is supposed to be the
  //!  raw data from the HTTP request. See @[Flickr.Request.query()].
  //!
  //! @returns
  //!  Returns the instance of this object.
  Cache save(string id, string xml)
  {
    __cache[id] = xml;
    return this_object();
  }


  //! Remove @[id] from the cache container.
  //!
  //! @note
  //!  This will not write the change to disk!
  //!
  //! @returns
  //!  This instance
  Cache remove(string id)
  {
    m_delete(__cache, id);
    return this;
  }


  //! Clears the cache container.
  //!
  //! @note
  //!  This will not write the change to disk.
  //!
  //! @returns
  //!  This instance
  Cache clear()
  {
    __cache = ([]);
    return this;
  }


  //! Retreives the data from the cache container with id @[id]
  //!
  //! @param id
  string get(string id)
  {
    return __cache[id];
  }


  //! Writes the cache container to disk
  void write()
  {
    if (mixed e = catch(Stdio.write_file(path, encode_value(__cache))))
      THROW("Error writing cache do disk!");
  }


  //! Returns the indices from the cache container
  array _indices()
  {
    return indices(__cache);
  }
} // }}}
