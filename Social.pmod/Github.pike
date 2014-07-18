/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

inherit Social.Api : parent;

//! The base uri to the Github API
constant API_URI = "https://api.github.com";

//! Getter for the @[Any] object which is a generic object for making request
//! to the Github API
//!
//! @seealso
//!  @[Any]
Any `any()
{
  return _any || (_any = Any());
}

//! Make a generic @expr{GET@} request to the Github API.
//!
//! @param path
//!  What to request. Like @expr{me@}, @expr{me/pictures@},
//!  @expr{[some_id]/something@}.
//!
//! @param params
//! @param cb
//!  Callback for async requests
mapping get(string path, void|ParamsArg params, void|Callback cb)
{
  return `any()->get(path, params, cb);
}

//! Make a generic @expr{PUT@} request to the Github API.
//!
//! @param path
//!  What to request. Like @expr{me@}, @expr{me/pictures@},
//!  @expr{[some_id]/something@}.
//!
//! @param params
//! @param cb
//!  Callback for async requests
mapping put(string path, void|ParamsArg params, void|Callback cb)
{
  return `any()->put(path, params, cb);
}

//! Make a generic @expr{POST@} request to the Github API.
//!
//! @param path
//!  What to request. Like @expr{me@}, @expr{me/pictures@},
//!  @expr{[some_id]/something@}.
//!
//! @param params
//! @param data
//! @param cb
//!  Callback for async requests
mapping post(string path, void|ParamsArg params, void|string data,
             void|Callback cb)
{
  return `any()->post(path, params, cb);
}

//! Make a generic @expr{DELETE@} request to the Github API.
//!
//! @param path
//!  What to request. Like @expr{me@}, @expr{me/pictures@},
//!  @expr{[some_id]/something@}.
//!
//! @param params
//! @param cb
//!  Callback for async requests
mapping delete(string path, void|ParamsArg params, void|Callback cb)
{
  return `any()->delete(path, params, cb);
}

//! Default parameters that goes with every call
protected mapping default_params()
{
  return ([ "format" : "json" ]);
}

// Just a convenience class
protected class Method
{
  inherit Social.Api.Method;

  //! Internal convenience method
  public mixed get(string s, void|ParamsArg p, void|Callback cb)
  {
    return parent::get(get_uri(METHOD_PATH + s), p, cb);
  }

  //! Internal convenience method
  public mixed put(string s, void|ParamsArg p, void|Callback cb)
  {
    return parent::put(get_uri(METHOD_PATH + s), p, cb);
  }

  //! Internal convenience method
  public mixed post(string s, void|ParamsArg p, void|Callback cb)
  {
    return parent::post(get_uri(METHOD_PATH + s), p, 0, cb);
  }

  //! Internal convenience method
  public mixed delete(string s, void|ParamsArg p, void|Callback cb)
  {
    return parent::delete(get_uri(METHOD_PATH + s), p, cb);
  }
}

//! A generic wrapper around @[Method]
protected class Any
{
  inherit Method;
  protected constant METHOD_PATH = "/";
}

private Any _any;

//! Authorization class.
//!
//! @seealso
//!  @[Social.Api.Authorization]
class Authorization
{
  inherit Social.Api.Authorization;

  constant OAUTH_AUTH_URI  = "https://github.com/login/oauth/authorize";
  constant OAUTH_TOKEN_URI = "https://github.com/login/oauth/access_token";

  enum Scopes {
    SCOPE_REPO = "repo",
    SCOPE_GIST = "gist",
    SCOPE_USER = "user",
    SCOPE_USER_EMAIL = "user:email",
    SCOPE_USER_FOLLOW = "user:follow",
    SCOPE_PUBLIC_REPO = "public_repo",
    SCOPE_REPO_DEPLOYMENT = "repo_deployment",
    SCOPE_REPO_STATUS = "repo:status",
    SCOPE_DELETE_REPO = "delete_repo",
    SCOPE_NOTIFICATIONS = "notifications",
    SCOPE_READ_REPO_HOOK = "read:repo_hook",
    SCOPE_WRITE_REPO_HOOK = "write:repo_hook",
    SCOPE_ADMIN_REPO_HOOK = "admin:repo_hook",
    SCOPE_READ_ORG = "read:org",
    SCOPE_WRITE_ORG = "write:org",
    SCOPE_ADMIN_ORG = "admin:org",
    SCOPE_READ_PUBLIC_KEY = "read:public_key",
    SCOPE_WRITE_PUBLIC_KEY = "write:public_key",
    SCOPE_ADMIN_PUBLIC_KEY = "admin:public_key"
  };

  protected multiset valid_scopes = (<
    SCOPE_REPO,
    SCOPE_GIST,
    SCOPE_USER,
    SCOPE_USER_EMAIL,
    SCOPE_USER_FOLLOW,
    SCOPE_PUBLIC_REPO,
    SCOPE_REPO_DEPLOYMENT,
    SCOPE_REPO_STATUS,
    SCOPE_DELETE_REPO,
    SCOPE_NOTIFICATIONS,
    SCOPE_READ_REPO_HOOK,
    SCOPE_WRITE_REPO_HOOK,
    SCOPE_ADMIN_REPO_HOOK,
    SCOPE_READ_ORG,
    SCOPE_WRITE_ORG,
    SCOPE_ADMIN_ORG,
    SCOPE_READ_PUBLIC_KEY,
    SCOPE_WRITE_PUBLIC_KEY,
    SCOPE_ADMIN_PUBLIC_KEY
  >);
}
