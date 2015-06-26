/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! JavaScript stuff

//! Minifies JavaScript using Douglas Crockford's algorithm
//!
//! @throws
//!  An error if the parsing fails
//!
//! @param data
string minify(Stdio.File|string data)
{
  return JSMin(data)->minify();
}

//! Minfies JavaScript slightly harder than @[minify()]
string minify2(Stdio.File|string data)
{
  return JSMin2()->minify(data);
}

//| Using the jsmin algorithm originally by Douglas Crockford
//|
//| Copyright © 2002 Douglas Crockford  (www.crockford.com)
//| Copyright © 2010 Pontus Östlund (http://www.poppa.se)
//|
//| Permission is hereby granted, free of charge, to any person obtaining a copy
//| of this software and associated documentation files (the "Software"), to
//| deal in the Software without restriction, including without limitation the
//| rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//| sell copies of the Software, and to permit persons to whom the Software is
//| furnished to do so, subject to the following conditions:
//|
//| The above copyright notice and this permission notice shall be included in
//| all copies or substantial portions of the Software.
//|
//| The Software shall be used for Good, not Evil.
//|
//| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//| IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//| FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//| AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//| LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//| FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//| IN THE SOFTWARE.

class JSMin
{
  constant EOF = '\0';

  private int a;
  private int b;
  private int lookahead = EOF;
  private Stdio.FakeFile input;
  private String.Buffer output;

  void create(Stdio.File|string data)
  {
    if (stringp(data))
      input = Stdio.FakeFile(data);
    else
      input = data;

    output = String.Buffer();
  }

  string minify()
  {
    jsmin();
    // Remove the first newline added
    return output->get()[1..];
  }

  private int get()
  {
    int c = lookahead;
    lookahead = EOF;

    c == EOF && sscanf(input->read(1), "%c", c);

    if (c >= ' ' || c == '\n' || c == EOF)
      return c;

    return c == '\r' && '\n' || ' ';
  }

#define add(C) output->add(sprintf("%c", (C)))
#define peek() (lookahead = get())

  private int next()
  {
    int c = get();
    if (c == '/') {
      switch (peek())
      {
        case '/':
          while (c = get())
            if (c <= '\n')
              return c;
          break;

        case '*':
          get();
          while (1) {
            switch (get())
            {
              case '*':
                if (peek() == '/') {
                  get();
                  return ' ';
                }
                break;

              case EOF:
                error("Unterminated string literal! ");
            }
          }
          break;

        default:
          return c;
      }
    }

    return c;
  }

#define action(d)                                                          \
  do {                                                                     \
    switch ((int)d)                                                        \
    {                                                                      \
      case 1:                                                              \
        add(a);                                                            \
      case 2:                                                              \
        a = b;                                                             \
        if (a == '"' || a == '\'') {                                       \
          while (1) {                                                      \
            add(a);                                                        \
            a = get();                                                     \
            if (a == b)                                                    \
              break;                                                       \
            if (a == '\\') {                                               \
              add(a);                                                      \
              a = get();                                                   \
            }                                                              \
            if (a == EOF)                                                  \
              error("Unterminated string literal! ");                      \
          }                                                                \
        }                                                                  \
      case 3:                                                              \
        b = next();                                                        \
        if (b == '/' &&                                                    \
           (< '(',',','=',':','[','!','&','|','?','{','}',';','\n' >)[a] ) \
        {                                                                  \
          add(a);                                                          \
          add(b);                                                          \
          while (1) {                                                      \
            a = get();                                                     \
            if (a == '/')                                                  \
              break;                                                       \
            if (a == '\\') {                                               \
              add(a);                                                      \
              a = get();                                                   \
            }                                                              \
            if (a == EOF)                                                  \
              error("Unterminated regular expression literal");            \
            add(a);                                                        \
          }                                                                \
          b = next();                                                      \
        }                                                                  \
        break;                                                             \
    }                                                                      \
  } while(0)

#define is_alnum(c) ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || \
                     (c >= 'A' && c <= 'Z') || c == '_' || c == '$' ||   \
                      c == '\\' || c > 126)

  private void jsmin()
  {
    a = '\n';
    action(3);
    while (a != EOF) {
      switch (a)
      {
        case ' ':
          if (is_alnum(b))
            action(1);
          else
            action(2);
          break;

        case '\n':
          switch (b)
          {
            case '{':
            case '[':
            case '(':
            case '+':
            case '-':
              action(1);
              break;
            case ' ':
              action(3);
              break;

            default:
              if (is_alnum(b))
                action(1);
              else
                action(2);
          }
          break;

        default:
          switch (b)
          {
            case ' ':
              if (is_alnum(a)) {
                action(1);
                break;
              }
              action(3);
              break;

            case '\n':
              switch (a)
              {
                case '}':
                case ']':
                case ')':
                case '+':
                case '-':
                case '\'':
                case '"':
                  action(1);
                  break;
                default:
                  if (is_alnum(a))
                    action(1);
                  else
                    action(3);
              }
              break;

            default:
              action(1);
          }
      }
    }
  }
}

#ifdef prev
# define old_prev prev;
# undef prev
#endif

#ifdef next
# define old_next next;
# undef next
#endif

#ifdef curr
# define old_curr curr;
# undef curr
#endif

#define prev  input[pos-1]
#define next  input[pos+1]
#define curr  input[pos]
#define scurr input[pos..pos]

class JSMin2
{
  enum TokenType {
    TOK_ANY = 1,
    TOK_DELIMITER,
    TOK_REGEXP,
    TOK_COMMENT,
    TOK_STRING,
    TOK_OPERATOR,
    TOK_NEWLINE
  }

  private string input;
  private String.Buffer output;
  private function push;

  void create()
  {
    output = String.Buffer();
    push = output->add;
  }

  string minify(string|Stdio.File file)
  {
    if (objectp(file)) {
      file->seek(0);
      input = file->read();
    }
    else
      input = file;

    parse();

    string ret = output->get();
    output = 0;
    return ret;
  }

  private void parse()
  {
    array tokens = tokenize();

    if (sizeof(tokens)) {
      tokens = ({ 0 }) + tokens + ({ 0, 0 });
      int p = 1;
      mapping ptok, tok, ntok;
      string val, nval, pval;
      int type, ntype, ptype;
      ADT.Stack func_stack = ADT.Stack();

      while (1) {
        tok = tokens[p];

        if (!tok) {
          return;
        }

        ptok = tokens[p-1];
        ntok = tokens[p+1];

        type  = tok->type;
        ntype = ntok && ntok->type;
        ptype = ptok && ptok->type;

        val  = tok->value;
        pval = ptok && ptok->value;
        nval = ntok && ntok->value;

        if (type != TOK_NEWLINE) {
          if (type == TOK_COMMENT && ptok)
            push("\n");
          push(tok->value);
        }

        if (type == TOK_COMMENT && ntok) {
          push("\n");
        }
        else if (type == TOK_ANY) {
          if (ntype == TOK_ANY) {
            push(" ");
          }
          else if (ntype == TOK_NEWLINE) {
            mapping x = tokens[p+2];

            if (x) {
              if (x->type == TOK_ANY)
                push(";");
            }
          }
          if (val == "function" && pval && pval == "=")
            func_stack->push("function");
        }
        else if (val == "{") {
          func_stack->push(1);
        }
        else if (val == "}") {
          if (sizeof(func_stack)) {
            func_stack->pop();
            if (sizeof(func_stack)) {
              if (func_stack->top() == "function") {
                func_stack->pop();

                if (nval && nval != ";") {
                  mapping nntok = tokens[p+2];

                  if (nntok && nntok->value != "}")
                    push(";");
                }
              }
              else {
                if (ntype == TOK_NEWLINE) {
                  mapping x = tokens[p+2];
                  if (x->type == TOK_ANY)
                    push(";");
                }
              }
            }
            else {
              if (ntype == TOK_NEWLINE) {
                mapping x = tokens[p+2];
                if (x && x->type == TOK_ANY)
                  push(";");
              }
            }
          }
        }

        p += 1;
      }
    }
  }

  #define READ_LINE() do {                                          \
    while (1) {                                                     \
      if (curr == '\n' || curr == '\0')                             \
        break;                                                      \
      pos += 1;                                                     \
    }                                                               \
  } while (0)

  #define READ_TO_NEXT() do {                                       \
    pos += 1;                                                       \
    while (1) {                                                     \
      if (curr == c) {                                              \
        if (prev == '\\') {                                         \
          int t = pos;                                              \
          int n = 0;                                                \
          while (input[--t] == '\\')                                \
            n++;                                                    \
          if (n % 2 == 0) {                                         \
            break;                                                  \
          }                                                         \
        }                                                           \
        else break;                                                 \
      }                                                             \
      pos += 1;                                                     \
    }                                                               \
  } while (0)

  private array(mapping(string:string|int)) tokenize()
  {
    int start, pos, prev_char, tok_type;

    array(mapping(string:string|int)) ret = ({});

    multiset regex_prev = (<
      '(',',','=',':','[','!','&','|','?','{','}',';','\n' >);

    multiset delimiters = (<
      '=','!',':',',',';','.','-','+','*','/','&','|','?','%','<','>','^',
      '(',')',
      '{','}',
      '[',']',
      '\n','\t',' ','\f','\r'
      >);

    input += "\0\0";

    ow: while (1) {
      tok_type = TOK_ANY;
      start = pos;
      int c = curr;

      switch (c) {
        case '\0': return ret;

        case ' ':
        case '\r':
        case '\f':
        case '\t':
        case '\b':
          pos += 1;
          continue;

        case '\n':
          if (!prev_char) {
            pos += 1;
            continue;
          }

          if (next == '\r' || next == '\n') {
            pos += 1;

            while (1) {
              c = curr;

              if (!c) {
                break;
              }

              if (c == '\n') {
                pos += 1;
                continue;
              }
              else if (c == '\r') {
                pos += 1;

                if (next == '\n')
                  pos += 1;

                continue;
              }

              pos -= 1;

              break;
            }
          }

          pos += 1;

          ret += ({ ([ "value" : "\n", "type" : TOK_NEWLINE ]) });
          continue;

        case '/':
          int n = next;

          if (n == '/') {
            READ_LINE();
            pos += 1;
            continue;
          }
          else if (n != '*') {
            if (regex_prev[prev_char]) {
              READ_TO_NEXT();
              tok_type = TOK_REGEXP;
            }
            else {
              if (next == '=') {
                tok_type = TOK_OPERATOR;
                pos += 1;
              }
            }
          }
          else {
            pos += 2;
            int(0..1) keep_comment = curr == '!';
            while (1) {
              if (curr == '*' && next == '/') {
                pos += 1;
                if (!keep_comment) {
                  pos += 1;
                  continue ow;
                }

                break;
              }
              pos += 1;
            }
            tok_type = TOK_COMMENT;
          }
          break;

        case '"':
        case '\'':
          READ_TO_NEXT();
          tok_type = TOK_STRING;
          break;

        case '=':
          if (next == '=') {
            pos += 1;
            if (next == '=')
              pos += 1;
          }
          tok_type = TOK_OPERATOR;
          break;

        case '.':
        case ',':
        case ':':
        case ';':
        case '[': case ']':
        case '{': case '}':
        case '(': case ')':
          tok_type = TOK_DELIMITER;
          break;

        case '!':
          if (next == '!') {
            pos += 1;
          }
          else if (next == '=') {
            pos += 1;
            if (next == '=')
              pos += 1;
          }
          tok_type = TOK_OPERATOR;
          break;

        case '<':
        case '>':
        case '*':
        case '-':
        case '+':
          if ((< '=', '+', '-' >)[next])
            pos += 1;

            tok_type = TOK_OPERATOR;
          break;

        case '&':
          if (next == '&') {
            pos += 1;
          }
          tok_type = TOK_OPERATOR;
          break;

        case '|':
          if ((< '|', '=' >)[next]) {
            pos += 1;
          }

          tok_type = TOK_OPERATOR;
          break;

        default:
          if (!delimiters[c]) {
            while (!delimiters[c]) {
              c = input[++pos];
              if (!c) break;
            }
            pos--;
          }
          break;
      }

      prev_char = curr;
      ret += ({ ([ "value" : input[start..pos], "type" : tok_type ]) });

      pos += 1;
    }


    return ret;
  }
}

#ifdef old_prev
# undef prev
# define prev old_prev
#endif

#ifdef old_next
# undef next
# define next old_next
#endif

#ifdef old_curr
# undef curr
# define curr old_curr
#endif
