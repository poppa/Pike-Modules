#ifndef _FACEBOOK_H
#define _FACEBOOK_H
#include "../social.h"

#ifdef FB_DEBUG
# define TRACE(X...) werror(">>> FB (%s:%d): %s", basename(__FILE__), \
                            __LINE__, sprintf(X))
#else
# define TRACE(X...)
#endif

#define ASSERT_SESSION(FUNC) \
	{ if (!session_key) \
			error("%s needs a session but none is available!", (FUNC)); \
	}

#endif /* _FACEBOOK_H */
