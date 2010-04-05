/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! The @tt{DesktopApi@} is identical to @[Api()] except this class uses
//! @tt{Basic@} authentication instead of @tt{OAuth@}. This makes this class
//! a better alternative for applications not running in a web browser.
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [PROG-NAME].pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [MODULE-NAME].pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [PROG-NAME].pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "twitter.h"
import ".";
import Security.OAuth;
inherit Api;

//! The username to log on as
private string username;

//! The password for the user to log on as
private string password;

// The HTTP client object
//private Protocols.HTTP.Query http;

//! Creates a new instance of @[DesktopApi].
//!
//! @param _username
//! @param _password
void create(void|string _username, void|string _password)
{
  username = _username;
  password = _password;
}

//! Does the low level HTTP call to Twitter.
//!
//! @param url
//!  The full address to the Twitter service e.g:
//!  @tt{http://twitter.com/direct_messages.xml@}
//! @param args
//!  Arguments to send with the request
//! @param mehod
//!  The HTTP method to use
public string call(string|Standards.URI url, void|mapping|Params args,
		   void|string method)
{
  method = ::normalize_method(method);

  if (mappingp(args)) {
    mapping m = copy_value(args);
    args = Params();
    args->add_mapping(m);
  }

  mapping(string:string) headers = ([]);

  headers["Connection"]   = "Keep-Alive";
  headers["Keep-Alive"]   = "300";
  headers["Content-Type"] = "application/x-www-form-urlencoded";

  if (username && password) {
    headers["Authorization"] = 
      "Basic " + MIME.encode_base64(username + ":" + password);
  }

  string body = args && args->get_query_string();

//    werror("\n>>> %s %s?%s\n", method, url, body||"");

  Protocols.HTTP.Query http = Protocols.HTTP.do_method(method, url, 0,
						       headers, 0, body);

  if (http->status != 200)
    error("Bad status (%d) in HTTP response!", http->status);

#ifdef TWITTER_DEBUG
  Stdio.write_file(basename((string)url), http->data());
#endif
  
  return http->data();
}
