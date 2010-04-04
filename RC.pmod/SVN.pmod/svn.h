#ifndef SVN_H
#define SVN_H
#ifdef __NT__
# define FILE_SEPARATOR '\\'
# define FILE_SEPARATOR_S "\\"
#else
# define FILE_SEPARATOR '/'
# define FILE_SEPARATOR_S "/"
#endif /* __NT__ */

#define ASSERT_BASE_SET()                                               \
  {                                                                     \
    if (!.get_repository_base()) {                                      \
      error("No repository is defined. Call SVN.set_repository_base("   \
            "string path) first!\n");                                   \
    }                                                                   \
  }
/* ASSERT_BASE_SET */
#endif /* SVN_H */
