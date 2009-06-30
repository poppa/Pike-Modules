//! Copyright � 2008, Pontus �stlund - @url{www.poppa.se@}
//!
//! Class for all Flickr photosets methods. For a complete reference of the
//! Flickr web services see @url{http://www.flickr.com/services/api/@}

#include "flickr.h"

//| Default error message for missing photoset ID
#define ERRMSG_NOID "Missing required photoset ID!"
//| Default error message for missing required permission
#define ERRMSG_NOPERM "Missing required permisson \"write\" or \"delete\"!"
//| Most methods that need higher perms than "read" setles with "write"
//| This will check for a minumum write permisson for the current user.
#define VALIDATE() validate(.BIT_PERM_WRITE|.BIT_PERM_DELETE)

inherit .FlickrMethod;

//! The id of a photoset
private int _id;


//! Creates a new instance of @[Photosets]
//!
//! @param api
//!   The @[Flickr.Api] to use on this instance.
//! @param photoset_id
//!   A photoset ID, if any. Not all methods of this class requires a
//!   photoset ID.
void create(.Api api, void|string|int photoset_id)
{
  ::create(api);
  _id = (int)photoset_id;
}


//! Getter/setter for the photset ID
//!
//! @param photoset_id
//!   Sets a new photoset ID.
//!
//! @returns
//!   The photoset ID
int id(void|int photoset_id)
{
  if (photoset_id) _id = photoset_id;
  return _id;
}


//! Creates a new photoset
//!
//! @note
//!   This method call will never be cached
//!
//! @param title
//!   The title of the new photoset
//! @param primary_photo_id
//!   The id of the photo to represent this set. The photo must belong to the
//!   calling user.
//! @param description
//!   A description of the photoset. May contain limited html.
.Response create_new(string title, string primary_photo_id,
                     void|string description)
{
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);

  .SignedParams p = ([ "title" : title, 
                       "primary_photo_id" : primary_photo_id ]);

  if (description)
    p->description = description;

  return execute("flickr.photosets.create", p, 0, 1);
}


//! Adds a new photo to the end of an existing photoset
//!
//! @note
//!   This method call will never be cached
//!
//! @param photo_id
//!   The ID of the photo to add to the set
.Response add_photo(string photo_id)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);
  .SignedParams p = ([ "photo_id" : photo_id ]);
  return execute("flickr.photosets.addPhoto", p, 0, 1);
}


//! Remove a photo from a photoset.
//!
//! @note
//!   This method call will never be cached
//!
//! @param photo_id
//!   The id of the photo to remove from the set.
.Response remove_photo(string photo_id)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);
  .SignedParams p = ([ "photo_id" : photo_id, "photoset_id" : _id ]);
  return execute("flickr.photosets.removePhoto", p, 0, 1);
}


//! Delete a photoset.
//!
//! @note
//!   This method call will never be cached
.Response delete()
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);
  .SignedParams p = ([ "photoset_id" : _id ]);
  return execute("flickr.photosets.removePhoto", p, 0, 1);
}


//! Modify the meta-data for a photoset.
//!
//! @fixme
//!   Verify that the title element is required. It says so in the Flickr
//!   documentation but that sounds rather silly to me. What if I only want
//!   to edit the description?!
//!
//! @note
//!   This method call will never be cached
//!
//! @param title
//!   The new title for the photoset
//! @param description
//!   A description of the photoset. May contain limited html.
.Response edit_meta(string title, void|string description)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);

  .SignedParams p = ([ "photoset_id" : _id, "title" : title ]);

  if (description)
    p->description = description;

  execute("flickr.photosets.editMeta", p, 0, 1);
}


//! Modify the photos in a photoset. Use this method to add, remove and
//! re-order photos.
//!
//! @note
//!   This method call will never be cached
//!
//! @param primary_photo_id
//!   The id of the photo to use as the @tt{primary@} photo for the set. This id
//!   must also be passed along in @[photo_ids] list argument.
//! @param photo_ids
//!   A comma-delimited @expr{string@}, or @expr{array@}, of photo ids to 
//!   include in the set. They will appear in the set in the order sent. This 
//!   list must contain the primary photo id. All photos must belong to the 
//!   owner of the set. This list of photos replaces the existing list. Call 
//!   @[Flickr.Photosets.add_photo()] to append a photo to a set.
.Response edit_photos(string primary_photo_id, array|string photo_ids)
{
  if (!_id) THROW(ERRMSG_NOID);
  if (!VALIDATE()) THROW(ERRMSG_NOPERM);

  if (arrayp(photo_ids)) photo_ids = photo_ids*",";

  photo_ids = photo_ids - " ";

  .SignedParams p = ([ "photoset_id"      : _id,
                       "primary_photo_id" : primary_photo_id,
                       "photo_ids"        : photo_ids ]);

  return execute("flickr.photosets.editPhotos", p, 0, 1);
}


//! Returns a list of all photosets tied to the @[Flickr.Api].
//!
//! @param user_id
//!   The @tt{NSID@} of the user to get a photoset list for. If none is 
//!   specified, the calling user is assumed.
.Response get_list(void|string user_id)
{
  .SignedParams p = ([]);

  if (user_id)
    p->user_id = user_id;
  else {
    if (api->use_cache())
      user_id = api->userid();
  }

  return execute("flickr.photosets.getList", p, (string)user_id);
}


//! Gets information about a photoset
//!
//! @param photoset_id
//!   If not set the ID in the current instance will be used
.Response get_info()
{
  if (!_id) THROW(ERRMSG_NOID);
  .SignedParams p = ([ "photoset_id" : _id ]);
  return execute("flickr.photosets.getInfo", p, (string)_id);
}


//! Returns photos of the current photoset.
//!
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
//! @param privacy_filter
//!   Return photos only matching a certain privacy level. This only applies
//!   when making an authenticated call to view a photoset you own.
//!   Valid values are:
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
//! @param per_page
//!   Number of photos to return per page. If this argument is omitted, it
//!   defaults to @expr{500@}. The maximum allowed value is @expr{500@}.
//! @param page
//!   The page of results to return. If this argument is omitted, it
//!   defaults to @expr{1@}.
//! @param media
//!   Filter results by media type. Possible values are @tt{all@} (default),
//!   @tt{photos@} or @tt{videos@}
.Response get_photos(void|string    extras,
                     void|int       privacy_filter,
                     void|int       per_page,
                     void|int       page,
                     void|string    media)
{
  if (!_id) THROW(ERRMSG_NOID);

  .SignedParams p = ([ "photoset_id" : _id ]);

  if (extras)         p->extras         = extras;
  if (privacy_filter) p->privacy_filter = privacy_filter;
  if (per_page)       p->per_page       = per_page;
  if (page)           p->page           = page;
  if (media)          p->media          = media;

  return execute("flickr.photosets.getPhotos", p, (string)_id);
}


//! Returns next and previous photos for a photo in a set.
//!
//! @param photo_id
//!   The id of the photo to fetch the context for.
.Response get_context(string|int photo_id)
{
  if (!_id) THROW(ERRMSG_NOID);
  .SignedParams p = ([ "photo_id" : photo_id, "photoset_id" : _id ]);
  return execute("flickr.photosets.getContext", p, (string)photo_id);
}


//! Returns a @[Flickr.Photosets.Comments] instance for the current photoset.
Comments get_comments()
{
  if (!_id) THROW(ERRMSG_NOID);
  return Comments(api, _id);
}


//! Returns the full URL to a photo on the Flickr server
//!
//! @param item
//!   The photo item to get the URL for.
string get_photo_src(Flickr.Item item)
{
  return ::get_photo_src(item);
}


//! Print formatted string
string _sprintf(int t)
{
  return t == 'O' && sprintf("%s%d)", sprintf("%O", this_object())-")", _id);
}

/*
//! Checks if id @[cid] is set or if a default ID is set in the base.
//!
//! @param cid
private string|int check_id(void|string|int cid)
{
  if (!cid) cid = _id;
  return cid;
}
*/

//! Class for handling comments to photosets
class Comments
{
  inherit .FlickrMethod;

  //! The photoset ID to work on.
  static int photoset_id = 0;


  //! Creates a new instance of @[Comments].
  //!
  //! @param api
  //!   The @[Flickr.Api] to use on this instance.
  //! @param photoset_id
  //!   The photoset ID to work on.
  void create(.Api api, string|int _photoset_id)
  {
    ::create(api);
    photoset_id = (int)_photoset_id;
  }


  //! Returns the comments for a photoset.
  //!
  //! @param use_cache
  //!  Overrides the default cacheability in @[Flickr.Api]
  .Response get_list()
  {
    .SignedParams p = ([ "photoset_id" : photoset_id ]);
    return execute("flickr.photosets.comments.getList", p, (string)photoset_id);
  }


  //! Adds a comment to the photoset.
  //!
  //! @note
  //!   This method call will never be cached!
  //!
  //! @param comment_text
  //!   Text of the comment
  .Response add_comment(string comment_text)
  {
    if (!VALIDATE()) THROW(ERRMSG_NOPERM);
    .SignedParams p = ([ "photoset_id" : photoset_id,
                         "comment_text" : comment_text ]);
    return execute("flickr.photosets.comments.addComment", p, 0, 1);
  }


  //! Edit a comment to a photoset
  //!
  //! @note
  //!   This method call will never be cached!
  //!
  //! @param comment_id
  //!   The ID of the comment to edit
  //! @param comment_text
  //!   New text of the comment.
  .Response edit_comment(string comment_id, string comment_text)
  {
    if (!VALIDATE()) THROW(ERRMSG_NOPERM);
    .SignedParams p = ([ "comment_id"   : comment_id,
                         "comment_text" : comment_text ]);
    return execute("flickr.photosets.comments.editComment", p, 0, 1);
  }


  //! Delete a comment to a photoset
  //!
  //! @note
  //!   This method call will never be cached!
  //!
  //! @param comment_id
  //!   The ID of the comment to delete
  .Response delete_comment(string comment_id)
  {
    if (!VALIDATE()) THROW(ERRMSG_NOPERM);
    .SignedParams p = ([ "comment_id" : comment_id ]);
    return execute("flickr.photosets.comments.deleteComment", p, 0, 1);
  }


  //! Print formatted string
  string _sprintf(int t)
  {
    return t == 'O' && sprintf("Flickr.Photosets()->Comments(%d)", photoset_id);
  }
}
