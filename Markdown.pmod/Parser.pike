//! Markdown parser based on the original Markdown by John Gruber and
//! PHP Markdown by Michel Fortin.
//!
//! There's a code block addition which works like the code highlighting
//! directive in Github's Markdown:
//!
//! @code
//!  This some code:
//!
//!  ```pike
//!  array(string) a = "abcdefghijklmnop"/1;
//!  ```
//! @endcode
//!
//! Which will result in
//!
//! @code
//!  <pre>
//!    <code data-language="pike">array(string) a = "abcdefghijklmnop"/1;</code>
//!  </pre>
//! @endcode
//!
//! Usage:
//!
//! @code
//!  Markdown.Parser p = Markdown.Parser();
//!  string html = p->transform(markdown_text);
//! @endcode
//!
//! Alternatively use the @[Markdown.transform()] method in the module.
//!
//! @code
//!  string html = Markdown.transform(markdown_text);
//! @endcode

/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.

  This is a mixed port of the original Markdown in Perl by John Gruber  and
  the PHP Markdown by Michel Fortin.

  PHP Markdown:
  Copyright (c) 2004-2014 Michel Fortin
  <http://michelf.com/projects/php-markdown/>

  Original copyright:
  Copyright (c) 2004 John Gruber
  <http://daringfireball.net/projects/markdown/>
*/

import Regexp.PCRE;

#define TRIM String.trim_all_whites

constant Regex = Widestring;

enum HtmlVersion {
  HTML,
  HTML5,
  XHTML
}

// Shortened regexp options
constant RM   = OPTION.MULTILINE;
constant RX   = OPTION.EXTENDED;
constant RS   = OPTION.DOTALL;
constant RI   = OPTION.CASELESS;
constant RMX  = RM|RX;
constant RXS  = RX|RS;
constant RMS  = RM|RS;
constant RMXS = RMX|RS;

public mapping predef_urls;
public mapping predef_titles;

protected int htmlver = HTML5;
protected int tabw = 4;
protected int no_entities = 0;
protected int no_markup = 0;
protected string empty_elem_suffix = ">"; // html5
protected mapping url_hashes, title_hashes, html_hashes;
protected int(0..1) in_anchor;

protected int nested_brackets_depth = 6;
protected string nested_brackets_re;

protected int nested_url_parenthesis_depth = 4;
protected string nested_url_parenthesis_re;

// Table of hash values for escaped characters:
protected string escape_chars = "\\`*_{}[]()>#+-.!";
protected mapping(string:string) escape_hash_table;

protected mapping backslash_table;

protected mapping(int:string) document_gamut = ([
  20 : "strip_link_definitions",
  30 : "run_basic_block_gamut"
]);

protected mapping(int:string) block_gamut = ([
  10 : "do_headers",
  20 : "do_horizontal_rules",
  40 : "do_lists",
  50 : "do_codeblocks",
  60 : "do_blockquotes"
]);

protected mapping(int:string) span_gamut = ([
  -30 : "do_parse_span",
   10 : "do_images",
   20 : "do_anchors",
   30 : "do_autolinks",
   40 : "do_encode_amps_and_angles",
   50 : "do_italic_and_bold",
   60 : "do_hardbreaks"
]);

//! Constructor
//!
//! @param tabsize
//! @param html_version
void create(void|int tabsize, void|HtmlVersion html_version)
{
  tabw = tabsize || tabw;
  htmlver = html_version;

  if (htmlver == XHTML)
    empty_elem_suffix = " />";

  nested_brackets_re =
        ("(?>[^\\[\\]]+|\\[" * nested_brackets_depth) +
        ("\\])*" * nested_brackets_depth);

  nested_url_parenthesis_re =
        ("(?>[^()\\s]+|\\(" * nested_url_parenthesis_depth) +
        ("(?>\\)))*" * nested_url_parenthesis_depth);

  escape_hash_table = ([]);

  foreach (escape_chars/1, string c) {
    escape_hash_table[c] = String.string2hex(Crypto.MD5.hash(c));
  }
}

//!
//!
public void set_tab_width(int w)
{
  tabw = w;
}

//!
//!
public void set_html_version(HtmlVersion v)
{
  htmlver = v;
  empty_elem_suffix = v == XHTML ? " />" : ">";
}

//!
//!
public void set_no_entities(int(0..1) noent)
{
  no_entities = noent;
}

//!
//!
public void set_no_markup(int(0..1) nomarkup)
{
  no_markup = nomarkup;
}

//!
//!
public string transform(string text)
{
  url_hashes   = predef_urls   || ([]);
  title_hashes = predef_titles || ([]);
  html_hashes  = ([]);
  in_anchor    = 0;

  // Remove UTF-8 BOM and marker character in input, if present.
  text = Regex("^\xEF\xBB\xBF|\x1A")->replace(text, "");

  // Normalize newlines
  text = replace(text, ([ "\r\n" : "\n", "\r" : "\n" ]));
  text += "\n\n";
  text = detab(text);

  // Strip only whitespace lines of whitespace
  text = Regex("^[ \t]+$", RM)->replace(text, "");
  text = replace(text, "\n\n\n", "\n\n");

  // So that the HTML parser in hash_html_blocks doesn't catch HTML tags
  // in code.
  text = do_codeblocks(text);
  text = hash_html_blocks(text);

  foreach (sort(indices(document_gamut)), int i) {
    text = this[document_gamut[i]](text);
  }

  mapping tmp = mkmapping(values(escape_hash_table),
                          indices(escape_hash_table));

  text = replace(text, tmp);

  teardown();

  return text;
}

//!
//!
protected void teardown()
{
  url_hashes   = ([]);
  title_hashes = ([]);
  html_hashes  = ([]);
}

//!
//!
public string run_basic_block_gamut(string t)
{
  foreach (sort(indices(block_gamut)), int i) {
    if (this[block_gamut[i]]) {
      t = this[block_gamut[i]](t);
    }
  }

  t = form_paragraphs(t);

  return t;
}

//!
//!
public string run_block_gamut(string t)
{
  t = hash_html_blocks(t);
  return run_basic_block_gamut(t);
}

//!
//!
protected string run_span_gamut(string t, void|int(0..1) _trace)
{
  foreach (sort(indices(span_gamut)), int i) {
    if (this[span_gamut[i]]) {
      t = this[span_gamut[i]](t);
    }
  }

  return t;
}

// Converters

//!
//!
public string do_headers(string t)
{
  Regex re;

  // Headers level 1
  re = Regex("^(.+)[ \\t]*\\n=+[ \\t]*\\n+", RMX);

  t = re->replace(t, lambda (string a, string b) {
    string h = hash_block("<h1>" + run_span_gamut(b) + "</h1>");
    return "\n" + h + "\n\n";
  });

  // Headers level 2
  re = Regex("^(.+)[ \\t]*\\n-+[ \\t]*\\n+", RMX);

  t = re->replace(t, lambda (string a, string b) {
    string h = hash_block("<h2>" + run_span_gamut(b) + "</h2>");
    return "\n" + h + "\n\n";
  });

  re = Regex(#"
    ^(\\#{1,6})   # $1 = string of #'s
    [ \\t]*
    (.+?)         # $2 = Header text
    [ \\t]*
    \\#*          # optional closing #'s (not counted)
    \\n+
  ", RMX);

  t = re->replace(t, lambda (string a, string b, string c) {
    string n = "h" + sizeof(b);
    n = hash_block(sprintf("<%s>%s</%[0]s>", n, run_span_gamut(c)));
    return "\n" + n + "\n\n";
  });

  return t;
}

//!
//!
public string do_horizontal_rules(string t)
{
  Regex re;

  string hr = "<hr" + empty_elem_suffix;

  function cb = lambda (string a) {
    return "\n" + hash_block(hr) + "\n";
  };

  re = Regex("^[ ]{0,2}([ ]?\\*[ ]?){3,}[ \\t]*$", RM);
  t  = re->replace(t, cb);
  re = Regex("^[ ]{0,2}([ ]?\\-[ ]?){3,}[ \\t]*$", RM);
  t  = re->replace(t, cb);
  re = Regex("^[ ]{0,2}([ ]?\\_[ ]?){3,}[ \\t]*$", RM);
  t  = re->replace(t, cb);

  return t;
}

protected int list_level;
//!
//!
public string do_lists(string t)
{
  int tabless = tabw - 1;
  // Markers
  string m_ul  = "[*+-]";
  string m_ol  = "\\d+[\\.]";
  string m_any = "(?:" + m_ul + "|" + m_ol + ")";

  mapping mre = ([
    m_ul : m_ol,
    m_ol : m_ul
  ]);

  foreach (mre; string a; string b) {
    string all = #"
      (                           # $1 = whole list
        (                         # $2
        ([ ]{0," + tabless + #"}) # $3 = number of spaces
        (" + a + #")              # $4 = first list item marker
        [ ]+
        )
        (?s:.+?)
        (                         # $5
          \\z
        |
          \\n{2,}
          (?=\\S)
          (?!               # Negative lookahead for another list item marker
            [ ]*
            " + a + #"[ ]+
          )
        |
          (?=                     # Lookahead for another kind of list
            \\n
            \\3                   # Must have the same indentation
            " + b + #"[ ]+
          )
        )
      )
    ";

    //werror("# List level: %d\n", list_level);

    if (list_level) {
      t = Regex("^" + all, RMX)->replace(t, _lists_cb);
    }
    else {
      t = Regex("(?:(?<=\\n)\\n|\\A\\n?) # Must eat the newline" +
                all, RMX)->replace(t, _lists_cb);
    }
  }

  return t;
}

//!
//!
protected string _lists_cb(string a, string b, string c, string d, string e)
{
  string list  = b;
  string m_ul  = "[*+-]";
  string m_ol  = "\\d+[\\.]";
  string tag   = Regex(m_ul)->match(e) ? "ul" : "ol";
  string m_any = tag == "ul" ? m_ul : m_ol;

  list += "\n";

  string res = process_list_item(list, m_any);

  res = hash_block(sprintf("<%s>\n%s</%[0]s>", tag, res));
  return "\n" + res + "\n\n";
}

//!
//!
private string process_list_item(string list, string m_any)
{
  list_level++;

  list = Regex("\\n{2,}\\z")->replace(list, "\n");

  list = Regex(#"
    (\\n)?                    # leading line = $1
    (^[ ]*)                   # leading whitespace = $2
    (" + m_any + #"           # list marker and space = $3
      (?:[ ]+|(?=\\n))        # space only required if item is not empty
    )
    ((?s:.*?))                # list item text   = $4
    (?:(\\n+(?=\\n))|\\n)     # tailing blank line = $5
    (?= \\n* (\\z | \\2 (" + m_any + #") (?:[ ]+|(?=\\n))))
  ", RMX)->replace(list, _process_list_item_cb);

  list_level--;

  return list;
}

private string _process_list_item_cb(string aa, string bb, string cc,
                                     string dd, string ee, string ff)
{
  string item = ee;
  int(0..1) leading_line = sizeof(bb) > 0;
  int(0..1) tailing_line = sizeof(ff) > 0;

  if (leading_line || tailing_line || sscanf(dd, "%*s\n\n") > 0) {
    item = cc + (" " * sizeof(dd)) + item;
    item = run_block_gamut(outdent(item) + "\n");
  }
  else {
    item = do_lists(outdent(item));
    item = Regex("\\n+$")->replace(item, "");
    item = run_span_gamut(item);
  }

  return "<li>" + item + "</li>\n";
}

//!
//!
public string do_hardbreaks(string t)
{
  return Regex(" {2,}\\n")->replace(t, lambda () {
    return hash_part("<br" + empty_elem_suffix + "\n");
  });
}

//!
//!
public string do_codeblocks(string t)
{
  string rs;

  rs = #"
    ```([-a-z0-9]+\\n)?
    (.*?)
    ```";

  t = Regex(rs, RX|RS)->replace(t,
    lambda (string a, string b, string c) {
      string code = "<pre><code";
      if (sizeof(b))
        code += " data-language=\"" + TRIM(b) + "\"";

      code += ">" + encode_code(TRIM(c)) + "</code></pre>";

      return sprintf("%s", hash_block(code));
    }
  );

  rs = #"
    (?:\\n\\n|\\A)
    (             # $1 = the code block -- one or more lines,
                  # starting with a space/tab
      (?:
        (?:[ ]{" + tabw + #"} | \\t)  # Lines must start with a tab or a
                                      # tab-width of spaces
        .*\\n+
      )+
    )
    ((?=^[ ]{0," + tabw + #"}\\S)|\\Z) # Lookahead for non-space at
                                       # line-start, or end of doc
  ";

  t = Regex(rs, RMX)->replace(t, lambda (string a, string b) {
    b = outdent(b);
    b = encode_code(TRIM(b));
    b = hash_block("<pre><code>" + b + "</code></pre>");
    return sprintf("\n\n%s\n\n", b);
  });

  return t;
}

//!
//!
public string do_blockquotes(string t)
{
  string r = #"
    (                         # Wrap whole match in $1
      (
        ^[ \\t]*>[ \\t]?      # '>' at the start of a line
          .+\\n               # rest of the first line
        (.+\\n)*              # subsequent consecutive lines
        \\n*                  # blanks
      )+
    )
  ";

  t = Regex(r, RMX)->replace(t, lambda (string a, string b, string c) {
    b = Regex("^[ ]*>[ ]?|^[ ]+$", RM)->replace(b, "");
    b = run_block_gamut(b);
    b = Regex("^", RM)->replace(b, "  ");
    b = Regex("(\\s*<pre>.+?</pre>)", RMX|RS)->replace(b,
      lambda (string a, string b) {
        return Regex("^  ", RM)->replace(b, "");
      }
    );

    return sprintf("\n%s\n\n", hash_block("<blockquote>\n"+b+"\n</blockquote>"));
  });

  return t;
}

//!
//!
public string do_images(string t)
{
  string re;

  re = #"
    (                 # wrap whole match in $1
      !\\[
        (.*?)         # alt text = $2
      \\]

      [ ]?            # one optional space
      (?:\\n[ ]*)?    # one optional newline followed by spaces

      \\[
        (.*?)         # id = $3
      \\]
    )";

  t = Regex(re, RMXS)->replace(t,
    lambda (string a, string b, string c, string d) {
      string ret = "";
      string alt = c;
      string key = lower_case(d);

      //werror("a: %s, b: %s, c: %s, d: %O, e: %O\n", a, b, c, d, e);

      if (!sizeof(key))
        key = lower_case(alt);

      if (url_hashes[key]) {
        string url = url_hashes[key];
        url = replace(url, ([ "*" : escape_hash_table["*"],
                              "_" : escape_hash_table["_"] ]));
        ret = sprintf("<img src=\"%s\" alt=\"%s\"", url, alt);
        if (title_hashes[key]) {
          alt = title_hashes[key];
          alt = replace(alt, ([ "*" : escape_hash_table["*"],
                                "_" : escape_hash_table["_"] ]));
          ret += " title=\"" + alt + "\"";
        }

        ret += empty_elem_suffix;
      }
      else
        ret = a;

      return ret;
    }
  );

  re = #"
    (                   # wrap whole match in $1
      !\\[
        (.*?)           # alt text = $2
      \\]
      \\(               # literal paren
          [ \\t]*
          <?(\\S+?)>?   # src url = $3
          [ \\t]*
          (             # $4
            (['\"])     # quote char = $5
            (.*?)       # title = $6
            \\5         # matching quote
            [ \\t]*
          )?            # title is optional
      \\)
    )";

  t = Regex(re, RMXS)->replace(t,
    lambda (string a, string b, string c, string d, string e,
            string f, string g)
    {
      string alt   = .attr_quote(c);
      string url   = .attr_quote(d);
      string title = .attr_quote(g);

      string img = sprintf("<img src=\"%s\" alt=\"%s\"", url, alt);

      if (sizeof(title))
        img += " title=\"" + title + "\"";

      img += empty_elem_suffix;

      return img;
    }
  );

  return t;
}

//!
//!
public string do_anchors(string t)
{
  if (in_anchor) return t;
  in_anchor = 1;

  string re;

  //
  // First, handle reference-style links: [link text] [id]
  //
  re = #"
    (                 # wrap whole match in $1
      \\[
      (" + nested_brackets_re + #") # link text = $2
      \\]

      [ ]?            # one optional space
      (?:\\n[ ]*)?    # one optional newline followed by spaces

      \\[
      (.*?)           # id = $3
      \\]
    )";

  t = Regex(re, RXS)->replace(t,
    lambda (string a, string b, string c, string d) {
      string ret  = "";
      string text = c;
      string key  = lower_case(d);

      if (!sizeof(key))
        key = lower_case(text);

      if (url_hashes[key]) {
        string url = url_hashes[key];
        url = replace(url, ([ "*" : escape_hash_table["*"],
                              "_" : escape_hash_table["_"] ]));

        ret = sprintf("<a href=\"%s\"", url);

        if (title_hashes[key]) {
          string ttl = title_hashes[key];
          ttl = replace(ttl, ([ "*" : escape_hash_table["*"],
                                "_" : escape_hash_table["_"] ]));
          ret += " title=\"" + ttl + "\"";
        }

        ret += ">" + text + "</a>";
      }
      else
        ret = a;

      return hash_part(ret);
    }
  );

  //
  // Next, inline-style links: [link text](url "optional title")
  //
  re = #"
    (             # wrap whole match in $1
      \\[
          (" + nested_brackets_re + #") # link text = $2
      \\]
      \\(         # literal paren
          [ \\n]*
          (?:
            <(.+?)>   # href = $3
          |
            (" + nested_url_parenthesis_re + #")  # href = $4
          )
          [ \\n]*
          (           # $5
            (['\"])   # quote char = $6
            (.*?)     # Title = $7
            \\6       # matching quote
            [ \\n]*   # ignore any spaces/tabs between closing quote and )
          )?          # title is optional
      \\)
    )";

  t = Regex(re, RXS)->replace(t,
    lambda (string a, string b, string c, string d, string e, string f,
            string g, string h)
    {
      string linktext = run_span_gamut(c);
      string url = e == "" ? f : e;
      string unhashed = unhash(url);

      if (url != unhashed)
        url = Regex("^<(.*)>$")->replace_positional(unhashed, "%[1]");

      string res = "<a href=\"" + .attr_quote(url) + "\"";
      if (h != "") {
        res += " title=\"" + .attr_quote(h) + "\"";
      }

      res += ">" + linktext + "</a>";

      return hash_part(res);
    }
  );

  in_anchor = 0;

  return t;
}

//!
//!
public string do_encode_amps_and_angles(string t)
{
  if (no_entities) {
    t = replace(t, "&", "&amp;");
  }
  else {
    t = Regex("&(?!#?[xX]?(?:[0-9a-fA-F]+|\\w+);)")->replace(t, "&amp;");
  }

  t = Regex("<(?![a-z/?\\$!])")->replace(t, "&lt;");

  return t;
}

//!
//!
public string do_autolinks(string t)
{

  t = Regex("((https?|ftp|dict):[^'\">\\s]+)", RI)->replace(t,
    lambda (string a, string b, string c) {
      return hash_part(sprintf("<a href=\"%s\">%[0]s</a>", .attr_quote(b)));
    }
  );

  string re = #"
    <
    (?:mailto:)?
    (
      (?:
        [-!#$%&'*+/=?^_`.{|}~\\w\\x80-\\xFF]+
      |
        \".*?\"
      )
      \\@
      (?:
        [-a-z0-9\\x80-\\xFF]+(\\.[-a-z0-9\\x80-\\xFF]+)*\\.[a-z]+
      |
        \\[[\\d.a-fA-F:]+\\] # IPv4 & IPv6
      )
    )
    >";

  t = Regex(re, RI|RX)->replace(t, lambda (string a, string b) {
    b = .attr_quote(b);
    string enc = encode_email(b);
    return hash_part(enc);
  });

  return t;
}

//!
//!
public string do_italic_and_bold(string t)
{
  string re = " (\\*\\*|__) (?=\\S) (.+?[*_]*) (?<=\\S) \\1 ";
  t = Regex(re, RS|RX)->replace(t, lambda (string a, string b, string c) {
    return "<strong>" + c + "</strong>";
  });

  re = " (\\*|_) (?=\\S) (.+?) (?<=\\S) \\1 ";
  t = Regex(re, RS|RX)->replace(t, lambda (string a, string b, string c) {
    return "<em>" + c + "</em>";
  });

  return t;
}

//!
//!
public string do_parse_span(string t)
{
  t = code_spans(t);
  t = escape_special_chars(t);
  return t;
}

// Other

//!
//!
public string strip_link_definitions(string t)
{
  int lesstab = tabw - 1;

  string r = #"
    ^[ ]{0," + lesstab + #"}\\[(.+)\\]: # id = $1
      [ \\t]*
      \\n?               # maybe *one* newline
      [ \\t]*
    <?(\\S+?)>?          # url = $2
      [ \\t]*
      \\n?               # maybe one newline
      [ \\t]*
    (?:
        (?<=\\s)         # lookbehind for whitespace
        [\"(]
        (.+?)            # title = $3
        [\")]
        [ \\t]*
    )?                   # title is optional
    (?:\\n+|\\Z)";

  Regex re = Regex(r, RMX);

  t = re->replace(t, lambda (string a, string b, string c, string d) {
    string key = lower_case(b);
    url_hashes[key] = do_encode_amps_and_angles(c);

    if (sizeof(d)) {
      title_hashes[key] = .attr_quote(d);
    }

    return "";
  });

  return t;
}

//!
//!
protected string form_paragraphs(string t)
{
  t = Regex("\\A\\n+|\\n+\\z", RMX)->replace(t, "");

  array(string) graphs = (t/"\n\n") - ({ "\n" });

  //werror("\n------------------\n%O\n------------------------\n", graphs);

  graphs = map(graphs, lambda (string v) {
    v = TRIM(v);
    int isp = Regex("^B\\x1A[0-9]+B|^C\\x1A[0-9]+C$", RMX)->match(v);
    if (!isp) {
      v = run_span_gamut(v);
      v = Regex("^([ ]*)")->replace(v, "<p>");
      v += "</p>";
      v = unhash(v);
    }
    else {
      v = html_hashes[v];
    }
    return v;
  });

  t = graphs * "\n\n";
  //t = unhash(t);

  return t;
}

// Generic

//!
//!
protected string outdent(string t)
{
  string re = "^(\\t|[ ]{1," + tabw  + "})";
  t = Regex(re, RM)->replace(t, "");
  return t;
}

//! Normalize tab according to the @[tabw] setting
//!
//! @param t
protected string detab(string t)
{
  return Regex("(.*?)\t")->replace(t,
    lambda (string a, string b) {
      return b + (" " * (tabw - sizeof(b) % tabw));
    }
  );
}

// Helpers

protected string code_spans(string t)
{
  string r = #"
    (`+)    # $1 = Opening run of `
    (.+?)   # $2 = The code block
    (?<!`)
    \\1      # Matching closer
    (?!`)
  ";

  t = Regex(r, RX)->replace(t, lambda (string a, string b, string c) {
    c = encode_code(TRIM(c));
    return ("<code>" + c + "</code>");
  });

  return t;
}

//!
//!
protected array tokenize_html(string t)
{
  array(mapping) tokens = ({});
  Parser.HTML p = Parser.HTML();

  p->_set_tag_callback(lambda () {
    tokens += ({ ([ "tag" : p->current() ]) });
  });

  p->_set_data_callback(lambda () {
    tokens += ({ ([ "text" : p->current() ]) });
  });

  p->feed(t)->finish();

  return tokens;
}

//!
//!
protected string escape_special_chars(string t)
{
  array tokens = tokenize_html(t);

  string text = "";
  foreach (tokens, mapping tok) {
    if (tok->tag) {
      text += replace(tok->tag, ([ "*" : escape_hash_table["*"],
                                   "_" : escape_hash_table["_"] ]));
    }
    else {
      text += encode_backslash_escape(tok->text);
    }
  }

  return text;
}

//!
//!
protected string encode_backslash_escape(string t)
{
  if (!backslash_table) {
    backslash_table = ([
      "\\\\" : escape_hash_table["\\"],
      "\\`"  : escape_hash_table["`"],
      "\\*"  : escape_hash_table["*"],
      "\\_"  : escape_hash_table["_"],
      "\\{"  : escape_hash_table["{"],
      "\\}"  : escape_hash_table["}"],
      "\\["  : escape_hash_table["]"],
      "\\["  : escape_hash_table["["],
      "\\("  : escape_hash_table["("],
      "\\)"  : escape_hash_table[")"],
      "\\>"  : escape_hash_table[">"],
      "\\#"  : escape_hash_table["#"],
      "\\+"  : escape_hash_table["+"],
      "\\-"  : escape_hash_table["-"],
      "\\."  : escape_hash_table["."],
      "\\!"  : escape_hash_table["!"]
    ]);
  }

  return replace(t, backslash_table);
}

//!
//!
protected string encode_code(string t)
{
  t = unhash(t);
  t = replace(t, ([ "&" : "&amp;", "<" : "&lt;", ">" : "&gt;" ]));
  t = replace(t, escape_hash_table);
  return t;
}

//!
//!
protected string encode_email(string t)
{
  string addr = "mailto:" + t;
  int len = sizeof(addr);
  string out = "";

  array(function) enc = ({
    lambda (int c) { return "&#" + c + ";"; },
    lambda (int c) { return sprintf("&#x%x;", c); },
    lambda (int c) { return sprintf("%c", c); }
  });

  for (int i; i < len; i++) {
    int c = addr[i];

    if (c == '@') {
      out += enc[1](c);
    }
    else if (c == ':') {
      out += ":";
    }
    else {
      float r = random(1.0);
      if (r > .9) out += enc[2](c);
      else if (r > .45) out += enc[1](c);
      else out += enc[0](c);
    }
  }

  sscanf (out, "%*s:%s", string text);

  return sprintf("<a href=\"%s\">%s</a>", out, text);
}

//!
//!
protected string unhash(string t)
{
  return replace(t, html_hashes);
}

//!
//!
protected string hash_html_blocks(string t)
{
  array(string) tags;
  string bta, btb;

  bta = "ins|del|";
  btb = "p|div|h1|h2|h3|h4|h5|h6|blockquote|pre|table|dl|ol|ul|address|"
        "script|noscript|style|form|fieldset|iframe|math|svg|"
        "article|section|nav|aside|hgroup|header|footer|figure";

  tags = (bta+btb)/"|";

  function cb = lambda (Parser.HTML p, mapping attr, string data) {
    return  ({ "\n" + hash_block(p->current()) + "\n" });
  };

  Parser.HTML p = Parser.HTML();

  foreach (tags, string tag)
    p->add_container(tag, cb);

  return p->feed(t)->finish()->read();
}

//!
//!
protected string hash_part(string t, void|string boundary)
{
  boundary = boundary || "X";
  string k = sprintf("%s\x1A%d%[0]s", boundary, sizeof(html_hashes));
  html_hashes[k] = unhash(t);
  return k;
}

//!
//!
protected string hash_block(string t)
{
  return hash_part(t, "B");
}
