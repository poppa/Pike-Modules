/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Fetches weather forecast from Google for a given location.

//#define DEBUG

#ifdef DEBUG
# define TRACE(X...) \
#   werror("%s:%d: %s", basename(__FILE__), __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define GET_DATA(NODE) (NODE)->get_attributes()["data"]

import Parser.XML.Tree;

// The URL to the forecast RSS
private constant base_uri = "http://www.google.com/ig/api?weather=%s";

// User agent of this class is using
private constant user_agent = "Google Weather Client (Pike "+__VERSION__+")";

//! Information about the current forecast. See @[Information].
Information info;

//! The current weather condition. See @[CurrentCondition].
CurrentCondition current;

//! Forecast conditions. The next four days. See @[ForecastCondition].
array(ForecastCondition) forecast = ({});

// Default locales
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
//!
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

//! Abstract base class
class Base
{
  protected void create(Node n)
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

//! Withholds information about a forecast
class Information
{
  inherit Base;

  //! The name of the city the forecast is from
  string city;

  //! The postal code of the city
  string postal_code;

  //! The city's latitude
  float latitude;

  //! The city's longitude
  float longitude;

  //! The date and time of the forecast
  Calendar.Second date;

  //! The current date and time
  Calendar.Second current_date;

  //! Unit system used in the foreceast
  string unit_system;

  // Callback for the date node
  void parse_forecast_date(Node n)
  {
    date = Calendar.parse("%Y-%M-%D", GET_DATA(n));
  }

  // Callback for the current date node
  void parse_current_date_time(Node n)
  {
    current_date = Calendar.parse("%Y-%M-%D %h:%m:%s %z", GET_DATA(n));
  }

  // Callback for the longitude node
  void parse_longitude_e6(Node n)
  {
    longitude = (float)GET_DATA(n);
  }

  // Cllback for the latitude node
  void parse_latitude_e6(Node n)
  {
    latitude = (float)GET_DATA(n);
  }
}

//! Base class for a condition
class Condition
{
  inherit Base;

  //! The condition
  string condition;

  //! Icon representing the condition
  string icon;

  //! Returns the name of the icon
  string get_icon_name()
  {
    return icon && basename(icon);
  }
}

//! Class representing the current conditions
class CurrentCondition
{
  inherit Condition;

  //! Temperature in fahrenheit
  int temp_f;

  //! Temperature in celcius
  int temp_c;

  //! Current humidity
  string humidity;

  //! Current wind speed
  string wind;

  // Callback for the fahrenheit node
  void parse_temp_f(Node n)
  {
    temp_f = (int)GET_DATA(n);
  }

  // Callback for the celsius node
  void parse_temp_c(Node n)
  {
    temp_c = (int)GET_DATA(n);
  }

  // Callback for the wind node
  void parse_wind_condition(Node n)
  {
    wind = (string)GET_DATA(n);
  }
}

//! Conditions of a forecast
class ForecastCondition
{
  inherit Condition;

  //! Highest temperature
  int high;

  //! Lowest temperature
  int low;

  //! Week day
  string day_of_week;
}
