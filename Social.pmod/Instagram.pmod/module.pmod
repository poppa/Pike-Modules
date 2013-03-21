/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

constant API_URI = "https://api.instagram.com";

//! User Agent string for this API implementation
constant USER_AGENT = "Pike Instagram Client 0.1 (Pike "+__VERSION__+")";

string get_uri(string method)
{
  if (!has_prefix(method, "/")) method = "/" + method;
  return API_URI + "/v1" + method;
}

//! Parameter collection class
class Params
{
  inherit Social.Params;

  //! Creates a new instance of @[Params]
  //!
  //! @param args
  //!  Arbitrary number of @[Param] objects.
  void create(Param ... args)
  {
    ::create(@args);
  }
}

//! Representation of a parameter
class Param
{
  inherit Social.Param;

  //! Creates a new instance of @[Param]
  //!
  //! @param name
  //! @param value
  void create(string name, mixed value)
  {
    ::create(name, value);
  }
}
