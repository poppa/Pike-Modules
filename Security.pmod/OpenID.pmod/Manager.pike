/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{OpenID Manager@}
//!
//! This class handles all operations for doing an OpenID authentication.
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Manager.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Manager.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Manager.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "openid.h"

//! URL the operator should return to
private string return_to;

//! Realm of the authentication
private string realm;

//! If true @tt{openid.mode@} will be @tt{checkid_setup@} 
//! else @tt{checkid_immediate@}
private int(0..1) interactive = 1;

//! Set to true if the user has aborted the authentication.
private int(0..1) cancelled = 0;

//! Set if the user is authenticating throug an id URL, like
//! @tt{http://username.myopenid.com@}
private string claimed_id = 0;

//! Required info to request from the provider
private array(string) required_attributes = ({
  "email",
  "fullname",
  "language",
  "firstname",
  "lastname",
  "gender"
});

//! Optional info to request from the provider
private array(string) optional_attributes = ({});

//! Setter for which info info fields about the user to request from the 
//! provider. Default fields are: email, fullname, language, firstname, 
//! lastname and gender.
//!
//! @param attributes
void set_required_attributes(array(string) attributes)
{
  required_attributes = attributes;
}

//! Returns the required info fields.
array(string) get_required_attributes()
{
  return required_attributes;
}

//! Setter for which info fields about the user should be optional to request
//! from the provider.
void set_optional_attributes(array(string) attributes)
{
  optional_attributes = attributes;
}

//! Getter for the optional info fields
array(string) get_optional_attributes()
{
  return optional_attributes;
}

//! Sets the returning URL after authentication
//!
//! @param _return_to
void set_return_to(string|Standards.URI _return_to)
{
  return_to = (string)_return_to;
}

//! Sets the realm of the authentication
//!
//! @param _realm
//!  For instance @tt{http://*.myhost.com@}
void set_realm(string _realm)
{
  realm = _realm;
}

//! Returns whether or not the authentication was cancelled by the user.
int(0..1) is_cancelled()
{
  return cancelled;
}

//! Parses the response from an authentication attempt.
//!
//! @param response
//!  This should be the query string variables returned from the operator.
//! @param assoc
.Authentication parse_auth_response(mapping response, .Association assoc)
{
  string alias;

  TRACE("Response: %O\n", response);

  foreach (indices(response), string a)
    if (sscanf(a, "openid.%s.type", alias) > 0)
      break;

#define P(X) response["openid." + (X)]
#define V(X) response["openid." + alias + ".value." + (X)] || \
             response["openid." + alias + "." + (X)]

  if (!alias) {
    werror("Unables to resolv alias! ");
    alias = P("ns.sreg") && "sreg" || .DEFAULT_ENDPOINT_ALIAS;
  }

  if (P("mode") == "cancel") {
    cancelled = 1;
    return 0;
  }

  if (P("invalidate_handle"))
    error("Handle is invalidated! ");

  string sig = P("sig");
  if (!sig) error("Missing 'openid.sig' !");

  string signed = P("signed");
  if (!signed) error("Missing 'openid.signed' !");

  if (return_to != P("return_to"))
    error("'openid.return_to != %O !", return_to);

  String.Buffer sb = String.Buffer();
  foreach (signed/",", string s)
    sb->add(s, ":", (string)P(s), "\n");

  string sigbase = sb->get();
  string rawmac  = assoc->get_raw_mac_key();
  string hmac    = MIME.encode_base64(
#if constant(Crypto.HMAC)
      Crypto.HMAC(Crypto.SHA1)(rawmac)((safe_utf8(sigbase)))
#else /* Compat for Pike 7.4 */
      Crypto.hmac(Crypto.sha)(rawmac)(safe_utf8(sigbase))
#endif
  );

  if (sig != hmac)
    error("Signature verification failed! ");

  string fname = V("firstname");
  string lname = V("lastname");
  string name  = V("fullname");
  if (!fname && name) fname = (name/" ")[0];
  if (!lname && name) lname = (name/" ")[-1];
  if (!name) name = ({ fname||"", lname||"" })*" ";

  .Authentication a = .Authentication();
  a->set_identity(P("identity"));
  a->set_email(V("email"));
  a->set_language(V("language"));
  a->set_gender(V("gender"));
  a->set_fullname(name);
  a->set_firstname(fname);
  a->set_lastname(lname);

  return a;
}

//! Returns the endpoint for @[url].
//!
//! @param url
//!  Either a full URL or the shortname of a provider as indexed in 
//!  @[Security.OpenID]. "google" and "yahoo" is default providers for instance.
//! @param alias
//!  The alias used in the openid parameters. This is unlikely needed since the
//!  alias should be available in the @[.Endpoint].
.Endpoint get_endpoint(string url, void|string alias)
{
  if (search(url, "://") == -1) {
    TRACE("Find provider by shortname!\n");
    .Provider p = .get_provider(url);
    url = p->get_url();
    alias = p->get_alias();
  }
  else
    claimed_id = url;

  .Endpoint ep;
  if ((ep = .endpoint_cache(url)) && !ep->is_expired()) {
    TRACE("Found %O in cache\n", ep);
    return ep;
  }

  if (mixed e = catch(ep = request_endpoint(url, alias)))
    error("Error requesting endpoint: %s\n", describe_error(e));

  return .endpoint_cache(url, ep);
}

//! Returns the authentication URL for endpoint @[ep] with association
//! @[assoc].
//!
//! @param ep
//! @param assoc
string get_login_url(.Endpoint ep, .Association assoc)
{
  string url = ep->get_url();
  mapping tmp = ([
    "openid.ns" : assoc->get_namespace()||"http://specs.openid.net/auth/2.0",
    "openid.mode" : interactive ? "checkid_setup" : "checkid_immediate",
    "openid.assoc_handle" : assoc->get_association_handle(),
    "openid.return_to" : return_to,
    "openid.claimed_id" : "http://specs.openid.net/auth/2.0/identifier_select",
    "openid.identity" : "http://specs.openid.net/auth/2.0/identifier_select"
  ]);

  if (realm) tmp["openid.realm"] = realm;

  if (claimed_id) {
    tmp["openid.claimed_id"] = claimed_id;
    tmp["openid.identity"] = claimed_id;
    tmp["openid.ns.sreg"]  = "http://openid.net/sreg/1.0";
    tmp["openid.sreg.required"] = required_attributes*",";
    if (optional_attributes)
      tmp["openid.sreg.optional"] = optional_attributes*",";
  }
  else {
    string a = ep->get_alias();
    tmp += ([
      "openid.ns."+a : "http://openid.net/srv/ax/1.0",
      "openid."+a+".mode" : "fetch_request",
      "openid."+a+".type.email" : "http://axschema.org/contact/email",
      "openid."+a+".type.fullname" : "http://axschema.org/namePerson",
      "openid."+a+".type.language" : "http://axschema.org/pref/language",
      "openid."+a+".type.firstname" : "http://axschema.org/namePerson/first",
      "openid."+a+".type.lastname" : "http://axschema.org/namePerson/last",
      "openid."+a+".type.gender" : "http://axschema.org/person/gender",
      "openid."+a+".required" : required_attributes*","
    ]);
    if (optional_attributes)
      tmp["openid."+a+".optional"] = optional_attributes*",";
  }

  Standards.URI u = Standards.URI(url);
  if (u->scheme != "https")
    tmp["no_ssl"] = "true";

  //TRACE("%O\n", tmp);

  return url + ((search(url, "?") > -1) ? "&" : "?") +
         .build_http_query(tmp);
}

//! Creates an association between @[endpoint] and the request.
//!
//! @param endpoint
.Association get_association(.Endpoint endpoint)
{
  .Association assoc;
  if ((assoc = .association_cache(endpoint->get_url())) && 
      !assoc->is_expired()) 
  {
    TRACE("Found %O in cache\n", assoc);
    return assoc;
  }

  if (mixed e = catch(assoc = request_association(endpoint)))
    error("Error requesting association: %s\n", describe_error(e));

  if (!assoc) return 0;

  return .association_cache(endpoint->get_url(), assoc);
}

//! Creates and enpoint for @[url].
//!
//! @param url
//! @param alias
private .Endpoint request_endpoint(string url, void|string alias)
{
  mapping h = ([ "Accept" : "application/xrds+xml" ]);
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, 0, h);

  if (q->status != 200)
    error("Bad status (%d) in HTTP response\n", q->status);

  int expires = .get_max_age(q->headers);
  string data = q->data();

  if ( string enc = q->headers["content-encoding"] )
    if (enc == "gzip")
      data = Gz.uncompress(data);

  string ep_url = .get_named_xml_element(q->data(), "URI");

  return .Endpoint(ep_url, alias, expires);
}

//! Creates an association between @[endpoint] and the current request
//!
//! @param endpoint
private .Association request_association(.Endpoint endpoint)
{
  Protocols.HTTP.Query q = Protocols.HTTP.post_url(endpoint->get_url(), 
                                                   assoc_vars);
  if (q->status != 200)
    error("Bad status (%d) in HTTP response!", q->status);

  .Association assoc = .Association();

  foreach (q->data()/"\n", string line) {
    TRACE("=== %s\n", line);
    if (sscanf(line, "%s:%s", string key, string value) == 2) {
      TRACE("====== %s >>> %s\n", key, value);
      switch (key) 
      {
      	case "session_type":
	  assoc->set_session_type(value);
	  break;

	case "assoc_type":
	  assoc->set_association_type(value);
	  break;

	case "assoc_handle":
	  assoc->set_association_handle(value);
	  break;

	case "expires_in":
	  assoc->set_max_age((int)value);
	  break;

	case "mac_key":
	  assoc->set_mac_key(value);
	  break;

	case "ns":
	  assoc->set_namespace(value);
	  break;
      }
    }
  }
  
  return assoc;
}

//! Query parameters for doing an association request
private mapping assoc_vars = ([
  "openid.ns"           : "http://specs.openid.net/auth/2.0",
  "openid.mode"         : "associate",
  "openid.session_type" : .Association.SESSION_TYPE_NO_ENCRYPTION,
  "openid.assoc_type"   : .Association.ASSOC_TYPE_HMAC_SHA1
]);

//! UTF8 encodes @[s] without throwing an error if @[s] is already UTF8 encoded.
string safe_utf8(string s)
{
  catch (s = string_to_utf8(s));
  return s;
}

//! Latin-1 encodes @[s] without throwing an error if @[s] is already 
//! Latin-1 encoded.
string safe_iso88591(string s)
{
  catch (s = utf8_to_string(s));
  return s;
}

