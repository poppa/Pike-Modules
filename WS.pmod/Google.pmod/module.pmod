/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{WS.Google module@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! This file is part of Google.pmod
//!
//! Google.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Google.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Google.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}
//!

string md5(string s)
{
#if constant(Crypto.MD5)
  s = String.string2hex(Crypto.MD5.hash(s));
#else /* Compat cludge for Pike 7.4 */
  s = Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif
  return s;
}

string download(string url, void|mapping headers)
{
  url = replace(url, "&amp;", "&");
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, 0, headers);
  if (q->status != 200)
    error("Bad status \"%d\" in Google.download()\n", q->status);

  return q->data();
}