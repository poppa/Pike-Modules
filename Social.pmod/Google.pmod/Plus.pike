/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Google+ API

//! API base URI.
protected constant API_URI = "https://www.googleapis.com/plus/v1";

inherit .Api : parent;

//! Getter for the @[People] object which has methods for all @expr{people@}
//! related Google+ API methods.
//!
//! @seealso
//!  @url{https://developers.google.com/+/api/latest/people@}
People `people()
{
  return _people || (_people = People());
}

//! Getter for the @[Activities] object which has methods for all
//! @expr{activities@} related Google+ API methods.
//!
//! @seealso
//!  @url{https://developers.google.com/+/api/latest/activities@}
Activities `activities()
{
  return _activities || (_activities = Activities());
}

//! Class implementing the Google+ People API.
//! @url{https://developers.google.com/+/api/latest/people@}
//!
//! Retreive an instance of this class through the
//! @[Social.Google.Plus()->people] property
class People
{
  inherit Method;
  protected constant METHOD_PATH = "/people/";

  //! Get info ablut a person.
  //!
  //! @param user_id
  //!  If empty the currently authenticated user will be fetched.
  //! @param cb
  //!  Callback for async request
  mapping get(void|string user_id, void|Callback cb)
  {
    return _get (user_id||"me", 0, cb);
  }

  //! List all of the people in the specified @[collection].
  //!
  //! @param user_id
  //!  If empty the currently authenticated user will be used.
  //!
  //! @param collection
  //!  If empty "public" activities will be listed. Acceptable values are:
  //!  @ul
  //!   @item "public"
  //!    The list of people who this user has added to one or more circles,
  //!    limited to the circles visible to the requesting application.
  //!  @endul
  //!
  //! @param params
  //!  @mapping
  //!   @member int "maxResult"
  //!    Max number of items ti list
  //!   @member string "orderBy"
  //!    The order to return people in. Acceptable values are:
  //!    @ul
  //!     @item "alphabetical"
  //!      Order the people by their display name.
  //!     @item "best"
  //!      Order people based on the relevence to the viewer.
  //!    @endul
  //!   @member string "pageToken"
  //!    The continuation token, which is used to page through large result
  //!    sets. To get the next page of results, set this parameter to the value
  //!    of @expr{nextPageToken@} from the previous response.
  //!  @endmapping
  //!
  //! @param cb
  //!  Callback for async request
  mapping list(void|string user_id, void|string collection,
               void|ParamsArg params, void|Callback cb)
  {
    return _get((user_id||"me") + "/activities/" + (collection||"public"),
                params, cb);
  }
}

//! Class implementing the Google+ Activities API.
//! @url{https://developers.google.com/+/api/latest/activities@}
//!
//! Retreive an instance of this class through the
//! @[Social.Google.Plus()->activities] property
class Activities
{
  inherit Method;
  protected constant METHOD_PATH = "/activities/";

  mapping activity(string activity_id, void|Callback cb)
  {
    return _get(activity_id, 0, cb);
  }
}

private People _people;
private Activities _activities;

//! Authorization class.
//!
//! @seealso
//!  @[Social.Api.Authorization]
class Authorization
{
  inherit  .Api.Authorization;

  //! Authentication scopes
  constant SCOPE_ME = "https://www.googleapis.com/auth/plus.me";
  constant SCOPE_LOGIN = "https://www.googleapis.com/auth/plus.login";
  constant SCOPE_EMAIL = "https://www.googleapis.com/auth/userinfo.email";

  //! All valid scopes
  protected multiset valid_scopes = (< SCOPE_ME, SCOPE_LOGIN, SCOPE_EMAIL >);

  //! Default scope
  protected string _scope = SCOPE_ME;
}
