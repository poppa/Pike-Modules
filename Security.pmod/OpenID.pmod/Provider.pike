/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Provider.pike@}
//!
//! This class represents an OpenID provider
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Provider.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Provider.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Provider.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

//! The name of the provider, like google, yahoo etc.
private string name;

//! The URL of the authentication page
private string url;

//! The alias used in the OpenID parameters, like ext1, ax etc
private string alias;

//! Creates a new OpenID provider object
//!
//! @param _name
//! @param _url
//! @param _alias
void create(string _name, string _url, string _alias)
{
  name = _name;
  url = _url;
  alias = _alias;
}

//! Returns the name of the provider
string get_name()
{
  return name;
}

//! Returns the URL of the authentication page of the provider
string get_url()
{
  return url;
}

//! Returns the alias the provider is using in the OpenID parameters
string get_alias()
{
  return alias;
}
