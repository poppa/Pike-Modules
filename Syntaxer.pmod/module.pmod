/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Generic syntax highlighting
//!
//! To add support for a new language just inherit the Parser class and see
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
//| But still: The script "stxparser" will parse a stx file for Edit+ and
//| generate a Pike stub.
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
  return .Hilite(type);
}

.Hilite get_parser_from_file(string path)
{
  if (!Stdio.exist(path))
    error("\"%s\" doesn't exist! ", path);

  string ext;
  array(string) p = path/".";
  if (sizeof(p) > 1)
    ext = p[-1];
  else {
    Stdio.File f = Stdio.File(path, "r");
    string s = f->read(32);
    f->close();
    if (sscanf(s, "#!%*[a-zA-Z0-9/] %s\n", ext) == 2){}
    else if (sscanf(s, "#!%[a-zA-Z0-9/]\n", ext) == 1)
      ext = basename(ext);
  }

  return get_parser(ext);
}

