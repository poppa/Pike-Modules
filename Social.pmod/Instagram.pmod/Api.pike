/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

inherit Social.Api;

void create(.Authorization auth)
{
  ::create((object(Social.Authorization)) auth);
}

mixed get_user_feed(void|string uid, void|mapping|.Params p)
{
  string u = .get_uri("/users/" + (uid ? uid + "/media/recent" : "self/feed"));
  return ::get(u, p);
}