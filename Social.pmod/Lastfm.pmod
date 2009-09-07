/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Bitly class@}
//!
//! This class communicates with @url{http://bit.ly@} which is a service to
//! shorten, track and share links.
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Lastfm.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Lastfm.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Lastfm.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

constant USER_AGENT = "Pike Last.fm Client (Pike " + __VERSION__ + ")";
constant REST_URL = "http://ws.audioscrobbler.com/2.0/";
constant AUTH_URL = "http://www.last.fm/api/auth";

constant FORMAT_JSON = "json";
constant FORMAT_XML  = "xml";

function json_decode = Standards.Json()->decode;

class Api
{
  string key;
  string secret;

  protected string  session;
  protected mapping user;
  protected string  format = "json";

  void create(string _key, string _secret)
  {
    key     = _key;
    secret  = _secret;
  }

  void set_format(string value)
  {
    if ( !(< FORMAT_JSON, FORMAT_XML >)[lower_case(value)] )
      error("Bad format (%s). Expected %s\n", value, 
            String.implode_nicely(({ FORMAT_JSON, FORMAT_XML }), "or"));

    format = value;
  }

  void set_session(string session_key)
  {
    session = session_key;
  }
  
  string get_format()
  {
    return format;
  }

  string get_login_url()
  {
    return AUTH_URL + "?api_key=" + key;
  }

  mapping get_token()
  {
    return call("auth.getToken");
  }

  string get_session(void|string token)
  {
    if (session)
      return session;

    mixed d = call("auth.getSession", Params(Param("token", token)));

    if (d && mappingp(d) && d->session) {
      session = d->session->key;
      return session;
    }

    return 0;
  }

  mapping get_user()
  {
    assure_session();
    if (user) return user;

    mixed d = call("user.getInfo");
    if (d && mappingp(d) && d->user) {
      user = d->user;
      return user;
    }

    return 0;
  }

  mixed call(string method, void|Params params, void|string http_method)
  {
    http_method = upper_case(http_method||"GET");
    Params p = get_default_params(method);
    
    if (params)
      p += params;

    p += Param("api_sig", p->sign(secret));
    p += Param("format", format);

    mapping heads = ([ 
      "User-Agent" : USER_AGENT,
      "Content-Type" : "application/x-www-form-urlencoded; charset=utf-8"
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.do_method(http_method,
                                                      REST_URL,
                                                      p->to_mapping(),
                                                      heads);
    if (q->status != 200)
      error("Bad status (%d) in HTTP call\n", q->status);

//    werror("Data: %O\n", q->data());
    
    return json_decode(q->data());
  }

  protected Params get_default_params(string method)
  {
    Params p = Social.Params(
      Param("api_key", key),
      Param("method", method),
    );

    if (session)
      p += Param("sk", session);

    return p;
  }

  protected void assure_session()
  {
    if (!session)
      error("Method requires a session key");
  }
}

class Params
{
  inherit Social.Params;
}

class Param
{
  inherit Social.Param;

  string name_value()
  {
    return name + value;
  }
}