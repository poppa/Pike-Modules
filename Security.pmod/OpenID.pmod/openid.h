#ifndef OPENID_H
#define OPENID_H

#define OPENID_DEBUG

#ifdef OPENID_DEBUG
# define TRACE(X...) werror("%s:%d: %s", basename(__FILE__), __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#if constant(Crypto.MD5)
# define MD5(S) String.string2hex(Crypto.MD5.hash((S)))
#else
# define MD5(S) Crypto.string_to_hex(Crypto.md5()->update((S))->digest())
#endif

#endif
