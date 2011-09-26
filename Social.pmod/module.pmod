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
