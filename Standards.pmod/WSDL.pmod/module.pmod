#if constant(Crypto.MD5)
# define MD5(S) String.string2hex(Crypto.MD5.hash((S)))
#else /* Compat cludge for Pike 7.4 */
# define MD5(S) Crypto.string_to_hex(Crypto.md5()->update((S))->digest())
#endif

private mapping cache = ([]);
private int(0..1) disk_cache = 1;
private string dcache_location = "pike-wsdl-cache";

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

void use_disk_cache(int(0..1) dcache)
{
  disk_cache = dcache;
}

void add_cache(string|Standards.URI uri, string wsdl_xml)
{
  cache[(string)uri] = wsdl_xml;
}

.Definitions get_url(string|Standards.URI url)
{
  return .Definitions(get_cache(url));
}

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

Parser.XML.Tree.Node find_root(Parser.XML.Tree.Node n)
{
  foreach (n->get_children(), Parser.XML.Tree.Node c)
    if (c->get_node_type() == Parser.XML.Tree.XML_ELEMENT)
      return c;
  
  return 0;
}