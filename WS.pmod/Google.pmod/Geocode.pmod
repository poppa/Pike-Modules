/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Google Geocoding API.
//! @url{https://developers.google.com/maps/documentation/geocoding/@}

//! Endpoint of the Google geocode service
constant endpoint = "https://maps.google.com/maps/api/geocode/";

//! Supported formats
enum Format {
  FORMAT_XML,
  FORMAT_JSON
};

//! @ignore
//  All available params to the Google service
constant ALL_PARAMS = (<
  "address",    // required if no latlng
  "latlng",     // required if no address
  "components", // optional if address is given otherwise required
  "sensor",     // required but internally set to false as default
  "bound",
  "language",
  "region"
>);

private constant FORMAT_TO_STRING = ([
  FORMAT_XML  : "xml",
  FORMAT_JSON : "json"
]);
//! @endignore

//! Do the geocoding
//!
//! @param params
//!  A mapping with params. For more in-depth descriptions see the Geocode
//!  API documentation at Google:
//!  @url{https://developers.google.com/maps/documentation/geocoding/@}
//!  @mapping
//!   @member string "address"
//!    required if no latlng
//!   @member string "latlng"
//!    required if no address
//!   @member string components
//!    optional if address is given otherwise required
//!   @member string "sensor"
//!    @tt{true|false@}. Default is @tt{false@}
//!   @member string "bound"
//!   @member string "language"
//!   @member string "region"
//!  @endmapping
//!
//! @param format
//!  XML or JSON is supported. JSON is default
string|mapping geocode(mapping(string:string) params, void|Format format)
{
  if (zero_type(format))
    format = FORMAT_JSON;

  string ep = endpoint, fmt;
  if (!(fmt = FORMAT_TO_STRING[format]))
    error("Unknown response format \"%s\"!\n", format);

  ep += fmt;

  if (!params->address && !params->latlng)
    error("Missing required parameter \"address\" or \"latlng\"!\n");

  if (params->latlng && !params->components)
    error("Missing required parameter \"components\"!\n");

  if (!params->sensor)
    params->sensor = "false";

  foreach (indices(params), string k)
    if (!ALL_PARAMS[k])
      m_delete(params, k);

  Protocols.HTTP.Query q = Protocols.HTTP.get_url(ep, params);

  if (q->status != 200)
    error("Bad status (%d) in HTTP response!\n", q->status);

  string data = q->data();

  if (format == FORMAT_JSON)
    return Standards.JSON.decode(data);

  return data;
}

//! A class representing a point on the earth.
class LatLng
{
  // Radius of the earth in kilometers
  constant R = 6371;

  //! Latitude
  float lat;

  //! Longitude
  float lng;

  //! Radius
  int radius;

  //! Constructor
  //!
  //! @param _lat
  //! @param _lng
  //! @param _radius
  //!  The radius to use when calculating @[distance_to()]. If not given
  //!  it will default to the radius of the earth @[R].
  void create(float _lat, float _lng, void|int _radius)
  {
    lat    = _lat;
    lng    = _lng;
    radius = _radius || R;
  }

  //! Calculates the distance in kilometers between the object being called
  //! and @[other].
  //!
  //! All credit for this goes to Chris Veness:
  //! http://www.movable-type.co.uk/scripts/latlon.js
  //!
  //! @param other
  float distance_to(LatLng other)
  {
    [float lat1, float lng1] = to_rad();
    [float lat2, float lng2] = other->to_rad();
    float dlat = lat2 - lat1;
    float dlng = lng2 - lng1;
    float a = sin(dlat/2) * sin(dlat/2) +
              cos(lat1)   * cos(lat2) *
              sin(dlng/2) * sin(dlng/2);

    float c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  //! Returns the radius of @[lat] and @[lng]. Always two indices where
  //! latitude is the first and longitude the second.
  array(float) to_rad()
  {
    return ({ lat * Math.pi / 180.0, lng * Math.pi / 180.0 });
  }

  //! Returns the degrees of @[lat] and @[lng]. Always two indices where
  //! latitude is the first and longitude the second.
  array(float) to_deg()
  {
    return ({ lat * 180.0 / Math.pi, lng * 180.0 / Math.pi });
  }

  //! Cast method
  //!
  //! @param how
  mixed cast(string how)
  {
    switch (how)
    {
      case "mapping": return ([ "lat" : lat, "lng" : lng ]);
      case "array": return ({ lat, lng });
    }

    error("No cast method for %O in object! ", how);
  }

  //! String formatting method
  //!
  //! @param t
  string _sprintf(int t)
  {
    return sprintf("%O(%f, %f)", object_program(this), lat, lng);
  }
}
