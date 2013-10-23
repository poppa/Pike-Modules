/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Module for fetching data from a Google Analytics account

import Parser.XML.Tree;

//! The Analytics API version being used
constant API_VERSION = "2";

//! Type of account
constant ACCOUNT_TYPE = "GOOGLE";

//! Name of service
constant SERVICE = "analytics";

//! URL for login
constant LOGIN_ENDPOINT = "https://www.google.com/accounts/ClientLogin";

//! URL for fetching data
constant DATA_ENDPOINT = "https://www.google.com/analytics/feeds/data";

//! URL for getting feeds
constant FEED_ENDPOINT = "https://www.google.com/analytics/feeds/accounts/"
                         "default";

//! This class handles authentication against and data fetching from Google
//! Analytics. This class is intended to be use by web clients.
class Api
{
  //! Hash from authentication. Not actually used.
  protected string sid;

  //! Hash from authentication. Not actually used
  protected string lsid;

  //! The authentication session.
  protected string auth;

  //! Errors from a response is stored here.
  //!
  //! @mapping
  //!  @member string "domain"
  //!   The error domain
  //!  @member string "code"
  //!   The error code
  //!  @member string "internalreason"
  //!   The error description
  //! @endmapping
  protected mapping gerror;

  //! Authenticate the current user
  int(0..1) authenticate()
  {
    error("Not implemented yet! Use the DesktopApi instead.\n");
  }

  //! Returns the list of available accounts
  //!
  //! @param prettyprint
  //!  If @tt{1@} the returned XML document will be formatted
  string get_feed(void|int(0..1) prettyprint)
  {
    mapping h = ([ "prettyprint" : prettyprint ? "true" : "false" ]);
    Protocols.HTTP.Query q = Protocols.HTTP.get_url(FEED_ENDPOINT, h,
                                                    default_headers());

    if (q->status == 200)
      return q->data();

    return 0;
  }

  //! Returns the error mapping if any
  mapping get_error()
  {
    return gerror;
  }

  //! Fetches report data from Google Analytics
  //!
  //! @seealso
  //!  @url{http://code.google.com/intl/sv-SE/apis/analytics/docs/gdata/@
  //!gdataReferenceDataFeed.html#dataRequest@}
  //!
  //! @param table_id
  //!  The ID of the site in Google Analytics, i.e: @tt{ga:123456@}
  //! @param params
  //!  Mapping of parameters for the call to the API. The mapping can contain
  //!  the following indices
  //!  @mapping
  //!   @member string "start-date"
  //!    ISO formatted date from when to fetch data
  //!   @member string "end-date"
  //!   @member string "dimensions"
  //!   @member string "metrics"
  //!   @member string "sort"
  //!   @member string "segment"
  //!   @member int    "start-index"
  //!   @member int    "max-results"
  //!   @member string "filter"
  //!   @member string "prettyprint"
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
    if (q->status != 200) {
      Node xroot = parse_input(q->data());
      xroot && xroot[0]->walk_inorder(
        lambda(Node n) {
          if (n->get_tag_name() == "error") {
            gerror = ([]);
            foreach (n->get_children(), Node en) {
              if (en->get_node_type() == XML_ELEMENT) {
                gerror[lower_case(en->get_tag_name())] = en->value_of_node();
              }
            }
          }
        }
      );

      if (gerror)
        error("%s: %s! ", gerror->code, gerror->internalreason);
      else
        error("Bad HTTP status code (%d) in response! ", q->status);
    }

    return q->data();
  }

  //! Created the default headers mapping
  protected mapping default_headers()
  {
    return ([
      "Authorization" : "GoogleLogin Auth=" + auth,
      "GData-Version" : API_VERSION
    ]);
  }
}

//! This class handles authentication against and data fetching from Google
//! Analytics. This class is intended to be use by non-web clients.
class DesktopApi
{
  inherit Api;

  //! Authenticate a user
  //!
  //! @param email
  //! @param password
  //! @param source
  //!  This is an abritrary string which identifies the current client
  //!  implementation. Could be something like: @tt{my-ga-client-v0.1@}.
  //!
  //! @returns
  //!  @tt{1@} on success, @tt{0@} otherwise.
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

//! This class handles parsing of a successful response from Google Analytics.
//! Some generic results, from the top level in the XML document, will populate
//! this object and all @tt{entry@} nodes will be parsed - into a mapping - and
//! put in the array @[DataParser()->rows].
//!
//! If this class is inherited and a method, prefixed with @tt{_@}
//! (an underscore), exists in the inherited class with the same name as a node
//! in the XML document, that method will be called with the XML node as
//! argument.
//!
//! @code
//!   class GData {
//!     inherit DataParser;
//!
//!     void _entry(Node n) {
//!       werror("Got entry node: %O\n", n);
//!     }
//!   }
//! @endcode
class DataParser
{
  //! Array of entries (i.e. the data nodes of the document)
  array(mapping) rows = ({});

  //! Contains aggregated results of the @tt{metric@} parameter
  mapping aggregates = ([]);

  //! The id is the URL of the report at Google Analytics.
  string id;

  //! The title of the report
  string title;

  //! Total results of the report
  int total_results;

  //! Starts index (page) of the report
  int start_index;

  //! Items displayed per page in the report
  int items_per_page;

  //! When the report was last updated
  Calendar.Second updated;

  //! The start date of the report
  Calendar.Day start_date;

  //! The end date of the report
  Calendar.Day end_date;

  //! Parsed the report XML and populates this object
  //!
  //! @param data
  //!  The result of a successful call to @[Api()->get_data()].
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

  // Handles the @tt{aggregates@} node in the XML document.
  // Consider protected, only used internally.
  //
  // @param n
  void _aggregates(Node n)
  {
    foreach (n->get_children(), Node cn) {
      if (cn->get_tag_name() == "metric") {
        mapping a = cn->get_attributes();
        sscanf(a->name, "%*s:%s", a->name);
        a->name = lower_case(a->name);
        switch (a->type)
        {
          case "integer": aggregates[a->name] = (int)a->value;   break;
          case "float":   aggregates[a->name] = (float)a->value; break;
          default:        aggregates[a->name] = a->value;        break;
        }
      }
    }
  }

  // Handles the @tt{entry@} nodes in the XML document.
  // Consider protected, only used internally.
  //
  // @param n
  void _entry(Node n)
  {
    if (n->get_attributes()["gd:kind"] == "analytics#datarow") {
      mapping m = ([]);
      foreach (n->get_children(), Node cn) {
        if ( cn->get_node_type() == XML_ELEMENT) {
          mapping a = cn->get_attributes();
          if (string val = a->value) {
            sscanf(a->name, "%*s:%s", a->name);
            switch (a->type)
            {
              case "integer": m[lower_case(a->name)] = (int)val;   break;
              case "float":   m[lower_case(a->name)] = (float)val; break;
              default:        m[lower_case(a->name)] = val;        break;
            }
          }
        }
      }

      rows += ({ m });
    }
  }
}
