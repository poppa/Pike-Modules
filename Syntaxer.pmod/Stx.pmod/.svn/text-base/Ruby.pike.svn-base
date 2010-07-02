inherit "../Parser.pike";

public string title = "Ruby";

protected multiset(string) delimiters = (<
  ",","(",")","{","}","[","]","-","+","*","/","=","~","&","|",
  "?",":",";",".","!" >);

private mapping(string:multiset(string)) _keywords = ([
  "keywords" : (<
    "alias","and","begin","BEGIN","break","case","class","def","defined","do",
    "each","else","elsif","end","END","ensure","false","for","if","in",
    "module","next","nil","not","or","redo","rescue","retry","return","self" >),

  "functions" : (<
    "Array","at_exit","autoload","binding","caller","catch","chomp","chomp!",
    "chop","chop!","eval","exec","exit","exit!","fail","Float","fork","format",
    "gets","get","global_variables","gsub","gsub!","Integer","iterator?",
    "join","lambda","load","local_variables","loop","mkdir","open","p","print",
    "printf","proc","putc","puts","raise","rand","readline","readlines",
    "require","select","sleep","slice","split","sprintf","srand","String" >),

  "constants" : (<
    "ARGF","ARGV","DATA","ENV","FALSE","NIL","RUBY_PLATFORM" >),

  "classes" /* and modules */ : (<
    "ArgumentError","Array","Bignum","Class","Data","Dir","EOFError",
    "Exception","fatal","File","Fixnum","Float","FloatDomainError","Hash",
    "IndexError","Integer","Interrupt","IO","IOError","LoadError",
    "LocalJumpError","MatchingData","Module","NameError","NilClass",
    "NotImplementError","Numeric","Object","Proc","Range","Regexp",
    "RuntimeError","SecurityError","SignalException","StandardError","String",
    "Struct","SyntaxError","SystemCallError","SystemExit","SystemStackError",
    "ThreadError","Time","TypeError","ZeroDivisionError","Comparable",
    "Enumerable","Errno","FileTest","GC","Kernel","Marshal","Math" >)
]);

protected mapping(string:string) prefixes = ([
  "prefix"  : "$",
  "prefix2" : "@",
  "prefix3" : "%"
]);

private mapping(string:string) _colors = ([
  "prefix"    : "#900",
  "prefix2"   : "#909",
  "classes"   : "#973"
]);

private mapping(string:array(string)) _styles = ([
  "prefix"  : ({ "<b>", "</b>" }),
  "prefix2" : ({ "<b>", "</b>" }),
  "classes" : ({ "<b>", "</b>" })
]);

protected array(array) blockcomments = ({ ({ "=begin", "=end" }) });
protected array linecomments  = ({ "#" });

void create()
{
  tabsize = 2;
  quotes += ({ "`" });
  keywords  = _keywords;
  colors += _colors;
  styles += _styles;
  case_sensitive = 1;
  ::create();
}