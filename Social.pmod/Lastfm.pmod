/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Last.fm module@}
//!
//! This is a wrapper class around the @url{http://last.fm@} API.
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

import Parser.XML.Tree;

//! User agent string
constant USER_AGENT = "Pike Last.fm Client (Pike " + __VERSION__ + ")";

//! Last.fm API endpoint
constant REST_URL = "http://ws.audioscrobbler.com/2.0/";

//! Authentication URL
constant AUTH_URL = "http://www.last.fm/api/auth";

//! Last.fm API class
class Api
{
  //! API key
  string key;

  //! API secret
  string secret;

  //! Current session key
  protected string session;
  
  //! Logged in user.
  protected mixed user;

  //! Creates a new instance of @[Social.Lastfm]
  void create(string _key, string _secret)
  {
    key    = _key;
    secret = _secret;
  }

  //! Set the session key.
  //!
  //! @note
  //!  A session key will last for ever so when one is received for a user the
  //!  first time that key can be reused.
  //!
  //! @param session_key
  void set_session(string session_key)
  {
    session = session_key;
  }
  
  //! Returns the login URL
  string get_login_url()
  {
    return AUTH_URL + "?api_key=" + key;
  }

  //! Fetches an authentication token.
  string get_token()
  {
    return call("auth.getToken")->token->get_value();
  }

  //! Returns the session key or tries to fetch a new one if none is set
  //!
  //! @param token
  //!  A token key received from @[get_token()]
  //! @param force_new
  //!  If a session exists but a new one is wanted set this to @tt{1@} to
  //!  force generation of a new session.
  string get_session(string token, void|int(0..1) force_new)
  {
    if (session && !force_new)
      return session;

    Response d = call("auth.getSession", Params(Param("token", token)));
    session = (string)d->session->key;
    return session;
  }

  //! Fetches information about the currently logged on user
  Response get_user()
  {
    assure_session();
    if (user) return user;
    user = call("user.getInfo")->user;

    return user;
  }

  //! Sends a request to a Last.fm method.
  //!
  //! @param method
  //!  The Last.fm method to call. @url{http://www.lastfm.se/api/@}
  //! @param params
  //!  Method specific parameters. All default parameters will be added
  //!  automatically
  //! @param http_method
  //!  Should be GET or POST. Default is GET.
  Response call(string method, void|Params params, void|string http_method)
  {
    http_method = upper_case(http_method||"GET");
    Params p = get_default_params(method);

    if (params) p += params;

    p += Param("api_sig", p->sign(secret));

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

    Response r = Response(q->data());

    if (r->get_attributes()["status"] == "failed") {
      string ec = r->error->get_attributes()["code"];
      string ev = r->error->get_value();
      error("Response error (%s): %s\n", ec, ev);
    }

    return r;
  }

  //! Sets up and returns the default parameters.
  //!
  //! @param method
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

//! Class that handles and parses XML responses from the @[Api]
//!
//! @seealso 
//!  @[Misc.SimpleXML]
class Response
{
  inherit Misc.SimpleXML;
  
  void create(string|Node xml)
  {
    ::create(xml);
  }
}

//! Parameter collection class
//!
//! @seealso 
//!  @[Social.Params]
class Params
{
  inherit Social.Params;

  //! Creates a new instance of @[Params]
  //!
  //! @param params
  void create(Param ... params)
  {
    ::create(@params);
  }
}

//! Parameter class
//!
//! @seealso 
//!  @[Social.Param]
class Param
{
  inherit Social.Param;
 
  //! Creates a new instance of @[Param]
  //!
  //! @param name
  //! @param value
  void create(string name, mixed value)
  {
    ::create(name, value);
  }

  //! Returns the param name and value concatenated for usage when signing 
  //! the parameters.
  string name_value()
  {
    return name + value;
  }
}

