import Standards.XML.Namespace;

constant PIKE_STRING    = 1<<0;
constant PIKE_FLOAT     = 1<<1;
constant PIKE_INT       = 1<<2;
constant PIKE_MAPPING   = 1<<3;
constant PIKE_ARRAY     = 1<<4;
constant PIKE_MULTISET  = 1<<5;
constant PIKE_OBJECT    = 1<<6;
constant PIKE_PROGRAM   = 1<<7;
constant PIKE_FUNCTION  = 1<<8;
constant PIKE_CLASS     = 1<<9;
constant PIKE_DATE      = 1<<10;
constant PIKE_NIL       = 1<<11;

//! Check (lazy) if object @[o] is a Calendar object
//!
//! @param o
int(0..1) is_date_object(object o) // {{{
{
  return has_prefix(sprintf("%O", object_program(o)), "Calendar");
} // }}}

//! Returns a string representation of Pike type @[t]
//!
//! @param t
string pike_type_to_string(int t) // {{{
{
  return ([ PIKE_STRING   : "string",
            PIKE_FLOAT    : "float",
	    PIKE_INT      : "int",
	    PIKE_MAPPING  : "mapping",
	    PIKE_ARRAY    : "array",
	    PIKE_MULTISET : "multiset",
	    PIKE_OBJECT   : "object",
	    PIKE_PROGRAM  : "program",
	    PIKE_FUNCTION : "function",
	    PIKE_CLASS    : "class",
	    PIKE_DATE     : "dateTime",
	    PIKE_NIL      : "undefined" ])[t]||PIKE_NIL;
} // }}}

//! Tries to find the Pike type of @[v]
//!
//! @param v
int get_pike_type(mixed v) // {{{
{
  if (stringp(v))
    return PIKE_STRING;

  if (floatp(v))
    return PIKE_FLOAT;

  if (intp(v))
    return PIKE_INT;

  if (mappingp(v))
    return PIKE_MAPPING;

  if (arrayp(v))
    return PIKE_ARRAY;

  if (multisetp(v))
    return PIKE_MULTISET;

  if (objectp(v)) {
    if (is_date_object(v))
      return PIKE_DATE;

    return PIKE_OBJECT;
  }

  if (programp(v))
    return PIKE_PROGRAM;

  if (functionp(v) || callablep(v))
    return PIKE_FUNCTION;

  return PIKE_NIL;
} // }}}

//! Serializes the internal @[container] array
//!
//! @param v
string serialize(mixed v)
{
  string s = "";
  int type = get_pike_type(v);
  
  switch (type) 
  {
    case PIKE_STRING:
      s += replace(v, ({ "&", "<", ">" }), ({ "&amp;", "&lt;", "&gt;" }));
      break;

    case PIKE_INT:
      s += (string)v;
      break;

    case PIKE_FLOAT:
      s += sprintf("%.2f", v);
      break;

    case PIKE_DATE:
      s += v->format_ymd() + " " + v->format_xtod();
      break;

    case PIKE_PROGRAM:
    case PIKE_MAPPING:
      /* Fall through */
    case PIKE_OBJECT:
      foreach (indices(v), string key)
	if (!functionp( v[key] ))
	  s += sprintf("<%s>%s</%s>", key, serialize( v[key] ), key);
      break;

    case PIKE_MULTISET:
      v = (array)v;
      /* Fall through */
    case PIKE_ARRAY:
      foreach (v, mixed av) {
	string type = pike_type_to_string(get_pike_type(av));
	s += sprintf("<%s>%s</%s>", type, serialize(av), type);
      }

      break;

    default:
      /* Nothing */
  }
  
  return s;
}

class Type
{
  protected QName name;
  protected string prefix;
  
  void create(QName|string _name)
  {
    if (!objectp(_name)) 
      name = QName("", _name);
    else
      name = _name;
  }
}

class String
{
  inherit Type : __type;
  inherit Standards.XSD.Types.String : __string;
  
  void create(QName|string name, string value)
  {
    __type::create(name);
    __string::create(value);
  }
}