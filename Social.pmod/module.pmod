/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Social module
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Social.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Social.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Social.pmod. If not, see <http://www.gnu.org/licenses/>.

#include "social.h"

constant USER_AGENT = "Pike Social client (Pike " + __VERSION__ + ")";

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
void set_json_decode(function func)
{
  json_decode = func;
}

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