/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! Class representing a direct message.
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [PROG-NAME].pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [MODULE-NAME].pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [PROG-NAME].pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "twitter.h"
import ".";
import Parser.XML.Tree;
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
