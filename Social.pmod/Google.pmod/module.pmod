/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Abstract API for Google services.
class Api
{
  inherit Social.Api : parent;

  protected constant API_URI = "";

  //! Creates a new Api instance
  //!
  //! @seealso
  //!  @[Social.Api]
  //!
  //! @param client_id
  //!  The application ID
  //!
  //! @param client_secret
  //!  The application secret
  //!
  //! @param redirect_uri
  //!  Where the authorization page should redirect back to. This must be
  //!  fully qualified domain name.
  //!
  //! @param scope
  //!  Extended permissions to use for this authorization.
  void create(string client_id, string client_secret, void|string redirect_uri,
              string|void scope)
  {
    ::create(client_id, client_secret, redirect_uri, scope);
  }

  class Authorization
  {
    inherit Social.Api.Authorization;

    constant OAUTH_AUTH_URI  = "https://accounts.google.com/o/oauth2/auth";
    constant OAUTH_TOKEN_URI = "https://accounts.google.com/o/oauth2/token";
  }

  protected string get_uri(string s)
  {
    if (sizeof(API_URI)) {
      if (has_suffix(API_URI, "/") && s[0] == '/')
        s = s[1..];
      else if (s[0] != '/')
        s = "/" + s;

      return API_URI + s;
    }

    error ("Constant API_URI is not set!\n");
  }

  // Just a convenience class
  protected class Method
  {
    inherit Social.Api.Method;

    //! Internal convenience method
    protected mixed _get(string s, void|ParamsArg p, void|Callback cb)
    {
      return parent::get(get_uri(METHOD_PATH + s), p, cb);
    }

    //! Internal convenience method
    protected mixed _post(string s, void|ParamsArg p, void|Callback cb)
    {
      return parent::post(get_uri(METHOD_PATH + s), p, 0, cb);
    }

    //! Internal convenience method
    protected mixed _delete(string s, void|ParamsArg p, void|Callback cb)
    {
      return parent::delete(get_uri(METHOD_PATH + s), p, cb);
    }
  }
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
