//| Tab width: 8
//| Indent width: 2

//! Pike Json encoder/decoder
//!
//! Copyright © 2008 Pontus Östlund <pontus@poppa.se>
//!
//! A port of the following PHP script
//! @url{http://mike.teczno.com/JSON/JSON.phps@}
//!
//! Orginal Json encoder/decoder
//! @ul
//!  @item
//!   Author      Michal Migurski <mike-json@teczno.com>
//!  @item
//!   Author      Matt Knapp <mdknapp[at]gmail[dot]com>
//!  @item
//!   Author      Brett Stimmerman <brettstimmerman[at]gmail[dot]com>
//!  @item
//!   Copyright © 2005 Michal Migurski
//| @endul
//!
//| LICENSE: Redistribution and use in source and binary forms, with or
//| without modification, are permitted provided that the following
//| conditions are met: Redistributions of source code must retain the
//| above copyright notice, this list of conditions and the following
//| disclaimer. Redistributions in binary form must reproduce the above
//| copyright notice, this list of conditions and the following disclaimer
//| in the documentation and/or other materials provided with the
//| distribution.
//|
//| THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
//| WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//| MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
//| NO EVENT SHALL CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//| INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//| BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//| OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//| ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//| TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
//| USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
//| DAMAGE.

//! Brief example of use:
//!
//! @xml{<code lang='pike' detab='3' tabsize='2'>
//!   // create a new instance of Json
//!   .Json json = .Json();
//!
//!   // convert a complexe value to JSON notation, and send it to the browser
//!   array value = ({ "foo", "bar", ({ 1, 2, "baz" }),
//!                    ([ "k1" : "v 1","k2" : "v 2" ]), "boom" });
//!   string output = json->encode(value);
//!
//!   write(output);
//!   // prints: ["foo","bar",[1,2,"baz"],{"k1":"v 1","k2":"v 2"},"boom"]
//!
//!   // accept incoming POST data, assumed to be in JSON notation
//!   string input = "some post data in Json notation"
//!   mixed value = json->decode(input);
//!
//|   =======================================================================
//!
//!   // In a Roxen module
//!
//!   array a = ({ "one", 2, ({ "three", "four" }), 5 });
//!   RoxenModule json_mod = configuration->get_provider("json");
//!   string encoded = json_mod->Json()->encode(a);
//!   // Result: ["one",2,["three","four"],5]
//! </code>@}

// #define DEBUG
#define TRIM(x)  String.trim_all_whites(x)
#define ERROR(E) throw ( ({ "Json error: " + E + "\n", backtrace() }) )
#define NAME_VALUE(name, value) ({ encode(name), encode(value) }) * ":"
#define RFROM                   ({ "\r\n","\r","\\\"","\"" })
#define RTO                     ({ "\n","\n","\"","\\\"" })
#define escape_string(s)        (replace(s, RFROM, RTO))
#define rtrim(x, y)             (reverse(ltrim(reverse(x), y)))

//### Roxen stuff ##############################################################
#if constant (roxen)

#include <config.h>
#include <module.h>
inherit "module";

constant thread_safe = 1;
constant module_type = MODULE_PROVIDER;
constant module_name = "TVAB Tags: JSON";
constant module_doc  = "JSON encoder/decoder provider";

void create(Configuration conf)
{
  set_module_creator("Pontus Östlund <pontus.ostlund@tekniskaverken.se>");
}

multiset(string) query_provides() { return (< "json" >); }

#endif // end Roxen stuff
//##############################################################################

//! @constant
//! Marker constant for @[Json()->decode()], used to flag stack state
constant JSON_SLICE           = 1;

//! @constant
//! Marker constant for  @[Json()->decode()], used to flag stack state
constant JSON_IN_STR          = 2;

//! @constant
//! Marker constant for  @[Json()->decode()], used to flag stack state
constant JSON_IN_ARR          = 3;

//! @constant
//! Marker constant for  @[Json()->decode()], used to flag stack state
constant JSON_IN_OBJ          = 4;

//! @constant
//! Marker constant for  @[Json()->decode()], used to flag stack state
//! @deprecated Not useful in this Pike version. All comments are stripped
//! in Json()->reduce_string()
constant JSON_CMT             = 5;

//! @constant
//! Behavior switch for  @[Json()->decode()]
//! @deprecated Not useful in this Pike version
constant JSON_LOOSE_TYPE      = 16;

//! @constant
//! Behavior switch for  @[Json()->decode()]
//! @deprecated Not useful in this Pike version
constant JSON_SUPPRESS_ERRORS = 32;

#if constant (roxen)
// If run as a Roxen module we need a class definition since the module it self
// needs a constructor and we can't have two constructors can we!
class Json {
#endif

//!
int use;

//! Constructs a new Json instance
//!
//! @param _use
//!   This is not useful in this Pike version
void create(int|void _use)
{
  use = _use||0;
}

//! Encodes an arbitrary variable into JSON format
//!
//! @param var
//!   any int, float, string, array, mutliset or mapping to be encoded.
//!   if @[var] is a string, note that encode() always expects it to be in
//!   ASCII or UTF-8 format!
//!
//! @returns
//!   JSON string representation of input @[var]
//!
//! @throws
//!   An error if an un-encodable variables is fed
string encode(mixed var)
{
  if (zero_type(var))
    return "null";

  if (stringp(var)) {
    var = escape_string(var);
    return "\"" + Locale.Charset.encoder("us-ascii")->feed(var)->drain() + "\"";
  }

  if (arrayp(var) || multisetp(var))
    return "[" + map((array)var, encode)*"," + "]";

  if (mappingp(var)) {
    array keys = indices(var);
    array vals = values(var);
    if (sizeof(keys) != sizeof(vals))
      ERROR("A seriously f**ked up mapping was found! "
            "sizeof(keys) != sizeof(values)");

    array properties = ({});
    for (int i = sizeof(keys)-1; i >= 0; i--)
      properties += ({ NAME_VALUE( keys[i], vals[i] ) });

    return "{" + properties*"," + "}";
  }

  if (objectp(var))
    ERROR("Can not encode an object!");

  if (programp(var))
    ERROR("Can not encode a program");

  return (string)var;
}

//! Decodes a JSON string into appropriate variable
//!
//! @throws
//!   An error if an ECMA object with mismatching key/value pairs is found
//!
//! @param str
//!   JSON-formatted string
//!
//! @param dont_utf8_encode
//!   If 1 strings won't be utf8_encoded (my addition)
//!
//! @returns
//!   int, float, boolean, string, array, or mapping corresponding to given
//!   JSON input string.
mixed decode(string str, int(0..1)|void dont_utf8_encode)
{
  str = reduce_string(str);

  switch (lower_case(str))
  {
    case "true": return 1;

    case "false":
    case "null":
      return 0;

    default:
      array m = ({});
      string chrs;

      if (sscanf(str, "%{%[-0-9]%}", array a) && sizeof(a) > 0) {
	//wlog("=== Numeric value");
	return (float)str == (float)((int)str) ? (int)str : (float)str;
      }
      else if (sscanf(str, "\"%*s\"") > 0 || sscanf(str, "'%*s'") > 0) {
	//wlog("::: String value");
	return dont_utf8_encode ?
	       str[1..sizeof(str)-2] :
	       string_to_utf8( str[1..sizeof(str)-2] );
      }
      else if (sscanf(str, "{%*s}") > 0 || sscanf(str, "[%*s]") > 0) {
	//wlog("+++ Object/Array notation");
	array stk, arr;
	mapping obj;

	if (str[0] == '[') {
	  stk = ({ JSON_IN_ARR });
	  arr = ({});
	}
	else {
	  stk = ({ JSON_IN_OBJ });
	  obj = ([]);
	}

	stk += ({ ([ "what"  : JSON_SLICE,
		     "where" : 0,
		     "delim" : 0 ]) });

	chrs = reduce_string( str[1..sizeof(str)-2] );

	if (!sizeof(chrs))
	  return stk[0] == JSON_IN_ARR ? arr : obj;

	int strlen_chrs = sizeof(chrs);

	for (int c = 0; c <= strlen_chrs; ++c) {
	  mapping top = stk[sizeof(stk)-1];

	  // found a comma that is not inside a string, array, etc.,
	  // OR we've reached the end of the character list
	  if ((c == strlen_chrs) ||
	     (chrs[c] == ',' && top->what == JSON_SLICE))
	  {
	    string slice = chrs[top->where..c-1];

	    stk += ({([ "what" : JSON_SLICE, "where" : c+1, "delim" : 0 ])});

	    if (stk[0] == JSON_IN_ARR)
	      arr += ({ this->decode( slice, dont_utf8_encode ) });
	    else if (stk[0] == JSON_IN_OBJ) {
	      int pos = search(slice, ":");
	      if (pos == -1)
		ERROR("Bad object/array notation");

	      array parts = ({ TRIM( slice[..pos-1] ),
	                       TRIM( slice[(pos+1)..] ) });

	      if (sizeof(parts) != 2) {
		ERROR("Bad key/value pair in object. length != 2! "
		      "This means you have a malformed Json string!");
	      }
	      else {
		[string k, string v] = parts;
		if (k[0] == '\'' || k[0] == '"')
		  k = this->decode(k, dont_utf8_encode);

		obj[k] = this->decode(v, dont_utf8_encode);
	      }
	    }
	  }
	  else if ((chrs[c] == '"' || chrs[c] == '\'') &&
		  top->what != JSON_IN_STR)
	  {
	    //wlog(">>> String begin");
	    stk += ({([ "what"  : JSON_IN_STR,
	                "where" : c,
			"delim" : chrs[c..c] ])});
	  }
	  else if ((chrs[c..c] == top->delim) &&
		  (top->what == JSON_IN_STR) &&
		  (( sizeof( chrs[..c] ) - sizeof(rtrim(chrs[..c], "\\")))
		  % 2 != 1))
	  {
	    //wlog(">>> In string");
	    stk = stk[..sizeof(stk)-2];
	  }
	  else if ((chrs[c] == '[') &&
		  (< JSON_SLICE, JSON_IN_ARR, JSON_IN_OBJ >)[top->what] )
	  {
	    //wlog(">>> Left bracet");
	    stk += ({([ "what" : JSON_IN_ARR, "where" : c, "delim" : 0 ])});
	  }
	  else if ((chrs[c] == ']') && (top->what == JSON_IN_ARR))
	  {
	    //wlog(">>> Right bracet in array");
	    stk = stk[..sizeof(stk)-2];
	  }
	  else if ((chrs[c] == '{') &&
		  (< JSON_SLICE, JSON_IN_ARR, JSON_IN_OBJ >)[top->what] )
	  {
	    //wlog(">>> Left brace in array, object or slice");
	    stk += ({([ "what" : JSON_IN_OBJ, "where" : c, "delim" : 0 ])});
	  }
	  else if ((chrs[c] == '}') && (top->what == JSON_IN_OBJ)) {
	    ///wlog(">>> Right brace in object");
	    stk = stk[..sizeof(stk)-2];
	  }
	}

	if (stk[0] == JSON_IN_ARR)
	  return arr;
	else if (stk[0] == JSON_IN_OBJ)
	  return obj;

      } // end object/array notation
  }
}

//! Reduce a string by removing comments and whitespace
//!
//! @param  str
//!   string value to strip of comments and whitespace
//!
//! @returns
//!   string value stripped of comments and whitespace
private string reduce_string(string str)
{
  string    out            = "";
  array     lines          = str / "\n";
  int(0..1) open_multiline = 0;
  int       pos;

  foreach (lines, string line) {
    string t = TRIM(line);

    if (t[0..1] == "//" || sizeof(t) == 0)
      continue;

    if ((pos = search(t, "/*")) > -1) {
      if (pos > 0) t = t[0..pos];

      // Multiline comment on one line!
      if (t[sizeof(t)-2..] == "*/")
	continue;

      open_multiline = 1;
      continue;
    }

    if (open_multiline && search(t, "*/") == -1)
      continue;
    if (open_multiline && (pos = search(t, "*/")) > -1) {
      if (pos+5 == sizeof(line)) {
	open_multiline = 0;
	continue;
      }
      line = line[pos+5..];
      open_multiline = 0;
    }

    out += TRIM(line);
  }

  return out;
}

#if constant (roxen)
} // end Json class definition in Roxen mode
#endif

string ltrim(string in, string|void char)
{
  if (char && sizeof(char)) {
    if (has_value(char, "-")) char = (char - "-") + "-";
    if (has_value(char, "]")) char = "]" + (char - "]");
    if (char == "^") {
      //  Special case for ^ since that can't be represented in the sscanf
      //  set. We'll expand the set with a wide character that is illegal
      //  Unicode and hence won't be found in regular strings.
      char = "\xFFFFFFFF^";
    }
    sscanf(in, "%*[" + char + "]%s", in);
  } else
    sscanf(in, "%*[ \n\r\t\0]%s", in);
  return in;
}

// Debugging method
void wlog(mixed ... args)
{
#ifdef DEBUG
# if constant (roxen)
  string fmt = args[0];
  if (sizeof(args) > 1)
    fmt = sprintf( fmt, @args[1..] );

  if (fmt[sizeof(fmt)-1..] != "\n")
    fmt += "\n";

  report_debug("JSON: " + fmt);
# else
  if (args && args[0][-1] != '\n')
    args[0] += "\n";

  werror(@args);
# endif
#endif
}
