inherit .C;

public string title = "CMOD - Pike C Module";

void create()
{
  ::create();

  mapping old_kw = ::keywords;
  keywords = ([
  "keywords"  : old_kw->keywords,
  "cmodwords" : (< "PIKEFUN","PIKECLASS","DECLARATIONS","INIT","EXIT",
                   "PIKE_MODULE_INIT","PIKE_MODULE_EXIT","THIS",
                   "RETURN","CVAR","PIKEVAR" >),
  "cmodfunc"  : (< "pop_n_elems","Pike_error","make_shared_string","push_int",
                   "push_string","push_mapping","push_array",
                   "add_integer_constant","add_string_constant","f_aggregate",
                   "f_aggregate_mapping" >),
  "constants" : (< "T_INT","T_STRING","T_FUNCTION","T_OBJECT","T_MAPPING",
                   "T_FLOAT","T_PROGRAM","T_MULTISET","T_ARRAY" >) + 
                   old_kw->constants
  
  ]);
  colors->cmodwords    = "#1E719E";
  colors->cmodfunc     = "#6C0820";
  colors->constants    = "#4A007B";
  styles->cmodwords    =
  styles->cmodfunc     = ({ "<b>","</b>" });

  kw_order = indices(keywords);
}
