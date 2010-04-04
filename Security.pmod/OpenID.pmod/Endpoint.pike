/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Endpoint.pike@}
//!
//! This class represents an OpenID endpoint, that is an authentication page.
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Enpoint.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Endpoint.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Endpoint.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

//! The URL of the endpoint
private string url;

//! The alias used in the OpenID parametes, like ext1, ax etc
private string alias;

//! The time when the endpoint expires, seconds since epoch.
private int expired;


//! Creates a new Endpoint object
//!
//! @param _url
//!  The URL of the endpoint
//! @param _alias
//!  The alias used in the OpenID parametes, like ext1, ax etc
//! @param max_age_in_seconds
//!  Number of seconds the object is valid. Default is @tt{7200@}
void create(string|Standards.URI _url, string|void _alias, 
            int|void max_age_in_seconds)
{
  if (!_url) error("URL is null!");
  url = (string)_url;
  alias = _alias||.DEFAULT_ENDPOINT_ALIAS;
  expired = time() + (max_age_in_seconds||7200);
}

//! Returns the URL of the endpoint
string get_url()
{
  return url;
}

//! Returns the alias used in the OpenID parameters
string get_alias()
{
  return alias;
}

//! Checks if the endpoint has expired or not.
int(0..1) is_expired()
{
  return time() >= expired;
}

//! Comparer method. Checks if this object equals the @[other] object
int(0..1) `==(Security.OpenID.Endpoint other)
{
  return other->get_url() == url;
}

string _sprintf(int t)
{
  Calendar.Second tajm = Calendar.Second("unix", expired);
  return t == 'O' && sprintf("%O(\"%s\", \"%s\", \"%s\")",
                             object_program(this), url,
                             alias, tajm->format_time());
}
