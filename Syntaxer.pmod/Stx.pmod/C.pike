//! C syntax highlighter

//!
inherit .Cpp;

public string title = "C";

void create()
{
  ::create();

  keywords = ([
    "keywords" : (<
      // ANSI-C
      "auto","break","case","char","const","continue","default","do","double",
      "else","enum","extern","float","for","goto","if","int","long","register",
      "return","short","signed","sizeof","static","struct","switch","typedef",
      "union","unsigned","void","volatile","while", 
      // GNU extension
      "asm","inline","typeof" >),
    "constants": (< "__FILE__","__LINE__","TRUE","FALSE","NULL" >),
    "compiler" : (<
      "define","error","include","elif","if","line","else","ifdef","pragma" >)
  ]);
}
