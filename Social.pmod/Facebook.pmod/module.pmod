/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Facebook class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Facebook.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Facebook.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Facebook.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}
#define FB_DEBUG

#include "facebook.h"
import Parser.XML.Tree;

//! Facebook API version to use
constant VERSION = "1.0";

//! Use request/response in XML format
constant FORMAT_XML = "xml";

//! Use request/response in JSON format
constant FORMAT_JSON = "json";

//! User aget of the Pike Facebook client
constant USER_AGENT = "Pike Facebook Client 0.1 (Pike " + __VERSION__ + ")";

//! The URL to the Facebook REST server
constant REST_URL = "http://api.new.facebook.com/restserver.php";

//! Fields to fetch in @[Api()->get_user_info()] if no fields are given.
constant DEFAULT_USER_INFO_FIELDS = ({
  "about_me",
  "birthday",
  "birthday_date",
  "current_location",
  "email_hashes",
  "first_name",
  "is_app_user",
  "hometown_location",
  "interests",
  "is_blocked",
  "last_name",
  "locale",
  "name",
  "pic",
  "pic_small",
  "pic_square",
  "profile_blurb",
  "profile_url",
  "status",
  "timezone",
  "username",
  "website"
});

//! MD5 routine
//!
//! @param s
string md5(string s)
{
#if constant(Crypto.MD5)
  return String.string2hex(Crypto.MD5.hash(s));
#else
  return Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif
}

//! Returns the full URL to Facebook
//!
//! @param subdomain
string get_facebook_url(void|string subdomain)
{
  return "http://" + (subdomain||"www") + ".facebook.com";
}

//! Facebook API class
class Api
{
  //! The API key
  string key;

  //! The API secret
  string secret;

  //! Whether or not to generate a session secret
  int(0..1) generate_session_secret;

  //! Format to use in requests/responses
  protected string format = FORMAT_XML;

  //! Sesssion key. Most likely received from @[auth_get_session()]
  protected string session_key;

  //! Session secret. Most likely received from @[auth_get_session()]
  protected string session_secret;

  //! User ID. Most likely received from @[auth_get_session()]
  protected string uid;

  //! Session expire time. Most likely received from @[auth_get_session()]
  protected int expires;

  //! Canvas mode or not
  protected int(0..1) in_canvas = 0;

  //! Create a new Facebook Api instance
  //!
  //! @param _key
  //! @param _secret
  //! @param gen_sess
  void create(string _key, string _secret, void|int(0..1) gen_sess)
  {
    key = _key;
    secret = _secret;
    generate_session_secret = gen_sess;
  }

  //! Setter for the session key
  //!
  //! @param value
  void set_session_key(string value)
  {
    session_key = value;
  }

  //! Getter for the session key
  string get_session_key()
  {
    return session_key;
  }

  //! Setter for the session secret
  //!
  //! @param value
  void set_session_secret(string value)
  {
    session_secret = value;
  }

  //! Getter for the session secret
  string get_session_secret()
  {
    return session_secret;
  }

  //! Setter for the uid
  //!
  //! @param value
  void set_uid(string value)
  {
    uid = value;
  }

  //! Getter for the uid
  string get_uid()
  {
    return uid;
  }

  //! Setter for the expires member
  //!
  //! @param value
  void set_expires(int|string value)
  {
    expires = (int)value;
  }

  //! Getter for the expires member
  int get_expires()
  {
    return expires;
  }

  //! Sets members from the result of @[auth_get_session()]. This is the same
  //! as calling @[set_session_key()], @[set_session_secret()],
  //! @[set_uid()] and @[set_expires()] respectively.
  //!
  //! @param value
  void set_session_values(mapping value)
  {
    session_key    = value->session_key;
    session_secret = value->secret;
    uid            = value->uid;
    expires        = (int)value->expires;
  }

  //! Set the request/response format
  //!
  //! @param _format
  //!
  //! @throws 
  //!  An exception if format is other than XML or JSON
  void set_format(string _format)
  {
    if ( !(< FORMAT_XML, FORMAT_JSON >)[_format] )
      error("Unknown format \"%s\". Must be one of %s", _format,
            String.implode_nicely(({ FORMAT_XML, FORMAT_JSON }), "or"));

    format = _format;
  }

  //! Returns the format being used in requests/responses
  string get_format()
  {
    return format;
  }

  //! Returns the URL for loggin on to Facebook
  //!
  //! @param next
  //!  The URL the loginpage at FB should redirect back to
  //! @param canvas
  string get_login_url(void|string next, void|int|string canvas)
  {
    string u = get_facebook_url() + "/login.php";
    Params p = Params(Param("api_key", key), Param("v", VERSION));

    if (next)
      p += Param("next", next);

    if (canvas) {
      in_canvas = 1;
      p += Param("canvas", canvas);
    }

    return u + "?" + p->to_query();
  }

  //! Request an auth token
  Response auth_create_token()
  {
    return call("auth.createToken");
  }

  //! Requests a session
  //!
  //! @param auth_token
  //!  Either from login callback or @[auth_create_token()]
  Response auth_get_session(string auth_token, void|int(0..1) gen_sess_secret)
  {
    return call("auth.getSession", Params(
                Param("auth_token", auth_token),
                Param("generate_session_secret", gen_sess_secret)));
  }

  //! Invalidates the current session being used, regardless of whether it is 
  //! temporary or infinite. After successfully calling this function, no 
  //! further API calls requiring a session will succeed using this session. 
  //! If the invalidation is successful, this will return true.
  //! 
  //! @seealso 
  //!  http://wiki.developers.facebook.com/index.php/Auth.expireSession
  Response expire_session()
  {
    string sk = session_key;
    session_key = 0;
    return call("auth.expireSession", Params(Param("session_key", sk)));
  }

  //! If this method is called for the logged in user, then no further API calls 
  //! can be made on that user's behalf until the user decides to authorize the 
  //! application again.
  //!
  //! @seealso 
  //!  http://wiki.developers.facebook.com/index.php/Auth.revokeAuthorization
  Response revoke_authorization()
  {
    return call("auth.revokeAuthorization");
  }

  //! Returns a wide array of user-specific information for each user 
  //! identifier passed, limited by the view of the current user.
  //!
  //! @seealso 
  //!  http://wiki.developers.facebook.com/index.php/Users.getInfo
  //!
  //! @throws
  //!  An error if no session is available and no @[uids] is give
  //!
  //! @param uids 
  //!  List of user IDs. If a @tt{string@} it should be a comma separated
  //!  list of user IDs.
  //! @param fields
  //!  List of desired fields in return. If a @tt{string@} it should be a 
  //!  comma separated list of fields.
  Response get_user_info(void|string|array uids, void|string|array fields)
  {
    // ASSERT_SESSION("get_user_info()");

    if (!uids && uid)
      uids = ({ uid });
    else if (stringp(uids))
      uids = [array](uids/",");

    if (!uids || !sizeof(uids))
      error("No UIDs given and no authentication available.");

    if (!fields)
      fields = DEFAULT_USER_INFO_FIELDS;
    else if (stringp(fields))
      fields = [array](fields/",");

    return call("users.getInfo", Params(Param("uids", uids*","), 
                                        Param("fields", fields*",")));
  }

  //! Calls a Facebook method
  //!
  //! @throws
  //!  An error if the response status code isn't @tt{200@}
  //!
  //! @param method
  //! @param params
  Response call(string method, void|Params params, void|string http_method)
  {
    http_method = upper_case(http_method||"POST");

    [Params get, Params post] = get_default_params(method);

    if (params)
      post += params;

    post += Param("sig", (get+post)->sign(secret));

    TRACE("\n### GET: %s\n### POST: %s\n", get->to_query(), post->to_query());

    mapping eheads = ([
      "User-Agent"   : USER_AGENT,
      "Content-Type" : "application/x-www-form-urlencoded"
    ]);

    string url = REST_URL + "?" + get->to_query();

    Protocols.HTTP.Query q = Protocols.HTTP.do_method(http_method,
                                                      url,
                                                      0,
                                                      eheads,
                                                      0,
                                                      post->to_query());
    if (q->status != 200)
      error("Bad status code (%d) in HTTP response!\n", q->status);

    return Response(q->data());
  }

  //! Returns the default params
  protected array(Params) get_default_params(string method)
  {
    Params get_params = Params(
      Param("api_key", key),
      Param("v", VERSION),
      Param("format", format),
      Param("method", method)
    );

    Params post_params = Params(Param("call_id", gethrtime()));

    return ({ get_params, post_params });
  }
}

//! The @[Response] class turns an XML response from a Facebook API call into
//! an object. Each XML node will be an instance of @[Response]. A psuedo 
//! example could be:
//!
//! @xml{<codify lang="xml" detab="3">
//!   <users_getInfo_response>
//!     <user>
//!       <name>John Doe</name>
//!       <status>
//!         <message>The last status message</message>
//!         <time>1261168463</time>
//!         <status_id>210488073921</status_id>
//!       </status>
//!     </user>
//!   </users_getInfo_response>
//! </codify>@}
//!
//! @xml{<codify lang="pike" detab="3">
//!   array fields = ({ "name", "status" });
//!   // Fetch the current users info
//!   Response res = facebook->get_user_info(0, fields);
//!
//!   string name = res->user->name->get_value();
//!   string message = res->user->status->message->get_value();
//!
//!   // Or cast
//!   write("Hello %s\n", (string)res->user->name);
//!
//!   // Print all status nodes
//!   foreach ((array)res->user->status, Response child)
//!     write("%s: %s\n", child->get_name(), (string)child);
//! </codify>@}
class Response
{
  inherit Misc.SimpleXML;

  //! Creates a new insance of @[SimpleXML]
  //!
  //! @throws 
  //!  An error if @[xml] is a string and XML parsing fails
  //!
  //! @param xml
  void create(string|Parser.XML.Tree.Node xml)
  {
    ::create(xml);
  }
}

//! Parameter collection class
class Params
{
  inherit Social.Params;
  
  //! Creates a new instance of @[Params]
  //!
  //! @param args
  void create(Param ... args)
  {
    ::create(@args);
  }
}

//! Representation of a parameter
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
}
