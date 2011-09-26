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

constant API_URI = "https://www.googleapis.com/plus/v1";

inherit .Api;

void create(.Authorization auth)
{
  ::create(auth);
}

mixed get_people(string|int user_id)
{
  string uri = API_URI + "/people/" + user_id;
  return ::get(uri);
}

mixed list_activites(string|int user_id, void|string collection,
                     void|int max_results, void|string page_token)
{
  collection = collection || "public";
  string uri = API_URI + "/people/" + user_id + "/activities/" + collection;

  .Params p = .Params();

  if (max_results) p += .Param("maxResults", max_results);
  if (page_token)  p += .Param("pageToken", page_token);

  return ::get(uri, p);
}

mixed get_activity(string|int activity_id)
{
  string uri = API_URI + "/activites/" + activity_id;
  return ::get(uri);
}
