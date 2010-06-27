/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Class representing a direct message.
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| DirectMessage.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| DirectMessage.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with DirectMessage.pike. If not, see <http://www.gnu.org/licenses/>.

#include "twitter.h"
import ".";
import Parser.XML.Tree;
inherit XmlMapper;

//! The message ID
string id = NULL;

//! The user ID of the sender of the message
string sender_id = NULL;

//! The message
string text = NULL;

//! The use ID of the recipient
string recipient_id = NULL;

//! Date and time when the message was created
Calendar.Second created_at = Calendar.now();

//! The screen name of the sender
string sender_screen_name = NULL;

//! The screen name of the recipient
string recipient_screen_name = NULL;

//! The @[User] object of the sender.
User sender;

//! The @[User] object of the recipient
User recipient;

// Handles the @tt{created_at@} node. Turns the date into a 
// @tt{Calendar.Second@} object.
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

// Handles the @tt{recipient@} node. Turns the node tree into a @[User]
// object.
//
// @note
//  This method is called from the constructor of @[XmlMapper] and should 
//  be considered private.
//
// @param n
public void handle_recipient(Node n)
{
  recipient = User(n);
}

// Handles the @tt{sender@} node. Turns the node tree into a @[User]
// object.
//
// @note
//  This method is called from the constructor of @[XmlMapper] and should 
//  be considered private.
//
// @param n
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
