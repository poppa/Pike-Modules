/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! WSDL.pmod decodes (eventually perhaps also encodes) a WSDL document
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| WSDL.pmod decodes (eventually perhaps also encodes) a WSDL document
//|
//| License GNU GPL version 3
//|
//| WSDL.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| WSDL.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with WSDL.pmod. If not, see <http://www.gnu.org/licenses/>

#define WSDL_DEBUG
#include "wsdl.h"

#if constant(Crypto.MD5)
# define MD5(S) String.string2hex(Crypto.MD5.hash((S)))
#else /* Compat cludge for Pike 7.4 */
# define MD5(S) Crypto.string_to_hex(Crypto.md5()->update((S))->digest())
#endif

//! Storage for fetched wsdl files
private mapping cache = ([]);

//! Use disk cache or not
private int(0..1) disk_cache = 1;

//! Sub directory in which to put fetched wsdl files if disk cache is 
//! enabled. This director will be put in the systems temporary directory
private string dcache_location;

void set_cache_location(string path)
{
  if (!path) {
    mapping env = getenv();
    path = combine_path(env->TEMP||env->TMP||"/tmp","pike-wsdl-cache");
    if (!Stdio.exist(path))
      Stdio.mkdirhier(path, 00777);
  }

  if (!Stdio.exist(path))
    error("\"%s\" doesn't exist! ", path);

  dcache_location = path;
}

//! Store fetched WSDL files on disk or not.
//!
//! @param dcache
void use_disk_cache(int(0..1) dcache)
{
  disk_cache = dcache;
}

//! Manually adds a WSDL file to the runtime cache
//!
//! @param url
//! @param wsdl_xml
void add_cache(string|Standards.URI url, string wsdl_xml)
{
  cache[(string)url] = wsdl_xml;
}

//! Fetches the WSDL file at @[url] and returns a @[Definitions] object
//!
//! @param url
//! @param username
//! @param password
.Definitions get_url(string|Standards.URI url, void|string username,
                     void|string password,
                     void|Protocols.HTTP.Query con)
{
  return .Definitions(get_cache(url, username, password, con));
}

//! Checks if @[url] exists in the caches, if not fetches it, and returns the
//! raw XML of the WSDL file
//!
//! @param url
//! @param username
//! @param password
string get_cache(string|Standards.URI url, void|string username,
                 void|string password, void|Protocols.HTTP.Query con)
{
  string file, data;
  url = String.trim_all_whites((string)url);
  if ( data = cache[url] )
    return data;

  if (disk_cache) {
    if (!dcache_location) 
      set_cache_location(0);

    sscanf(url, "%*s://%[^?]?%[^=&]=%s", string lurl, string ext, string tail);
    if (tail) {
      tail = replace(tail, ({ "=","&" }), ({ "_","_" }));
      lurl += "-" + tail;
    }

    lurl += "." + (ext||"wsdl");
    array(string) parts = lurl/"/";
    string dir = combine_path( dcache_location, @parts[0..sizeof(parts)-2] );
    if (!Stdio.exist(dir))
      Stdio.mkdirhier(dir);

    file = combine_path( dir, parts[-1] );

    if (Stdio.exist(file))
      cache[url] = data = Stdio.read_file(file);
  }

  if (data) return data;

  mapping headers = ([]);

  if (username && password) {
    headers["Authorization"] = 
      "Basic " + MIME.encode_base64(username+":"+password);
  }
  else if (sscanf(url, "%s://%s:%s@%s", string a, string b,
                                        string c, string d) == 4)
  {
    headers["Authorization"] = "Basic " + MIME.encode_base64(b+":"+c);
    url = a + "://" + d;
  }

  Protocols.HTTP.Query q;

  if (con) {
    if (stringp(url)) url = Standards.URI(url);
    string host;
    if (con->con->query_address())
      host = (con->con->query_address()/" ")[0];
    else
      host = url->host;

    string query = url->path;
    if (url->query) query += "?" + url->query;
    query = sprintf("GET %s HTTP/1.0", query);
    headers = headers;
    TRACE("+++ con->sync_request(%O,%d,%O,%O)\n", host, url->port, query, headers);
    q = con->sync_request(host, url->port, query, headers);
  }
  else {
    q = Protocols.HTTP.get_url(url, 0, headers);
  }

  if (q->status == 200) {
    cache[url] = q->data();
    if (file) Stdio.write_file( file, cache[url] );
    return cache[url];
  }

  werror("Bad HTTP status (%d) when trying to fetch %O\n", q->status, url);
}

//! Finds the root node of an XML document.
//!
//! @param n
Parser.XML.Tree.Node find_root(Parser.XML.Tree.Node n)
{
  foreach (n->get_children(), Parser.XML.Tree.Node c)
    if (c->get_node_type() == Parser.XML.Tree.XML_ELEMENT)
      return c;

  return 0;
}

string get_ns_from_uri(string uri)
{
  if (!uri) return 0;
  if (uri[-1] != '/') uri += "/";
  return Standards.SOAP.Constants.URI_TO_NS[uri];
}
