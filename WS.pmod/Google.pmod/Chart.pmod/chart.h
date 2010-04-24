/* NOTE! Still work in progress but works quite ok.
 */

#define CHART_DEBUG

#ifdef CHART_DEBUG
# define TRACE(A...) werror("Google.Chart: %s", sprintf(A))
#else
# define TRACE(A...) 0
#endif