#ifndef _FACEBOOK_H
#define _FACEBOOK_H

#define FB_DEBUG

#ifdef FB_DEBUG
# define TRACE(X...) werror(">>> FB (%s:%d): %s", basename(__FILE__), \
                            __LINE__, sprintf(X))
#else
# define TRACE(X...)
#endif

#define EMPTY(STR)	(!STR || !sizeof(STR))
#define NOT_NULL(STR)	STR = STR||""
#define ARG_ERROR(ARG, MSG...) \
  error("Argument exception (%s): %s\n", (ARG), sprintf(MSG))

#endif /* _FACEBOOK_H */