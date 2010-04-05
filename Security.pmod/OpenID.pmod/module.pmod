/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{OpenID@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! OpenID is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! OpenID is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with OpenID. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#include "openid.h"

import Parser.XML.Tree;

public constant DEFAULT_ENDPOINT_ALIAS = "ext1";

//! Cache storage for @[.Endpoint]s
private mapping(string:.Endpoint) _endpoint_cache = ([]);

//! Cache storage for @[.Association]s
private mapping(string:.Association) _assoc_cache = ([]);

//! Getter/setter for the endpoint cache.
//!
//! @decl endpoint_cache(string key)
//! @decl endpoint_cache(string key, .Endpoint ep)
//!
//! @param key
//!  Cache key, most likely the endpoint URL
//! @param ep
//!
//! @returns
//!  If no @[ep] is given the endpoint with @[key] will be returned from
//!  the cache. If @[ep] is given it will be stored in the cache with the key
//!  @[key] and the endpoint it self will be returned.
.Endpoint endpoint_cache(string key, void|.Endpoint ep)
{
  if (!ep) return _endpoint_cache[key];
  return _endpoint_cache[key] = ep;
}

//! Getter/setter for the association cache.
//!
//! @decl association_cache(string key)
//! @decl association_cache(string key, .Endpoint ep)
//!
//! @param key
//!  Cache key, most likely the association URL
//! @param as
//!
//! @returns
//!  If no @[as] is given the association with @[key] will be returned from
//!  the cache. If @[as] is given it will be stored in the cache with the key
//!  @[key] and the association it self will be returned.
.Association association_cache(string key, void|.Association as)
{
  if (!as) return _assoc_cache[key];
  return _assoc_cache[key] = as;
}

//! Default OpenID providers
private mapping(string:.Provider) providers = ([
  "google" : .Provider("google", "https://www.google.com/accounts/o8/id",
                       "ext1"),
  "yahoo"  : .Provider("yahoo", "http://open.login.yahooapis.com/openid20/"
                       "www.yahoo.com/xrds", "ax")
]);

//! Returns the available providers
mapping(string:.Provider) get_providers()
{
  return providers;
}

//! Returns the provider with @[name] if it exists.
.Provider get_provider(string name)
{
  .Provider p = providers[name];
  if (!p) error("No provider named \"%s\" exist!", name);
  return p;
}

//! Add a provider
//! 
//! @param p
void add_provider(.Provider p)
{
  providers[p->get_name()] = p;
}

//! Builds a query string from a mapping
//!
//! @param parts
string build_http_query(mapping(string:string) parts)
{
  array(string) pts = ({});
  foreach (parts; string k; string v)
    pts += ({ k + "=" + Protocols.HTTP.uri_encode(v) });

  return pts*"&";
}

//! Finds the max age from a HTTP header collection
//!
//! @param http_headers
int get_max_age(mapping http_headers)
{
  if ( string cc = http_headers["cache-control"] ) {
    sscanf(cc, "%*smax-age=%d", int max_age);
    return max_age;
  }

  return 0;
}

//! Finds the charset from a HTTP header collection
//!
//! @param http_headers
string get_charset(mapping http_headers)
{
  if ( string cc = http_headers["content-type"] ) {
    sscanf(cc, "%*scharset=%s", string charset);
    return charset;
  }

  return 0;
}

//! Tries to find the OpenID authentication URL in the XRDS document
//!
//! @param xrds_xml
string resolve_endpoint_url(string xrds_xml)
{
  TRACE(">>> Resolve endpoint url!\n");

  Node root = get_xml_root(parse_input(xrds_xml));
  string uri;
  array(Node) xrds = ({});
  foreach (root->get_children(), Node n) {
    if (n->get_node_type() != XML_ELEMENT)
      continue;

    if (lower_case(n->get_tag_name()) == "xrd")
      xrds += ({ n });
  }

  loop: foreach (xrds, Node xrd) {
    foreach (xrd->get_children(), Node n) {
      if (n->get_node_type() != XML_ELEMENT)
      	continue;

      int is_openid = 0;
      if (lower_case(n->get_tag_name()) == "service") {
      	foreach (n->get_children(), Node cn) {
      	  if (is_openid && uri)
      	    break loop;

      	  if (cn->get_node_type() != XML_ELEMENT)
      	    continue;

      	  string name = lower_case(cn->get_tag_name());
      	  if (!is_openid && name == "type") {
      	    string v = cn->value_of_node();
      	    if (sscanf(v, "%*sopenid.net%*ssignon") > 1 ||
      	        sscanf(v, "%*sopenid.net%*sauth%*sserver") > 2)
	    {
      	      is_openid = 1;
      	      continue;
      	    }
      	  }

      	  if (name == "uri") 
      	    uri = cn->value_of_node();
      	}

      	if (is_openid && uri) break loop;

      	is_openid = 0;
      	uri = 0;
      }
    }
  }
  
  return uri;
}

//! Returns the first XML element node from an XML document node.
//!
//! @param n
private Node get_xml_root(Node n)
{
  foreach (n->get_children(), Node cn)
    if (cn->get_node_type() == XML_ELEMENT)
      return cn;

  return 0;
}
