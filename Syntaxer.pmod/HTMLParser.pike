#include "syntaxer.h"

#define HAS_NEWLINE(X) (search(X, "\n") > -1)

import Parser.HTML;
inherit .Hilite;

protected string line = "";
protected array(array(string)) blockcomments = ({ ({ "<!--", "-->" }) });
protected string default_tag_color = "#729ECE";

void create()
{
  ::create();
  colors["default"] = "#727";
}

string parse(string _data)
{
  tab = SPACE * tabsize;
  data = _data;

  Parser.HTML p = Parser.HTML();
  p->case_insensitive_tag(1);
  p->lazy_entity_end(1);
  p->lazy_argument_end(0);
  p->_set_tag_callback(tcb);
  p->_set_data_callback(dcb);
  p->_set_entity_callback(ecb);
  p->add_quote_tag("!--", cmt_cb, "--");
  p->add_quote_tag("?comment", cmt_cb, "?");
  p->add_quote_tag("?xml", preprocinst_cb, "?");
  p->feed(data, 1)->finish();

  APPEND_LINE(line);

  return (string)buffer;
}

protected void preprocinst_cb(Parser.HTML p, string _data)
{
  _data = "<?xml" + _data + "?>";
  parse_mline_tag(_data);
}

protected string attr_to_string(mapping attr)
{
  string ret = "";
  foreach (attr; string key; string val) {
    string clrkey = get_color_key(key) || "attributes";
    ret += sprintf(
      " %s=%s",
      colorize(key, clrkey),
      colorize("\"" + TO_WHITE(ENTIFY(val)) + "\"", "quote")
    );
  }
  return ret;
}

protected void parse_mline_tag(string in)
{
  int index = -1, slen = sizeof(in), got_tag = 0;
  string w = "";

  while(++index < slen) {
    string char = in[index..index];

    if ( WHITES[char] ) {
      switch (char) {
	case " ":  line += SPACE; break;
	case "\t": line += tab;   break;
	case "\n": APPEND_LINE(line + SPACE);
	           line = "";
	           break;
      }
      continue;
    }

    if (is_quote(char, index)) {
      int i = index;
      string str = char;
      while (++i < slen) {
	string c = sprintf( "%c", in[i] );
	str += c;
	if (c == char)
	  break;
      }

      index += sizeof(str)-1;
      array sl = str/"\n";
      int cnt = sizeof(sl);
      for (i = 0; i < cnt; i++) {
	line += colorize(TO_WHITE( sl[i] ), "quote");
	if (i < cnt - 1) {
	  APPEND_LINE(line);
	  line = "";
	}
      }
      continue;
    }

    if ( delimiters[char] ) {
      line += ENTIFY(char);
      continue;
    }

    string word = char;
    string c;
    while (++index < slen) {
      c = in[index..index];
      if ( !stop_chars[c] )
	word += c;
      else
	break;
    }
    string|int color_key = get_color_key(word) || (got_tag ? "attributes" : 
                                                             "default");
			
    if (stringp(color_key))
      line += colorize(ENTIFY(word), color_key);
    else
      line += ENTIFY(word);

    if (index == slen)
      break;

    char = "";
    if ( !WHITES[c] )
      line += ENTIFY(c);
    else
      index--;

    got_tag = 1;
  } // end while
}

//! Comments callback
protected void cmt_cb(Parser.HTML p, string _data)
{
  string name  = p->tag_name(), c_name = "";
  string cmt_start = "<" + name;
  string cmt_end;

  foreach (blockcomments, array a) {
    if (has_value(a, cmt_start)) {
      cmt_end = a[1];
      break;
    }
  }

  if (HAS_NEWLINE(_data)) {
    array pts = _data/"\n";
    if (line != "") {
      pts[0] = line + colorize(TO_WHITE(ENTIFY( cmt_start + pts[0] )),
                               "blockcomment");
      APPEND_LINE( pts[0] );
      pts = pts[1..];
    }
    else
      pts[0] = cmt_start + pts[0];

    foreach (pts[..sizeof(pts)-2], string ln)
      APPEND_LINE(colorize(TO_WHITE(ENTIFY(ln)), "blockcomment"));

    line = colorize(TO_WHITE(ENTIFY(pts[sizeof(pts)-1] + cmt_end)),
                    "blockcomment");
    return 0;
  }
  else
    line += colorize(TO_WHITE(ENTIFY(cmt_start + _data + cmt_end)),
                     "blockcomment");
}

//! Tag callback
protected void tcb(Parser.HTML p, string _data)
{
  string  name  = p->tag_name(), c_name = "";
  mapping args  = p->tag_args();
  mapping pargs = p->parse_tag_args(_data);

  int(0..1) truncated = 0;
  if (name[0] == '/') {
    name = name[1..];
    truncated = 1;
  }

  string  tag_end = "&gt;";
  if ( pargs["/"] ) tag_end = " /";
  else if (search(_data, "/>") > -1)
    tag_end = "/";

  string ck = get_color_key(name);
  string ts;
  
  if (!ck) {
    ts = colorize("&lt;" + (truncated ? "/" : "") + name, 0);
  }
  else {
    ts = "&lt;" +  (truncated ? "/" : "") + colorize(name, ck);
  }
  //c_name = colorize(name, get_color_key(name));

  if (HAS_NEWLINE(_data))
    parse_mline_tag(_data);
  else
    line += sprintf(
      ts + "%s%s",
      attr_to_string(args),
      colorize(tag_end, 0)
    );
}

//! Data callback
protected void dcb(Parser.HTML p, string _data)
{
  if (HAS_NEWLINE(_data)) {
    array pts = _data/"\n";
    if (line != "") {
      pts[0] && (pts[0] = line + TO_WHITE(ENTIFY( pts[0] )));
      APPEND_LINE( pts[0] );
      pts = pts[1..];
    }

    foreach (pts[..sizeof(pts)-2], string ln)
      APPEND_LINE(TO_WHITE(ENTIFY(ln)));

    line = TO_WHITE(ENTIFY( pts[sizeof(pts)-1] ));
    return 0;
  }

  line += TO_WHITE(ENTIFY(_data));
}

//! Entity callback
protected void ecb(Parser.HTML p, string _data)
{
  if (p->context() == "data")
    line += colorize(ENTIFY(_data), "entity");
}

string _sprintf(int t)
{
  return ::_sprintf(t);
}

protected string colorize(string what, string how)
{
  string clr  = colors[how] || default_tag_color || colors["default"];
  array style = styles[how];

  //if (!clr) clr = colors["default"];
  if (what == "") what = SPACE;
  if (style) what = style * what;

  return clr ? "<span style='color:" + clr + "'>" + what + "</span>" : what;
}