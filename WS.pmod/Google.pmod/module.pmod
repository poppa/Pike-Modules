
string md5(string s)
{
#if constant(Crypto.MD5)
  s = String.string2hex(Crypto.MD5.hash(s));
#else /* Compat cludge for Pike 7.4 */
  s = Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif

  return s;
}

string download(string url)
{
  url = replace(url, "&amp;", "&");
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(url);
  if (q->status != 200)
    error("Bad status \"%d\" in Google.download()\n", q->status);

  return q->data();
}