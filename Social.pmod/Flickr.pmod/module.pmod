/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Flickr@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Flickr.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Flickr.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Flickr.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "flickr.h"

//! This Flickr APIs version
constant VERSION = "0.2";

//! String used as user agent in HTTP requests
constant HTTP_USER_AGENT = "Pike Flickr Agent v" + VERSION;

//! Default extra HTTP headers used in HTTP requests
constant HTTP_HEADERS = ([ "User-Agent" : HTTP_USER_AGENT ]);

//! The query param for the API key
constant API_KEY = "api_key";

//! The query param for the API secret
constant API_SECRET = "api_secret";

//! The query param for the API signature
constant API_SIG = "api_sig";

//! The query param for the auth token
constant AUTH_TOKEN = "auth_token";

//! The query param for the frob
constant FROB = "frob";

//! The query param for the permisson
constant PERMS = "perms";

//! The query param for the method
constant METHOD = "method";

//! The query param for the response format
constant FORMAT = "format";

//! The query param for the privacy filter
constant PRIVACY_FILTER = "privacy_filter";

//! Read permission
constant PERM_READ = "read";

//! Write permission
constant PERM_WRITE = "write";

//! Delete permission
constant PERM_DELETE = "delete";

//! Bitmask value of read permission
constant BIT_PERM_READ = 1;

//! Bitmask value of write permission
constant BIT_PERM_WRITE = 2;

//! Bitmask permisson of delete permission
constant BIT_PERM_DELETE = 4;

//! String permission to bitmask map
constant BIT_PERM_MAP = ([
  PERM_READ   : BIT_PERM_READ,
  PERM_WRITE  : BIT_PERM_WRITE,
  PERM_DELETE : BIT_PERM_DELETE
]);

//! Default response format
constant RESPONSE_FORMAT = "rest";

//! Default API endpoint url
constant ENDPOINT_URL = "http://www.flickr.com/services/rest/";

//! Default authentication endpoint url
constant AUTH_ENDPOINT_URL = "http://www.flickr.com/services/auth/";

//! Default upload endpoint url
constant UPLOAD_ENDPOINT_URL = "http://api.flickr.com/services/upload/";

//! Downloads the URL in @[src] to the directory @[save_to]
//!
//! @param src
//!  Either a single URL to an image or an array of URLs.
//! @param save_to
//!  The path to a directory where to save the downloaded images
//!
//! @returns
//!  Returns the path(s) to the downloaded image(s)
string|array download(string|array src, string save_to)
{
  if (!Stdio.is_dir(save_to))
    error("Download directory \"%s\" doesn't exist!", save_to);

  string path;
  if (arrayp(src)) {
    array out = ({});
    .DownloadManager.ThreadPool tp = .DownloadManager.ThreadPool(5, 3);
    foreach (src, string s) {
      path = combine_path(save_to, basename(s));
      tp->add(.DownloadManager.download, s, path);
      out += ({ path });
    }

    tp->run();
    return out;
  }

  path = combine_path(save_to, basename(src));
  .DownloadManager.download(src, path);
  return path;
}

string get_src(.Response photo)
{
  mapping a = photo->get_attributes();
  string url = sprintf("farm%s.static.flickr.com/%s/%s_%s.jpg",
                       a->farm, a->server, a->id, a->secret);
  return "http://" + url;
}

