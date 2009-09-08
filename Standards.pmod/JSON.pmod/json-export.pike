//! @author Johan Sundström

//! intended for use by inheritance

//! number of spaces to indent per level
int indent_step = 1;

//! stuff to insert to break up records visually
string line_separator = "\n";
string array_element_separator = " ";

// 1 to sort values in objects by the size of the serialized data, ascending;
// -1 descending, 0 to sort by index, paying attention to @[head] and @[tail].
int sort_by_size = 1;

//! keys to sort before or after others in the output presentation format:
array(string) head = ({}); // "id,uri,url,title,version,$t" / ",";
array(string) tail = ({}); // "link,feed,entry"/",";

//! encode @[data] into JSON form
string encode_json( mixed data, int|void level, string|void jsonp )
{
  string res = "", end = "", type = sprintf("%t", data);

  if( jsonp ) {
    res = jsonp + "(";
    end = ")";
  }
  switch( type )
  {
    case "int":
      return res + (string)data + end;

    case "float":
      data = reverse( (string)data );
      sscanf( data, "%*[0]%s", data );
      res += reverse( data );
      return (has_suffix( res, "." ) ? res + "0" : res) + end;

    case "string":
      return sprintf( "%s%O%s", res, data, end );

    case "mapping":
      array(string) ind = indices( data );
      array(string) val = map( values( data ), encode_json, level+indent_step );

      if( !sort_by_size )
	val = rows( mkmapping( ind, val ), ind = sort_by_relevance( ind ) );
      else {
	array(int) size = map( val, sizeof );
	sort( size, ind, val );
      }

      data = Array.transpose( ({ ind, val }) );
      if( sort_by_size < 0 )
	data = reverse( data );

      string fmt_pair( array indval ) {
	[mixed index, string value] = indval;
	return indent( encode_json( index, level ), level+indent_step ) +
	  ":" + value;
      };

      return res + "{" + line_separator +
	(map( data, fmt_pair ) * ("," + line_separator)) + line_separator +
	indent( "}", level ) + end;

    case "array":
      return res + "[" + (map( data, encode_json, level+indent_step ) *
			  ("," + array_element_separator)) + "]" + end;

    case "false":
    case "true":
    case "null":
      return res + type + end;

    default:
      throw( sprintf( "Can't handle %s: %O", type, data ) );
  }
}

// prettify
string indent( string value, int level )
{
  return sprintf( "%*s%s", level, "", value );
}

// information aesthetics
array(string) sort_by_relevance( array(string) properties )
{
  array first = ({}), last = ({});
  mapping there = mkmapping( properties, properties );
  foreach( head, string pick )
    if( has_index( there, pick ) )
      first += ({ m_delete( there, pick ) });
  foreach( tail, string pick )
    if( has_index( there, pick ) )
      last += ({ m_delete( there, pick ) });
  return first + sort( indices( there ) ) + last;
}

