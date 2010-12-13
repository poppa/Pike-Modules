/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Syntax highlighter
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Hilite.pike is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Hilite.pike is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Hilite.pike. If not, see <http://www.gnu.org/licenses/>.

//! Tabs will be replaces by this many spaces
public int tabsize;

//! Is the code HTML-embedded (like PHP)
public int(0..1) html_embedded = UNDEFINED;

//! Title of the language
public string title;

//! How to wrap each line. This should be an array with two indices:
//! 1. Line start
//! 2. Line end
public array line_wrap;

private string type;
private .Parser parser;

//! Creates a syntax highlighting parser
//!
//! @param _type
//!  Like php, js, pike, perl and what languages is supported
void create(string _type)
{
  type = _type;
  parser = low_get_parser();
}

//! Parse and highlight @[data]
//!
//! @param data
string parse(string data)
{
  if (tabsize) parser->tabsize = tabsize;
  if (!zero_type(html_embedded)) {
    werror("Set HTML embedded to: %d\n", html_embedded);
    parser->html_embedded = html_embedded;
  }
  if (title) parser->title = title;
  if (line_wrap) parser->line_wrap = line_wrap;

  return parser->parse(data);
}

//! Returns the parser object
.Parser get_parser()
{
  return parser;
}

//! Getter for the language/title
string get_title()
{
  return parser->get_title();
}

//! Number of lines of code
int get_lines()
{
  return parser->get_lines();
}

string _sprintf(int t)
{
  return sprintf("%O", parser);
}

private .Parser low_get_parser()
{
  object_program mod = .Stx;
  string cls;
  switch (lower_case(type||"")) 
  {
    //| General C like languages
    case "c-like":
      cls = "C";
      break;

    case "css":
      cls = "Css";
      break;

    case "pike": case "pmod":
      cls = "Pike";
      break;

    case "cmod":
      cls = "CMod";
      break;

    case "xml": case "wsdl":
      cls = "XML";
      mod = .Stx.Markup;
      break;

    case "htm": case "html":
      cls = "HTML";
      mod = .Stx.Markup;
      break;

    case "xsl": case "xslt":
      cls = "XSL";
      mod = .Stx.Markup;
      break;

    case "c":
      cls = "C";
      break;

    case "h":
      cls = "C";
      if (!title) title = "Header file";
      break;

    case "java":
      cls = "Java";
      break;

    case "javascript": case "js":
      cls = "JavaScript";
      break;

    case "cpp": case "cc": case "c++":
      cls = "Cpp";
      break;

    case "c#": case "cs": case "csharp":
      cls = "CSharp";
      break;

    case "rxml":
      cls = "RXML";
      mod = .Stx.Markup;
      break;

    case "pl": case "pm": case "perl":
      cls = "Perl";
      break;

    case "python": case "py":
      cls = "Python";
      break;

    case "ruby": case "rb": case "rbw":
      cls = "Ruby";
      break;

    case "actionscript": case "as":
      cls = "ActionScript";
      break;

    case "php": case "php3": case "php4": case "php5":
      cls = "PHP";
      break;

    case "bash": case "sh":
      cls = "Bash";
      break;

    case "ada":
      cls = "Ada";
      break;

    default:
      cls = type;
      break;
  }

  object klass = mod[cls];
  return klass && klass () || .Stx.Generic();
}

