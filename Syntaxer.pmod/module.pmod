//! Generic syntax highlighting
//!
//! To add support for a new language just inherit the Hilite class and see
//! how the other extensions are made.
//|
//| This is in part a Pike port of my generic styntax highlighting script
//| Syntaxer [http://plib.poppa.se/doc/index.php?__plibmodule=Parser.Syntaxer
//| .Syntaxer] written in PHP.
//|
//| The biggest difference is that the PHP version uses the syntax files from
//| Edit+ (http://editplus.com) to create the syntax maps, but since Pike
//| isn't as a dynamic language like PHP I decided to skip that path for this
//| solution.
//|
//| ============================================================================
//|
//| author:  Pontus Östlund <pontus@poppa.se>
//| date:    2007-04-22, 2007-05-20, 2008-09-10
//| license: GPL License 2
//| version: 0.2
//|
//| todo:
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

#include "syntaxer.h"

//! Returns a parser object for @[type] which can be a file extension name
//! or an alias for a supported language
//!
//! @param type
.Hilite get_parser(string type)
{
  .Hilite o;

  switch (lower_case(type||"")) {
    //| General C like languages
    case "c-like":
      o = .Hilite();
      break;

    case "css":
      o = .Css();
      break;

    case "pike": case "pmod":
      o = .Pike();
      break;

    case "xml": 
      o = .Markup.XML();
      break;

    case "htm": case "html": case "wsdl":
      o = .Markup.HTML();
      break;

    case "xsl": case "xslt":
      o = .Markup.XSL();
      break;

    case "c":
      o = .C();
      break;

    case "h":
      o = .C();
      o->title = "Header file";
      break;

    case "java":
      o = .Java();
      break;

    case "javascript": case "js":
      o = .JavaScript();
      break;

    case "cpp": case "cc": case "c++":
      o = .Cpp();
      break;

    case "c#": case "cs": case "csharp":
      o = .CSharp();
      break;

    case "rxml":
      o = .Markup.RXML();
      break;

    case "pl": case "pm": case "perl":
      o = .Perl();
      break;

    case "python": case "py":
      o = .Python();
      break;

    case "ruby": case "rb": case "rbw":
      o = .Ruby();
      break;

    case "actionscript": case "as":
      o = .ActionScript();
      break;

    case "php": case "php3": case "php4": case "php5":
      o = .PHP();
      break;

    case "bash": case "sh":
      o = .Bash();
      break;

    case "ada":
      o = .Ada();
      break;

    default:
      o = .Generic();
      break;
  }

  return o;
}
