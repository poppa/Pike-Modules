/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Google Analytics API

//! API base URI.
protected constant API_URI = "https://www.googleapis.com/analytics/v3";

inherit .Api : parent;

//! Getter for the @[Core] API
Core `core()
{
  return _core || (_core = Core());
}

//! Getter for the @[RealTime] API
RealTime `realtime()
{
  return _realtime || (_realtime = RealTime());
}

//! Getter for the @[Management] API
Management `management()
{
  return _management || (_management = Management());
}

//! Interface to the Google Analytics core API
class Core
{
  inherit Method;

  protected constant METHOD_PATH = "/data/ga";

  mixed get(mapping params, void|Callback cb)
  {
    return _get("", params, cb);
  }
}

//! Interface to the Google Analytics realtime API
class RealTime
{
  inherit Method;

  protected constant METHOD_PATH = "/data/realtime";

  mixed get(mapping params, void|Callback cb)
  {
    return _get("", params, cb);
  }
}

//! Interface to the Google Analytics managment API
class Management
{
  inherit Method;

  protected constant METHOD_PATH = "/management";

  mixed account_summaries(void|ParamsArg params, void|Callback cb)
  {
    return _get("/accountSummaries", params, cb);
  }
}

protected Core _core;
protected RealTime _realtime;
protected Management _management;

//! Authorization class.
//!
//! @seealso
//!  @[Social.Api.Authorization]
class Authorization
{
  inherit  .Api.Authorization;

  //! Authentication scopes
  constant SCOPE_RO = "https://www.googleapis.com/auth/analytics.readonly";
  constant SCOPE_RW = "https://www.googleapis.com/auth/analytics";
  constant SCOPE_EDIT = "https://www.googleapis.com/auth/analytics.edit";
  constant SCOPE_MANAGE_USERS =
    "https://www.googleapis.com/auth/analytics.manage.users";
  constant SCOPE_MANAGE_USERS_RO =
    "https://www.googleapis.com/auth/analytics.manage.users.readonly";

  //! All valid scopes
  protected multiset valid_scopes = (<
    SCOPE_RO, SCOPE_RW, SCOPE_EDIT, SCOPE_MANAGE_USERS,
    SCOPE_MANAGE_USERS_RO >);

  //! Default scope
  protected string _scope = SCOPE_RO;
}
