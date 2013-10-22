/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Various Google related modules and classes

//! Makes an @tt{MD5@} hashed string of @[s].
//!
//! @param s
string md5(string s)
{
#if constant(Crypto.MD5)
  s = String.string2hex(Crypto.MD5.hash(s));
#else /* Compat cludge for Pike 7.4 */
  s = Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif
  return s;
}

//! Makes a HTTP GET request to @[url].
//!
//! @throws
//!  An error if the HTTP response code isn't @tt{200@}.
//!
//! @param url
//! @param headers
string download(string url, void|mapping headers)
{
  url = replace(url, "&amp;", "&");
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, 0, headers);

  if (q->status != 200)
    error("Bad status \"%d\" in Google.download()\n", q->status);

  return q->data();
}
