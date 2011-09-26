#!/usr/bin/env pike
/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! [PROG-NAME]
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| [PROG-NAME].pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| [PROG-NAME].pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with [PROG-NAME].pike. If not, see <http://www.gnu.org/licenses/>.

#define GOOGLE_DEBUG

#include "google.h"

import ".";

constant OAUTH_AUTH_URI  = "https://accounts.google.com/o/oauth2/auth";
constant OAUTH_TOKEN_URI = "https://accounts.google.com/o/oauth2/token";

constant json_decode = Social.json_decode;

//! The application ID
private string app_id;

//! The application secret
private string app_secret;

//! Where the authorization page should redirect to
private string redirect_uri;

//! The authorization's access token
private string access_token;

//! The authorization's refresh token
private string refresh_token;

private string token_type;

//! Unix timestamp when the authorization explires
private int expire;

//! When the authorization was created
private int created;

//! The extended permissions
private string permissions;

private string response_type = "code";

//! Creates an Authorization object
//!
//! @param client_id
//!  The Facebook application ID
//!
//! @param client_secret
//!  The Facebook application secret
//!
//! @param _redirect_uri
//!  Where the authorization page should redirect back to. This must be
//!  fully qualified domain name.
//!
//! @param _permissions
//!  Extended permissions to use for this authorization.
//!  @url{http://developers.facebook.com/docs/authentication/permissions@}.
void create(string client_id, string client_secret, string _redirect_uri,
	    string _permissions)
{
  app_id       = client_id;
  app_secret   = client_secret;
  redirect_uri = _redirect_uri;
  permissions  = _permissions;
}

//! Returns the application ID
string get_application_id()
{
  return app_id;
}

//! Returns the application secret.
string get_application_secret()
{
  return app_secret;
}

//! Returns the redirect uri
string get_redirect_uri()
{
  return redirect_uri;
}

//! Setter for the redirect uri
//!
//! @param uri
void set_redirect_uri(string uri)
{
  redirect_uri = uri;
}

//! Returns an authorization URI.
//!
//! @param args
//!  Additional argument.
string get_auth_uri(void|mapping args)
{
  Params p = Params(Param("client_id", app_id),
                    Param("response_type", response_type),
                    Param("redirect_uri",
                          args&&args->redirect_uri||redirect_uri));

  if (args)
    m_delete(args, "redirect_uri");

  if (permissions)
    p += Param("scope", permissions);

  if (args)
    p->add_mapping(args);

  return OAUTH_AUTH_URI + "?" + p->to_query();
}

//! Returns the access token
string get_access_token()
{
  return access_token;
}

//! Requests an access token
//!
//! @throws
//!  An error if the access token request fails.
//!
//! @param code
//!  The code returned from the authorization page.
//!
//! @returns
//!  If OK a Pike encoded mapping (i.e it's a string) is returned which can 
//!  be used to populate an @[Authorization] object at a later time.
//!
//!  The mapping looks like
//!  @mapping
//!   @member string "access_token"
//!   @member int    "expires"
//!   @member int    "created"
//!   @member string "code"
//!  @endmapping
string request_access_token(void|string code)
{
  Params p = Params(Param("client_id",     app_id),
                    Param("redirect_uri",  redirect_uri),
                    Param("client_secret", app_secret),
                    Param("grant_type",    "authorization_code"),
                    Param("code",          code));

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.post_url(OAUTH_TOKEN_URI,
			      p->to_mapping(),
			      ([ "User-Agent"   : USER_AGENT,
				 "Content-Type" :
				    "application/x-www-form-urlencoded" ]));

  string c = q->data();

  if (q->status != 200) {
    string emsg = sprintf("Bad status (%d) in HTTP response! ", q->status);
    if (string reason = try_get_error(c))
      emsg += "Reason: " + reason + "! ";

    error(emsg);
  }

  mapping ret;
  mixed e = catch {
    ret = json_decode(c);
  };
  
  if (!ret)
    error("Unable to decode response. Unknown error! ");
  
  if (ret->access_token) {
    created       = time();
    expire        = created + (int)ret->expires_in;
    access_token  = ret->access_token;
    refresh_token = ret->refresh_token;
    token_type    = ret->token_type;
    
    return encode_value(([
      "access_token"  : access_token,
      "expire"        : expire,
      "created"       : created,
      "refresh_token" : refresh_token,
      "token_type"    : token_type
    ]));
  }

  error("Failed getting access token!");
}

private mixed try_get_error(string data)
{
  catch {
    mixed x = json_decode(data);
    if (mappingp(x) && x->error)
      return x->error;
  };
}

//! Checks if the authorization is renewable. This is true if the 
//! @[Authorization] object has been populated from 
//! @[Authorization()->set_from_cookie()], i.e the user has been authorized
//! but the session has expired.
int(0..1) is_renewable()
{
  return !!created;
}

//! Checks if this authorization has expired
int(0..1) is_expired()
{
  return expire ? time() > expire : 1;
}

//! Populate this object with the result from 
//! @[Authorization->request_access_token()].
//!
//! @param encoded_value
object_program set_from_cookie(string encoded_value)
{
  mixed e = catch {
    mapping m = decode_value(encoded_value);
    foreach (m; string k; mixed v) {
      switch (k) {
	case "access_token":  access_token  = v; break;
	case "refresh_token": refresh_token = v; break;
	case "token_type":    token_type    = v; break;
	case "expire":        expire        = v; break;
	case "created":       created       = v; break;
      }
    }
    
    return this;
  };
}

//! Parses a signed request
//!
//! @throws
//!  An error if the signature doesn't match the expected signature
//!
//! @param sign
mapping parse_signed_request(string sign)
{
  sscanf(sign, "%s.%s", string sig, string payload);

  function url_decode = lambda (string s) {
    return MIME.decode_base64(replace(s, ({ "-", "_" }), ({ "+", "/" })));
  };

  sig = url_decode(sig);
  mapping data = json_decode(url_decode(payload));

  if (upper_case(data->algorithm) != "HMAC-SHA256")
    error("Unknown algorithm. Expected HMAC-SHA256");

  string expected_sig;

#if constant(Crypto.HMAC)
# if constant(Crypto.SHA256)
  expected_sig = Crypto.HMAC(Crypto.SHA256)(payload)(app_secret);
# else
  error("No Crypto.SHA256 available in this Pike build! ");
# endif
#else
  error("Not implemented in this Pike version! ");
#endif

  if (sig != expected_sig)
    error("Badly signed signature. ");

  return data;
}

//! Cast method. If casted to @tt{string@} the @tt{access_token@} will be
//! returned. If casted to @tt{int@} the @tt{expires@} timestamp will
//! be returned.
//!
//! @param how
mixed cast(string how)
{
  switch (how) {
    case "string": return access_token;
    case "int": return expire;
  }

  error("Can't cast %O to %s! ", object_program(this), how);
}

string _sprintf(int t)
{
  switch (t) {
    case 's':
      return access_token;

    default:
      return sprintf("%O(%O, %O, %O, %O)", object_program(this), access_token,
					   redirect_uri,
					   Calendar.Second("unix", created),
					   Calendar.Second("unix", expire));
  }
}
