#ifndef FLICKR_H
#define FLICKR_H

#define FLICKR_DEBUG
#define NULL "\0"
#define NULLIFY(STR) STR && sizeof(STR) && STR

#ifdef FLICKR_DEBUG
# define TRACE(X...) werror("# %s:%d: %s", basename(__FILE__), __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#endif
