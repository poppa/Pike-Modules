/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! JSON.pmod is simply a JSON encoder/decoder
//|
//| Copyright © 2010, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| JSON.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| JSON.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with JSON.pmod. If not, see <http://www.gnu.org/licenses/>.

#include "json.h"

//! Decode a JSON string into a Pike data type
//!
//! @para json_data
mixed decode(string json_data)
{
  return __decoder->decode(json_data);
}

//! Encode a Pike data type into a JSON string
//!
//! @param pike_data
//! @param readable
//!  If @tt{1@} indentation and line breaks will be added to the output.
//!  Useful for debugging
string encode(mixed pike_data, void|int(0..1) readable)
{
  return __encoder->encode(pike_data, readable);
}

//! Decodes unicode escaped characters. Like @tt{\\u00e5@} becomes @tt{å@}.
//!
//! @param s
string decode_unicode_chars(string s)
{
  sscanf(s, "%{%*s\\u%4[0-9a-fA-F]%}", array m);
  mapping used = ([]);
  foreach (m[*][0], string hex) {
    if ( used[hex] ) continue;
    sscanf(hex, "%x", int char);
    s = replace(s, "\\u"+hex, sprintf("%c", char));
    used[hex] = 1;
  }

  return s;
}

//! Object representing a JSON null data type
object null  = class { string _sprintf() { return "null";  } }();

//! Object representing a JSON false statement.
object false = class {
  int(0..1) `==(mixed c) { return intp(c) && c == 0; }
  int(1..1) `!() { return 1; }
  string _sprintf() { return "false"; } 
}();

//! Object representing a JSON true statement
object true = class { 
  int(0..1) `==(mixed c) { return intp(c) && c > 0; }
  int(0..0) `!() { return 0; }
  string _sprintf() { return "true";  }
}();

private class Encoder
{
  private String.Buffer buf;
  private int(0..1) rd;
  private int level = 0;

  string encode(mixed data, void|int(0..1) readable)
  {
    rd = readable;
    buf = String.Buffer();
    encode_value(data);
    return buf->get();
  }

  void encode_value(mixed val)
  {
    if (zero_type(val))
      add("null");
    else if (stringp(val))
      add("\"%s\"", val);
    else if (intp(val))
      add("%d", val);
    else if (floatp(val))
      add("%f", val);
    else if (arrayp(val)) {
      int len = sizeof(val);
      int i = 0;
      add("[");
      foreach (val, mixed v) {
	encode_value(v);
	if (++i < len)
	  add(",");
      }
      add("]");
    }
    else if (mappingp(val) || objectp(val)) {
      if (objectp(val)) {
      	if (val == null) {
      	  add("null");
      	  return;
      	}
      	else if (val == false) {
      	  add("false");
      	  return;
      	}
      	else if (val == true) {
      	  add("true");
      	  return;
      	}
      }
      int len = sizeof(val);
      int i = 0;
      add("{");
      foreach (indices(val), int|string k) {
	mixed v = val[k];
      	if (stringp(k))
	  add("\"%s\":", k);
	else 
	  add("%d:", k);

      	encode_value(v);

      	if (++i < len) {
      	  add(",");
      	}
      }
      add("}");
    }
    else
      error("Unhandled Pike type: %O\n", val);
  }
}

private class Decoder
{
  private int len;
  private int p = -1;
  private string data;

  private mixed parse()
  {
    mixed ret;
    skip_white();
    string buf = "";
    getc(buf);

    switch ( buf[0] )
    {
      // Delimiter
      case ',':
      case ':':
	p++;
	parse();
      	break;

      // String quotes
      case '\'':
      case '"':
	ret = "";
	read_to(buf[0], ret);
	return ret;

      // Array
      case '[':
	ret = ({});
	skip_white();

	// Empty array found
	if (data[p+1] == ']')
	  return p++ && ret;

	while (++p < len) {
	  skip_white();
	  int c = data[p];
	  if (c == ']')
	    return ret;
	  else if (c == ',')
	    continue;

	  ret += ({ parse() });
	}
	break;

      // Object
      case '{':
      	ret = ([]);
      	skip_white();
      	
      	// Empty object
      	if (data[p+1] == '}')
      	  return p++ && ret;

      	string key = "";
      	index: while (++p < len) {
      	  skip_white();
      	  int c = data[p];
      	  switch (c)
      	  {
	    case '}':
	      return ret;

	    case '"':
	    case '\'':
	    case ',':
	      break;

	    case ':':
	      ++p;
	      ret[key] = parse();
	      key = "";
	      break;

	    default:
	      key += data[p..p];
	      break;
	  }
      	}

	break;

      // Numerics
      case '-':
      case '0'..'9':
	if (search(buf, ".") > -1 || buf[-1] == 'e' || buf[-1] == 'E')
	  return (float)buf;
	return (int)buf;
	break;

      // undefined
      case 'u':
	if (data[p..p+8] == "undefined") {
	  p += 8;
	  return UNDEFINED;
	}
	error("Illegal character \"%c\" at byte %d\n", buf[0], p);

      // false
      case 'f':
	if (data[p..p+4] == "false") {
	  p += 4;
	  return false;
	}
	error("Illegal character \"%c\" at byte %d\n", buf[0], p);

      // true
      case 't':
	if (data[p..p+3] == "true") {
	  p += 3;
	  return true;
	}
	error("Illegal character \"%c\" at byte %d\n", buf[0], p);

      // null
      case 'n':
	if (data[p..p+3] == "null") {
	  p += 3;
	  return null;
	}
	error("Illegal character \"%c\" at byte %d\n", buf[0], p);

      default:
	error("Illegal character \"%c\" at byte %d!\n", buf[0], p);
    }

    return ret;
  }

  mixed decode(string _data)
  {
    len = sizeof(_data);
    if (len == 0) return UNDEFINED;
    // Pad for peeking so that we don't run out of offset
    data = _data + "\0\0\0\0\0\0";
    return parse();
  }
}