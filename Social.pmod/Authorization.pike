/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

inherit Security.OAuth2;

void create(string client_id, string client_secret, string redirect_uri,
            string|void scope)
{
  ::create(client_id, client_secret, redirect_uri, scope);
}