/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

/* This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/* File licensing and authorship information block.
 *
 * Version: MPL 1.1/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Initial Developer of the Original Code is
 *
 * Pontus Östlund <pontus@poppa.se>
 *
 * Portions created by the Initial Developer are Copyright (C) Pontus Östlund
 * All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of the LGPL, and not to allow others to use your version
 * of this file under the terms of the MPL, indicate your decision by
 * deleting the provisions above and replace them with the notice
 * and other provisions required by the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL or the LGPL.
 *
 * Significant Contributors to this file are:
 *
 */

constant USER_AGENT  = "Pike OAuth2 Client (Pike + " + __VERSION__ + ")";
constant json_decode = Standards.JSON.decode;
constant Params      = Social.Params;
constant Param       = Social.Param;

//! The application ID
protected string client_id;

//! The application secret
protected string client_secret;

//! Where the authorization page should redirect to
protected string redirect_uri;

//! The scope
protected string scope;

protected string grant_type = "authorization_code";

protected string response_type = "code";

protected mapping request_headers = ([ 
  "User-Agent"   : USER_AGENT,
  "Content-Type" : "application/x-www-form-urlencoded" 
]);

public mapping gettable = ([ "access_token"  : 0,
                             "refresh_token" : 0,
                             "expires"       : 0,
                             "created"       : 0,
                             "token_type"    : 0 ]);

//! Creates an Authorization object
//!
//! @param client_id
//!  The application ID
//!
//! @param client_secret
//!  The application secret
//!
//! @param _redirect_uri
//!  Where the authorization page should redirect back to. This must be
//!  fully qualified domain name.
//!
//! @param _scope
//!  Extended permissions to use for this authorization.
//!  @url{http://developers.facebook.com/docs/authentication/permissions@}.
void create(string _client_id, string _client_secret, string _redirect_uri,
            string _scope)
{
  client_id     = _client_id;
  client_secret = _client_secret;
  redirect_uri  = _redirect_uri;
  scope         = _scope;
}

mixed `[](string key)
{
  if ( gettable[key] )
    return gettable[key];

  return ::`[](key);
}

mixed `->(string key)
{
  return `[](key);
}

//! Returns the application ID
string get_client_id()
{
  return client_id;
}

//! Returns the application secret.
string get_client_secret()
{
  return client_secret;
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
string get_auth_uri(string base_auth_uri, void|mapping args)
{
  Params p = Params(Param("client_id",     client_id),
                    Param("response_type", response_type),
                    Param("redirect_uri",  redirect_uri));

  if (args)  m_delete(args, "redirect_uri");
  if (scope) p += Param("scope", scope);
  if (args)  p->add_mapping(args);

  return base_auth_uri + "?" + p->to_query();
}

//! Returns the access token
string get_access_token()
{
  return gettable->access_token;
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
string request_access_token(string oauth_token_uri, string code)
{
  Params p = Params(Param("client_id",     client_id),
                    Param("redirect_uri",  redirect_uri),
                    Param("client_secret", client_secret),
                    Param("grant_type",    grant_type),
                    Param("code",          code));

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.post_url(oauth_token_uri, p->to_mapping(), 
                              request_headers);

  string c = q->data();

  if (q->status != 200) {
    string emsg = sprintf("Bad status (%d) in HTTP response! ", q->status);
    if (string reason = try_get_error(c))
      emsg += "Reason: " + reason + "! ";

    error(emsg);
  }

  if (decode_access_token_response(c))
    return encode_value(gettable);

  error("Failed getting access token!");
}

protected int(0..1) decode_access_token_response(string r)
{
  if (!r) return 0;

  mapping v = ([]);

  if (has_prefix(r, "access_token")) {
    foreach (r/"&", string s) {
      sscanf(s, "%s=%s", string key, string val);
      v[key] = val;
    }
  }
  else {
    if (catch(v = json_decode(r)))
      return 0;
  }

  if (!v->access_token)
    return 0;

  gettable->created = time();

  foreach (v; string key; string val) {
    if (search(key, "expires") > -1) {
      gettable->expires = gettable->created + (int)val;
    }
    else
      gettable[key] = val;
  }

  return 1;
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
  return !!gettable->created;
}

//! Checks if this authorization has expired
int(0..1) is_expired()
{
  return gettable->expires ? time() > gettable->expires : 1;
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
	case "access_token":  gettable->access_token  = v; break;
	case "refresh_token": gettable->refresh_token = v; break;
	case "token_type":    gettable->token_type    = v; break;
	case "expires":       gettable->expires       = v; break;
	case "created":       gettable->created       = v; break;
      }
    }
    
    return this;
  };

  error("Unable to decode cookie! %s. ", describe_error(e));
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
  expected_sig = Crypto.HMAC(Crypto.SHA256)(payload)(client_secret);
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
    case "string": return gettable->access_token;
    case "int":    return gettable->expires;
  }

  error("Can't cast %O to %s! ", object_program(this), how);
}

string _sprintf(int t)
{
  switch (t) {
    case 's':
      return gettable->access_token;

    default:
      return sprintf("%O(%O, %O, %O, %O)", 
                     object_program(this), gettable->access_token,
                     redirect_uri,
                     Calendar.Second("unix", gettable->created),
                     Calendar.Second("unix", gettable->expires));
  }
}
