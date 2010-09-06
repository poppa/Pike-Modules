#!/usr/bin/env pike
/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! DesktopApi.pike
//!
//! Copyright © 2010, Pontus Östlund - www.poppa.se
//!
//! License GNU GPL version 3
//!
//! DesktopApi.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! DesktopApi.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with DesktopApi.pike. If not, see <http://www.gnu.org/licenses/>.

#include "flickr.h"
import ".";

inherit Api;

void create(string api_key, string api_secret, void|string api_token)
{
  ::create(api_key, api_secret, api_token);
}

string get_frob()
{
  mixed a = call("flickr.auth.getFrob");
  if (is_ok(a))
    return (string)a->frob;

  return 0;
}

//! Returns the authorization url.
//!
//! @param perm
//!  What permission to give to the authenticated user. This overrides the
//!  global value of the object.
string get_auth_url(string frob, void|string perm)
{
  if (perm) set_permission(perm);

  Params p = Params(
    Param(API_KEY, key),
    Param(PERMS, permission),
    Param(FROB, frob)
  );

  p += Param(API_SIG, p->sign(secret));
  werror("Login: %s\n", p->to_query());
  return AUTH_ENDPOINT_URL + "?" + p->to_query();
}
