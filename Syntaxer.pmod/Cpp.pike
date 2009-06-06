inherit .Hilite;

public string title = "C++";

protected int(0..1) macro = 1;

//| Override the keywords mapping
private mapping(string:multiset(string)) keywords = ([
  "keywords" : (<
    "auto","bool","break","case","catch","char","cerr","cin","class","const",
    "continue","cout","default","delete","do","double","else","enum",
    "explicit","extern","float","for","friend","goto","if","inline","int",
    "long","namespace","new","operator","private","protected","public",
    "register","return","short","signed","sizeof","static","struct","switch",
    "template","this","throw","try","typedef","union","unsigned","virtual",
    "void","volatile","while","__asm","__fastcall","__based","__cdecl",
    "__pascal","__inline","__multiple_inheritance","__single_inheritance" >),

  "compiler" : (<
    "define","error","include","elif","if","line","else","ifdef","pragma" >)
]);

//| Override the default since # is no line comment in C++
protected array(string) linecomments = ({ "//" });

void create()
{
  ::create();
  colors += ([ "compiler" : "#060" ]);
  styles += ([ "compiler" : ({ "<b>", "</b>" }) ]);
}