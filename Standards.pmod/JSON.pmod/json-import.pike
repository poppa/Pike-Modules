//! @author Johan Sundström

//! intended for use by inheritance

//! decode @[input] into native pike types
mixed decode_json( string|Stdio.File input ) {
  if( stringp( input ) )
    input = Stdio.FakeFile( input );
  PeekReader data = PeekReader( input );
  //function ignore = Regexp( "^\\);?$" )->match;
  //  data->ignore_trailing = ignore;
  while( data->peek() == "" ) {
    data->read(1);
  }
  return decode( data );
}

object true = class { string _sprintf(){ return "true"; } }();
object false= class { string _sprintf(){ return "false";} }();
object null = class { string _sprintf(){ return "null"; } }();

class PeekReader( Stdio.File f )
{
  function ignore_trailing = lambda( string s ){ return 0; };
  string buf;
  string read( int i )
  {
    if( buf )
    {
      string ret = buf + f->read(i-1);
      buf = 0;
      return ret;
    }
    return f->read(i);
  }

  string peek()
  {
    if(!buf) buf=f->read(1);
    return buf;
  }
}

string get_token(PeekReader f)
{
  string out = "";

  while( 1 )
  {
    string c = f->read(1);
    if( c == "" ) return 0;
    switch( c[0] )
    {
      case '{':
      case '}':
      case ':':
      case ',':
      case '[':
      case ']':
	return c;

      case 't':
	if( f->read(3)!="rue" ) error("Illegal tokens.\n");
	return "true";

      case 'f':
	if( f->read(4)!="alse" ) error("Illegal tokens.\n");
	return "false";

      case 'n':
	if( f->read(3)!="ull" ) error("Illegal tokens.\n");
	return "null";

      case '\"':
	while( 1 )
	{
	  switch(c=f->read(1))
	  {
	    case "": error("EOF in string.\n");
	    case "\"": return "\"" + out + "\"";

	    case "\\":
	      switch(f->read(1))
	      {
		case "\"": out += "\""; break;
		case "\\": out += "\\"; break;
		case "/": out += "/"; break;
		case "b": out += "\b"; break;
		case "f": out += "\f"; break;
		case "n": out += "\n"; break;
		case "r": out += "\r"; break;
		case "t": out += "\t"; break;
		case "u":
		  int char;
		  // No verification that u is followed by 4 hex.
		  sscanf(f->read(4), "%4x", char);
		  out += sprintf("%c", char);
		  //werror( "char %O\n", char);
		  break;
		default:
		  error("Illegal escaped character.\n");
	      }
	      break;

	    default:
	      out += c;
	      //werror( "c %O\n", c);
	      break;
	  }
	}
	throw( "This will never happen!" );
	break; // This will never happen

      case '-':
      case '0'..'9':
	out += c;
        if(c[0]>'0')
	  while( (< "0", "1", "2", "3", "4", "5",
		    "6", "7", "8", "9" >)[f->peek()] )
	    out += f->read(1);
	if(f->peek()==".")
	{
	  out += f->read(1);
	  while( (< "0", "1", "2", "3", "4", "5",
		    "6", "7", "8", "9" >)[f->peek()] )
	    out += f->read(1);
	}
	if( lower_case(f->peek())=="e" )
	{
	  out += f->read(1);
	  out += f->read(1); // +, -, or digit. Should check.
	  while( (< "0", "1", "2", "3", "4", "5",
		    "6", "7", "8", "9" >)[f->peek()] )
	    out += f->read(1);
	}
	return out;

      default:
	//werror( c+"\n" );
    }
  }
}

function is_float = Regexp("[.eE]")->match;

mixed decode( PeekReader f )
{
  mixed ret;
  string t = get_token(f);
  //werror( "token %O\n", t );
  if(!t) error("EOF\n");
  switch(t[0])
  {
    // Number
    case '-':
    case '0'..'9':
      if(is_float(t)) return (float)t;
    return (int)t;

    // String
    case '\"':
      return t[1..sizeof(t)-2];

    // Array
    case '[':
      ret = ({});
      while(1)
      {
	ret += ({ decode(f) });
	if( get_token(f)=="]" ) return ret;
	// We could check that token is ",".
      }

    // Mapping (Object literal)
    case '{':
      ret = ([]);
      while(1)
      {
	t = get_token(f);
	if( t=="}" ) return ret;
	string index = t[1..sizeof(t)-2];

	t = get_token(f);
	// We could check that token is ":".
	//werror( "didn't check : == %O\n", t );

	ret[index] = decode(f);

	t = get_token(f);
	if( t=="}" ) return ret;
	// We could check that token is ",".

	//werror( "didn't check , == %O\n", t );
      }

    case 'n': return null;
    case 't': return true;
    case 'f': return false;

    default:
      error("Illegal token %O\n", t);
  }
}
