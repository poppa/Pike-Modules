//! Markup syntax parser

#include "../syntaxer.h"
#define HAS_NEWLINE(X) (search(X, "\n") > -1)

import Parser.HTML;

//! Parser for paring markup languages
class HTMLParser
{
  //!
  inherit "../Parser.pike";

  protected string line = "";
  protected array(array(string)) blockcomments = ({ ({ "<!--", "-->" }) });
  protected string default_tag_color = "#729ECE";

  private object js_parser;
  private object css_parser;

  private mapping(string:object/* Syntaxer.Parser */) preproc_parsers = ([]);

  void create()
  {
    ::create();
    colors["default"] = default_tag_color;
  }

  void set_preprocessor_parser(string name,
                               object /* Syntaxer.Parser */ parser)
  {
    if (name[0] != '?')
      name = "?" + name;
    parser->line_wrap = ({ "", "\n" });
    preproc_parsers[name] = parser;
  }

  string parse(string _data)
  {
    buffer = String.Buffer();
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
    p->add_containers(([ "script" : script_cb, "style" : style_cb ]));
    p->add_tag("!DOCTYPE", doctype_cb);

    foreach (indices(preproc_parsers), string pp)
      p->add_quote_tag(pp, preprocinst_cb, "?");

    p->feed(data, 1)->finish();

    if (sizeof(line))
      APPEND_LINE(line);

    return buffer->get();
  }

  string js_buf, css_buf;

  protected array script_cb(Parser.HTML p, mapping args, string tag)
  {
    string ck = get_color_key("script");
    line += colorize(ENTIFY("<script"), ck) + attr_to_string(args);
    line += colorize(ENTIFY(">"), ck);

    //werror("#####\n%s#####\n", line);
    
    if (sizeof(TRIM(tag))) {
      if (!js_parser) {
	js_parser = Syntaxer.get_parser("js");
	js_parser->line_wrap = ({ "", "\n" });
	js_parser->tabsize = tabsize;
      }

      string tmp = line + js_parser->parse(tag);
      array(string) lns = tmp/"\n";
      //string last = lns[-2];
      lns = lns[..sizeof(lns)-2];
      foreach (lns, string ln)
	APPEND_LINE(ln);

      //werror("Here...%s\n", last);
      
      line = colorize(ENTIFY("</script>"), ck);
    }
    else
      line += colorize(ENTIFY("</script>"), ck);

    return ({ });
  }

  protected array style_cb(Parser.HTML p, mapping args, string tag)
  {
    string ck = get_color_key("style");
    line += colorize(ENTIFY("<style"), ck) + attr_to_string(args);
    line += colorize(ENTIFY(">"), ck);

    if (sizeof(TRIM(tag))) {
      if (!css_parser) {
	css_parser = Syntaxer.get_parser("css");
	css_parser->line_wrap = ({ "", "\n" });
	css_parser->tabsize = tabsize;
      }

      string tmp = line + css_parser->parse(tag);
      array(string) lns = tmp/"\n";
      string last = lns[-2];
      lns = lns[0..sizeof(lns)-3];
      foreach (lns, string ln)
	APPEND_LINE(ln);

      line = last[0..sizeof(last)-7] + colorize(ENTIFY("</style>"), ck);
    }
    else
      line += colorize(ENTIFY("</style>"), ck);

    return ({});
  }

  protected void doctype_cb(Parser.HTML p, mapping args)
  {
    array(string) l = p->current()/"\n";
    int size = sizeof(l);
    for (int i = 0; i < size; i++) {
      string s = colorize(TO_WHITE(ENTIFY( l[i] )), "doctype");
      if ( i < size-1 ) {
	APPEND_LINE(line + s);
	line = "";
      }
      else line += s;
    }
  }

  protected void preprocinst_cb(Parser.HTML p, string _data)
  {
    string ck = get_color_key(p->tag_name());
    string tag = p->tag_name();

    line += colorize(TO_WHITE(ENTIFY("<"+tag)), "tags");
    if (object parser = preproc_parsers[tag] ) {
      string d = line + parser->parse(_data);
      array(string) lns = d/"\n";
      string last = lns[-2];
      lns = lns[0..sizeof(lns)-3];

      foreach (lns, string ln)
	APPEND_LINE(ln);

      line = last[0..sizeof(last)-7]; // Remove the last space (&#160;)
    }
    else {
      parse_mline_tag(_data);
    }
    line += colorize(TO_WHITE(ENTIFY("?>")), "tags");
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
      /*
      string|int color_key = get_color_key(word) || (got_tag ? "attributes" :
							       "default");

      if (stringp(color_key))
	line += colorize(ENTIFY(word), color_key);
      else
	line += ENTIFY(word);
      */

      line += colorize(ENTIFY(word), "attributes");

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
    if (name[0] == '?')
      cmt_end = "?>";

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

  int parse_js, parse_css;
  string pre_js, pre_css;

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
    if ( pargs["/"] ) tag_end = "/&gt;";
    else if (search(_data, "/>") > -1)
      tag_end = "/&gt;";

    string ck = get_color_key(name);
    string ts;

    if (!ck)
      ts = colorize("&lt;" + (truncated ? "/" : "") + name, 0);
    else
      ts =  colorize("&lt;" +  (truncated ? "/" : "") +name, ck);

    if (HAS_NEWLINE(_data))
      parse_mline_tag(_data);
    else
      line += sprintf(
	ts + "%s%s",
	attr_to_string(args),
	colorize(tag_end, ck)
      );
  }

  //! Data callback
  protected void dcb(Parser.HTML p, string _data)
  {
    if (parse_js && js_buf) {
      js_buf += _data;
      return;
    }
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

    if (what == "") what = SPACE;
    if (style) what = style * what;

    return clr ? "<span style='color:" + clr + "'>" + what + "</span>" : what;
  }
}

class HTML
{
  //inherit Syntaxer.Hilite;
  inherit HTMLParser;

  public string title = "HTML";
  public int tabsize = 2;

  protected string escape;
  protected array(string) linecomments = ({});
  protected array(array(string)) blockcomments = ({ ({ "<!--", "-->" }) });

  protected multiset(string) delimiters = (<
    "<",">","/","=","\"","'","%",",",".","(",")","{","}",
    "[","]","+","*","~","&","|",";" >);

  protected array(string) kw_order = ({ "keywords", "attributes" });

  protected mapping(string:multiset(string)) _keywords = ([
    "keywords" : (<
      "!doctype","a","abbr","acronym","address","applet","area","b",
      "base","basefont","bgsound","bdo","big","blink","blockquote",
      "body","br","button","caption","center","cite","code","col",
      "colgroup","comment","dd","del","dfn","dir","div","dl","dt","em",
      "embed","fieldset","font","form","frame","frameset","h","h1","h2",
      "h3","h4","h5","h6","head","hr","hta:application","html","i",
      "iframe","img","input","ins","isindex","kbd","label","legend","li",
      "link","listing","map","marquee","menu","meta","multicol","nextid",
      "nobr","noframes","noscript","object","ol","optgroup","option","p",
      "param","plaintext","pre","q","s","samp","script","select","server",
      "small","sound","spacer","span","strike","strong","style","sub",
      "sup","table","tbody","td","textarea","textflow","tfoot","th",
      "thead","title","tr","tt","u","ul","var","wbr","xmp" >),

    "attributes" : (<
      "abbr","accept-charset","accept","accesskey","action","align",
      "alink","alt","applicationname","archive","autoflush","axis",
      "background","behavior","bgcolor","bgproperties","border",
      "bordercolor","bordercolordark","bordercolorlight","borderstyle",
      "buffer","caption","cellpadding","cellspacing","char","charoff",
      "charset","checked","cite","class","classid","clear","code",
      "codebase","codetype","color","cols","colspan","compact","content",
      "contenttype","coords","data","datetime","declare","defer","dir",
      "direction","disabled","dynsrc","encoding","enctype","errorpage",
      "extends","face","file","flush","for","frame","frameborder",
      "framespacing","gutter","headers","height","href","hreflang",
      "hspace","http-equiv","icon","id","import","info","iserrorpage",
      "ismap","isthreadsafe","label","language","leftmargin","link",
      "longdesc","loop","lowsrc","marginheight","marginwidth",
      "maximizebutton","maxlength","media","method","methods",
      "minimizebutton","multiple","name","nohref","noresize","noshade",
      "nowrap","object","onabort","onblur","onchange","onclick",
      "ondblclick","onerror","onfocus","onkeydown","onkeypress","onkeyup",
      "onload","onmousedown","onmousemove","onmouseout","onmouseover",
      "onmouseup","onreset","onselect","onsubmit","onunload","page",
      "param","profile","prompt","property","readonly","rel","rev","rows",
      "rowspan","rules","runat","scheme","scope","scrollamount",
      "scrolldelay","scrolling","selected","session","shape",
      "showintaskbar","singleinstance","size","src","standby",
      "start","style","summary","sysmenu","tabindex","target","text",
      "title","topmargin","type","urn","usemap","valign","value",
      "valuetype","version","vlink","vrml","vspace","width","windowstate",
      "wrap" >)
  ]);

  protected mapping(string:string) _colors = ([
    "tags"       : "#006",
    "attributes" : "#02838b",
    "entity"     : "#770",
    "doctype"    : "#8b3c02"
  ]);

  protected mapping(string:array(string)) _styles = ([
    "entity" : ({ "<b>", "</b>" }),
    "doctype" : ({ "<b>", "</b>" })
  ]);

  void create()
  {
    ::create();
    case_sensitive = 0;
    colors += _colors;
    keywords += _keywords;
    styles = _styles;
  }
}

class RXML
{
  inherit HTML;

  public string title = "Roxen Macro Language";

  protected mapping(string:multiset(string)) __keywords = ([
    "_keywords" : (<
      "define","set","if","else","elseif","cond","case","vform","vinput",
      "emit","eval","wash-html","date","accessed","configurl","countdown",
      "help","modified","number","roxen","user","ai","autoformat",
      "charset","comment","default","doc","foldlist","obox","random",
      "recode","replace","smallcaps","sort","strlen","tablify",
      "trimlines","catch","for","throw","anfang","atlas","cimg",
      "cimg-url","colorscope","configimage","diagram","gbutton",
      "gbutton-url","gh","gtext","gtext-id","gtext-js","gtext-url","imgs",
      "tablist","ldap","sqlquery","sqltable","search-form",
      "search-result","search-help","then","noparse","cache","nocache",
      "insert", "email", "noindex" >)
  ]);

  protected mapping(string:string) __colors = ([
    "_keywords" : "#B00",
    "entity"    : "#055"
  ]);

  protected mapping(string:array(string)) _styles = ([
    "_keywords" : ({ "<b>", "</b>" })
  ]);

  void create()
  {
    ::create();

    default_tag_color = "#006";
    colors += __colors;
    keywords += __keywords;
    kw_order = ({ "_keywords" }) + kw_order;
    blockcomments += ({ ({ "<?comment", "?>" }) });
    styles = _styles;
  }

  string _sprintf(int t)
  {
    return ::_sprintf(t);
  }
}

class XML
{
  inherit HTML;

  public string title = "XML";

  void create()
  {
    ::create();
    default_tag_color = "#006";
    kw_order = ({});
    keywords = ([]);
  }
}

class XSL
{
  inherit RXML;

  public string title = "XML Stylesheet Language";

  protected multiset(string) delimiters = (<
    ",","(",")","{","}","[","]","+","*","/","=","~",
    "!","&","|","<",">",";","." >);

  protected mapping(string:multiset(string)) ___keywords = ([
    "_xkeywords" : (<
      "xsl:apply-imports","xsl:apply-templates","xsl:attribute",
      "xsl:attribute-set","xsl:call-template","xsl:choose","xsl:comment",
      "xsl:copy","xsl:copy-of","xsl:element","xsl:fallback",
      "xsl:for-each","xsl:if","xsl:import","xsl:include","xsl:key",
      "xsl:locale","xsl:message","xsl:number","xsl:otherwise",
      "xsl:output","xsl:param","xsl:preserve-space",
      "xsl:processing-instruction","xsl:sort","xsl:strip-space",
      "xsl:stylesheet","xsl:template","xsl:text","xsl:transform",
      "xsl:use-attribute-sets","xsl:value-of","xsl:variable",
      "xsl:when","xsl:with-param","xsl:decimal-format",
      "xsl:namespace-alias" >),

    "xattributes" : (<
      "case-order","count","data-type","decimal-separator","digit",
      "disable-output-escaping","doctype-public","doctype-system",
      "elements","encoding","extension-element-prefixes","format",
      "from","grouping-separator","grouping-size","indent",
      "infinity","lang","letter-value","level","match","media-type",
      "method","minus-sign","mode","name","namespace","nan","order",
      "pattern-separator","percent","per-mille","priority",
      "section-elements","select","standalone","use",
      "use-attribute-sets","value","version","xml-declaration",
      "zero-digit","test","terminate","stylesheet-prefixt","select",
      "result-prefix","omit-xml-declaration","cdata-section-elements",
      "exclude-result-prefixes","xmlns:xsl","xmlns:fo","xmlns:php",
      "xsl:extension-element-prefixes" >)
  ]);

  private mapping(string:string) ___colors = ([
    "_xkeywords"   : "#8b5602",
    "xattributes" : "#707"
  ]);

  protected mapping(string:array(string)) ___styles = ([
    "_xkeywords"   : ({ "<b>", "</b>" }),
    "xattributes" : ({ "<b>", "</b>" })
  ]);

  void create()
  {
    ::create();

    kw_order  = ({ "_xkeywords",
		   "xattributes",
                   "_keywords", // From RXML
                   "keywords",
                   "attributes" });
    colors   += ___colors;
    keywords += ___keywords;
    styles   += ___styles;
  }
}