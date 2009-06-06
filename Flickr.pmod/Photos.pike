//! Copyright © 2008, Pontus Östlund - @url{www.poppa.se@}
//!
//! Class for all Flickr photos methods. For a complete reference of the
//! Flickr web services see @url{http://www.flickr.com/services/api/@}

#include "flickr.h"

//| Default error message for missing photoset ID
#define ERRMSG_NOID "Missing required photo ID!"
//| Default error message for missing required permission
#define ERRMSG_NOPERM "Missing required permisson \"write\" or \"delete\"!"
//| Default error message for missing required delete permission
#define ERRMSG_NODELETE "Missing required minimum permisson \"delete\"!"
//| Default error message for missing required read permission
#define ERRMSG_NOREAD "Missing required minimum permisson \"read\"!"
//| Most methods that need higher perms than "read" setles with "write"
//| This will check for a minumum write permisson for the current user.
#define VALIDATE() validate(.BIT_PERM_WRITE|.BIT_PERM_DELETE)
//| Validates against a minumum delete permission
#define VALIDATE_D() validate(.BIT_PERM_DELETE)
//| Validates against a minumum read permission
#define VALIDATE_R() validate(.BIT_PERM_READ|.BIT_PERM_WRITE|.BIT_PERM_DELETE)

inherit .FlickrMethod;

//! A few Flickr methods can take a parameter named @tt{extras@}.
//! This multiset contains all these flags.
constant PARAM_EXTRAS = (< "license", "date_upload", "date_taken", "owner_name",
                           "icon_server", "original_format", "last_update",
                           "geo", "tags", "machine_tags", "o_dims", "views",
                           "media" >);

//! The id of a photo
private string _id;

//! Default @[Flickr.SignedParams]
private .SignedParams params = ([]);

//! Creates a new instance of @[Photos]
//!
//! @param api
//!   The @[Flickr.Api] to use on this instance.
//! @param photo_id
//!   A photo ID, if any. Not all methods of this class requires a photo ID.
void create(.Api api, void|string photo_id)
{
  ::create(api);
  _id = (string)photo_id||0;
  if (_id)
    params->photo_id = _id;
}


//! Getter/setter for the photo ID
//!
//! @param photo_id
//!   Sets a new photo ID.
//!
//! @returns
//!   The photo ID
string id(void|string photo_id)
{
  if (photo_id) {
    _id = photo_id;
    params->photo_id = _id;
  }
  return _id;
}


//! Add tags to a photo
//!
//! @note
//!  This method call will never be cached.
//!  This method has no specific response - It returns an empty success
//!  response if it completes without error.
//!
//! @param tags
//!   The tags to add to the photo.
.Response add_tags(string tags)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);

  params->tags = tags;

  return execute("flickr.photos.addTags", params, 0, 1);
}


//! Delete a photo from Flickr. Requires delete permission.
//!
//! @note
//!  This method call will never be cached.
//!  This method has no specific response - It returns an empty success
//!  response if it completes without error.
.Response delete()
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE_D()) THROW(ERRMSG_NODELETE);

  return execute("flickr.photos.delete", params, 0, 1);
}


//! Returns all visible sets and pools the photo belongs to.
.Response get_all_contexts()
{
  if (!_id) THROW(ERRMSG_NOID);
  return execute("flickr.photos.getAllContexts", params, _id);
}


//! Fetch a list of recent photos from the calling users' contacts.
//!
//! @param count
//!   Number of photos to return. Defaults to @expr{10@}, maximum @expr{50@}.
//!   This is only used if @[single_photo] is not passed.
//! @param just_friends
//!   set as @expr{1@} to only show photos from friends and family (excluding
//!   regular contacts)
//! @param single_photo
//!   Only fetch one photo (the latest) per contact, instead of all photos in
//!   chronological order.
//! @param include_self
//!   Set to @expr{1@} to include photos from the calling user.
//! @param extras
//!   A comma-delimited list of extra information to fetch for each returned
//!   record. Currently supported fields are:
//!   @ul
//!    @item
//!     license
//!    @item
//!     date_upload
//!    @item
//!     date_taken
//!    @item
//!     owner_name
//!    @item
//!     icon_server
//!    @item
//!     original_format
//!    @item
//!     last_update.
//!  @endul
.Response get_contacts_photos(void|int       count,
                              void|int(0..1) just_friends,
			      void|int(0..1) single_photo,
			      void|int(0..1) include_self,
			      void|string    extras)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  m_delete(params, "photo_id");

  if (count)        params->count        = count;
  if (just_friends) params->just_friends = just_friends;
  if (single_photo) params->single_photo = single_photo;
  if (include_self) params->include_self = include_self;
  if (extras)       params->extras       = extras;

  return execute("flickr.photos.getContactsPhotos", params, _id);
}

//! Fetch a list of recent public photos from a users' contacts.
//!
//! @param user_id
//!   The NSID of the user to fetch photos for.
//! @param count
//!   Number of photos to return. Defaults to @expr{10@}, maximum @expr{50@}.
//!   This is only used if @[single_photo] is not passed.
//! @param just_friends
//!   set as @expr{1@} to only show photos from friends and family (excluding
//!   regular contacts)
//! @param single_photo
//!   Only fetch one photo (the latest) per contact, instead of all photos in
//!   chronological order.
//! @param include_self
//!   Set to @expr{1@} to include photos from the calling user.
//! @param extras
//!   A comma-delimited list of extra information to fetch for each returned
//!   record. Currently supported fields are:
//!   @ul
//!    @item
//!     license
//!    @item
//!     date_upload
//!    @item
//!     date_taken
//!    @item
//!     owner_name
//!    @item
//!     icon_server
//!    @item
//!     original_format
//!    @item
//!     last_update.
//!   @endul
//!
.Response get_contacts_public_photos(string         user_id,
                                     void|int       count,
                                     void|int(0..1) just_friends,
			             void|int(0..1) single_photo,
			             void|int(0..1) include_self,
			             void|string    extras)
{
  m_delete(params, "photo_id");

  params->user_id = user_id;

  if (count)        params->count        = count;
  if (just_friends) params->just_friends = just_friends;
  if (single_photo) params->single_photo = single_photo;
  if (include_self) params->include_self = include_self;
  if (extras)       params->extras       = extras;

  return execute("flickr.photos.getContactsPhotos", params, user_id);
}


//! Returns next and previous photos for a photo in a photostream.
.Response get_context()
{
  if (!_id) THROW(ERRMSG_NOID);
  return execute("flickr.photos.getContext", params, _id);
}


//! Gets a list of photo counts for the given date ranges for the calling user.
//!
//! @param dates
//!   A comma delimited list of unix timestamps, denoting the periods to return
//!   counts for. They should be specified smallest first.
//! @param taken_dates
//!   A comma delimited list of mysql datetimes, denoting the periods to return
//!   counts for. They should be specified smallest first.
.Response get_counts(void|string dates, void|string taken_dates)
{
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  m_delete(params, "photo_id");

  if (dates) params->dates = dates;
  if (taken_dates) params->taken_dates = taken_dates;

  return execute("flickr.photos.getCounts", params, dates);
}


//! Retrieves a list of @tt{EXIF/TIFF/GPS@} tags for a given photo. The calling
//! user must have permission to view the photo.
//!
//! @param secret
//!   The secret for the photo. If the correct secret is passed then permissions
//!   checking is skipped. This enables the 'sharing' of individual photos by
//!   passing around the id and secret.
.Response get_exif(void|string secret)
{
  if (!secret)
    if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);
  else
    params->secret = secret;

  if (!_id) THROW(ERRMSG_NOID);

  return execute("flickr.photos.getExif", params, _id);
}


//! Returns the list of people who have favorited a given photo.
//!
//! @param page
//!   The page of results to return. If this argument is omitted, it defaults
//!   to @expr{1@}.
//! @param per_page
//!   Number of users to return per page. If this argument is omitted, it
//!   defaults to @expr{10@}. The maximum allowed value is @expr{50@}.
.Response get_favorites(void|int page, void|int per_page)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (page) params->page = page;
  if (per_page) params->per_page = per_page;
  return execute("flickr.photos.getFavorites", params, _id);
}


//! Get information about a photo.
//!
//! @param secret
//!   The secret for the photo. If the correct secret is passed then permissions
//!   checking is skipped. This enables the 'sharing' of individual photos by
//!   passing around the id and secret.
.Response get_info(void|string secret)
{
  if (!secret)
    if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);
  else
    params->secret = secret;

  if (!_id) THROW(ERRMSG_NOID);

  return execute("flickr.photos.getInfo", params, _id);
}


//! Returns a list of your photos that are not part of any sets.
//!
//! @param min_upload_date
//!   Minimum upload date. Photos with an upload date greater than or equal to
//!   this value will be returned. The date should be in the form of a unix
//!   timestamp.
//! @param max_upload_date
//!   Maximum upload date. Photos with an upload date less than or equal to
//!   this value will be returned. The date should be in the form of a unix
//!   timestamp.
//! @param min_taken_date
//!   Minimum taken date. Photos with an taken date greater than or equal to
//!   this value will be returned. The date should be in the form of a mysql
//!   datetime.
//! @param max_taken_date
//!   Maximum taken date. Photos with an taken date less than or equal to this
//!   value will be returned. The date should be in the form of a mysql
//!   datetime.
//! @param privacy_filter
//!   Return photos only matching a certain privacy level. Valid values are:
//!   @ul
//!    @item
//!     1 : public photos
//!    @item
//!     2 : private photos visible to friends
//!    @item
//!     3 : private photos visible to family
//!    @item
//!     4 : private photos visible to friends & family
//!    @item
//!     5 : completely private photos
//!   @endul
//!
//! @param media
//!   Filter results by media type. Possible values are all (default), photos
//!   or videos
//! @param extras
//!   A comma-delimited list of extra information to fetch for each returned
//!   record. Currently supported fields are:
//!   @ul
//!    @item
//!     license
//!    @item
//!     date_upload
//!    @item
//!     date_taken
//!    @item
//!     owner_name
//!    @item
//!     icon_server
//!    @item
//!     original_format
//!    @item
//!     last_update
//!    @item
//!     geo
//!    @item
//!     tags
//!    @item
//!     machine_tags
//!    @item
//!     o_dims
//!    @item
//!     views
//!    @item
//!     media
//!   @endul
//!
//! @param per_page
//!   Number of photos to return per page. If this argument is omitted, it
//!   defaults to @expr{100@}. The maximum allowed value is @expr{500@}.
//! @param page
//!   The page of results to return. If this argument is omitted, it defaults
//!   to @expr{1@}.
.Response get_not_in_set(void|string min_upload_date,
                         void|string max_upload_date,
			 void|string min_taken_date,
			 void|string max_taken_date,
			 void|int    privacy_filter,
			 void|string media,
			 void|string extras,
			 void|int    per_page,
			 void|int    page)
{
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  m_delete(params, "photo_id");

  if (min_upload_date) params->min_upload_date = min_upload_date;
  if (max_upload_date) params->max_upload_date = max_upload_date;
  if (min_taken_date)  params->min_taken_date  = min_taken_date;
  if (max_taken_date)  params->max_taken_date  = max_taken_date;
  if (privacy_filter)  params->privacy_filter  = privacy_filter;
  if (media)           params->media           = media;
  if (extras)          params->extras          = extras;
  if (per_page)        params->per_page        = per_page;
  if (page)            params->page            = page;

  return execute("flickr.photos.getNotInSet", params);
}


//! Get permissions for a photo
.Response get_perms()
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);
  return execute("flickr.photos.getPerms", params, _id);
}


//! Returns a list of the latest public photos uploaded to flickr.
//!
//! @param extras
//!   A comma-delimited list of extra information to fetch for each returned
//!   record. For supported fields see @[Photos.PARAM_EXTRAS].
//! @param per_page
//!   Number of photos to return per page. If this argument is omitted, it
//!   defaults to @expr{100@}. The maximum allowed value is @expr{500@}.
//! @param page
//!   The page of results to return. If this argument is omitted, it defaults
//!   to @expr{1@}.
.Response get_recent(void|string extras, void|int per_page, void|int page)
{
  m_delete(params, "photo_id");
  if (extras)   params->extras   = extras;
  if (per_page) params->per_page = per_page;
  if (page)     params->page     = page;
  return execute("flickr.photos.getRecent", params);
}


//! Returns the available sizes for a photo. The calling user must have
//! permission to view the photo.
.Response get_sizes()
{
  if (!_id) THROW(ERRMSG_NOID);
  return execute("flickr.photos.getSizes", params);
}


//! Returns a list of your photos with no tags.
//! For a description of the arguments see @[get_not_in_set()]
//!
//! @seealso
//!   @[Flickr.Photos.get_not_in_set()]
.Response get_untagged(void|string min_upload_date,
                       void|string max_upload_date,
                       void|string min_taken_date,
                       void|string max_taken_date,
                       void|int    privacy_filter,
                       void|string media,
                       void|string extras,
                       void|int    per_page,
                       void|int    page)
{
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  m_delete(params, "photo_id");

  if (min_upload_date) params->min_upload_date = min_upload_date;
  if (max_upload_date) params->max_upload_date = max_upload_date;
  if (min_taken_date)  params->min_taken_date  = min_taken_date;
  if (max_taken_date)  params->max_taken_date  = max_taken_date;
  if (privacy_filter)  params->privacy_filter  = privacy_filter;
  if (media)           params->media           = media;
  if (extras)          params->extras          = extras;
  if (per_page)        params->per_page        = per_page;
  if (page)            params->page            = page;

  return execute("flickr.photos.getUntagged", params);
}


//! Returns a list of your geo-tagged photos.
//! For a description of the arguments see @[Flickr.Photos.get_not_in_set()]
//!
//! @seealso
//!   @[Flickr.Photos.get_not_in_set()]
.Response get_with_geo_data(void|string min_upload_date,
                            void|string max_upload_date,
                            void|string min_taken_date,
                            void|string max_taken_date,
                            void|int    privacy_filter,
			    void|string sort,
                            void|string media,
                            void|string extras,
                            void|int    per_page,
                            void|int    page)
{
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  m_delete(params, "photo_id");

  if (min_upload_date) params->min_upload_date = min_upload_date;
  if (max_upload_date) params->max_upload_date = max_upload_date;
  if (min_taken_date)  params->min_taken_date  = min_taken_date;
  if (max_taken_date)  params->max_taken_date  = max_taken_date;
  if (privacy_filter)  params->privacy_filter  = privacy_filter;
  if (sort)            params->sort            = sort;
  if (media)           params->media           = media;
  if (extras)          params->extras          = extras;
  if (per_page)        params->per_page        = per_page;
  if (page)            params->page            = page;

  return execute("flickr.photos.getWithGeoData", params);
}


//! Returns a list of your photos without geo-tags
//! For a description of the arguments see @[Flickr.photos.get_not_in_set()]
//!
//! @seealso
//!   @[Flickr.Photos.get_not_in_set()]
.Response get_without_geo_data(void|string min_upload_date,
                               void|string max_upload_date,
                               void|string min_taken_date,
                               void|string max_taken_date,
                               void|int    privacy_filter,
                               void|string sort,
                               void|string media,
                               void|string extras,
                               void|int    per_page,
                               void|int    page)
{
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  m_delete(params, "photo_id");

  if (min_upload_date) params->min_upload_date = min_upload_date;
  if (max_upload_date) params->max_upload_date = max_upload_date;
  if (min_taken_date)  params->min_taken_date  = min_taken_date;
  if (max_taken_date)  params->max_taken_date  = max_taken_date;
  if (privacy_filter)  params->privacy_filter  = privacy_filter;
  if (sort)            params->sort            = sort;
  if (media)           params->media           = media;
  if (extras)          params->extras          = extras;
  if (per_page)        params->per_page        = per_page;
  if (page)            params->page            = page;

  return execute("flickr.photos.getWithoutGeoData", params);
}


//! Return a list of your photos that have been recently created or which have
//! been recently modified.
//!
//! Recently modified may mean that the photo's metadata (title, description,
//! tags) may have been changed or a comment has been added (or just modified
//! somehow :-)
//!
//! @param min_date
//!   A Unix timestamp indicating the date from which modifications should be
//!   compared.
//! @param extras
//!   A comma-delimited list of extra information to fetch for each returned
//!   record. Currently supported fields are:
//!   @ul
//!    @item
//!     license
//!    @item
//!     date_upload
//!    @item
//!     date_taken
//!    @item
//!     owner_name
//!    @item
//!     icon_server
//!    @item
//!     original_format
//!    @item
//!     last_update
//!    @item
//!     geo
//!    @item
//!     tags
//!    @item
//!     machine_tags
//!    @item
//!     o_dims
//!    @item
//!     views
//!    @item
//!     media
//!   @endul
//!
//! @param per_page
//!   Number of photos to return per page. If this argument is omitted, it
//!   defaults to @expr{100@}. The maximum allowed value is @expr{500@}.
//! @param page
//!   The page of results to return. If this argument is omitted, it defaults
//!   to @expr{1@}.
.Response recently_updated(string min_date, void|string extras,
                           void|int per_page, void|int page)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE_R()) THROW(ERRMSG_NOREAD);

  params->min_date = min_date;

  if (extras)   params->extras   = extras;
  if (per_page) params->per_page = per_page;
  if (page)     params->page     = page;

  return execute("flickr.photos.recentlyUpdated", params);
}


//! Remove a tag from a photo.
//!
//! @note
//!  This method call will never be cached
//!
//! @param tag_id
//!   The tag to remove from the photo. This parameter should contain a tag id,
//!   as returned by @[Flickr.Photos.get_info()]
//!
//! @seealso
//!   @url{http://www.flickr.com/services/api/flickr.photos.getInfo.html@}
.Response remove_tag(string tag_id)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);
  params->tag_id = tag_id;
  return execute("flickr.photos.removeTag", params, 0, 1);
}


//! Return a list of photos matching some criteria. Only photos visible to the
//! calling user will be returned. To return private or semi-private photos,
//! the caller must be authenticated with @tt{read@} permissions, and have
//! permission to view the photos. Unauthenticated calls will only return
//! public photos.
//!
//! This method takes a million arguments so to make it easier the arguments
//! that should be passed to the Flickr method should be in the mapping @[args].
//! The principle is that the indices in @[args] are the parameters and the
//! values in @[args] are the parameter values (doh!).
//!
//! @note
//!   This method call will never be cached
//!
//! @seealso
//!   For a list of all parameters see the documentation at flickr:
//!   @url{http://www.flickr.com/services/api/flickr.photos.search.html@}
//!
//! @param args
.Response search(mapping args)
{
  m_delete(params, "photo_id");
  params += args;
  return execute("flickr.photos.search", params, 0, 1);
}
