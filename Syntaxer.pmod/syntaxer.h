#define NEWLINE     "\n"
#define AMPERSAND   "&#38;"
#define SPACE       "&#160;"
#define WHITES      (< " ", "\t", "\n", "\0" >)
#define WHITE_FROM  ({ "\t", " " })
#define WHITE_TO    ({ tab, SPACE })
#define TO_WHITE(S) replace(S, WHITE_FROM, WHITE_TO)
#define ENTIFY(X)   replace(X, html_char, html_ent)
#define IS_MACRO()  macro_continue || ((macro && (char == macro_char) && \
                    (macro_indent || (!macro_indent && line == ""))))

#define APPEND_LINE(S) do{              \
          lines++;                      \
          add(line_wrap * (S + SPACE)); \
        } while (0)

#define TRIM(x)  String.trim_all_whites(x)
#define RTRIM(x) reverse(ltrim(reverse(x)))

string ltrim(string s)
{
  sscanf(s, "%*[ \n\r\t\0]%s", s);
  return s;
}