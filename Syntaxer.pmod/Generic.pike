//! Used when no matching subclass is found.
//! This will pretty much only indent palin text.

#include "syntaxer.h"
inherit .Hilite;

protected mapping(string:multiset(string)) keywords = ([]);
protected multiset(string) delimiters = (<>);
protected array quotes        = ({});
protected array linecomments  = ({});
protected array blockcomments = ({});

void create()
{
  ::create();
}