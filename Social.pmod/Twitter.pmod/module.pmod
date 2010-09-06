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

#include "twitter.h"

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
constant request_token_url    = SURL("oauth/request_token");
constant access_token_url     = SURL("oauth/access_token");
constant user_auth_url        = SURL("oauth/authorize");

//! Parses Twitter dates into a @[Calendar.Second] object
//!
//! @param date
//!  I.e. Sun Mar 18 06:42:26 +0000 2007
public Calendar.Second parse_date(string date)
{
  return Calendar.parse("%e %M %D %h:%m:%s %z %Y", date)
                  ->set_timezone(Calendar.Timezone.locale);
}
