/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

inherit Social.Authorization;

constant OAUTH_AUTH_URI  = "https://api.instagram.com/oauth/authorize";
constant OAUTH_TOKEN_URI = "https://api.instagram.com/oauth/access_token";

void create(string client_id, string client_secret, string redirect_uri,
            string|void scope)
{
  ::create(client_id, client_secret, redirect_uri, scope);
}

string get_auth_uri(void|mapping args)
{
  return ::get_auth_uri(OAUTH_AUTH_URI, args);
}

string request_access_token(string code)
{
  return ::request_access_token(OAUTH_TOKEN_URI, code);
}
