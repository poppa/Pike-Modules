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

inherit .Api;

constant API_URI  = "https://www.googleapis.com/tasks/v1";
constant SCOPE_RW = "https://www.googleapis.com/auth/tasks";
constant SCOPE_RO = "https://www.googleapis.com/auth/tasks.readonly";

void create(.Authorization auth)
{
  ::create(auth);
}

mixed get_lists(void|string user)
{
  string uri = API_URI + "/users/" + (user||"@me") + "/lists";
  return ::get(uri);
}
