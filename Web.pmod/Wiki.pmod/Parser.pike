/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Wiki parser
//!
//! Copyright © 2010, Pontus Östlund - www.poppa.se
//!
//! License GNU GPL version 3
//!
//! Parser.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Parser.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Parser.pike. If not, see <http://www.gnu.org/licenses/>.

#define WIKI_DEBUG

#define TRIM String.trim_all_whites

#ifdef WIKI_DEBUG
# define TRACE(X...) werror("%s:%-4d: %s", basename(__FILE__), __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define PCRE_SW  Regexp.PCRE.StudiedWidestring
#define PCRE_OPT Regexp.PCRE.OPTION

// Replacement for block elements that shouldn't be wrapped in <p></p> or
// wiki parsed
#define REPLACE  "\1"+(match_count++)+"\2"

// Replacements for inline elements that shouldn't be wiki parsed
#define REPLACE2 "\3"+(match_count++)+"\4"

private mapping(string:string) simple_patterns = ([
  "**" : "strong",
  //"//" : "em",
  "^^" : "sup",
  "__" : "sub",
  "--" : "del",
  "`"  : "code"
]);

private mapping(PCRE_SW:string) simple_re_patterns;

// Regexp template for simple patterns. Used in the constructor when 
// settings up the regexp for the simple stuff. Will look like:
//
// "//(.+)//", "\\*\\*(.+)\\*\\*"
// @note
//  This is a bit sloppy. 
private string simple_re_template = "%s(.+)%[0]s";

private PCRE_SW re_em = Regexp.PCRE("[^:]//(.+)[^:]//", PCRE_OPT.UNGREEDY);

// Regexp matching links, like: [/my/path/|Link description]
private PCRE_SW re_link = Regexp.PCRE("\\\[(.[^\\\]]*)(\\\|(.*))*\\\]",
                                      PCRE_OPT.UNGREEDY);

// Regexp matching images, like: [img:/my/path/|attr]
private PCRE_SW re_img = Regexp.PCRE("\\\[img:(.[^\\\]]*)(\\\|(.*))*\\\]",
                                     PCRE_OPT.UNGREEDY);

// Regexp matching wiki page link, like: [wiki:WikiWord]
private PCRE_SW re_wiki = Regexp.PCRE("\\\[wiki:(.[^\\\]]*)((.*))*\\\]",
                                      PCRE_OPT.UNGREEDY);

// Regexp matching code blocks, like: {{{ my code }}}
private PCRE_SW re_code = Regexp.PCRE("\\\{\\\{\\\{(.+)\\\}\\\}\\\}",
                                      PCRE_OPT.UNGREEDY|PCRE_OPT.DOTALL);

// Regexp matching headers, like: = Header 1, == Header 2
private PCRE_SW re_headers = Regexp.PCRE("^[=]+.*$", PCRE_OPT.MULTILINE);

// Macro regexp, like: [[BR]], [[Date]]
private PCRE_SW re_macro = Regexp.PCRE("\\\[\\\[(.*)\\]\\]", PCRE_OPT.UNGREEDY);

// HR regexp
private PCRE_SW re_hr = Regexp.PCRE("\n[-]{4,}\n");

private mapping(PCRE_SW:function) re_dynamic = ([]);

private mapping(string:mixed) macros = ([
  "BR" : "<br/>"
]);

private array(string)       out_from    = ({});
private array(string)       out_to      = ({});
private int                 match_count = 0;
private mapping             hiliters    = ([]);
private mapping             wiki_words  = ([]);
private string              wiki_root   = "";

//! Creates a new Wiki @[Parser] object
//!
//! @param _wiki_root
//!  Root path of the wiki
//! @param _wiki_words
//!  Known wiki words
void create(void|string _wiki_root, void|mapping _wiki_words)
{
  wiki_root  = _wiki_root||wiki_root;
  wiki_words = _wiki_words||wiki_words;

  simple_re_patterns = ([]);
  foreach (simple_patterns; string k; string v) {
    k = replace(k, ({"*","|","^"}), ({"\\\*", "\\\|","\\\^"}));
    string pattern = sprintf(simple_re_template, k);
    PCRE_SW re = Regexp.PCRE(pattern, PCRE_OPT.UNGREEDY);
    simple_re_patterns[re] = v;
  }
}

//! Adds a wiki word or a mapping of wiki words
//!
//! @param word
void add_wiki_word(string|mapping word)
{
  if (stringp(word))
    wiki_words[word] = 1;
  else
    wiki_words += word;
}

//! Remove one or many wiki words
//!
//! @param word
void remove_wiki_word(string|mapping word)
{
  if (stringp(word))
    m_delete(wiki_words, word);
  else
    foreach (indices(word), string key)
      m_delete(wiki_words, word);
}

//! Add a regexp to the wiki parser
//!
//! @param re
//! @param callback
//!  The function to call upon a regexp match.
void add_regexp(Regexp.PCRE.StudiedWidestring re, function callback)
{
  re_dynamic[re] = callback;
}

//! Add macro to the parser
//!
//! @param name
//!  What the macro should match
//! @param todo
//!  What to do upon match
void add_macro(string name, mixed todo)
{
  macros[name] = todo;
}

//! Returns a replacepment string for block items
string get_replace_block()
{
  return REPLACE;
}

//! Returns a replacement string for inline items
string get_replace_inline()
{
  return REPLACE2;
}

//! Returns the wiki root
string get_wiki_root()
{
  return wiki_root;
}

//! Parse the @[text]
//!
//! @param text
string parse(string text)
{
  text = normalize_lines(TRIM((text-"\r"))/"\n")*"\n";
  text = re_code->replace(text, code_callback);
  text = re_hr->replace(text, hr_callback);
  text = re_macro->replace(text, macro_callback);
  text = simple_replace(text);
  text = re_headers->replace(text, header_callback);
  text = finalize(text);
  return replace(text, out_from, out_to);
}

private string macro_callback(string m)
{
  sscanf(m, "[[%s]]", m);
  sscanf(m, "%s(%s)", m, string args);
  if ( mixed macro = macros[m] ) {
    if (stringp(macro))
      m = macro;
    else if (functionp(macro)) {
      array|string ret = call_function(macro, m, args);
      if (arrayp(ret)) {
      	out_from += ({ m = ret[0] });
      	out_to   += ({ ret[1] });
      }
      else m = ret;
    }
  }
  return m;
}

private string hr_callback(string m)
{
  string ret = REPLACE;
  out_from += ({ ret });
  out_to += ({ "<hr/>" });
  return ret + "\n";
}

private string wiki_callack(string m)
{
  sscanf(m, "[wiki:%[^ ]%s]", string word, string text);
  if (!word) return m;
  if (!text) word -= "]";
  
  string root = wiki_root[-1] == '/' ? wiki_root : wiki_root + "/";

  mapping args = ([ "href" : root + word ]);
  if ( wiki_words[word] )
    args["class"] = "wiki";
  else
    args["class"] = "wiki no-wiki";
  
  TRACE("Wiki word: %O\n", args);
  
  return sprintf("<a%{ %s=%O%}>%s</a>", (array)args, TRIM(text||word));
}

private string header_callback(string m)
{
  sscanf(m, "%[=]%s", string level, string text);

  int cnt    = sizeof(level/1);
  string ret = REPLACE;

  out_from += ({ ret });
  out_to += ({ sprintf("<h%d id='id-%d'>%s</h%[0]d>",
                       cnt, match_count, TRIM(text)) });

  return ret;
}

private string code_callback(string m)
{
  m = TRIM( m[3..sizeof(m)-4] );
  sscanf(m, "#!%s\n", string lang);
  if (lang) {
    sscanf(m, "#!%*s\n%s", m);
    m = TRIM(m);
    Syntaxer.Hilite p;
    if (!( p = hiliters[lang] )) {
      p = Syntaxer.get_parser(lang);
      p->tabsize = 2;
      p->line_wrap = ({ "", "\n" });
      hiliters[lang] = p;
    }
    m = p->parse(m);
  }

  string ret = REPLACE;

  out_from += ({ ret });
  out_to   += ({ "<code><pre>" + m + "</pre></code>" });

  return ret + "\n";
}

private string img_callback(string m)
{
  sscanf(m, "[img:%s]", m);
  sscanf(m, "%s|%s", m, string attr);
  string ret = REPLACE2;
  out_from += ({ ret });
  out_to += ({ sprintf("<img src='%s'%s/>", m, attr ? " " + attr : "") });
  return ret;
}

private string finalize(string text)
{
  array(string) lns = text/"\n\n";
  array(string) out = ({});
  foreach (lns, string ln) {
    //TRACE(">> %s\n", ln);
    if (sizeof(ln) > 2) {
      // List or blockquote..
      if (ln[0..1] == "  ") {
      	out += ({ TRIM(do_lists(ln)) });
      }
      else {
      	if (ln[0] == '\1')
      	  out += ({ TRIM(ln) });
      	else
	  out += ({ "<p>" + TRIM(ln) + "</p>" });
      }
    }
  }
  return out*"\n";
}

private string do_lists(string s)
{
  array(string) lns = s/"\n";
  array(string) nl  = ({});
  array(string) tmp = ({});
  multiset(int) bullets = (< '*', '#', '@', '!' >);
  string tail;
  int len = sizeof(lns);
  int i = 0;

  loop: foreach (lns, string ln) {
    sscanf(ln, "  %[*#@! ]", string t);
    string tag_open = "<ul>", tag_close = "</ul>";

    switch ( sizeof(t) && t[0] )
    {
      case '!':
      case '#':
      case '@':
      case '*':
	if (t[0] == '#')
	  tag_open = "<ol>", tag_close = "</ol>";
	else if (t[0] == '@')
	  tag_open = "<ol type='a'>", tag_close = "</ol>";
	else if (t[0] == '!')
	  tag_open = "<ol type='i'>", tag_close = "</ol>";

	array(string) sub = ({});
	for (; i < len; i++) {
	  if (lns[i][0] == '\1') {
	    tail = lns[i];
	    break;
	  }
	  ln = lns[i][2..];
	  // Collect all consecutive list items that has deeper indentation
	  // than the current root
	  if (ln[0] == ' ') {
	    string tln = TRIM(ln);

	    // Sub list item
	    if ( bullets[ln[2]] ) {
	      sub += ({ ln });
	      int j = i+1;
	      for (; j < len; j++) {
	      	sscanf(lns[j], "  %s", tln);
	      	if (tln[0] == ' ') sub += ({ tln });
		else break;
	      }
	      i = j-1;
	    }
	    // * List item that
	    //   continues on the next line
	    else tmp[sizeof(tmp)-1] += " " + tln;
	  }
	  else {
	    if (sizeof(sub)) {
	      tmp[sizeof(tmp)-1] += do_lists( sub*"\n" );
	      sub = ({});
	    }
	    tmp += ({ TRIM( ln[2..] ) });
	  }
	}
	
	if (sizeof(sub))
	  tmp[sizeof(tmp)-1] += do_lists(sub*"\n");

	if (sizeof(tmp)) {
	  s = tag_open + "\n <li>" + tmp*"</li>\n <li>" + "</li>\n" +
	      tag_close;
	}
	
	if (tail)
	  s += tail;

	break loop;

      // Blockquote
      default:
	for (; i < len; i++)
	  tmp += ({ TRIM( lns[i] ) });

	if (sizeof(tmp))
	  nl += ({ "<p>" + tmp*" " + "</p>" });

	s = "<blockquote>" + (nl*"\n") + "</blockquote>";

	break loop;
    }
    
    i++;
  }

  return s;
}

private string simple_replace(string s)
{
  s = re_img->replace(s, img_callback);
  s = re_wiki->replace(s, wiki_callack);

  foreach (re_dynamic; PCRE_SW regexp; function cb) {
    array|string ret = regexp->replace(s, cb);
    if (stringp(ret))
      s = ret;
    else {
      out_from += ({ s = ret[0] });
      out_to += ({ ret[1] });
    }
  }

  s = re_em->replace(s,
    lambda (string m) {
      sscanf(m, "%s//%s//", string pre, m);
      return "<em>" + pre + m + "</em>";
    }
  );

  foreach (simple_re_patterns; object regex; string v) {
    s = regex->replace_positional(s, "<" + v + ">%[1]s</" + v + ">");
  }

  s = re_link->replace(s, lambda(string m) {
      sscanf(m, "[%s%*[|]%s]", m, string text);
      m -= "]";
      return sprintf("<a href='%s'>%s</a>", m, text||m);
    }
  );

  return s||"";
}

private array(string) normalize_lines(array(string) lines)
{
  array(string) ret = ({});
  int(0..1) prev_empty = 0;
  foreach (lines, string ln) {
    string t;
    if (sizeof(t = TRIM(ln)) == 0) {
      if (prev_empty) continue;
      ln = t;
      prev_empty = 1;
    }
    else
      prev_empty = 0;

    ret += ({ ln });
  }

  return ret;
}
