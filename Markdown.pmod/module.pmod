/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! @ignore
private .Parser p = .Parser();
//! @endignore

//! Transform Markdown text @[t] to HTML. This is a convenience method for
//! @[Markdown.Parser()->text()] which uses a global @[Markdown.Parser]
//! object.
//!
//! @param t
string transform(string text)
{
  return p->text(text);
}

//! Set the HTML version of the result for the global parser object.
//!
//! @param version
//!  If @[.Parser.HtmlVersion.XHTML] empty element tags (e.g @tt{br, hr, img@})
//!  and such will be closed with @tt{/>@}.
void set_html_version(.Parser.HtmlVersion version)
{
  p->set_html_version(version);
}

//! If set to @tt{1@} all HTML markup in the MD file will be escaped and not
//! treated as HTML. Default is @tt{0@}. This applies to the global parser
//! object.
//!
//! @param escaped
void set_markup_escaped(int(0..1) escaped)
{
  p->set_markup_escaped(escaped);
}

//! Set how newlines between generated tags should be handled. The default
//! behaviour is to add newlines between tags but if you wan't the result
//! on one line set this to @tt{0@}. This applies to the global parser object.
//!
//! @param nl
void set_newline(int(0..1) nl)
{
  p->set_newline(nl);
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

//! Obfuscate an email address with entities so it gets harder for spambots
//! to detect.
//!
//! @param address
//!
//! @returns
//!  An array with two indices. The first is the address with @tt{mailto:@}
//!  prepended (for usage in a @tt{href@} attribute), and the second index is
//!  the address it self.
array encode_email(string address)
{
  if (!has_prefix(address, "mailto:"))
    address = "mailto:" + address;

  string addr = address;
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

  return ({ out, text });
}
