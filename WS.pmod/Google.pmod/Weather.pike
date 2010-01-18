/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{WS.Google.Weather class@}
//!
//! Fetches weather forecast from Google for a given location.
//!
//! Copyright © 2009, Pontus Östlund - @url{http://www.poppa.se@}
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

#define DEBUG

#ifdef DEBUG
# define TRACE(X...) \
#   werror("%s:%d: %s", basename(__FILE__), __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define GET_DATA(NODE) (NODE)->get_attributes()["data"]

import Parser.XML.Tree;

//! The URL to the forecast RSS
private constant base_uri = "http://www.google.com/ig/api?weather=%s";

//! User agent of this class is using
private constant user_agent = "Google Weather Client (Pike "+__VERSION__+")";

//! Information about the current forecast. The the @[Information] class
//! for more info
Information info;

//! The current weather condition. See @[CurrentCondition].
CurrentCondition current;

//! Forecast conditions. The next four days. See @[ForecastCondition].
array(ForecastCondition) forecast = ({});

//! Default locales
private multiset(string) locale = (< "en", "en-us" >);

//! Creates a new @[Weather] object
//!
//! @param city
//!  The city to fetch the forecast for. Like @tt{new york, ny@} or 
//!  @tt{stockholm@}.
//! @param _locale
//!  Locale of the preferred language the response should be in.
//!  Like @tt{sv@} for Swedish or @tt{no@} for Norwegian.
void create(string city, void|string _locale)
{
  if (_locale)
    locale = (< _locale >) + locale;

  parse(city);
}

//! Fetches and parses the requested forecast.
//!
//! @throws
//!  An error if the HTTP request fails or if the XML parsing fails
//! @param city
private void parse(string city)
{
  string url = Protocols.HTTP.uri_encode_invalids(sprintf(base_uri, city));
  mapping eh = ([
    "User-Agent"      : user_agent,
    "Accept-Language" : ((array)locale)*","
  ]);

  Protocols.HTTP.Query q = Protocols.HTTP.get_url(url, 0, eh);
  if (q->status != 200)
    error("Bad status \"%d\" in Google.download()\n", q->status);

  parse_xml(q->data());
}

private void parse_xml(string xml)
{
  Node root = parse_input(xml);
  if (root && sizeof(root) > 0) {
    if (root[1]->get_tag_name() != "xml_api_reply")
      error("Bad XML in response. Root node name isn't \"xml_api_reply\"!");

    root = root[1]->get_children()[0];
    if (root->get_tag_name() != "weather")
      error("Bad XML in response. No \"weather\" node was found!");

    foreach (root->get_children(), Node node) {
      if (node->get_node_type() != XML_ELEMENT)
      	continue;

      string tn = node->get_tag_name();

      switch (tn)
      {
      	case "problem_cause": 
	  error("An error occured: %s! ", GET_DATA(node));
	  break;

	case "forecast_information":
	  info = Information(node);
	  break;

	case "current_conditions":
	  current = CurrentCondition(node);
	  break;

	case "forecast_conditions":
	  forecast += ({ ForecastCondition(node) });
	  break;
      }
    }
  }
}

private class Base
{
  void create(Node n)
  {
    n && n->iterate_children(
      lambda (Node cn) {
      	if (cn->get_node_type() != XML_ELEMENT)
      	  return;

      	string tn = cn->get_tag_name();
      	if ( function fn = this["parse_" + tn] )
      	  fn(cn);
      	else if (object_variablep(this ,tn))
      	  parse_default(cn);
      }
    );
  }

  protected void parse_default(Node n)
  {
    this[n->get_tag_name()] = (string)GET_DATA(n);
  }
}

class Information
{
  inherit Base;

  string city;
  string postal_code;
  float  latitude;
  float  longitude;
  Calendar.Second date;
  Calendar.Second current_date;
  string unit_system;

  void parse_forecast_date(Node n)
  {
    date = Calendar.parse("%Y-%M-%D", GET_DATA(n));
  }

  void parse_current_date_time(Node n)
  {
    current_date = Calendar.parse("%Y-%M-%D %h:%m:%s %z", GET_DATA(n));
  }

  void parse_longitude_e6(Node n)
  {
    longitude = (float)GET_DATA(n);
  }

  void parse_latitude_e6(Node n)
  {
    latitude = (float)GET_DATA(n);
  }
}

private class Condition
{
  inherit Base;

  string condition;
  string icon;
  
  string get_icon_name()
  {
    return icon && basename(icon);
  }
}

class CurrentCondition
{
  inherit Condition;

  int temp_f;
  int temp_c;
  string humidity;
  string wind;

  void parse_temp_f(Node n)
  {
    temp_f = (int)GET_DATA(n);
  }

  void parse_temp_c(Node n)
  {
    temp_c = (int)GET_DATA(n);
  }

  void parse_wind_condition(Node n)
  {
    wind = (string)GET_DATA(n);
  }
}

class ForecastCondition
{
  inherit Condition;

  int high;
  int low;
  string day_of_week;
}
