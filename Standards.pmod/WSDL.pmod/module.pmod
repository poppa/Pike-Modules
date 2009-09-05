/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Standards.WSDL.Binding@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! WSDL.pmod decodes (eventually perhaps also encodes) a WSDL document
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! WSDL.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! WSDL.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with WSDL.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

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
private string dcache_location = "pike-wsdl-cache";

// Debugging only method
void dtrace(mixed ... args)
{
#ifdef __NT__
  mapping env = getenv();
  string p = combine_path(env->TEMP||env->TMP||"\\Temp", "wsdl.log");
  Stdio.File fh = Stdio.File(p, "wac");
#else
  Stdio.File fh = Stdio.File("/tmp/wsdl.log", "wac", 00666);
#endif
  fh->write(@args);
  fh->close();
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
.Definitions get_url(string|Standards.URI url)
{
  return .Definitions(get_cache(url));
}

//! Checks if @[url] exists in the caches, if not fetches it, and returns the
//! raw XML of the WSDL file
//!
//! @param url
string get_cache(string|Standards.URI url)
{
  string file, data;
  url = String.trim_all_whites((string)url);
  if ( data = cache[url] )
    return data;

  if (disk_cache) {
    mapping env = getenv();
    string tmpdir = combine_path(env->TEMP||env->TMP||"/tmp", dcache_location);
    if (!Stdio.exist(tmpdir)) {
      if (mixed err = catch(Stdio.mkdirhier(tmpdir, 00777))) {
	werror("Unable to create wsdl cache dir %O!\N", tmpdir);
	return 0;
      }
    }

    file = combine_path(tmpdir, MD5(url) + ".wsdl");
    if (Stdio.exist(file))
      cache[url] = data = Stdio.read_file(file);
  }
  
  if (data) return data;
  
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);

  if (q->status == 200) {
    cache[url] = q->data();
    if (file) Stdio.write_file( file, cache[url] );
    return cache[url];
  }

  error("Bad HTTP status (%d) when trying to fetch %O\n", q->status, url);
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