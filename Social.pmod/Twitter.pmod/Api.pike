/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! The main Twitter object from which all Twitter actions take place.
//|
//| Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//|
//| License GNU GPL version 3
//|
//| Api.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Api.pike.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with [PROG-NAME].pike. If not, see <http://www.gnu.org/licenses/>.

#define TWITTER_DEBUG
#include "twitter.h"

import ".";
import Security.OAuth;
import Parser.XML.Tree;

//! The consumer object used for OAuth authentication
private Consumer consumer;

//! The token object used for OAuth authentication
private Token token;

//! Is the current instance authenticated or not
protected int(0..1) is_authenticated = 0;

//! Creates a new @[Api] object
//!
//! @param _consumer
//! @param _token
void create(void|Consumer _consumer, void|Token _token)
{
  consumer = _consumer;
  token = _token;
}

//! Set the token object
//!
//! @param _token
//!  Either a valid @[Token] object, or a token key. If a key @[secret] is
//!  required.
//! @param secret
void set_token(Token|string _token, void|string secret)
{
  if (objectp(_token))
    token = _token;
  else
    token = Token(_token, secret);
}

//! Returns the @[Token] object of this instance.
Token get_token()
{
  return token;
}

//! Set if the user is authenticated or not. This gets set in
//! @[verify_credentials()] but for web apps to call that method for every
//! page access will slow it down considerably so if you know the user is
//! authenticated you can verify that by calling this method with
//! @[ok] set to @tt{1@}.
//!
//! @param ok
void set_is_authenticated(int(0..1) ok)
{
  is_authenticated = ok;
}

//! Fetches a request token
//!
//! @param callback_uri
//!  Overrides the callback uri in the application settings
//! @param force_login
//!  If @tt{1@} forces the user to provide its credentials at the Twitter
//!  login page.
Token get_request_token(void|string|Standards.URI callback_uri,
                        void|int(0..1) force_login)
{
  mapping p = ([]);
  if (callback_uri)
    p->oauth_callback = (string)callback_uri;

  if (force_login)
    p->force_login = "true";

  string ctoken = call(request_token_url, p, "POST");
  mapping res = ctoken && (mapping)query_to_params(ctoken);
  token = Token( res[TOKEN_KEY], res[TOKEN_SECRET_KEY] );
  return token;
}

//! Fetches an access token
//!
//! @param oauth_verifier
Token get_access_token(void|string oauth_verifier)
{
  if (!token)
    error("Can't fetch access token when no request token is set!\n");

  Params pm;
  if (oauth_verifier)
    pm = Params(Param("oauth_verifier", oauth_verifier));

  string ctoken = call(access_token_url, pm, "POST");
  mapping p = (mapping)query_to_params(ctoken);
  token = Token( p[TOKEN_KEY], p[TOKEN_SECRET_KEY] );
  return token;
}

//! Returns the authorization URL.
final string get_auth_url(void|string|Standards.URI callback_uri,
                          void|int(0..1) force_login)
{
  get_request_token(callback_uri, force_login);
  return sprintf("%s?%s=%s", user_auth_url, TOKEN_KEY,
		 (token&&token->key)||"");
}

//! Use this method to test if supplied user credentials are valid.
//!
//! @returns
//!  Returns @tt{0@} if verification fails
User verify_credentials()
{
  mixed e = catch {
    string resp = call(TURL("account/verify_credentials"));
    User u = parse_user_xml(resp);
    is_authenticated = u && !!u->id;
    return u;
  };

  return 0;
}

//! Updates the authenticating user's status. Requires the status parameter
//! specified below. A status update with text identical to the
//! authenticating user's current status will be ignored to prevent
//! duplicates.
//!
//! @param status
//! @param params
//!  If replying add @tt{in_reply_to_status_id@} to the @[params] mapping
Message update_status(string status, void|mapping params)
{
  ASSERT_AUTHED("update_status()");
  if (!params) params = ([]);
  params->status = status;
  string resp = call(status_update_url, params, "POST");
  return parse_message_xml(resp);
}

//! Retweets a tweet. Returns the original tweet with retweet details
//! embedded.
//!
//! @param status_id
//!  The ID of the message being retweeted
Message retweet(string|int status_id)
{
  ASSERT_AUTHED("retweet()");
  string url = sprintf(retweet_status_url, (string)status_id);
  string resp = call(url, 0, "POST");
  return parse_message_xml(resp);
}

//! Returns the 20 most recent statuses from non-protected users who have set
//! a custom user icon.
//!
//! @seealso
//!  @url{http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-@
//!public_timeline@}
array(Message) get_public_timeline()
{
  return parse_status_xml(call(public_timeline_url, 0));
}

//! Returns the 20 most recent statuses, including retweets, posted by the
//! authenticating user and that user's friends. This is the equivalent of
//! @tt{/timeline/home@} on the Web.
//!
//! Usage note: This home_timeline is identical to statuses/friends_timeline
//! except it also contains retweets, which statuses/friends_timeline does
//! not (for backwards compatibility reasons). In a future version of the
//! API, statuses/friends_timeline will go away and be replaced by
//! home_timeline.
//!
//! @seealso
//!  @url{http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-@
//!home_timeline@}
//!
//! @param params
//!  @mapping
//!   @member string|int "since_id"
//!    Optional. Returns only statuses with an ID greater than (that is,
//!    more recent than) the specified ID.
//!   @member string|int "max_id"
//!    Optional. Returns only statuses with an ID less than (that is, older
//!    than) or equal to the specified ID.
//!   @member string|int "count"
//!    Optional. Specifies the number of statuses to retrieve. May not be
//!    greater than @tt{200@}.
//!   @member string|int "page"
//!    Optional. Specifies the page of results to retrieve. Note: there are
//!    pagination limits.
//!  @endmapping
array(Message) get_home_timeline(void|mapping params)
{
  ASSERT_AUTHED("get_home_timeline()");
  string resp = call(home_timeline_url, params);
  if (!resp) error("Fix this error!\n");
  return sizeof(resp) && parse_status_xml(resp) || ({});
}

//! Returns the 20 most recent mentions (status containing (at)username) for
//! the authenticating user
//!
//! @param params
//!  @mapping
//!   @member string|int "since_id"
//!    Optional. Returns only statuses with an ID greater than (that is,
//!    more recent than) the specified ID.
//!   @member string|int "max_id"
//!    Optional. Returns only statuses with an ID less than (that is, older
//!    than) or equal to the specified ID.
//!   @member string|int "count"
//!    Optional. Specifies the number of statuses to retrieve. May not be
//!    greater than @tt{200@}.
//!   @member string|int "page"
//!    Optional. Specifies the page of results to retrieve. Note: there are
//!    pagination limits.
//!  @endmapping
array(Message) get_mentions(void|mapping params)
{
  string resp = call(mentions_url, params);
  return parse_status_xml(resp);
}

//! Returns the 20 most recent retweets posted by the authenticating user.
//!
//! @param params
//!  @mapping
//!   @member string|int "since_id"
//!    Optional. Returns only statuses with an ID greater than (that is,
//!    more recent than) the specified ID.
//!   @member string|int "max_id"
//!    Optional. Returns only statuses with an ID less than (that is, older
//!    than) or equal to the specified ID.
//!   @member string|int "count"
//!    Optional. Specifies the number of statuses to retrieve. May not be
//!    greater than @tt{200@}.
//!   @member string|int "page"
//!    Optional. Specifies the page of results to retrieve. Note: there are
//!    pagination limits.
//!  @endmapping
array(Message) get_retweeted_by_me(void|mapping params)
{
  string resp = call(retweeted_by_me_url, params);
  return parse_status_xml(resp);
}

//! Returns a list of the 20 most recent direct messages sent to the
//! authenticating user. The XML and JSON versions include detailed
//! information about the sending and recipient users.
//!
//! @param params
//!  @mapping
//!   @member string|int "since_id"
//!    Optional. Returns only statuses with an ID greater than (that is,
//!    more recent than) the specified ID.
//!   @member string|int "max_id"
//!    Optional. Returns only statuses with an ID less than (that is, older
//!    than) or equal to the specified ID.
//!   @member string|int "count"
//!    Optional. Specifies the number of statuses to retrieve. May not be
//!    greater than @tt{200@}.
//!   @member string|int "page"
//!    Optional. Specifies the page of results to retrieve. Note: there are
//!    pagination limits.
//!  @endmapping
array(DirectMessage) get_direct_messages(void|mapping params)
{
  ASSERT_AUTHED("get_direct_messages()");
  string resp = call(TURL("direct_messages"), params);
  return parse_direct_messages_xml(resp);
}

//! Does the low level HTTP call to Twitter.
//!
//! @throws
//!  An error if HTTP status != 200
//!
//! @param url
//!  The full address to the Twitter service e.g:
//!  @tt{http://twitter.com/direct_messages.xml@}
//! @param args
//!  Arguments to send with the request
//! @param mehod
//!  The HTTP method to use
string call(string|Standards.URI url, void|mapping|Params args,
            void|string method)
{
  method = normalize_method(method);

  if (mappingp(args)) {
    mapping m = copy_value(args);
    args = Params();
    args->add_mapping(m);
  }

  Request r = request(url, consumer, token, args, method);
  r->sign_request(Signature.HMAC_SHA1, consumer, token);

  Protocols.HTTP.Query q = r->submit();

  if (q->status != 200) {
    if (mapping e = parse_error_xml(q->data())) 
      error("Error in %O: %s\n", e->request, e->error);
    else
      error("Bad status, %d, from HTTP query!\n", q->status);
  }

  return q->data();
}

//! Normalizes and verifies the HTTP method to be used in a HTTP call
//!
//! @param method
protected string normalize_method(string method)
{
  method = upper_case(method||"GET");
  if ( !(< "GET", "POST", "DELETE", "PUT" >)[method] )
    error("HTTP method must be GET, POST, PUT or DELETE! ");

  return method;
}

//! Parses an error xml tree
//!
//! @param xml
//!
//! @returns
//!  A mapping:
//!  @mapping
//!   @member string "request"
//!   @member string "error"
//!  @endmapping
mapping parse_error_xml(string xml)
{
  mapping m;
  if (Node n = get_xml_root(xml)) {
    m = ([]);
    foreach (n->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT)
      	m[cn->get_tag_name()] = cn->value_of_node();
    }
  }

  return m;
}

//! Parses an XML response from the Twitter API method returning
//! @tt{statuses@} as the root node
//!
//! @param xml
//!  The raw response from @[call()].
array(Message) parse_status_xml(string xml)
{
  array(Message) list = ({});
  if (Node root = get_xml_root(xml)) {
    if (root->get_tag_name() != "statuses")
      error("Name of root node in XML is not \"statuses\"! ");

    foreach (root->get_children(), Node status)
      if (status->get_tag_name() == "status")
	list += ({ Message(status) });
  }

  return list;
}

//! Parses an XML response from the Twitter API method returning
//! @tt{direct-messages@} as the root node
//!
//! @param xml
//!  The raw response from @[call()].
array(DirectMessage) parse_direct_messages_xml(string xml)
{
  array(DirectMessage) list = ({});
  if (Node root = get_xml_root(xml)) {
    if (root->get_tag_name() != "direct-messages")
      error("Name of root node in XML is not \"direct-messages\"! ");

    foreach (root->get_children(), Node node)
      if (node->get_tag_name() == "direct_message")
	list += ({ DirectMessage(node) });
  }

  return list;
}

//! Parses an XML response from the Twitter API method returning
//! @tt{status@} as the root node, wich is the same as a message
//!
//! @param xml
//!  The raw response from @[call()].
Message parse_message_xml(string xml)
{
  Message m;
  if (Node root = get_xml_root(xml)) {
    if (root->get_tag_name() != "status")
      error("Name of root node in XML is not \"status\"! ");

    m = Message(root);
  }

  return m;
}

//! Parses an XML response from the Twitter API method returning
//! @tt{user@} as the root node
//!
//! @param xml
//!  The raw response from @[call()].
User parse_user_xml(string xml)
{
  User user;
  if (Node root = get_xml_root(xml)) {
    if (root->get_tag_name() != "user")
      error("Name of root node in XML is not \"user\"! ");

    user = User(root);
  }

  return user;
}

//! Returns the first @tt{XML_ELEMENT@} node in an XML tree.
//!
//! @param xml
//!  Either an XML tree as a string or a node object.
private Node get_xml_root(string|Node xml)
{
  catch {
    if (stringp(xml))
      xml = parse_input(xml);

    foreach (xml->get_children(), Node n) {
      if (n->get_node_type() == XML_ELEMENT) {
	xml = n;
	break;
      }
    }

    return objectp(xml) && xml;
  };
}
