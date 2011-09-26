#ifndef GOOGLE_H
# define GOOGLE_H

# ifdef GOOGLE_DEBUG
#  define TRACE(X...) werror("%s:%d: %s", basename(__FILE__),__LINE__,sprintf(X))
# else
#  define TRACE(X...) 0
# endif

#endif