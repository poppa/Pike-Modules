/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! [PROG-NAME]
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| [PROG-NAME].pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| [PROG-NAME].pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with [PROG-NAME].pike. If not, see <http://www.gnu.org/licenses/>.

#define GOOGLE_DEBUG

#include "google.h"

//! Authorization object.
//!
//! @seealso
//!  @[Authorization]
protected .Authorization auth;

//! Creates a new Api instance
//!
//! @param _auth
//!  Athorization object. See also @[Authorization] and
//!  @[set_authorization()]
void create(.Authorization _auth)
{
  auth = _auth;
}

//! Setter for the authorization object.
//!
//! @seealso
//!  @[Authorization]
//!
//! @param _auth
void set_authorization(.Authorization _auth)
{
  auth = _auth;
}

//! Issues a call with a GET method
//!
//! @param g_method
//!  The Facebook Graph API method to call
//! @param params
mixed get(string g_method, void|mapping|.Params params)
{
  return call(g_method, params);
}

//! Issues a call with a POST method
//!
//! @param g_method
//!  The Facebook Graph API method to call
//! @param params
//! @param data
//!  Eventual inline data to send
mixed post(string g_method, void|mapping|.Params params, void|string data)
{
  return call(g_method, params, "POST", data);
}

//! Issues a call with a DELETE method
//!
//! @param g_method
//!  In most cases this will be the ID of what to delete
//! @param params
mixed delete(string g_method, void|mapping|.Params params)
{
  return call(g_method, params, "DELETE");
}

//! Calls a Facebook Graph method.
//!
//! @throws
//!  An exception is thrown if the response status code is other than
//!  @tt{200@}, @tt{301@} or @tt{302@}.
//!
//! @param g_method
//!  The Facebook method to call: @tt{me@}, @tt{me/home@},
//!  @tt{[user_id]/photos@} and so on.
//!
//! @param params
//!  Additional params to send in the request
//!
//! @param http_method
//!  HTTP method to use. @tt{GET@} is default
//!
//! @param data
//!  Inline data to send in a @tt{POST@} request for instance.
//!
//! @returns
//!  If JSON is available the JSON response from Facebook will be decoded
//!  and returned. If not the raw response (e.g a JSON string) will be
//!  returned.
//!  The exception to this is if the status code in the response is a 
//!  @tt{30x@} (a redirect), then the response headers mapping will be 
//!  returned.
mixed call(string g_method, void|mapping|.Params params,
	   void|string http_method, void|string data)
{
  http_method = http_method || "GET";
  mapping headers = ([ "User-Agent" : .USER_AGENT ]);
  .Params p = .Params();
  
  if (params) {
    if (mappingp(params))
      p->add_mapping(params);
    else
      p += params;
  }

  if (auth && !auth->is_expired()) {
    if (string a = auth->get_access_token())
      p += .Param("access_token", a);
  }

  string uri = (g_method);

  TRACE("\n$$$ %s %s %O\n\n", http_method, uri, p->to_mapping());

  if (upper_case(http_method) != "GET") {
    data = p->to_query();
    params = 0;
  }
  else
    params = p->to_mapping();

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.do_method(http_method, uri, params, headers, 0, data);

  if ( (< 301, 302 >)[q->status] )
    return q->headers;

  if (q->status != 200) {
    string d = q->data();
    if (has_value(d, "error")) {
      mapping e = Social.json_decode(d);
      if (e->error)
	error("Error %d: %s. ", e->error->code, e->error->message);
    }

    error("Bad status (%d) in HTTP response! ", q->status);
  }

  string jdata = unescape_forward_slashes(q->data());

  return Social.json_decode(jdata);
}

protected string unescape_forward_slashes(string s)
{
  return replace(s, "\\/", "/");
}
