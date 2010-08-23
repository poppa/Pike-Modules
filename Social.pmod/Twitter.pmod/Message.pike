/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Class representing a Twitter message (or @tt{status@} as the XML nodes
//! are called).
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Message.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Message.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Message.pike. If not, see <http://www.gnu.org/licenses/>.

#include "twitter.h"
import ".";
import Parser.XML.Tree;
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
public bool favorited;

//! @tt{true@} if the message has been truncated
public bool truncated;

//! The user who created the message
public User user;

//! NULL if the message isn't a retweet.
public Message retweeted_status;

//! The time and date when the message was created
public Calendar.Second created_at = Calendar.now();

// Handles the @tt{created_at@} node. Turns the date into a 
// @[Calendar.Second] object. 
//
// @note
//  This method is called from the constructor of @[XmlMapper] and should 
//  be considered private.
//
// @param n
public void handle_created_at(Node n)
{
  created_at = parse_date(n->value_of_node());
}

// Handles the @tt{user@} node. Turns the date into a @[User] object. 
//
// @note
//  This method is called from the constructor of @[XmlMapper] and should 
//  be considered private.
//
// @param n
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

