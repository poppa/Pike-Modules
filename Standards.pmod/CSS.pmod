/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

#define next css[i+1]
#define prev css[i-1]
#define curr css[i]

Minifier minifier;

//! Minifies CSS
//!
//! @throws
//!  An error if the parsing fails
//!
//! @param data
string minify(string data)
{
  if (!minifier) minifier = Minifier();
  return minifier->minify(data);
}

class Minifier
{
  constant DELIMITERS = (< ';',',',':','{','}','(',')' >);
  constant WHITES = (< ' ','\t','\n' >);
  constant WHITES_DELIMS = DELIMITERS + WHITES;

  string minify(string css)
  {
    int len = sizeof(css);
    css += "\0";
    String.Buffer buf = String.Buffer();
    function add = buf->add;
    int(0..1) in_import = 0, in_media = 0;

    outer: for (int i; i < len; i++) {
      int c = css[i];
      switch (c)
      {
        case '@':
          if (next == 'i') {
            in_import = 1;
            add (" ");
          }
          else if (next == 'm') {
            in_media = 1;
            add (" ");
          }
          break;

        case '(':
          if (in_media) {
            add(" (");
            in_media = 0;
            continue outer;
          }

        case ';':
          if (in_import) {
            add(css[i..i], "\n");
            in_import = 0;
            continue outer;
          }
          break;

        case '\r':
        case '\n':
          in_media = 0;
          in_import = 0;
          continue outer;

        case ' ':
        case '\t':
          if (WHITES_DELIMS[prev] || WHITES_DELIMS[next])
            continue outer;
          break;

        case '/':
          if (next == '*') {
            i++;

            int (0..1) keep = 0;
            if (next == '!') {
              keep = 1;
              add ("/*");
            }

            while (i++ < len) {
              if (keep) add (css[i..i]);
              if (curr == '*' && next == '/') {
                if (keep) add ("/\n");
                i++;
                continue outer;
              }
            }
          }
          break;

        case ')': // This is needed for Internet Explorer
          if (!DELIMITERS[next]) {
            add(") ");
            continue outer;
          }
          break;

        case '}':
          add(css[i..i], "");
          continue outer;
      }
      add(css[i..i]);
    }

    return String.trim_all_whites(buf->get());
  }
}

#undef next
#undef curr
#undef prev
