/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Last.fm module@}
//!
//! This wrapper class around the @url{http://last.fm@} API.
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

//! JSON decode method if JSON is choosen as response format.
//!
//! @xml{<code detab="3">
//!   // If using the JSON object bundled with this framework
//!   Social.Lastfm.set_json_decode(Standards.JSON.decode);
//! </code>@}
function json_decode = lambda(string data) {
  error("JSON decode method not set. Set \"Social.Lastfm.json_decode\" "
        "prior to any method calls");
};

//! Set what function to use for JSON decoding
//!
//! @param func
void set_json_decode(function func)
{
  json_decode = func;
}

//! User agent string
constant USER_AGENT = "Pike Last.fm Client (Pike " + __VERSION__ + ")";

//! Last.fm API endpoint
constant REST_URL = "http://ws.audioscrobbler.com/2.0/";

//! Authentication URL
constant AUTH_URL = "http://www.last.fm/api/auth";

//! Get responses in JSON format
//!
//! @note
//!  Only matters internally, of no interest of API end user
constant FORMAT_JSON = "json";

//! Get responses in XML format
//!
//! @note
//!  Only matters internally, of no interest of API end user
constant FORMAT_XML  = "xml";

//! Last.fm API class
class Api
{
  //! API key
  string key;

  //! API secret
  string secret;

  //! Current session key
  protected string  session;
  
  //! Logged in user.
  protected mapping user;
  
  //! Response format
  protected string  format = FORMAT_XML;

  //! Creates a new instance of @[Social.Lastfm]
  void create(string _key, string _secret)
  {
    key     = _key;
    secret  = _secret;
  }

  //! Set the response format. 
  //!
  //! @note 
  //!  Of no real interest. The return value from the methods are the same
  //!  regardless.
  //!
  //! @throws
  //!  An error if @[value] is unrecognized.
  //!
  //! @param value
  //!  @[FORMAT_JSON] or @[FORMAT_XML]
  void set_format(string value)
  {
    if ( !(< FORMAT_JSON, FORMAT_XML >)[lower_case(value)] )
      error("Bad format (%s). Expected %s\n", value, 
            String.implode_nicely(({ FORMAT_JSON, FORMAT_XML }), "or"));

    format = lower_case(value);
  }

  //! Returns the response format being used.
  string get_format()
  {
    return format;
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
  mapping get_token()
  {
    return call("auth.getToken");
  }

  //! Returns the session key or tries to fetch a new one if none is set
  //!
  //! @param token
  //!  A token key received from @[get_token()]
  string get_session(string token)
  {
    if (session)
      return session;

    mixed d = call("auth.getSession", Params(Param("token", token)));

    if (d && mappingp(d) && d->session) {
      session = d->session->key;
      return session;
    }

    error("Failed to get session!\n"); 
  }

  //! Fetches information about the currently logged on user
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

  //! Sends a request to a Last.fm method.
  //!
  //! @param method
  //!  The Last.fm method to call. @url{http://www.lastfm.se/api/@}
  //! @param params
  //!  Method specific parameters. All default parameters will be added
  //!  automatically
  mixed call(string method, void|Params params, void|string http_method)
  {
    http_method = upper_case(http_method||"GET");
    Params p = get_default_params(method);

    if (params)
      p += params;

    p += Param("api_sig", p->sign(secret));

    if (format != FORMAT_XML)
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

    if (format != FORMAT_XML)
      return json_decode(q->data());
    else
      return Response(q->data())->get_result();
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

//! Parameter collection class
//!
//! @seealso Social.Params
class Params
{
  inherit Social.Params;
}

//! Parameter class
//!
//! @seealso Social.Param
class Param
{
  inherit Social.Param;

  //! Returns the param name and value concatenated for usage when signing 
  //! the parameters.
  string name_value()
  {
    return name + value;
  }
}

//! Class that parses a Last.fm XML response
class Response // {{{
{
  //! The raw XML
  protected string xml;
  
  //! The parsed response
  protected mapping res = ([]);

  //! Creates a new @[Response] object
  void create(string response)
  {
    xml = response;

    if (!sizeof(xml))
      error("Empty response\n");

    //werror("Parse response data:\n%s\n", xml);

    parse();
  }

  //! Returns the @[result] mapping
  mixed get_result()
  {
    return res->response;
  }
  
  //! Parses the XML response
  protected void parse()
  {
    Node root = parse_input(xml);
    root = root && root[1];

    if (!root)
      error("Unable to find root node of response\n");

    if (root->get_attributes()["status"] == "failed") {
      root = root->get_children()[0];
      error("%s (%s)\n", root->value_of_node(),
                         root->get_attributes()["code"] );
    }

    extract(root, res);
    res = ([ "response" : res[indices(res)[0]] ]);
  }

  //! Low parsing method
  //!
  //! @param n
  //! @param p
  protected mapping extract(Node n, mapping p)
  {
    string name = n->get_tag_name();
    p[name] = ([]);

    if (!n->get_first_element()) {
      p[name] = n->value_of_node();
      return p;
    }
    
    array(Node) children = map(n->get_children(), 
      lambda (Node ln) {
	if (ln->get_node_type() == XML_ELEMENT)
	  return ln;
      }
    ) - ({ 0 });
    
    int cn_count = sizeof(children);
    
    foreach (children, Node cn) {
      if (cn->get_first_element()) {
	if (cn_count > 1 && cn->count_children() > 1) {
	  if (!arrayp( p[name] ))
	    p[name] = ({});

	  werror("Extract to array: %s\n", cn->get_tag_name());

	  p[name] += ({ extract(cn, ([])) });
	}
	else {
	  werror("Extract to mapping: %s\n", cn->get_tag_name());

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