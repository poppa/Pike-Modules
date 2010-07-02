//! Used when no matching subclass is found.
//! This will pretty much only indent palin text.

inherit "../Parser.pike";

protected mapping(string:multiset(string)) keywords = ([]);
protected multiset(string) delimiters = (<>);
protected array quotes        = ({});
protected array linecomments  = ({});
protected array blockcomments = ({});

void create()
{
  title = "Text";
  ::create();
}