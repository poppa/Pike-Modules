/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Api@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Api.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Api.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Api.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "flickr.h"
import ".";

protected multiset all_perms = (< PERM_READ, PERM_WRITE, PERM_DELETE >);
protected string key;
protected string secret;
protected string token;

protected string endpoint = ENDPOINT_URL;
protected string response_format = "rest";
protected string permission = PERM_READ;
protected int bit_permission = BIT_PERM_READ;

protected User user;

void create(string api_key, string api_secret, void|string api_token)
{
  key = api_key;
  secret = api_secret;
  token = api_token;
}

string get_identifer()
{
  return key + secret + (token||"") + (user && user->username || "");
}

void set_token(string api_token)
{
  token = api_token;
}

string get_token()
{
  return token;
}

void set_user(User _user)
{
  user = _user;
}

User get_user()
{
  if (user) return user;
  Response rsp = call("flickr.auth.checkToken");
  if (rsp) {
    token = (string)rsp->auth->token;
    set_permission((string)rsp->auth->perms);
    return user = User()->from_mapping((mapping)rsp->auth->user);
  }

  return 0;
}

int(0..1) is_authenticated()
{
  return !!get_user();
}

string get_response_format()
{
  return response_format;
}

string get_permission()
{
  return permission;
}

int get_bit_permission()
{
  return bit_permission;
}

void set_permission(string perm)
{
  if ( !all_perms[perm] ) {
    error("Unknown permission %O. Expected %s! ", perm,
          String.implode_nicely((array)all_perms, "or"));
  }

  permission = perm;
  bit_permission = BIT_PERM_MAP[perm];
}

string get_auth_url(void|string perm)
{
  if (perm) set_permission(perm);

  Params p = Params(
    Param(API_KEY, key),
    Param(PERMS, permission),
    Param(FORMAT, response_format)
  );

  p += Param(API_SIG, p->sign(secret));
  return AUTH_ENDPOINT_URL + "?" + p->to_query();
}

int(0..1) request_token(string frob)
{
  Params p = Params(Param(FROB, frob));
  Response rsp = call("flickr.auth.getToken", p);
  if (rsp) {
    token = (string)rsp->auth->token;
    set_permission((string)rsp->auth->perms);
    user = User()->from_mapping((mapping)rsp->auth->user);
    return 1;
  }

  return 0;
}

string call_xml(string api_method, void|mapping|Params _params,
                void|int(0..1) dont_throw_error)
{
  Params params = Params();

  if (objectp(_params)) params = _params;
  if (mappingp(_params)) params = Params()->add_mapping(_params);

  if ( !params[API_KEY] ) params += Param(API_KEY, key);
  if ( !params[METHOD] )  params += Param(METHOD, api_method);
  if ( !params[FORMAT] )  params += Param(FORMAT, response_format);
  if ( !params[PERMS] )   params += Param(PERMS, permission);
  if ( token && !params[AUTH_TOKEN] ) params += Param(AUTH_TOKEN, token);

  mapping vars = params->to_mapping() + ([ API_SIG : params->sign(secret) ]);
  
  //TRACE("call(%O, %O)\n", api_method, vars);
  
  Protocols.HTTP.Query q = Protocols.HTTP.post_url(endpoint,vars,HTTP_HEADERS);

  //TRACE("Data: %s\n", q->data());

  if (q->status != 200)
    error("Bad status \"%d\" in HTTP response! ", q->status);

  string data = q->data();
  Response rsp = Response(data);
  mapping a = rsp->get_attributes();

  if (!a->stat) error("Malformed XML response from Flickr");

  if (!dont_throw_error) {
    if (a->stat != "ok") {
      if (rsp = rsp->err) {
	mapping a = rsp->get_attributes();
	error("Flickr API error: %s (%s)! ", a->msg||"", a->code||"");
      }
      else
	error("Unknown Flickr API error: %s\n", q->data());
    }
  }

  return data;
}

Response call(string api_method, void|mapping|Params params)
{
  return Response(call_xml(api_method, params));
}
