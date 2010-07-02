inherit "../Parser.pike";

public string title = "Pike";
private mapping(string:multiset(string)) _keywords = ([
  "keywords" : (<
    "if","else","switch","case","default","break","class","continue","import",
    "do","for","foreach","inherit","return","typedef","lambda","catch",
    "throw","constant","global","this","this_program","public","private",
    "protected","inline","final","static","local","optional","nomask",
    "variant","do","while" >),

  //| Types
  "keywords1" : (<
    "mixed","float","int","program","string","function","array","mapping",
    "multiset","object","void" >),

  //| Pike modules
  "keywords2" : (<
    "ADT","Array","Audio","Bz2","Cache","Calendar","Calendar_I","Colors",
    "CommonLog","Crypto","DVB","Debug","Error","Filesystem","Float","Function",
    "GDK","GL","GLU","GLUE","GTK","Gdbm","Geography","Getopt","Gmp","Gnome",
    "Graphics","Gz","Image","Int","Java","Languages","Local","Locale","MIME",
    "Mapping","Math","Mird","Msql","Multiset","Mysql","Nettle","PDF","Parser",
    "Perl","Pike","Postgres","Process","Program","Protocols","Regexp","Remote",
    "SANE","SDL","SSL","Shuffler","Sql","Standards","Stdio","String","System"
    >),
    
  "functions" : (<
    "__empty_program","__parse_pike_type","_disable_threads","_do_call_out",
    "_exit","_next","_prev","_refs","_typeof","`!","`!=","`%","`&","`()","`*",
    "`+","`-","`->","`->=","`/","`<","`<<","`<=","`==","`>","`>=","`>>","`[]",
    "`[]=","`^","`|","`~","abs","acos","acosh","add_constant","aggregate",
    "aggregate_mapping","alarm","all_constants","allocate","array_sscanf",
    "arrayp","asin","asinh","atan","atan2","atanh","atexit","backtrace",
    "basename","basetype","call_function","call_out","call_out_info",
    "callablep","cd","ceil","column","combine_path","combine_path_amigaos",
    "combine_path_nt","combine_path_unix","compile","compile_file",
    "compile_string","copy_value","cos","cosh","cpp","crypt","ctime",
    "decode_value","delay","describe_backtrace","describe_error","destruct",
    "dirname","encode_value","encode_value_canonic","enumerate","equal",
    "errno","error","exece","exit","exp","explode_path","file_stat",
    "file_truncate","filesystem_stat","filter","find_call_out","floatp",
    "floor","fork","function_name","function_object","function_program",
    "functionp","gc","get_all_groups","get_all_users","get_backtrace",
    "get_dir","get_groups_for_user","get_iterator","get_profiling_info",
    "get_weak_flag","getcwd","getenv","getgrgid","getgrnam","gethrtime",
    "gethrvtime","getpid","getpwnam","getpwuid","glob","gmtime","has_index",
    "has_prefix","has_suffix","has_value","hash","hash_7_0","hash_7_4",
    "hash_value","indices","intp","is_absolute_path","kill","load_module",
    "localtime","log","lower_case","m_delete","map","mappingp","master","max",
    "min","mkdir","mkmapping","mkmultiset","mktime","multisetp","mv",
    "next_object","normalize_path","object_program","object_variablep",
    "objectp","pow","programp","putenv","query_num_arg","random","random_seed",
    "random_string","remove_call_out","replace","replace_master","reverse",
    "rm","round","rows","search","set_priority","set_weak_flag","sgn","signal",
    "signame","signum","sin","sinh","sizeof","sleep","sort","sprintf","sqrt",
    "strerror","string_to_unicode","string_to_utf8","stringp","strlen","tan",
    "tanh","this_object","throw","time","trace","ualarm","unicode_to_string",
    "upper_case","utf8_to_string","values","version","werror","write" >),
    
  //| Special functions
  "special_funcs" : (< "catch","gauge","sscanf","typeof" >),

  //| Roxen Modules
  "keywords3" : (<
    "Configuration",
    "DBManager",
    "SBObject",
    "SBFile",
    "SBDir",
    "RequestID",
    "Roxen",
    "RXML",
    "Variable" >),
]);

private mapping(string:string) _colors = ([
  "keywords1"     : "#09F",
  "keywords2"     : "#909",
  "keywords3"     : "#099",
  "special_funcs" : "#A90"
]);

//| Override the default since # is no line comment in pike
protected array(string) linecomments = ({ "//" });

//| Override default
protected int(0..1) macro = 1;

void create()
{
  werror("Init Pike parser\n");
  keywords += _keywords;
  colors += _colors;
  styles += ([ "keywords1"     : ({ "<b>", "</b>" }),
               "keywords2"     : ({ "<b>", "</b>" }),
	       "special_funcs" : ({ "<b>", "</b>" }) ]);

  ::create();
}