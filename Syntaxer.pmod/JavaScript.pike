inherit .Hilite;

public string title = "JavaScript";

protected multiset(string) delimiters = (<
  ",","(",")","{","}","[","]","-","+","*","%","/","=","\"","'",
  "~","!","&","|","<",">","?",":",";","." >);

protected mapping(string:multiset(string)) keywords = ([
  "keywords" : (<
    "abstract","boolean","break","byte","case","catch","char","class","const",
    "continue","default","delete","do","double","else","extends","false",
    "final","finally","float","for","function","goto","if","implements",
    "import","in","instanceof","int","interface","long","native","new","null",
    "package","private","protected","public","return","short","static","super",
    "switch","synchronized","this","throw","throws","transient","true","try",
    "var" >),

  "functions" : (<
     "alert","clearTimeout","concat","confirm","dump","escape","eval","parse" 
  >),

  "objects" : (<
    "_content","ActiveXObject","Anchor","anchors","all","Applet","applets",
    "Application","Area","Array","attributes","body","Button","cells",
    "Checkbox","children","classes","Components","contextMenu","cookie",
    "crypto","cssRules","Date","document","elements","embeds","Event","event",
    "FileUpload","filters","firstChild","floder","Form","forms","Frame",
    "frames","Function","Hidden","history","Image","images","interfaces",
    "layers","Link","links","location","makearray","Math","MimeType",
    "mimeTypes","navigator","node","Object","options","parent","parentElement",
    "parentNode","parentWindow","prototype","Password","Plugin","plugins",
    "previousSibling","Radio","referrer","RegExp","Reset","rows","rules",
    "Select","selection","self","String","style","Submit","Text","Textarea" >),

  "methods" : (<
    "abs","acos","addEventListener","anchor","Apply","asin","atan",
    "attachEvent","alinkColor","back","big","bold","blink","blur",
    "captureEvents","ceil","clear","close","charAt","charCodeAt","collapse",
    "cos","createElement","createRange","createTextRange","delayedOpenWindow",
    "execCommand","exp","fixed","floor","focus","fontcolor","fontFamily",
    "fontsize","forward","fromCharCode","getAttribute","getDate","getDay",
    "getElementById","getElementsByTagName","getHours","getMinutes","getMonth",
    "getNext","GetResource","getSeconds","getSelection","getService",
    "GetTarget","getTime","getTimezoneOffset","getYear","go","hasMoreElements",
    "indexOf","italics","javaEnabled","lastIndexOf","link","log",
    "makeURLAbsolute","match","max","min","open","openDialog","Play","pow",
    "queryCommandValue","QueryInterface","random","reload","removeAttribute",
    "replace","reset","resizeTo","resolve","round","scroll","scrollBy",
    "select","setAttribute","setDate","setHours","setInterval","setMinutes",
    "setMonth","setSeconds","setTime","setYear","ShellExecute","sin","small",
    "split","sqrt","Stop","strike","sub","submit","substr","substring","sup",
    "tan","target","test","toGMTString","toLocaleString","toLowerCase" >),
		
  "attributes" /* Object and Vars */ : (<
    "action","alt","align","alignment","appCodeName","appName","appVersion",
    "arguments","background","backgroundColor","baseURI","bgColor","border",
    "borderColor","borderStyle","borderWidth","cellPadding","cellSpacing",
    "characterSet","checkboxName","checked","className","clientHeight",
    "clientWidth","color","colorDepth","cpuClass","curLeft","cursor","curTop",
    "cssText","defaultStatus","description","disabled","display","E",
    "encoding","fgColor","filter","focusedWindow","fontFamily","fontSize",
    "fontStyle","fontWeight","gapLeft","gapTop","hasBGImage","hash","height",
    "host","hostname","href","icon","id","inFrame","innerHTML","innerHeight",
    "innerText","innerWidth","keyCode","lastMatch","lastModified","length",
    "left","link","linkColor","LN2","LN10","localName","LOG2E","LOG10E",
    "maxlength","method","MM_p","MM_pgH","MM_pgW","MOUSEMOVE","MOUSEOUT",
    "MOUSEOVER","name","nodeName","number","offsetHeight","offsetWidth",
    "onblur","onclick","ondblclick","onerror","onImage","onkeyup","onkeydown",
    "onLink","onload","onmousedown","onMouseMove","onmousemove","onmouseout",
    "onmouseover","onmouseup","onresize","onunload","opener","opera",
    "outerHTML","pageX","pageY","pageYOffset","pageXOffset","pathname","PI",
    "pixelDepth","pixelHeight","pixelLeft","pixelTop","pixelWidth","port",
    "protocol","scrollLeft","scrollTop","search","selected","selectedIndex",
    "selectorText","SQRT2","SQRT1_2","src","srcElement","status","tagName",
    "target","text","title","top","type","uniqueID","userAgent","value" >)
]);

private mapping(string:string) _colors = ([
  "classes"    : "#973",
  "objects"    : "#55C",
  "methods"    : "#C0A",
  "attributes" : "#958"
]);

protected array linecomments  = ({ "//" });

void create()
{
  ::create();
  colors += _colors;
}