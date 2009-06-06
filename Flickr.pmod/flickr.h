#define FLICKR_DEBUG
#define FLICKR_DEBUG2

#define THROW(x...) throw(({ sprintf(x)+"\n", backtrace() }))
#define TRIM(x)     String.trim_all_whites(x)

#if constant(Crypto.MD5)
# define MD5(s) String.string2hex(Crypto.MD5.hash(s))
#else
# define MD5(s) Crypto.string_to_hex(Crypto.md5()->update(s)->digest());
#endif

#ifdef FLICKR_DEBUG
  void TRACE(mixed ... args) // {{{
  {
    if (!has_suffix(args[0], "\n")) args[0] += "\n";
    args[0] = "Flickr: " + args[0];
    werror(@args);
  } // }}}
#else
# define TRACE(x...)
#endif

#ifdef FLICKR_DEBUG2
  void DDEBUG(mixed ... args) // {{{
  {
    if (!has_suffix(args[0], "\n\n")) args[0] += "\n\n";
    args[0] = "Flickr: " + args[0];
    werror(@args);
  } // }}}
#else
# define DDEBUG(x...)
#endif
