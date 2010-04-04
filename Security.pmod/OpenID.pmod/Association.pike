/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Association.pike@}
//!
//! This class creates an association between a requester and an operator.
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Association.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Association.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License along 
//! with Association.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

//! Session type constant
constant SESSION_TYPE_NO_ENCRYPTION = "no-encryption";

//! Association type constant
constant ASSOC_TYPE_HMAC_SHA1 = "HMAC-SHA1";

private string session_type;
private string assoc_type;
private string assoc_handle;
private string mac_key;
private string raw_mac_key;
private int expired;

//! Returns the session type
string get_session_type()
{
  return session_type;
}

//! Sets the session type
//!
//! @param _session_type
void set_session_type(string _session_type)
{
  session_type = _session_type;
}

//! Returns the association type
string get_association_type()
{
  return assoc_type;
}

//! Sets the association type
//!
//! @param association_type
void set_association_type(string association_type)
{
  assoc_type = association_type;
}

//! Returns the association handle
string get_association_handle()
{
  return assoc_handle;
}

//! Sets the association handle
//!
//! @param association_handle
void set_association_handle(string association_handle)
{
  assoc_handle = association_handle;
}

//! Returns the mac key, base64 encoded.
string get_mac_key()
{
  return mac_key;
}

//! Sets the mac key
//!
//! @param _mac_key
void set_mac_key(string _mac_key)
{
  mac_key = _mac_key;
  raw_mac_key = MIME.decode_base64(mac_key);
}

//! Returns the raw mac key, without base64 encoding
string get_raw_mac_key()
{
  return raw_mac_key;
}

//! Sets the max age of the association, in seconds from now
//!
//! @param seconds
void set_max_age(int seconds)
{
  expired = time() + seconds;
}

//! Sets the expiration time of the association, seconds from the epoch.
void set_expiration(int seconds)
{
  expired = seconds;
}

//! Checks if the association has expired or not.
int(0..1) is_expired()
{
  return time() >= expired;
}

//! Turns the object members into a mapping and encodes it with Pike's 
//! @[predef::encode_value()]
string encode_cookie()
{
  return encode_value(to_mapping());
}

//! Populates the object with the values from a cookie created with 
//! @[encode_cookie()]
object_program decode_cookie(string cookie)
{
  mixed e = catch {
    foreach (decode_value(cookie); string k; mixed v) {
      switch (k) 
      {
      	case "session_type": session_type = v; break;
      	case "assoc_handle": assoc_handle = v; break;
      	case "assoc_type":   assoc_type = v; break;
      	case "mac_key":
	  mac_key = v; 
	  raw_mac_key = MIME.decode_base64(v);
	  break;
	case "expired": expired = v; break;
      }
    }
  };

  if (e) error("Failed to decode cookie: %s\n", describe_error(e));

  return this;
}

//! Casting method. Only supports @tt{mapping@}.
//!
//! @param how
mixed cast(string how)
{
  if (how == "mapping")
    return to_mapping();
  
  error("Can't cast %O to %O\n", object_program(this), how);
}

private mapping to_mapping()
{
  return ([
    "session_type" : session_type,
    "assoc_type"   : assoc_type,
    "assoc_handle" : assoc_handle,
    "mac_key"      : mac_key,
    "raw_mac_key"  : raw_mac_key,
    "expired"      : expired
  ]);
}

string _sprintf(int t)
{
  Calendar.Second exp = Calendar.Second("unix", expired);
  return t == 'O' && sprintf("%O(session_type: %s, "
                             "assoc_type: %s, "
                             "assoc_handle: %s, "
                             "mac_key: %s, "
                             "expired: %s)",
                             object_program(this),
                             session_type||"",
                             assoc_type||"",
                             assoc_handle||"",
                             mac_key||"",
                             exp && exp->format_time());
}
