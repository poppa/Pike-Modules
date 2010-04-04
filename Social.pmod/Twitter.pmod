/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Twitter module@}
//!
//! Copyright © 2009, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @fixme
//!  Implement an AsyncTwitter as well perhaps?
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Twitter.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Twitter.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Twitter.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

import Social.OAuth;
import Parser.XML.Tree;

#define TURL(X) "http://twitter.com/" X ".xml"
#define AURL(X) "http://api.twitter.com/1/" X ".xml"
#define ASSERT_AUTHED(X) \
  is_authenticated || error("The method \"" X "\" requires authentication!");

constant home_timeline_url    = AURL("statuses/home_timeline");
constant retweet_status_url   = AURL("statuses/retweet/%s");
constant status_update_url    = TURL("statuses/update");
constant destroy_status_url   = TURL("statuses/destroy/%s");
constant mentions_url         = TURL("statuses/mentions");
constant friends_timeline_url = TURL("statuses/friends_timeline");
constant user_url             = TURL("users/show/%s");
constant public_timeline_url  = TURL("statuses/public_timeline"); 
constant user_timeline_url    = TURL("statuses/user_timeline"); 
constant retweeted_by_me_url  = TURL("statuses/retweeted_by_me");
constant retweeted_to_me_url  = TURL("statuses/retweeted_to_me");
constant retweets_of_me_url   = TURL("statuses/retweets_of_me");
constant request_token_url    = "https://twitter.com/oauth/request_token";
constant access_token_url     = "https://twitter.com/oauth/access_token";
constant user_auth_url        = "http://twitter.com/oauth/authorize";


//! The main Twitter object from which all Twitter actions take place.
public class Api
{
  //! The consumer object used for OAuth authentication
  private Consumer consumer;

  //! The token object used for OAuth authentication
  private Token token;

  //! Is the current instance authenticated or not
  protected int(0..1) is_authenticated = 0;

  //! Creates a new Twitter.Api object
  //!
  //! @param _consumer
  //! @param _token
  public void create(void|Consumer _consumer, void|Token _token)
  {
    consumer = _consumer;
    token = _token;
  }

  //! Fetches a request token
  public Token get_request_token()
  {
    string ctoken = call(request_token_url);
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

    string ctoken = call(access_token_url, pm);
    mapping p = (mapping)query_to_params(ctoken);
    token = Token( p[TOKEN_KEY], p[TOKEN_SECRET_KEY] );
    return token;
  }

  //! Returns the authorization URL.
  public final string get_auth_url()
  {
    error("Not implemented yet!");
  }

  //! Use this method to test if supplied user credentials are valid.
  public User verify_credentials()
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
  public Message update_status(string status, void|mapping params)
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
  public Message retweet(string|int status_id)
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
  //!  @url{http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-public_timeline@}
  public array(Message) get_public_timeline()
  {
    string resp = call(public_timeline_url, 0);
    return parse_status_xml(resp);
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
  //!  @url{http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses-home_timeline@}
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
  public array(Message) get_home_timeline(void|mapping params)
  {
    ASSERT_AUTHED("get_home_timeline()");
    string resp = call(home_timeline_url, params);
    if (!resp) error("Fix this error!\n");
    //werror("Home timeline XML:\n%s\n\n--------\n\n", resp);
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
  public array(Message) get_mentions(void|mapping params)
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
  public array(Message) get_retweeted_by_me(void|mapping params)
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
  public array(DirectMessage) get_direct_messages(void|mapping params)
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
  public string call(string|Standards.URI url, void|mapping|Params args,
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

    if (q->status != 200)
      error("Bad status, %d, from HTTP query!\n", q->status);

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

  //! Parses an XML response from the Twitter API method returning 
  //! @tt{statuses@} as the root node
  //!
  //! @param xml
  //!  The raw response from @[call()].
  public array(Message) parse_status_xml(string xml)
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
  public array(DirectMessage) parse_direct_messages_xml(string xml)
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
  public Message parse_message_xml(string xml)
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
  public User parse_user_xml(string xml)
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
    if (stringp(xml))
      xml = parse_input(xml);

    catch {
      foreach (xml->get_children(), Node n) {
	if (n->get_node_type() == XML_ELEMENT) {
	  xml = n;
	  break;
	}
      }

      return objectp(xml) && xml;
    };
  }
}

//! The @tt{DesktopApi@} is identical to @[Api()] except this class uses
//! @tt{Basic@} authentication instead of @tt{OAuth@}. This makes this class
//! a better alternative for applications not running in a web browser.
public class DesktopApi
{
  inherit Api;

  //! The username to log on as
  private string username;
  
  //! The password for the user to log on as
  private string password;
  
  // The HTTP client object
  //private Protocols.HTTP.Query http;

  //! Creates a new instance of @[DesktopApi].
  //!
  //! @param _username
  //! @param _password
  void create(void|string _username, void|string _password)
  {
    username = _username;
    password = _password;
  }

  //! Does the low level HTTP call to Twitter.
  //!
  //! @param url
  //!  The full address to the Twitter service e.g:
  //!  @tt{http://twitter.com/direct_messages.xml@}
  //! @param args
  //!  Arguments to send with the request
  //! @param mehod
  //!  The HTTP method to use
  public string call(string|Standards.URI url, void|mapping|Params args,
                     void|string method)
  {
    method = ::normalize_method(method);

    if (mappingp(args)) {
      mapping m = copy_value(args);
      args = Params();
      args->add_mapping(m);
    }

    mapping(string:string) headers = ([]);

    headers["Connection"]   = "Keep-Alive";
    headers["Keep-Alive"]   = "300";
    headers["Content-Type"] = "application/x-www-form-urlencoded";

    if (username && password) {
      headers["Authorization"] = 
	"Basic " + MIME.encode_base64(username + ":" + password);
    }

    string body = args && args->get_query_string();

//    werror("\n>>> %s %s?%s\n", method, url, body||"");

    Protocols.HTTP.Query http = Protocols.HTTP.do_method(method, url, 0,
                                                         headers, 0, body);

    if (http->status != 200)
      error("Bad status (%d) in HTTP response!", http->status);

    Stdio.write_file(basename((string)url), http->data());
    
    return http->data();
  }
}

#define bool  int(0..1)
#define true  1
#define false 0
#define uri_encode(X) Protocols.HTTP.uri_encode((X))
#define NULL "\0"
#define NULLIFY(X) (X) && sizeof((X)) && (X) || 0

//! This class maps and XML tree onto an inheriting class. Object members that
//! have a corresponding XML node in the tree will get their values from the
//! XML node. To handle child nodes - or nodes that should be mapped any thing
//! other than simple data types like strings and ints - can be handled by 
//! creating a method of the same name as a node but prefixed with 
//! @tt{handle_@}. So @tt{handle_created_at(Node n)@} will be called when an
//! XML node named @tt{created_at@} is being found in the XML tree
private inline class XmlMapper
{
  //! Creates a new instance of @[XmlMapper]
  //!
  //! @param xml
  void create(void|Node xml)
  {
    if (xml) {
      foreach (xml->get_children(), Node n) {
      	if (n->get_node_type() != XML_ELEMENT)
      	  continue;

      	string name = n->get_tag_name();

      	if ( function f = this["handle_" + name] )
      	  f(n);
      	else if ( object_variablep(this, name) ) {
      	  if (objectp( this[name] ))
      	    error("Unhandled complex node \"%s\". ", name);
      	  else {
      	    string value = n->value_of_node();
	    if (stringp( this[name] ))
	      this[name] = NULLIFY(value);
	    else if (intp( this[name] ))  {
	      if (value == "true")
	      	this[name] = true;
	      else if (value == "false")
	      	this[name] = false;
	      else 
	      	this[name] = (int)value;
	    }
	  }
      	}
      }
    }
  }
}

//! Class representing a Twitter message (or @tt{status@} as the XML nodes
//! are called).
public class Message
{
  inherit XmlMapper;

  //! The message ID
  public string id = NULL;
  
  //! The message text
  public string text = NULL;
  
  //! The application the message was send from.
  public string source = NULL;
  
  //! The screen name of the receiver if the message is a reply
  public string in_reply_to_screen_name = NULL;
  
  //! The id of the orginal message if this message is a reply
  public string in_reply_to_status_id = NULL;
  
  //! The ID of the author of the original message
  public string in_reply_to_user_id = NULL;
  
  //! @tt{true@} if this message is a favourite of the authenticating user
  public bool   favorited;
  
  //! @tt{true@} if the message has been truncated
  public bool   truncated;
  
  //! The user who created the message
  public User user;
  
  //! NULL if the message isn't a retweet.
  public Message retweeted_status;
  
  //! The time and date when the message was created
  public Calendar.Second created_at = Calendar.now();

  //! Handles the @tt{created_at@} node. Turns the date into a 
  //! @[Calendar.Second] object. 
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_created_at(Node n)
  {
    created_at = parse_date(n->value_of_node());
  }

  //! Handles the @tt{user@} node. Turns the date into a @[User] object. 
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_user(Node n)
  {
    user = User(n);
  }
  
  public void handle_retweeted_status(Node n)
  {
    retweeted_status = Message(n);
  }

  public string _sprintf(int t)
  {
    return t == 'O' && sprintf("Message(%O:%O)", id, user && user->name);
  }
}

//! Class representing a direct message.
public class DirectMessage
{
  inherit XmlMapper;
  
  //! The message ID
  public string id = NULL;
  
  //! The user ID of the sender of the message
  public string sender_id = NULL;
  
  //! The message
  public string text = NULL;
  
  //! The use ID of the recipient
  public string recipient_id = NULL;
  
  //! Date and time when the message was created
  public Calendar.Second created_at = Calendar.now();
  
  //! The screen name of the sender
  public string sender_screen_name = NULL;
  
  //! The screen name of the recipient
  public string recipient_screen_name = NULL;
  
  //! The @[User] object of the sender.
  public User sender;
  
  //! The @[User] object of the recipient
  public User recipient;
  
  //! Handles the @tt{created_at@} node. Turns the date into a 
  //! @[Calendar.Second] object. 
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_created_at(Node n)
  {
    created_at = parse_date(n->value_of_node());
  }
  
  //! Handles the @tt{recipient@} node. Turns the node tree into a @[User]
  //! object.
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_recipient(Node n)
  {
    recipient = User(n);
  }

  //! Handles the @tt{sender@} node. Turns the node tree into a @[User]
  //! object.
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_sender(Node n)
  {
    sender = User(n);
  }
  public string _sprintf(int t)
  {
    return t == 'O' && sprintf("DirectMessage(%O:%O>%O)", id,
                               sender && sender->name,
                               recipient && recipient->name);
  }
}

//! Class representing a Twitter user
public class User
{
  inherit XmlMapper;

  //! The user ID
  public string id = NULL;
  
  //! The name of the user
  public string name = NULL;
  
  //! The user's location
  public string location = NULL;
  
  //! The user description
  public string description = NULL;
  
  //! The URL to the user's profile image
  public string profile_image_url = NULL;
  
  //! The user's web site url
  public string url = NULL;
  
  //! @tt{true@} if the user is non-public user
  public bool is_protected;
  
  //! The number of people following the user
  public int followers_count;
  
  //! The profile background color
  public string profile_background_color = NULL;
  
  //! The profile link color
  public string profile_link_color = NULL;
  
  //! The profile sidebar color
  public string profile_sidebar_fill_color = NULL;
  
  //! The profile sidebar border color
  public string profile_sidebar_border_color = NULL;
  
  //! Number of friends of the user
  public int friends_count;
  
  //! Number of favourites of the user
  public int favourites_count;
  
  //! User's UTC offset
  public string utc_offset = NULL;
  
  //! User's time zone
  public string time_zone = NULL;
  
  //! User's profile background image
  public string profile_background_image_url = NULL;
  
  //! @tt{true@} if the user's background is tiled
  public bool profile_background_tile;
  
  //! boolean indicating if a user is receiving device updates for a given user
  public bool notifications;
  
  //! @tt{true@} if geo is enabled for the user
  public bool geo_enabled;
  
  //! @tt{true@} if the user's identity is verified.
  //! More on verified accounts: @url{http://twitter.com/help/verified@}
  public bool verified;
  
  //! @tt{true@} if the user if following some other user
  public bool following;
  
  //! Number of Twitter statuses the user has
  public int statuses_count;
  
  //! Time and date when the user was created.
  public Calendar.Second created_at;
  
  //! The last status message of the user.
  public Message status;

  //! Handles the @tt{created_at@} node. Turns the date into a 
  //! @[Calendar.Second] object. 
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_created_at(Node n)
  {
    created_at = parse_date(n->value_of_node());
  }

  //! Returns the text of the user's last status message
  public string get_status_text()
  {
    return status && status->text;
  }

  //! Handles the @tt{status@} node. Turns the tree node into a @[Message]
  //! object
  //!
  //! @note
  //!  This method is called from the constructor of @[XmlMapper] and should 
  //!  be considered private.
  //!
  //! @param n
  public void handle_status(Node n)
  {
    status = Message(n);
  }

  //! String format
  //!
  //! @param t
  //!  Only handles `%O`
  string _sprintf(int t)
  {
    return sprintf("%O(%s, \"%s\")", object_program(this), id, name);
  }
}

//! Parses Twitter dates into a @[Calendar.Second] object
//!
//! @param date
//!  I.e. Sun Mar 18 06:42:26 +0000 2007
private Calendar.Second parse_date(string date)
{
  return Calendar.parse("%e %M %D %h:%m:%s %z %Y", date)
                  ->set_timezone(Calendar.Timezone.locale);
}
