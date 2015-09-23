/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

#include "social.h"

constant USER_AGENT = "Mozilla 4.0 (Pike/" + __REAL_MAJOR__ + "." +
                      __REAL_MINOR__ + "." + __REAL_BUILD__ + ")";

#if constant(Standards.JSON.decode)
public function json_decode = Standards.JSON.decode;
#else
public function json_decode = lambda (string s) {
  error("No JSON decode function available. You can set an arbitrary JSON "
        "decode function via Graph.set_json_decode().\n");
};
#endif

//! Set JSON decoding function
//!
//! @param func
__deprecated__ void set_json_decode(function func)
{
  json_decode = func;
}

//! Human readable representation of @[timestamp].
//!
//! Examples are:
//!       0..30 seconds: Just now
//!      0..120 seconds: Just recently
//!   121..3600 seconds: x minutes ago
//!   ... and so on
//!
//! @param timestamp
string time_elapsed(int timestamp)
{
  int diff = (int) time(timestamp);
  int t;

  switch (diff)
  {
    case      0 .. 30: return "Just now";
    case     31 .. 120: return "Just recently";
    case    121 .. 3600: return sprintf("%d minutes ago",(int)(diff/60.0));
    case   3601 .. 86400:
      t = (int)((diff/60.0)/60.0);
      return sprintf("%d hour%s ago", t, t > 1 ? "s" : "");

    case  86401 .. 604800:
      t = (int)(((diff/60.0)/60.0)/24);
      return sprintf("%d day%s ago", t, t > 1 ? "s" : "");

    case 604801 .. 31449600:
      t = (int)((((diff/60.0)/60.0)/24)/7);
      return sprintf("%d week%s ago", t, t > 1 ? "s" : "");
  }

  return "A long time ago";
}

//! MD5 routine
//!
//! @param s
string md5(string s)
{
#if constant(Crypto.MD5)
  return String.string2hex(Crypto.MD5.hash(s));
#else
  return Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif
}

//! Same as @[Protocols.HTTP.uri_encode()] except this turns spaces into
//! @tt{+@} instead of @tt{%20@}.
//!
//! @param s
string urlencode(string s)
{
#if constant(Protocols.HTTP.uri_encode)
  return Protocols.HTTP.uri_encode(s);
#elif constant(Protocols.HTTP.http_encode_string)
  return Protocols.HTTP.http_encode_string(s);
#endif
}

//! Same as @[Protocols.HTTP.uri_decode()] except this turns spaces into
//! @tt{+@} instead of @tt{%20@}.
//!
//! @param s
string urldecode(string s)
{
#if constant(Protocols.HTTP.uri_decode)
  return Protocols.HTTP.uri_decode(s);
#elif constant(Protocols.HTTP.http_decode_string)
  return Protocols.HTTP.http_decode_string(s);
#else
  return s;
#endif
}

//! Turns a query string into a mapping
//!
//! @param query
mapping query_to_mapping(string query)
{
  mapping m = ([]);
  if (!query || !sizeof(query))
    return m;

  if (query[0] == '?')
    query = query[1..];

  foreach (query/"&", string p) {
    sscanf (p, "%s=%s", string k, string v);
    m[k] = urldecode(v);
  }

  return m;
}
