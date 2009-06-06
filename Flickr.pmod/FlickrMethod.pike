//! Base class for all Flickr API methods
//! Copyright © 2008, Pontus Östlund - @url{www.poppa.se@}

#include "flickr.h"

//! The @[Flickr.Api] to use for this instance
static .Api api;

//! Creates a new instance
//!
//! @param api
static void create(.Api _api)
{
  api = _api;
}


//! Execute the Flickr method.
//!
//! @param method
//!   The Flickr method to call
//! @param params
//!   The parameters to send to the method
//! @param cache_suffix
//!   Appended to the cache key if the same method can return different
//!   results. If unset a cache suffix will be generated from the @[param]
//!   values.
//! @param force_nocache
//!   Some method calls should never be cached regardless of the cache settings
//!   in @[FlickrMethod.api]. Set this to one and 
static .Response execute(string             method, 
                         void|.SignedParams params,
                         void|string        cache_suffix, 
			 void|int(0..1)     force_nocache)
{
  int(0..1) use_cache;

  if (force_nocache)
    use_cache = 0;
  else 
    use_cache = api->use_cache();

  .SignedParams p = api->get_default_params();
  if (params) p += params;
  p[.METHOD] = method;

  if (!cache_suffix)
    cache_suffix = .mk_cache_suffix(p);

  p = .sign_params(api->secret(), p);

  return .Request(api, method, p, cache_suffix)->query(use_cache);
}

//! Returns the full URL on the Flickr server to a photo.
//!
//! @param r
//!   The @[Flickr.Item] containing info about the photo to fetch
string get_photo_src(.Item r)
{
  mapping m = (mapping)r;
  string url = sprintf("farm%s.static.flickr.com/%s/%s_%s.jpg",
                       m->farm, m->server, m->id, m->secret);
  return "http://" + url;
}


//! Validates the required permission @[minperm] against permission @[perm]
//!
//! @example
//!   // True
//!   validate(BIT_PERM_WRITE|BIT_PERM_DELETE, "delete");
//! @example
//!   // False
//!   validate(BIT_PERM_WRITE|BIT_PERM_DELETE, "read");
//!
//! @param minperm
//!   Bitmask of the minimum required permission
//! @param perm
//!   The permission to check. If void the permission in the @[Flickr.Api]
//!   will be used.
int(0..1) validate(int minperm, void|string|int perm)
{
  if (!api->is_authenticated()) return 0;
  if (!perm) perm = api->permission();
  int bitperm = intp(perm) ? perm : .BIT_PERM_MAP[(string)perm];
  return bitperm && (minperm & bitperm) == bitperm;
}
