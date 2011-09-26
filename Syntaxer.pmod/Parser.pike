//! Generic syntax highlighting
//|
//| This is in part a Pike port of my generic styntax highlighting script
//| Syntaxer [@url{http://plib.poppa.se/doc/index.php?__plibmodule=@
//|Parser.Syntaxer.Syntaxer@}] written in PHP.
//|
//| The biggest difference is that the PHP version uses the syntax files from
//| Edit+ (@url{http://editplus.com@) to create the syntax maps, but since Pike
//| isn't as a dynamic language like PHP I decided to skip that path for this
//| solution.
//|
//| To add support for a new language just inherit the Hilite class and see
//| how the other extensions are made.
//|
//| ============================================================================
//|
//| author:  Pontus Östlund <pontus@poppa.se>
//| date:    2007-04-22, 2007-05-20, 2008-09-10
//|
//| TODO:
//|
//|   o Documentation!
//|     Since most stuff is ported from my PHP version it's already
//|     documented, it's just a matter of cut and paste.
//|
//|     The HTMLParser class, which is not ported from the PHP version, needs
//|     some documentation though.
//|
//| Tab width:    8
//| Indent width: 2
//|
//| ============================================================================
//|
//| License GNU GPL version 3
//|
//| Parser.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Parser.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Parser.pike. If not, see <http://www.gnu.org/licenses/>.

#include "syntaxer.h"

public int       tabsize       = 4;
public int(0..1) html_embedded = 0;
public string    title         = "";
//| How to wrap each line
public array line_wrap = ({ "<li>", "</li>\n" });

protected string escape            = "\\";
protected int(0..1) case_sensitive = 1;
//| For languages that has preprocessing macros
protected int(0..1) macro          = 0;
//| Can the macro start off of the first char. C# allows for this
protected int(0..1) macro_indent   = 0;
//| Default macro character
protected string macro_char        = "#";

//| Default delimiters for C/C++ like languages
protected multiset(string) delimiters = (<
  ",","(",")","{","}","[","]","-","+","*","%","/","=","\"",
  "'","~","!","&","|","<",">","?",":",";",".","#" >);

//| Default stuff for C/C++ like languages
protected array quotes        = ({ "\"", "'" });
protected array linecomments  = ({ "//", "#" });
protected array blockcomments = ({ ({ "/*", "*/" }) });

//| HTML characters
protected array(string) html_char = ({ "<", ">", "'", "\"", "&" });
//| HTML entities
protected array(string) html_ent = ({
  "&#60;", "&#62;", "&#39;", "&#34;", "&#38;" });

protected mapping(string:string) colors = ([
  "default"      : "#000",
  "functions"    : "#C00",
  "delimiter"    : "#00C",
  "keywords"     : "#006",
  "keywords1"    : "#A33",
  "quote"        : "#070",
  "numeric"      : "purple",
  "linecomment"  : "#818A9E",
  "blockcomment" : "#818A9E",
  "preprocessor" : "lime",
  "macro"        : "#99510a" ]);

protected mapping(string:array(string)) styles = ([
  "keywords"     : ({ "<b>", "</b>" }),
  "preprocessor" : ({ "<b style='background:black;'>", "</b>" }),
  "macro"        : ({ "<b>", "</b>" })
]);
protected mapping(string:multiset(string)) keywords = ([]);

//| Order of keywords. Default is by calling indices(keywords) but this can
//| be set manually in derrived classes
protected array(string) kw_order;

//| Some languages like PHP, Perl, Ruby has some variable prefixes
//| like $, @, % so we can use them to highlight these variables
//| differently. The key should be an identifier to lookup in the
//| colors mapping and the value should be the actual prefix.
//| It could look like this for Perl:
//|
//|   prefixes = ([
//|     "prefix1" : "$",
//|     "prefix2" : "%",
//|     "prefix3" : "@"
//|   ])
//|
//| or if you want all prefixes to be colorized the same way
//|
//|   prefixes = ([
//|     "prefix" : ({ "$", "%", "@" })
//|   ])
protected mapping(string:string|array) prefixes = ([]);

//| HTML embedded languages use preprocessor instructions to tell when
//| the actual program code starts and ends. Add them here...
//| PHP would look like this:
//| ({
//|   ({ "<?php", "?>"}), ({"<?", "?>"})
//| })
protected array(array(string)) preprocs = ({});

//| Runtime variables
protected string           tab;
protected int              lines = 0;
protected String.Buffer    buffer = String.Buffer();
protected string           data;
protected multiset(string) stop_chars;

void create()
{
  kw_order = indices(keywords);
  stop_chars = delimiters + WHITES;
}

string parse(string in)
{
  buffer = String.Buffer();
  tab = SPACE * tabsize;
  data = replace(in, ({ "\r\n", "\r" }), ({ "\n", "\n" }));

  if (html_embedded) {
    object parser = .get_parser("html");
    parser->tabsize = tabsize;
    parser->line_wrap = line_wrap;
    html_embedded = 0;
    foreach (preprocs, array(string) pp)
      parser->get_parser()->set_preprocessor_parser(pp[0][1..], this);
    return parser->parse(data);
  }

  lines = 0;

  string    line           = "";
  int       index          = -1;
  int       len            = strlen(data);
  int(0..1) highlight      = html_embedded    ? 0 : 1;
  int(0..1) has_prefix     = sizeof(prefixes) ? 1 : 0;
  int(0..1) macro_continue = 0;

  //| For HTML embedded languages
  string preproc_close;

main:
  while (++index < len) {
    string char = data[index..index];

    //| Whitespaces
    if ( WHITES[char] ) {
      switch (char) {
	default:   line += char;  break;
	case "\t": line += tab;   break;
	case " ":  line += SPACE; break;
	case "\n": APPEND_LINE(line + SPACE);
		   line = "";
		   break;
      }
      continue;
    }

    if (IS_MACRO()) {
      int nl = search(data, "\n", index);
      if (nl == -1) nl = len; 	// End of file
      string sline = data[index..nl];
      int tlen     = sizeof(sline);

      macro_continue = 0;

      // Multiline macro
      if (RTRIM(sline)[-1] == '\\')
	macro_continue = 1;

      index += tlen-1;

      APPEND_LINE(line + colorize(TO_WHITE(ENTIFY(sline)), "macro"));
      line = "";

      if (nl == len) break main;

      continue;
    }

    //| If we're dealing with an HTML embedded language and havn't yet
    //| found an opening script tag we look for it.
    if (html_embedded && !highlight) {
      array pproc = is_preproc(data, index);
      if (pproc) {
	highlight = 1;
	[string ppo, preproc_close] = pproc;
	line += colorize(ENTIFY(ppo), "preprocessor");
	index += strlen(ppo)-1;
      }
      else
	line += ENTIFY(char);

      continue;
    }
    //| See if we match the closing preprocessor
    else if (html_embedded && highlight) {
      string ppc = data[index..index+strlen(preproc_close)-1];
      if (ppc == preproc_close) {
	highlight = 0;
	line += colorize(ENTIFY(ppc), "preprocessor");
	index += strlen(ppc)-1;
	preproc_close = 0;
	continue;
      }
    }

    //| If we hit a line comment we just grab what's left of the
    //| line and append that to the buffer.
    if (is_line_comment(data, index)) {
      int nl = search(data, "\n", index);
      //| This means we've reached the end of the data
      if (nl == -1)
	nl = len;

      string end = data[index..nl-1];
      index += strlen(end);
      line += colorize(TO_WHITE(ENTIFY(end)), "linecomment");
      APPEND_LINE(line);
      line = "";
      continue;
    }

    //| Check for beginning of a block comment.
    //| If we find it we get the array index of the opening comment
    //| type in the array of available block comments. The closing
    //| instruction should be at the same index in in the block comment
    //| close array.
    string cc;
    if ((cc = is_block_comment(data, index))) {
      int cc_len = strlen(cc), i = index||1;
      int pos = search(data, cc, i-1);
      string comment = data[index..pos+cc_len-1];

      index += strlen(comment)-1;
      array tlines = comment/"\n";
      int tlen = sizeof(tlines);

      for (i = 0; i < tlen; i++) {
	line += colorize(TO_WHITE(ENTIFY( tlines[i] )), "blockcomment");
	if (i < tlen-1) {
	  APPEND_LINE(line);
	  line = "";
	}
      }
      continue;
    }

    //| Check for quote chars - ordinary strings
    if (is_quote(char, index)) {
      int i = index;
      string str = char;

      while (++i < len) {
	string c = sprintf( "%c", data[i] );
	str += c;
	string prev = sprintf( "%c", data[i-1] );

	//| This is tricky:
	//| We're matching a closing quote but it preceeds by an
	//| escape charcater. That means we should'nt close the
	//| quote. But what if the preceeding escape character also
	//| is preceedes by an escape character?
	//|
	//| We loop backwards until we don't find any consecutive
	//| escape chars and if we found an even number of escape
	//| chars we close the quote.
	//|
	//| This often happens in regexps:
	//|
	//|     $find    = array("\\", "'");
	//|     $replace = array("\\\\", "\'");
	//|
	if (escape && c == char && prev == escape) {
	  int k = 0, j = i - 1;
	  while (sprintf( "%c", data[--j] ) == escape)
	    k++;

	  if (k % 2) break;
	}
	else if (c == char && (prev != escape || !escape))
	  break;
      }

      index   += strlen(str)-1;
      array sl = str/"\n";
      int cnt  = sizeof(sl);

      for (i = 0; i < cnt; i++) {
	line += colorize(TO_WHITE(ENTIFY( sl[i] )), "quote");
	if (i < cnt - 1) {
	  APPEND_LINE(line);
	  line = "";
	}
      }
      continue;
    }

    //| Check for prefixes if they are being used at all
    if (has_prefix) {
      string key;
      string c;
      if (key = get_prefix_key(char)) {
	string word = char;
	while (++index < len) {
	  c = sprintf( "%c", data[index] );
	  if ( stop_chars[c] )
	    break;
	  else
	    word += c;
	}

	line += colorize(ENTIFY(word), key);

	if ( WHITES[c] )
	  index--;
	else
	  line += colorize(ENTIFY(c), "delimiter");

	continue;
      }
    }

    //| A delimiter. Higlight it, add it and move on
    if ( delimiters[char] ) {
      line += colorize(ENTIFY(char), "delimiter");
      continue;
    }
    //| When nothing has been caught earlier on we should look for a
    //| keyword, function or alike.
    //| We search from the current offset to the next delimiter or
    //| whitespace, and there we have our word!
    else {
      string word = char;
      string c;
      while (++index < len) {
	c = data[index..index];
	if ( !stop_chars[c] )
	  word += c;
	else
	  break;
      }

      if (intp((int)word) && (int)word > 0 || word == "0")
	line += colorize(ENTIFY(word), "numeric");
      else {
	string|int color_key = get_color_key(word);

	if (stringp(color_key))
	  line += colorize(ENTIFY(word), color_key);
	else
	  line += ENTIFY(word);
      }

      //| At the enf of the data...
      if (index == len) break;

      char = "";
      if ( !WHITES[c] )
	line += colorize(ENTIFY(c), "delimiter");
      else
	index--;
    }

    line += ENTIFY(char);
  }

  if (line != "")
    APPEND_LINE(line);

  return buffer->get();
}

protected string colorize(string what, string how)
{
  string clr  = colors[how];
  array style = styles[how];

  if (!clr) clr = colors["default"];
  if (what == "") what = SPACE;
  if (style) what = style * what;

  return clr ? "<span style='color:" + clr + "'>" + what + "</span>" : what;
}

protected string get_prefix_key(string char)
{
  foreach (prefixes; string key; array|string val) {
    if (stringp(val))
      if (val == char)
	return key;
    if (arrayp(val))
      if (has_value(val, char))
	return key;
  }

  return 0;
}

protected string is_block_comment(string data, int offset)
{
  foreach (blockcomments, array cmt)
    if (data[offset..offset+strlen(cmt[0])-1] == cmt[0])
      return cmt[1];

  return 0;
}

protected int(0..1) is_line_comment(string data, int offset)
{
  foreach (linecomments, string cmt)
    if (data[offset..offset+strlen(cmt)-1] == cmt)
      return 1;

  return 0;
}

protected int(0..1) is_quote(string char, int offset)
{
  foreach (quotes, string quote)
    if (quote == char && (string)data[offset-1] != escape)
      return 1;

  return 0;
}

protected array is_preproc(string data, int offset)
{
  foreach (preprocs, array preproc)
    if (data[offset..offset+strlen(preproc[0] )-1] == preproc[0])
      return ({ preproc[0], preproc[1] });

  return 0;
}

protected string|int get_color_key(string word)
{
  if (!sizeof(keywords)) return 0;
  if (!case_sensitive) word = lower_case(word);

  foreach (kw_order||indices(keywords), string key)
    if ( keywords[key] && keywords[key][word] )
      return key;

  return 0;
}

//! Returns the title
public string get_title()
{
  return title;
}

//! Returns the number of lines of code parsed
public int get_lines()
{
  return lines;
}

//! Returns the keywords
public mapping(string:multiset(string)) get_keywords()
{
  return keywords;
}

public string object_name()
{
  return basename(replace(sprintf("%O", object_program(this)), ".", "/"));
}

string _sprintf(int t)
{
  return t == 'O' && sprintf("%O(\"%s\")", object_program(this), title);
}
