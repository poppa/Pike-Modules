#ifndef TWITTER_H
#define TWITTER_H

#define TWITTER_DEBUG

#ifdef TWITTER_DEBUG
# define TRACE(X...) werror("# %s:%d: %s", basename(__FILE__), __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define TURL(X) "http://twitter.com/" X ".xml"
#define AURL(X) "http://api.twitter.com/1/" X ".xml"
#define ASSERT_AUTHED(X) \
  is_authenticated || error("The method \"" X "\" requires authentication!");

// For the XmlMapper stuff
#define bool  int(0..1)
#define true  1
#define false 0
#define uri_encode(X) Protocols.HTTP.uri_encode((X))
#define NULL "\0"
#define NULLIFY(X) (X) && sizeof((X)) && (X) || 0

#endif