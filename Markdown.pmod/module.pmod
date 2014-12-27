/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! @ignore
private .Parser p;
//! @endignore

//! Transform Markdown text @[t] to HTML
//!
//! @param t
string transform(string text)
{
  if (!p) p = .Parser();
  return p->transform(text);
}

//! Set tabwidth used in the source
//!
//! @param width
void set_tab_width(int(2..) width)
{
  (p || (p = .Parser()))->set_tab_width(width);
}

//! Set the HTML version of the result.
//!
//! @param version
//!  If @[.Parser.HtmlVersion.XHTML] empty element tags (e.g @tt{br, hr, img@})
//!  and such will be closed with @tt{/>@}.
void set_html_version(.Parser.HtmlVersion version)
{
  (p || (p = .Parser()))->set_html_version(version);
}

//! @ignore
constant attr_quote = Parser.XML.Tree.attribute_quote;
constant text_quote = Parser.XML.Tree.text_quote;
private string _special_preg_chars = ".\\+*?[^]$(){}=!<>|:-";
private mapping _quote_table;
//! @endignore

//! Quote string for usage in regular expressions
//!
//! @param s
string preg_quote(string s)
{
  if (!_quote_table) {
    _quote_table = ([]);
    map(_special_preg_chars/1, lambda(string c) {
      _quote_table[c] = "\\" + c;
    });
  }

  return replace(s, _quote_table);
}
