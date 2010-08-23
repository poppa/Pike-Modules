/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Flickr service API
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Api.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Api.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Api.pike. If not, see <http://www.gnu.org/licenses/>.

#include "flickr.h"
import ".";

protected multiset all_perms = (< PERM_READ, PERM_WRITE, PERM_DELETE >);
protected string key;
protected string secret;
protected string token;
protected string endpoint = ENDPOINT_URL;
protected string response_format = "rest";
protected string permission = PERM_READ;
protected int bit_permission = BIT_PERM_READ;
protected User user;

//! Creates a new instance of @[Api].
//!
//! @param api_key
//! @param api_secret
//! @param api_token
void create(string api_key, string api_secret, void|string api_token)
{
  key = api_key;
  secret = api_secret;
  token = api_token;
}

//! Returns an identifier of this instance. This can be used as a cache key or
//! something similar.
string get_identifer()
{
  return key + secret + (token||"") + (user && user->username || "");
}

//! Setter for the API token
//!
//! @param api_token
void set_token(string api_token)
{
  token = api_token;
}

//! Getter for the API token
string get_token()
{
  return token;
}

//! Setter for the user object
//!
//! @param _user
void set_user(User _user)
{
  user = _user;
}

//! Getter for the @[User] object.
User get_user()
{
  if (user) return user;
  Response rsp = call("flickr.auth.checkToken");
  if (rsp) {
    token = (string)rsp->auth->token;
    set_permission((string)rsp->auth->perms);
    return user = User()->from_mapping((mapping)rsp->auth->user);
  }

  return 0;
}

//! Returns true if the current instance is authenticated.
int(0..1) is_authenticated()
{
  return !!get_user();
}

//! Getter for the reponse format being used
string get_response_format()
{
  return response_format;
}

//! Returns the permissions
string get_permission()
{
  return permission;
}

//! Returns the permissions as bit flags
int get_bit_permission()
{
  return bit_permission;
}

//! Setter for the permissions
//!
//! @throws
//!  An error if @[perm] is unknown
//!
//! @param perm
//!  See the @tt{PERM_*@} constants in @[Flickr].
void set_permission(string perm)
{
  if ( !all_perms[perm] ) {
    error("Unknown permission %O. Expected %s! ", perm,
          String.implode_nicely((array)all_perms, "or"));
  }

  permission = perm;
  bit_permission = BIT_PERM_MAP[perm];
}

//! Returns the authorization url.
//!
//! @param perm
//!  What permission to give to the authenticated user. This overrides the
//!  global value of the object.
string get_auth_url(void|string perm)
{
  if (perm) set_permission(perm);

  Params p = Params(
    Param(API_KEY, key),
    Param(PERMS, permission),
    Param(FORMAT, response_format)
  );

  p += Param(API_SIG, p->sign(secret));
  return AUTH_ENDPOINT_URL + "?" + p->to_query();
}

//! Request an API token. Calls @tt{flickr.auth.getToken@}.
//!
//! @param frob
//!  A frob is given back after a successful authentication. 
//!  See @[get_auth_url()].
int(0..1) request_token(string frob)
{
  Params p = Params(Param(FROB, frob));
  Response rsp = call("flickr.auth.getToken", p);
  if (rsp) {
    token = (string)rsp->auth->token;
    set_permission((string)rsp->auth->perms);
    user = User()->from_mapping((mapping)rsp->auth->user);
    return 1;
  }

  return 0;
}

//! Async upload method
//!
//! @param image_path
//!  Local file system path to image to upload
//! @param _params
int upload(string image_path, void|mapping|Params _params)
{
  Params params = Params();
  if ( objectp(_params) )  params = _params;
  if ( mappingp(_params) ) params->add_mapping(_params);
  if ( !params[API_KEY] )  params += Param(API_KEY, key);
  if ( !params[FORMAT] )   params += Param(FORMAT, response_format);
  if ( !params[PERMS] )    params += Param(PERMS, permission);
  if ( token && !params[AUTH_TOKEN] ) params += Param(AUTH_TOKEN, token);

  string ext = lower_case( (basename(image_path)/".")[-1] );

  if (ext == "jpg")
    ext = "jpeg";
  else if (ext == "tif")
    ext = "tiff";

  mapping vars = params->to_mapping();
  vars->api_sig = params->sign(secret);

  string ct = "image/" + ext;
  string bound = Standards.UUID.make_version4()->str()-"-";
  mapping h = ([ "Content-Type" : "multipart/form-data; boundary=" + bound ]);
  string m = "";

  foreach (vars; string k; string v) {
    Multipart mp = Multipart(v);
    mp->set_boundary(bound);
    mp->set_content_disposition("form-data; name=\"" + k + "\"");

    m += (string)mp;
  }

  Multipart m4 = Multipart(Stdio.read_file(image_path));
  m4->set_boundary(bound);
  m4->set_content_type(ct);
  m4->set_content_disposition("form-data; name=\"photo\"; filename=\"" +
                              combine_path(getcwd(), image_path) + "\"");

  m += String.trim_all_whites((string)m4) + "--\r\n";
  m = "--" + bound + "\r\n" + m;

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.do_method("POST", UPLOAD_ENDPOINT_URL, 0, h, 0, m);

  Response rsp = Response(q->data());
  if (rsp->get_attributes()->stat == "ok")
    return (int)rsp->photoid->get_value();

  error("Upload error: %s! ", rsp->err->get_attributes()->msg);
}

//! Calls a Flickr web service and returns the raw response
//!
//! @throws
//!  An error if the HTTP status isn't 200
//!  An error if the response is unparsable.
//!  An error if the response status isn't OK and @[dont_throw_error] isn't
//!  @tt{1@}.
//!
//! @param api_method
//!  The method to call: @tt{flickr.auth.getToken, flickr.photos.getInfo@}
//!  for instance.
//! @param _params
//! @param dont_throw_error
//!  If @tt{1@} an error won't be thrown when the reponse status isn't OK.
string call_xml(string api_method, void|mapping|Params _params,
                void|int(0..1) dont_throw_error)
{
  Params params = Params();

  if (objectp(_params)) params = _params;
  if (mappingp(_params)) params = Params()->add_mapping(_params);

  if ( !params[API_KEY] ) params += Param(API_KEY, key);
  if ( !params[METHOD] )  params += Param(METHOD, api_method);
  if ( !params[FORMAT] )  params += Param(FORMAT, response_format);
  if ( !params[PERMS] )   params += Param(PERMS, permission);
  if ( token && !params[AUTH_TOKEN] ) params += Param(AUTH_TOKEN, token);

  mapping vars = params->to_mapping() + ([ API_SIG : params->sign(secret) ]);

  //TRACE("call(%O, %O)\n", api_method, vars);
  
  Protocols.HTTP.Query q = Protocols.HTTP.post_url(endpoint,vars,HTTP_HEADERS);

  //TRACE("Data: %s\n", q->data());

  if (q->status != 200)
    error("Bad status \"%d\" in HTTP response! ", q->status);

  string data = q->data();
  Response rsp = Response(data);
  mapping a = rsp->get_attributes();

  if (!a->stat) error("Malformed XML response from Flickr");

  if (!dont_throw_error) {
    if (a->stat != "ok") {
      if (rsp = rsp->err) {
	mapping a = rsp->get_attributes();
	error("Flickr API error: %s (%s)! ", a->msg||"", a->code||"");
      }
      else
	error("Unknown Flickr API error: %s\n", q->data());
    }
  }

  return data;
}

//! Calls a Flickr web service
//!
//! @seealso
//!  @[call_xml()]
//!
//! @param api_method
//! @param params
Response call(string api_method, void|mapping|Params params)
{
  return Response(call_xml(api_method, params));
}

