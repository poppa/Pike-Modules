/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Facebook class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
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

  //! Logged in user
  protected string user;

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
  //! @throws An exception if format is other than XML or JSON
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

  //! Returns the currently logged on user
  string get_user()
  {
    return user;
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
  string auth_create_token()
  {
    return call("auth.createToken")->get_result();
  }

  //! Requests a session
  //!
  //! @param auth_token
  //!  Either from login callback or @[auth_create_token()]
  mixed auth_get_session(string auth_token, void|int(0..1) gen_sess_secret)
  {
    return call("auth.getSession",
                Params(Param("auth_token", auth_token),
                       Param("generate_session_secret", gen_sess_secret)))
           ->get_result();
  }

  //! Calls a Facebook method
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

class Response // {{{
{
  protected string xml;
  protected int(0..1) is_error = 0;
  protected mapping res = ([]);

  void create(string response)
  {
    xml = response;

    if (!sizeof(xml))
      error("Empty response\n");

    TRACE("Parse response data:\n%s\n", xml);

    parse();
  }

  mixed get_result()
  {
    return res->response;
  }

  protected void parse()
  {
    Node root = parse_input(xml);
    root = root && root[1];

    if (!root)
      error("Unable to find root node of response\n");

    string name = root->get_tag_name();

    if (search(name, "error") > -1) {
      string code, msg;

      root->iterate_children(
	lambda(Node n) {
	  if (n->get_node_type() != XML_ELEMENT)
	    return;

	  if (n->get_tag_name() == "error_code")
	    code = n->value_of_node();
	  else if (n->get_tag_name() == "error_msg")
	    msg = n->value_of_node();
	}
      );

      error("%s (%s)\n", msg, code);
    }

    extract(root, res);
    res = ([ "response" : res[indices(res)[0]] ]);
  }

  protected mapping extract(Node n, mapping p)
  {
    string name = n->get_tag_name();
    p[name] = ([]);

    if (!n->get_first_element()) {
      p[name] = n->value_of_node();
      return p;
    }

    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() != XML_ELEMENT)
	continue;

      if (cn->get_first_element()) {
	if (cn->count_children() > 1) {
	  if (!arrayp( p[name] ))
	    p[name] = ({});

	  TRACE("Extract to array: %s\n", cn->get_tag_name());

	  p[name] += ({ extract(cn, ([])) });
	}
	else {
	  TRACE("Extract to mapping: %s\n", cn->get_tag_name());

	  if (sizeof( p[name] )) {
	    if (!arrayp( p[name] ))
	      p[name] = ({ p[name] });

	    p[name] += ({ extract(cn, ([])) });
	  }
	  else
	    p[name] += extract(cn, ([]));
	}
      }
      else {
	string cname = cn->get_tag_name();
	if ( p[name][cname] ) {
	  if (!arrayp( p[name][cname] ))
	    p[name][cname] = ({ p[name][cname] });

	  p[name][cname] += ({ cn->value_of_node() });
	}
	else
	  p[name][cname] = cn->value_of_node();
      }
    }

    return p;
  }
} // }}}

//! Parameter collection class
class Params
{
  //! The parameters.
  protected array(Param) params;

  //! Creates a new instance of @[Params]
  //!
  //! @param args
  void create(Param ... args)
  {
    params = args||({});
  }

  //! Sign the parameters
  //!
  //! @param secret
  //!  The API secret
  string sign(string secret)
  {
    TRACE("@@@ Sign: %s\n", sort(params)->name_value()*"\n"+"\n"+secret);
    return md5(sort(params)->name_value()*"" + secret);
  }

  //! Parameter keys
  array _indices()
  {
    return params->get_name();
  }

  //! Parameter values
  array _values()
  {
    return params->get_value();
  }

  //! Returns the array of @[Param]eters
  array(Param) get_params()
  {
    return params;
  }

  //! Turns the parameters into a query string
  string to_query()
  {
    array o = ({});
    foreach (params, Param p)
      o += ({ p->get_name()+"="+Protocols.HTTP.uri_encode(p->get_value()) });

    return o*"&";
  }

  //! Turns the parameters into a mapping
  mapping to_mapping()
  {
    return mkmapping(params->get_name(), params->get_value());
  }

  //! Add @[p] to the array of @[Param]eters
  //!
  //! @param p
  Params `+(Param|Params p)
  {
    Params pp = Params(@params);
    pp += p;

    return pp;
  }

  Params `+=(Param|Params p)
  {
    if (object_program(p) == object_program(this))
      params += p->get_params();
    else
      params += ({ p });
  }

  //! String format method
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O)", object_program(this), params);
  }
}

//! Representation of a parameter
class Param
{
  //! The name of the parameter
  protected string name;

  //! The value of the parameter
  protected string value;

  //! Creates a new instance of @[Param]
  //!
  //! @param _name
  //! @param _value
  void create(string _name, mixed _value)
  {
    name = _name;
    value = (string)_value;
  }

  //! Getter for the parameter name
  string get_name()
  {
    return name;
  }

  //! Setter for the parameter name
  //!
  //! @param _name
  void set_name(string _name)
  {
    name = _name;
  }

  //! Getter for the parameter value
  string get_value()
  {
    return value;
  }

  //! Setter for the parameter value
  //!
  //! @param _value
  void set_value(mixed _value)
  {
    value = (string)_value;
  }

  //! Returns the name and value as querystring key/value pair
  string name_value()
  {
    return name + "=" + value;
  }

  //! Comparer method. Checks if @[other] equals this object
  //!
  //! @param other
  int(0..1) `==(mixed other)
  {
    if (object_program(other) != Param) return 0;
    if (name == other->get_name())
      return value == other->get_value();

    return 0;
  }

  //! Checks if this object is greater than @[other]
  //!
  //! @param other
  int(0..1) `>(mixed other)
  {
    if (object_program(other) != Param) return 0;
    if (name == other->get_name())
      return value > other->get_value();

    return name > other->get_name();
  }

  //! String format method
  //!
  //! @param t
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("%O(%O,%O)", object_program(this), name, value);
  }
}