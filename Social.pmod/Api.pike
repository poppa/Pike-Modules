/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

/* This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/* File licensing and authorship information block.
 *
 * Version: MPL 1.1/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Initial Developer of the Original Code is
 *
 * Pontus Östlund <pontus@poppa.se>
 *
 * Portions created by the Initial Developer are Copyright (C) Pontus Östlund
 * All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of the LGPL, and not to allow others to use your version
 * of this file under the terms of the MPL, indicate your decision by
 * deleting the provisions above and replace them with the notice
 * and other provisions required by the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL or the LGPL.
 *
 * Significant Contributors to this file are:
 *
 */
 
#define TRACE(X...) werror("%s:%d: %s",basename(__FILE__),__LINE__,sprintf(X))

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

//! Invokes a call with a GET method
//!
//! @param g_method
//!  The Google API method to call
//! @param params
mixed get(string g_method, void|mapping|.Params params)
{
  return call(g_method, params);
}

//! Invokes a call with a POST method
//!
//! @param g_method
//!  The Google API method to call
//! @param params
//! @param data
//!  Eventual inline data to send
mixed post(string g_method, void|mapping|.Params params, void|string data)
{
  return call(g_method, params, "POST", data);
}

//! Invokes a call with a DELETE method
//!
//! @param g_method
//!  The Google API method to call
//! @param params
mixed delete(string g_method, void|mapping|.Params params)
{
  return call(g_method, params, "DELETE");
}

//! Invokes a call with a PUT method
//!
//! @param g_method
//!   The Google API method to call
//! @param params
mixed put(string g_method, void|mapping|.Params params)
{
  return call(g_method, params, "PUT");
}

//! Calls a Google API method.
//!
//! @throws
//!  An exception is thrown if the response status code is other than
//!  @tt{200@}, @tt{301@} or @tt{302@}.
//!
//! @param g_method
//!  The Google API method to call!
//!  This should be a Fully Qualified Domain Name
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
  Social.Params p = Social.Params();

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
