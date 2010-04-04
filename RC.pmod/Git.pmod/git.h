#ifndef GIT_H
#define GIT_H
#define ASSERT_BASE_SET()                                               \
  {                                                                     \
    if (!.get_repository_base()) {                                      \
      error("No repository is defined. Call Git.set_repository_base("   \
            "string path) first!\n");                                   \
    }                                                                   \
  }
/* ASSERT_BASE_SET */
#endif /* GIT_H */
