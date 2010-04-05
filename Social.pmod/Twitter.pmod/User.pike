/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! Class representing a Twitter user
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

