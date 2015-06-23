/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! This is an API interface to Forecast.io (@url{http://forecast.io@}).
//! To use this class you need to register at Forecast.io to get an
//! API key.
//!
//! Example usage:
//!
//! @code{
//!   import Weather;
//!
//!   // Using "si" units, swedish language and skipping the blocks hourly, ...
//!   ForecastIO o = ForecastIO(API_KEY, "si", "sv", "hourly,minutely,flags");
//!
//!   // Query the forecast at longitude and latitude
//!   ForecastIO.Result r = o->forecast(58.587745, 6.192421);
//!
//!   ForecastIO.Condition cur = r->currently;
//!   write("%s %.0f°C (feels like %.0f°C)\n",
//!         cur->summary, cur->temperature, cur->apparent_temperature);
//!
//!   write("Summary: %s\n", cur->summary);
//!
//!   foreach (fc->daily_data, ForecastIO.Condition d) {
//!     write("* %s: %s %.0f°C (low: %.0f°C at %s)\n",
//!           d->time->format_ymd(),
//!           d->precip_type, d->temperature,
//!           d->min_temperature,
//!           d->min_temperature_time->format_mod());
//!   }
//! @}


//! Default URI to the Forecast.io web service
public string apiuri = "https://api.forecast.io/forecast/";

//! User API key
public string apikey;

//! Default unit
protected string _units = "auto";

//! Language to use
//! For availabe langugages, or for contributions see
//! @url{https://github.com/darkskyapp/forecast-io-translations@}
protected string _lang;

//! Exclusions
//! See @url{https://developer.forecast.io/docs/v2#options@}
protected string _excl;

//! Valid units
protected multiset valid_units = (< "auto", "us", "si", "ca", "uk" >);

//! Valid exclusion blocks
protected multiset valid_excl = (< "currently", "minutely", "hourly",
                                   "daily", "alerts", "flags" >);

//! Create a new instance
//!
//! @param api_key
//! @param units
//! @param lang
//! @param exclusions
void create(string api_key, void|string units, void|string lang,
            void|string exclusions)
{
  apikey = api_key;
  if (units) this->units = units;
  if (exclusions) this->exclusions = exclusions;
  _lang  = lang;

}

//! Get the units being used
string `units() { return _units; }

//! Set what units to use
//!
//! @param units
void `units=(string units)
{
  if (units && !valid_units[units]) {
    error("Unknown unit (%s) Expected any of %s! ",
          units, String.implode_nicely((array) valid_units, "or"));
  }

  _units = units || "auto";
}

//! Get what language is used
string `lang() { return _lang; }

//! Set what language to use.
//! For availabe langugages, or for contributions see
//! @url{https://github.com/darkskyapp/forecast-io-translations@}
void `lang=(string language) { _lang = language; }

//! Get what exclusions are set
string `exclusions() { return _excl; }

//! Set what blocks to exclude
//!
//! @param excl
//!  See @url{https://developer.forecast.io/docs/v2#options@}
void `exclusions=(string excl)
{
  if (excl) {
   foreach (excl/",", string ex) {
      if (!valid_excl[ex]) {
        error("Unknown block exclusion (%s). Expected any of %s! ",
              ex, String.implode_nicely((array)valid_excl, "or"));
      }
    }
  }

  _excl = excl;
}

//! Query for a forecast
//!
//! @param lat
//!  Latitude
//! @param lon
//!  Longitude
//! @param timestamp
//!  Optional point in time of the forecast. Unix timestamp or ISO 8601
//!  formatted date. See @url{https://developer.forecast.io/docs/v2#time_call@}
Result forecast(float lat, float lon, void|string|int timestamp)
{
  if (!apikey) error("No API KEY is set! ");

  mapping params = ([]);
  params->units = _units;

  if (_lang)  params->lang    = _lang;
  if (_excl)  params->exclude = _excl;
  if (_units) params->units   = _units;

  string uri = apiuri + apikey + "/" + lat + "," + lon;
  if (timestamp) uri += "," + timestamp;

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.get_url(uri, params);

  if (q->status != 200)
    error("Bad status (%d) in HTTP response! ", q->status);

  return Result(q->data());
}

#define GET(X) (data && data[#X])

//! Base class for results
protected class base
{
  protected mapping data;

  void create(string|mapping _data)
  {
    if (stringp(_data))
      data = Standards.JSON.decode(_data);
    else
      data = _data;
  }

  mixed cast(string how)
  {
    switch (how)
    {
      case "mapping":
        return data;
        break;

      default:
        error("Unknown cast method %O in object! ", how);
        break;
    }
  }
}

//! Result class returned from @[forecast()]
class Result
{
  inherit base;

  //! Getter for the latitude
  float `latitude() { return GET(latitude); }

  //! Getter for the longitude
  float `longitude() { return GET(longitude); }

  //! Getter for the timezone
  string `timezone() { return GET(timezone); }

  //! Getter for the timezone offset
  int `offset() { return GET(offset); }

  //! Get the current weather condition
  Condition `currently()
  {
    return data->currently && Condition(data->currently);
  }

  //! Getter for the daily conditions
  array(Condition) `daily_data()
  {
    mapping h = GET(daily) || ([]);
    return map(h->data||({}), lambda (mapping m) { return Condition(m); });
  }

  //! Getter for the current day's icon
  string `daily_icon() { return (GET(daily) || ([]))->icon; }

  //! Getter for the current day's summary
  string `daily_summary() { return (GET(daily) || ([]))->summary; }

  //! Getter for the current hour's icon
  string `hourly_icon() { return (GET(hourly) || ([]))->icon; }

  //! Getter for the current hour's summary
  string `hourly_summary() { return (GET(hourly) || ([]))->summary; }

  //! Getter for the hourly conditions
  array(Condition) `hourly_data()
  {
    mapping h = GET(hourly) || ([]);
    return map(h->data||({}), lambda (mapping m) { return Condition(m); });
  }

  //! Getter for the flags
  mapping `flags() { return GET(flags); }
}

//! Class representing a weather condition
class Condition
{
  inherit base;

  //! Getter for the temperature
  float `temperature()
  {
    if (zero_type(data->temperature))
      return GET(temperatureMax);

    return GET(temperature);
  }

  //! Getter for the apparent temperature
  float `apparent_temperature()
  {
    if (zero_type(data->apparentTemperature))
      return GET(apparentTemperatureMax);

    return GET(apparentTemperature);
  }

  //! Getter for the the sun rises
  Calendar.Second `sunrise()
  {
    return Calendar.Second("unix", GET(sunriseTime));
  }

  //! Getter for when the sun sets
  Calendar.Second `sunset()
  {
    return Calendar.Second("unix", GET(sunsetTime));
  }

  //! Getter for the moon phase
  float `moon_phase() { return GET(moonPhase); }

  //! Getter for the cloud cover
  float `cloud_cover() { return GET(cloudCover); }

  //! Getter for the dew point
  float `dew_point() { return GET(dewPoint); }

  //! Getter for the humidity
  float `humidity() { return GET(humidity); }

  //! Getter for the icon
  string `icon() { return GET(icon); }

  //! Getter for the ozone
  float `ozone() { return GET(ozone); }

  //! Getter for the preciep intencity
  float `preciep_intencity() { return GET(preciepIntencity); }

  //! Getter for the highest preciep intencity
  float `max_preciep_intencity() { return GET(preciepIntencityMax); }

  //! Getter for the lowest preciep intencity
  float `min_preciep_intencity() { return GET(preciepIntencityMin); }

  //! Getter for the preciep probability
  float `preciep_probability() { return GET(preciepProbability); }

  //! Getter for the preciep type
  string `precip_type() { return GET(precipType); }

  //! Getter for the pressure
  float `pressure() { return GET(pressure); }

  //! Getter for the summary
  string `summary() { return GET(summary); }

  //! Getter for the wind bearing
  int `wind_bearing() { return GET(windBearing); }

  //! Getter for the wind speed
  float `wind_speed() { return GET(windSpeed); }

  //! Getter for the timestamp
  int `unixtime() { return GET(time); }

  //! Getter for the timestamp as a calendar object
  Calendar.Second `time() { return Calendar.Second("unix", GET(time)); }

  //! Getter for the highest temperature
  float `max_temperature() { return GET(temperatureMax); }

  //! Getter for the lowest temperature
  float `min_temperature() { return GET(temperatureMin); }

  //! Getter for the time of the highest temperature
  Calendar.Second `max_temperature_time()
  {
    return Calendar.Second("unix", GET(temperatureMaxTime));
  }

  //! Getter for the time of the lowest temperature
  Calendar.Second `min_temperature_time()
  {
    return Calendar.Second("unix", GET(temperatureMinTime));
  }

  //! Getter for the highest apparent temperature
  float `max_apparent_temperature() { return GET(apparentTemperatureMax); }

  //! Getter for the lowest apparent temperature
  float `min_apparent_temperature() { return GET(apparentTemperatureMin); }

  //! Getter for the time of the highest apparent temperature
  Calendar.Second `max_apparent_temperature_time()
  {
    return Calendar.Second("unix", GET(apparentTemperatureMaxTime));
  }

  //! Getter for the time of the lowest apparent temperature
  Calendar.Second `min_apparent_temperature_time()
  {
    return Calendar.Second("unix", GET(apparentTemperatureMinTime));
  }
}
