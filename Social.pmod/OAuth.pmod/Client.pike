/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{OAuth client class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of OAuth.pmod
//!
//! OAuth.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! OAuth.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with OAuth.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "oauth.h"

import ".";

#define assert_cache() if (!cache) return UNDEFINED

//! The consumer obejct
protected Consumer consumer;

//! The token object
protected Token token;

//! The endpoint to send request for a request token
protected string request_token_url;

//! The endpoint to send request for an access token
protected string access_token_url;

//! The enpoint to redirect to when authorize an application
protected string user_auth_url;

//! Data cache object
protected DataCache cache;

//! Create a new @[Client].
//!
//! @note
//!  This class must be inherited
protected void create(Consumer _consumer, Token _token)
{
  consumer = _consumer;
  token    = _token;
}

//! Returns the @[consumer]
Consumer get_consumer()
{
  return consumer;
}

//! Returns the @[token]
Token get_token()
{
  return token;
}

//! Set the Token
//!
//! @decl set_token(Token token)
//! @decl set_token(string token_key, string token_secret)
//!
//! @param key
//!  Either a @[Token()] object or a token key
//! @param secret
//!  The token secret if @[key] is a token key
void set_token(Token|string key, void|string secret)
{
  if (stringp(key)) {
    if (!secret)
      ARG_ERROR("secret", "Secret must be provided when \"key\" is a string\n");

    token = Token(key, secret);
  }
  else token = key;
}

//! Returns the url for requesting a request token
string get_request_token_url()
{
  return request_token_url;
}

//! Returns the url for requesting an access token
string get_access_token_url()
{
  return access_token_url;
}

//! Returns the url for authorizing an application
string get_user_auth_url()
{
  return user_auth_url;
}

//! Generates a cache key
string get_cache_key(string key)
{
  return MD5(consumer->secret + key);
}

//! Tries to find the entry @[key] in the cache
mixed get_cache(string key)
{
  assert_cache();
  return cache->get(get_cache_key(key));
}

//! Add to cache
//!
//! @param key
//! @param value
//! @param maxlife
void set_cache(string key, string value, void|int maxlife)
{
  assert_cache();
  cache->set(get_cache_key(key), value, maxlife);
}

//! Delete the entry with key @[key] from the cache
void delete_cache(string key)
{
  assert_cache();
  cache->delete(get_cache_key(key));
}

//! Returns the cache object
DataCache get_cache_obj()
{
  assert_cache();
  return cache;
}

//! Abstract class for cache handling
class DataCache
{
  protected mixed /* Cache.cache */ cache;
  protected void create() {}
  mixed get(string key);
  void  set(string key, mixed value, void|int maxlife);
  void  delete(string key);
}
