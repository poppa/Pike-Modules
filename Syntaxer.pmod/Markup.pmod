
class HTML // {{{ HTML
{
  inherit .Hilite;
  inherit .HTMLParser;

  public string title = "HTML";
  public int tabsize = 2;
	
  protected string escape;
  protected array(string) linecomments = ({});
  protected array(array(string)) blockcomments = ({ ({ "<!--", "-->" }) });

  protected multiset(string) delimiters = (<
    "<",">","/","=","\"","'","%",",",".","(",")","{","}",
    "[","]","+","*","~","&","|",";" >);

  protected mapping(string:multiset(string)) _keywords = ([
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
      "wrap" >),

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
      "thead","title","tr","tt","u","ul","var","wbr","xmp" >)
  ]);

  protected mapping(string:string) _colors = ([
    "attributes" : "#F06",
    "entity"     : "#770"
  ]);
  
  protected mapping(string:array(string)) _styles = ([
    "entity" : ({ "<b>", "</b>" })
  ]);

  void create()
  {
    ::create();
    case_sensitive = 0;
    colors += _colors;
    keywords += _keywords;
    styles = _styles;
  }
} // }}}

class RXML // {{{
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
      "insert", "email" >)
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
    colors += __colors;
    keywords += __keywords;
    blockcomments += ({ ({ "<?comment", "?>" }) });
    styles = _styles;
  }
  
  string _sprintf(int t)
  {
    return ::_sprintf(t);
  }
} // }}}

class XSL // {{{ Hilite_XSL
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
      "xsl:namespace-alias","?xml" >),

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
      "zero-digit","test","terminate","stylesheet-prefixt",
      "result-prefix","omit-xml-declaration","cdata-section-elements",
      "exclude-result-prefixes","xmlns:xsl","xmlns:fo","xmlns:php",
      "xsl:extension-element-prefixes" >)
  ]);

  private mapping(string:string) ___colors = ([
    "_xkeywords"   : "#50B",
    "xattributes" : "#707"
  ]);

  protected mapping(string:array(string)) ___styles = ([
    "_xkeywords"   : ({ "<b>", "</b>" }),
    "xattributes" : ({ "<b>", "</b>" })
  ]);

  void create()
  {
    ::create();

    colors   += ___colors;
    keywords += ___keywords;
    styles   += ___styles;
  }
} // }}}