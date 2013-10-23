/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! This class fetches weather forecast from Yahoo.

import Parser.XML.Tree;

//! URL to the forecast feed
constant BASE_URL = "http://weather.yahooapis.com/forecastrss";

//! URL to small condition image
constant SMALL_IMG_URL = "http://l.yimg.com/a/i/us/nws/weather/gr/%ss.png";

//! URL to large condition image
constant LARGE_IMG_URL = "http://l.yimg.com/a/i/us/nws/weather/gr/%%s%s.png";

//! Represent temperature in celcius
constant CELSIUS = 1;

//! Represent temperature in fahrenheit
constant FAHRENHEIT = 2;

//! Condition codes to text mapping
constant CONDITION_CODES = ([
     "0" : "tornado",
     "1" : "tropical storm",
     "2" : "hurricane",
     "3" : "severe thunderstorms",
     "4" : "thunderstorms",
     "5" : "mixed rain and snow",
     "6" : "mixed rain and sleet",
     "7" : "mixed snow and sleet",
     "8" : "freezing drizzle",
     "9" : "drizzle",
    "10" : "freezing rain",
    "11" : "showers",
    "12" : "showers",
    "13" : "snow flurries",
    "14" : "light snow showers",
    "15" : "blowing snow",
    "16" : "snow",
    "17" : "hail",
    "18" : "sleet",
    "19" : "dust",
    "20" : "foggy",
    "21" : "haze",
    "22" : "smoky",
    "23" : "blustery",
    "24" : "windy",
    "25" : "cold",
    "26" : "cloudy",
    "27" : "mostly cloudy (night)",
    "28" : "mostly cloudy (day)",
    "29" : "partly cloudy (night)",
    "30" : "partly cloudy (day)",
    "31" : "clear (night)",
    "32" : "sunny",
    "33" : "fair (night)",
    "34" : "fair (day)",
    "35" : "mixed rain and hail",
    "36" : "hot",
    "37" : "isolated thunderstorms",
    "38" : "scattered thunderstorms",
    "39" : "scattered thunderstorms",
    "40" : "scattered showers",
    "41" : "heavy snow",
    "42" : "scattered snow showers",
    "43" : "heavy snow",
    "44" : "partly cloudy",
    "45" : "thundershowers",
    "46" : "snow showers",
    "47" : "isolated thundershowers",
  "3200" : "not available"
]);

//! Storage class for parsed data
private YWeather weather = YWeather();

//! Location to fetch forecast for
private string location;

//! Degrees unit, @[CELSIUS] or @[FAHRENHEIT]
private string unit;

//! Time to live for the feed
private int ttl = 0;

//! Creates a new instance of @[Social.Yahoo.Forecast()]
//!
//! @param _location
//!  The location ID or US zip code. See @url{http://weather.yahoo.com/@}
//! @param _unit
//!  Either @[CELSIUS] or @[FAHRENHEIT]. Default is @[CELSIUS]
void create(string _location, void|string|int _unit)
{
  location = _location;

  if (zero_type(_unit))
    unit = "c";
  else if (stringp(_unit))
    unit = (< "f", "c" >)[_unit] && _unit || "c";
  else if(intp(_unit))
    unit = _unit == FAHRENHEIT ? "f" : "c";
}

//! Fetches and parses the forecast feed
void parse()
{
  mapping vars = ([ "p" : location, "u" : unit ]);
  Protocols.HTTP.Query q = Protocols.HTTP.get_url(BASE_URL, vars);
  if (q->status != 200)
    return;

  parse_xml(q->data());
}

//! Returns the mapping of tomorrow's forecast
mapping tomorrow()
{
  return sizeof(weather->forecast) && weather->forecast[0];
}

//! Returns the mapping of the day after tomorrow's forecast
mapping day_after_tomorrow()
{
  return sizeof(weather->forecast) > 1 && weather->forecast[1];
}

//! Returns the url to the image representing the condition code
//!
//! @param size
//!  Valid values are small or large
//! @param condition_code
string condition_img_url(void|string size, void|string condition_code)
{
  string url = get_image_string(size);
  return sprintf(url, condition_code||weather->condition->code);
}

//! Returns an image tag of the image representing the condition code
//!
//! @param size
//!  Valid values are small or large
//! @param condition_code
string condition_img(void|string size, void|string condition_code)
{
  string url = condition_img_url(size, condition_code);
  return sprintf("<img src='%s' alt='%s' title='' />",
                 url, weather->condition->text);
}

//! Returns the "time to live" for the current feed
int time_to_live()
{
  return ttl;
}

//! Arrow index lookup
//!
//! @param key
mixed `->(string key)
{
  if ( this[key] )
    return this[key];

  return weather[key];
}

//! String format
string _sprintf(int t)
{
  return t == 'O' && sprintf("Forecast(%O, %O)", location, unit);
}

// Parses the RSS feed and populates the @[weather] object
private void parse_xml(string xml)
{
  Node root = parse_input(xml);

  root && root[1][1]->iterate_children(
    lambda (Node n) {
      if (n->get_node_type() != XML_ELEMENT)
        return;

      switch (n->count_children())
      {
        case 0: /* Weather nodes */
          if (has_prefix(n->get_full_name(), "yweather"))
            weather[n->get_tag_name()] = n->get_attributes();

          break;

        case 1: /* General RSS nodes */
          if (n->get_tag_name() == "ttl")
            ttl = (int)n->value_of_node();
          break;

        default: /* Item, Image */
          if (n->get_tag_name() == "item") {
            foreach (n->get_children(), Node cn) {
              if (cn->get_node_type() != XML_ELEMENT)
                continue;

              if (has_prefix(cn->get_full_name(), "yweather")) {
                if (cn->get_tag_name() == "forecast")
                  weather->forecast += ({ cn->get_attributes() });
                else
                  weather[cn->get_tag_name()] = cn->get_attributes();
              }
              else if (has_prefix(cn->get_full_name(), "geo"))
                weather->geo[cn->get_tag_name()] = cn->value_of_node();
            }
          }
      }
    }
  );
}

//! Returns the image string for @[size]
//!
//! @param size
//!  huge, large or small
private string get_image_string(string size)
{
  size = lower_case(size || "large");

  switch (lower_case(size))
  {
    default: /* Fallthrough */
    case "large": return sprintf(LARGE_IMG_URL, is_night() ? "n" : "d");
    case "small": return SMALL_IMG_URL;
  }
}

//! Returns @tt{1@} if the current time is between sunset and sunrise
int is_night()
{
  string now  = Calendar.now()->format_mod();
  string set  = normalize_time(weather->astronomy->sunset);
  string rise = normalize_time(weather->astronomy->sunrise);

  return now < set && now < rise;
}

//! Turns the stupid pm/am into 24h format
//!
//! @param t
//!  Time as string @tt{hh:mm [am/pm]@}.
//! @param retobj
//!  if @tt{1@} the @tt{Calendar.Minute@} object will be returned. Else
//!  a 24h string representation will be returned.
string|Calendar.Minute normalize_time(string t, void|int(0..1) retobj)
{
  Calendar.Minute c;
  catch (c = Calendar.parse("%h:%m %p", t));
  if (!c) return t;
  return retobj ? c : c->format_mod();
}

//! Converts a date string into a Calendar.Second.
//!
//! @param date
//!   A string reprsentation of a date.
//! @param retobj
//!   If @tt{1@} the @tt{Calendar.Second@} object will be returned
//!
//! @returns
//!  Either an ISO formatted date string or the @tt{Calendar.Second@} object if
//!  @[retobj] is @tt{1@}. If no conversion can be made @[date] will be
//!  returned.
string|Calendar.Second strtotime(string date, int|void retobj) // {{{
{
  if (!date || !sizeof(date))
    return 0;

  Calendar.Second cdate;

  string fmt = "%e, %D %M %Y %h:%m %p %z";
  catch { cdate = Calendar.parse(fmt, date); };
  if (cdate) return retobj ? cdate : cdate->format_time();

  fmt = "%e, %D %M %Y %h:%m:%s %z";
  catch { cdate = Calendar.parse(fmt, date); };
  if (cdate) return retobj ? cdate : cdate->format_time();

  fmt = "%Y-%M-%D%*[T ]%h:%m:%s";
  date = replace(date, "Z", "");
  catch { cdate = Calendar.parse(fmt+"%z", date); };
  if (cdate) return retobj ? cdate : cdate->format_time();

  catch { cdate = Calendar.parse(fmt, date); };
  if (cdate) return retobj ? cdate : cdate->format_time();

  catch { cdate = Calendar.parse("%Y-%M-%D", date); };
  if (cdate) return retobj ? cdate : cdate->format_time();

  werror("Unknown date format: %s", date);

  return date;
} // }}}

private class YWeather
{
  mapping location;
  mapping units;
  mapping wind;
  mapping atmosphere;
  mapping astronomy;
  mapping condition;
  mapping geo = ([ "long" : 0, "lat" : 0 ]);
  array   forecast = ({});
}
