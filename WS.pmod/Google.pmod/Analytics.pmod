/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Google Analytics@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Analytics.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Analytics.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Analytics.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

import Parser.XML.Tree;

constant API_VERSION    = "2";
constant ACCOUNT_TYPE   = "GOOGLE";
constant SERVICE        = "analytics";
constant LOGIN_ENDPOINT = "https://www.google.com/accounts/ClientLogin";
constant DATA_ENDPOINT  = "https://www.google.com/analytics/feeds/data";
constant FEED_ENDPOINT  = "https://www.google.com/analytics/feeds/accounts"
			  "/default";

//! Use from web clients
class Api
{
  protected string sid;
  protected string lsid;
  protected string auth;

  int(0..1) authenticate()
  {
    error("Not implemented yet! ");
  }

  string get_feed(void|int(0..1) prettyprint)
  {
    mapping h = ([ "prettyprint" : prettyprint ? "true" : "false" ]);
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(FEED_ENDPOINT, h,
                                                    default_headers());

    if (q->status == 200)
      return q->data();

    return 0;
  }

  //! Fetches report data from Google Analytics
  //!
  //! @seealso http://code.google.com/intl/sv-SE/apis/analytics/docs/gdata/ \
  //!          gdataReferenceDataFeed.html#dataRequest
  //!
  //! @param table_id
  //!  The ID of the site in Google Analytics, i.e: ga:123456
  //! @param params
  //!  @mapping
  //!   @item start-date
  //!   @item end-date
  //!   @item dimensions
  //!   @item metrics
  //!   @item sort
  //!   @item segment
  //!   @item start-index
  //!   @item max-results
  //!   @item filter
  //!   @item prettyprint
  //!  @endmapping
  string get_data(string table_id, mapping params)
  {
    params = params||([]);
    params["ids"] = table_id;
    if (!params["ids"] || !sizeof( params["ids"] )) {
      error("Missing required argument \"ids\". This should be the accound ID "
            "of the site to fetch data for, e.g: \"ga:123456\"! ");
    }

    if ( !params["start-date"] ) {
      Calendar.Second now  = Calendar.now();
      now = now-(now->day()-1);
      Calendar.Second then = now - (now->month()-1) + (now->day()+1);
      params["start-date"] = then->format_ymd();
      params["end-date"]   = now->format_ymd();
    }

    if ( !params["end-date"] ) {
      error("Missing \"end-date\" parameter. If \"start-date\" is given "
            "\"end-date\" must also be given! ");
    }

    if ( !params["dimensions"] )
      params["dimensions"] = "ga:source,ga:medium";

    if ( !params["metrics"] )
      params["metrics"] = "ga:visits";

    Protocols.HTTP.Query q = Protocols.HTTP.get_url(DATA_ENDPOINT, params,
                                                    default_headers());
    if (q->status != 200)
      error("Bad HTTP status code (%d) in response! ", q->status);

    return q->data();
  }

  protected mapping default_headers()
  {
    return ([
      "Authorization" : "GoogleLogin Auth=" + auth,
      "GData-Version" : API_VERSION
    ]);
  }
}

//! Use from non-web clients
class DesktopApi
{
  inherit Api;

  int(0..1) authenticate(string email, string password, string source)
  {
    mapping(string:string) vars = ([
      "accountType" : ACCOUNT_TYPE,
      "service"     : SERVICE,
      "Email"       : email,
      "Passwd"      : password,
      "source"      : source
    ]);

    Protocols.HTTP.Query q = Protocols.HTTP.post_url(LOGIN_ENDPOINT, vars);

    if (q->status == 200) {
      foreach (q->data()/"\n", string line) {
      	if (sscanf(line, "%s=%s", string key, string val) == 2) {
	  switch (lower_case(key))
	  {
	    case "lsid": lsid = val; break;
	    case "sid":  sid  = val; break;
	    case "auth": auth = val; break;
	  }
	}
      }
      return 1;
    }

    return 0;
  }
}

class DataParser
{
  string id;
  string title;
  int total_results;
  int start_index;
  int items_per_page;

  Calendar.Second updated;
  Calendar.Day start_date;
  Calendar.Day end_date;

  mixed parse(string data)
  {
    Node root = parse_input(data);
    
    foreach (root->get_children(), Node n) {
      if (n->get_node_type() == XML_ELEMENT) {
      	root = n;
      	break;
      }
    }

    if (!root)
      error("Unable to find XML root node! ");

    root->walk_inorder(
      lambda(Node cn) {
      	if (cn->get_node_type() == XML_ELEMENT) {
	  string n = cn->get_tag_name();
	  if (!id && n == "id") {
	    id = cn->value_of_node();
	    return;
	  }
	  else if (!title && n == "title") {
	    title = cn->value_of_node();
	    return;
	  }
	  else if (!updated && n == "updated") {
	    updated = Calendar.parse("%Y-%M-%DT%h:%m:%s.%f%z", 
	                             cn->value_of_node());
	    return;
	  }
	  else if (!total_results && n == "totalResults") {
	    total_results = (int)cn->value_of_node();
	    return;
	  }
	  else if (!start_index && n == "startIndex") {
	    start_index = (int)cn->value_of_node();
	    return;
	  }
	  else if (!items_per_page && n == "itemsPerPage") {
	    items_per_page = (int)cn->value_of_node();
	    return;
	  }
	  else if (!start_date && n == "startDate") {
	    start_date = Calendar.parse("%Y-%M-%D", cn->value_of_node());
	    return;
	  }
	  else if (!end_date && n == "endDate") {
	    end_date = Calendar.parse("%Y-%M-%D", cn->value_of_node());
	    return;
	  }

	  if ( function f = this["_" + n] )
	    return call_function(f, cn);
	}
      }
    );
  }

  void dump_members()
  {
    string out = sprintf("%O(\n    ", object_program(this));
    array(string) mems = ({});
    foreach (sort(indices(this)), string key) {
      if (object_variablep(this, key))
	mems += ({ key + "=" + sprintf( "%O", this[key] ) });
    }

    werror("%s\n", out + (mems*"\n    ") + "\n)");
  }
}
