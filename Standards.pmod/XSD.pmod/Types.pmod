/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Standards.WSD.Types@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Types.pmod is part of XSD.pmod
//!
//! XSD.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! XSD.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with XSD.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

/* NOTE: Work in progress
 */

#define NSQN(V) Standards.XML.Namespace.QName(.NAMESPACE, (V), "xsd")

//!  XML Schema Namespace datatypes
//!
//! @seealso
//!  http://books.xmlschemata.org/relaxng/relax-CHP-19.html

int(0..1) LOOSE_CHECK = 0;

void set_loose_check(int(0..1) v) { LOOSE_CHECK = v; }

class NSDBase
{
  Standards.XML.Namespace.QName type;
  mixed     data;
  int(0..1) is_nil;

  protected void init(Standards.XML.Namespace.QName _type)
  {
    type = _type;
  }
}

class AnySimpleType
{
  inherit NSDBase;

  void create(mixed value)
  {
    init(NSQN(.ANY_SIMPLE_TYPE_LITERAL), value);
  }

  void set(mixed value)
  {
    if (zero_type(value)) {
      is_nil = 1;
      data = 0;
    }
    else {
      is_nil = 0;
      low_set(screen_data(value));
    }
  }

  mixed get()
  {
    return data;
  }

  Standards.XML.Namespace.QName get_type()
  {
    return type;
  }

  protected mixed screen_data(mixed value)
  {
    return value;
  }

  protected void init(Standards.XML.Namespace.QName type, mixed value)
  {
    ::init(type);
    set(value);
  }

  private void low_set(mixed value)
  {
    data = value;
  }

  string _sprintf(int t)
  {
    switch (t) 
    {
      case 's': return (string)data;
      case 'O': return sprintf("%O(%O, %O)", object_program(this), data, type);
    }
  }
}

class Nil
{
  inherit AnySimpleType;

  void create(void|mixed value)
  {
    ::init(NSQN(.NIL_LITERAL), .NIL_VALUE);
  }
}

class String
{
  inherit AnySimpleType;

  int(0..1) strict_validation = 0;

  void create(string value)
  {
    ::init(NSQN(.STRING_LITERAL), value);
  }

  protected string screen_data(string s)
  {
    s = (string) s;
    if (strict_validation)
      error("Strict validation not implemented yet!");

    return s;
  }
}

class Boolean
{
  inherit AnySimpleType;

  void create(string|int(0..1) value)
  {
    ::init(NSQN(.BOOLEAN_LITERAL), value);
  }

  protected int screen_data(string|int(0..1) value)
  {
    if (!value)
      return 0;

    if (stringp(value)) {
      if ( (< "true","1" >)[value] )
	value = 1;
      else if ( (< "false","0" >)[value] )
	value = 0;
      else
	if (!LOOSE_CHECK)
	  error("%O can not accept \"%s\"!", object_program(this), value);
    }

    return value;
  }
}

class Decimal
{
  inherit AnySimpleType;

  void create(string|float|int value)
  {
    ::init(NSQN(.DECIMAL_LITERAL), value);
  }

  protected float screen_data(string|float|int value)
  {
    if (intp(value))
      value = (float)value;
    if (stringp(value))
      value = screen_string(value);

    return value;
  }

  //! @note Not implemented...
  protected float screen_string(string value)
  {
    if (stringp(value)) {
      if (!LOOSE_CHECK)
	werror("warning: %O(), screening of decmial value not implemented. "
               "Data will simply be casted to float!\n",
	       object_program(this));
    }
    return (float)value;
  }
}

class Float
{
  inherit AnySimpleType;

  void create(float|int|string value)
  {
    ::init(NSQN(.FLOAT_LITERAL), value);
  }

  protected float screen_data(string|float|int value)
  {
    if (stringp(value)) {
      if (!LOOSE_CHECK)
	werror("warning: %O(), screening of floating point values not "
	       "implemented. Data will simply be casted to float!\n", 
	       object_program(this));
    }
    return (float) value;
  }
}

class Double
{
  inherit Float;

  void create(string|float|int value)
  {
    ::init(NSQN(.DOUBLE_LITERAL), value);
  }
}

//! @note not implemented
class Duration
{
  inherit AnySimpleType;

  string sign;
  int    year;
  int    month;
  int    day;
  int    hour;
  int    min;
  int    sec;

  void create(mixed value)
  {
    ::init(NSQN(.DURATION_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(mixed value)
  {
    error("%O() not implemented!", object_program(this));
  }
}

#define HAS_TZ_OFFSET(V) (sscanf((V), "%*s+%*d") > 0)
#define HAS_TZ(V)        (sscanf((V), "%*sZ") > 0)
#define HAS_SECFRAC(V)   (sscanf((V), "%*sT%*2d:%*2d:%2*d.%*d") > 4)

//! DateTime
//!
//! @seealso
//!  http://books.xmlschemata.org/relaxng/ch19-77049.html
class DateTime
{
  inherit AnySimpleType;
  
  void create(string value)
  {
    ::init(NSQN(.DATE_TIME_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    // Dunno if all dates are handled
    if (!value) return 0;

    string fmt = "%Y-%M-%DT%h:%m:%s";
    if (value[0] == '-')      fmt = "-" + fmt;
    if (HAS_SECFRAC(value))   fmt += ".%f";
    if (HAS_TZ(value))        fmt += "%z";
    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";

    return parse(value, fmt, "date-time");
  }

  protected Calendar.TimeRange parse(string value, string fmt, string type)
  {
    Calendar.TimeRange v;

    if (mixed e = catch(v = Calendar.parse(fmt, value)) || v == 0)
      if (!LOOSE_CHECK)
	error("%O(): Unknown %s: %s", object_program(this), type, value);

    return v;
  }

  string _sprintf(int t)
  {
    switch (t) 
    {
      case 's': return data->format_ymd()+"T"+data->format_tod();
    }
  }
}

class Time
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.TIME_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;

    string fmt = "%h:%m:%s";

    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";
    else if (HAS_TZ(value))   fmt += "%z";
    else if(sscanf(value, "%*2d:%*2d:%*2d.%*d") > 3) fmt += ".%f";

    return parse(value, fmt, "time");
  }
  
  string _sprintf(int t)
  {
    switch (t) 
    {
      case 's': return data->format_tod();
    }
  }
}

class Date
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.DATE_TIME_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;
    string fmt = "%Y-%M-%D";

    if (value && value[0] == '-') fmt = "-" + fmt;
    if (HAS_TZ(value)) fmt += "%z";
    else if (sscanf(value, "%*s+%*s") == 2) fmt += "+%h:%m";

    return parse(value, fmt, "date");
  }
  string _sprintf(int t)
  {
    switch (t) 
    {
      case 's': return data->format_ymd();
    }
  }
}

class GYearMonth
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.GYEAR_MONTH_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;

    string fmt = "%Y-%M-%D";

    sscanf(value, "%d-%d%s", int y, int m, string rest);
    string tmpval = sprintf("%d-%d-01%s", y, m, (string)rest);

    if (value[0] == '-')      fmt = "-" + fmt;
    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";
    else if (HAS_TZ(value))   fmt += "%z";

    return parse(tmpval, fmt, "year-month");
  }
}

class GYear
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.GYEAR_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;

    string fmt = "%Y-%M-%D";

    sscanf(value, "%d%s", int y, string rest);
    string tmpval = sprintf("%d-01-01%s", y, (string)rest);

    if (value[0] == '-')      fmt = "-" + fmt;
    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";
    else if (HAS_TZ(value))   fmt += "%z";

    return parse(tmpval, fmt, "year");
  }
}

class GMonthDay
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.GMONTH_DAY_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;

    string fmt = "%M-%D";

    sscanf(value, "--%d-%d%s", int m, int d, string rest);
    string tmpval = sprintf("%d-%d%s", m, d, (string)rest);

    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";
    else if (HAS_TZ(value))   fmt += "%z";

    return parse(tmpval, fmt, "month-day");
  }
}

class GDay
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.GDAY_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;

    string fmt = "%D";
    sscanf(value, "--%d%s", int d, string rest);
    string tmpval = sprintf("%d%s", -d, (string)rest);

    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";
    else if (HAS_TZ(value))   fmt += "%z";

    return parse(tmpval, fmt, "day");
  }
}

class GMonth
{
  inherit DateTime;

  void create(string value)
  {
    ::init(NSQN(.GMONTH_LITERAL), value);
  }

  protected Calendar.TimeRange screen_data(string value)
  {
    if (!value) return 0;

    string fmt = "%M-%D";
    sscanf(value, "--%d%s", int d, string rest);
    string tmpval = sprintf("%d-01%s", d, (string)rest);

    if (HAS_TZ_OFFSET(value)) fmt += "+%h:%m";
    else if (HAS_TZ(value))   fmt += "%z";

    return parse(tmpval, fmt, "month");
  }
}

#undef HAS_TZ_OFFSET
#undef HAS_TZ
#undef HAS_SECFRAC

//! @note not implemented
class HexBinary
{
  inherit AnySimpleType;

  void create(string value)
  {
    ::init(NSQN(.HEX_BINARY_LITERAL), value);
  }

  void screen_data(string value)
  {
    error("%O() not implemented yet!", object_program(this));
  }
}

class QName
{
  inherit AnySimpleType;

  void create(string|Standards.XML.Namespace.QName value)
  {
    // TODO: QName moved to Standards.XML.Namespace. Reimplement this
    error("QName not fully implemented in %O()\n", object_program(this));
    ::init(NSQN(.QNAME_LITERAL), value);
  }

  protected Standards.XML.Namespace.QName screen_data(mixed value)
  {
    if (stringp(value))
      value = Standards.XML.Namespace.QName(value);

    return value;
  }

  string _sprintf(int t)
  {
    switch (t)
    {
      case 's': return data->fqn();
    }
  }
}

//! @note not implemented
class Base64Binary
{
  inherit AnySimpleType;

  void create(string value)
  {
    ::init(NSQN(.BASE64_BINARY_LITERAL), value);
  }

  protected string screen_data(string data)
  {
    error("%O() not implemented yet!", object_program(this));
  }
}

class AnyURI
{
  inherit AnySimpleType;

  void create(string|Standards.URI value)
  {
    ::init(NSQN(.ANY_URI_LITERAL), value);
  }

  protected Standards.URI screen_data(string|Standards.URI value)
  {
    if (stringp(value)) {
      if (catch(value = Standards.URI(value)))
	if (!LOOSE_CHECK)
	  error("%O(): can not accept \"%s\"!", object_program(this), value);
    }

    return value;
  }
}

/* Derived types */

class NormalizedString
{
  inherit String;

  void create(mixed value)
  {
    ::init(NSQN(.NORMALIZED_STRING_LITERAL), value);
  }

  protected string screen_data(mixed value)
  {
    value = __builtin.string_trim_all_whites(value);
    value = replace((value), ({ "\r","\n","\t" }), ({ " "," "," "}));
    return value;
  }
}

class Token
{
  inherit NormalizedString;

  void create(string value)
  {
    ::init(NSQN(.TOKEN_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    value = ::screen_data(value);
    // Replace double spaces with one space
    while (search(value, "  ") > -1)
      value = replace(value, "  ", " ");

    return value;
  }
}

class Language
{
  inherit Token;

  void create(string value)
  {
    ::init(NSQN(.LANGUAGE_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    value = ::screen_data(value);
    // This is sloppy...
    sscanf(value, "%2s-%2s", string ln1, string ln2);
    if (!ln1 && !ln2) {
      if (!LOOSE_CHECK)
	error("%O(): can not accept %O!", object_program(this), value);
      else ln1 = "";
    }
    value = ln1 + (ln2 ? "-" + ln2 : "");
    return value;
  }
}

class NMTOKEN
{
  inherit Token;

  void create(string value)
  {
    ::init(NSQN(.NMTOKEN_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    if (!value) return 0;
    //! Sloppy
    return replace(::screen_data(value), ({ " ", "," }), ({ "", "" }));
  }
}

class NMTOKENS
{
  inherit NMTOKEN;

  void create(string|array(string) value)
  {
    ::init(NSQN(.NMTOKENS_LITERAL), value);
  }

  protected array screen_data(string|array(string) value)
  {
    if (stringp(value)) value = value/" ";
    array(string) nv = ({});
    foreach (value, string v)
      nv += ({ ::screen_data(v) });

    return nv;
  }
}

class Name
{
  inherit NMTOKEN;

  void create(string value)
  {
    ::init(NSQN(.NAME_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    value = ::screen_data(value);
    if ( (< '0','1','2','3','4','5','6','7','8','9' >)[value[0]] )
      if (!LOOSE_CHECK)
	error("%O(): Value %O can not start with a number!",
	      object_program(this), value);

    return value;
  }
}

class NCName
{
  inherit Name;

  void create(string value)
  {
    ::init(NSQN(.NCNAME_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    value = ::screen_data(value);
    if (search(value, ":") > -1)
      if (!LOOSE_CHECK)
	error("%O(%O): Value must not contain colons!",
	      object_program(this), value);

    return value;
  }
}

class ID
{
  inherit NCName;

  void create(string value)
  {
    ::init(NSQN(.ID_LITERAL), value);
  }

  //! @note
  //!  Perhaps check for uniqness?
  protected string screen_data(string value)
  {
    return ::screen_data(value);
  }
}

class IDREF
{
  inherit NCName;

  void create(string value)
  {
    ::init(NSQN(.IDREF_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    return ::screen_data(value);
  }
}

class IDREFS
{
  inherit IDREF;

  void create(string|array(string) value)
  {
    ::init(NSQN(.IDREFS_LITERAL), value);
  }

  protected array screen_data(string|array(string) value)
  {
    if (stringp(value)) value = value/" ";
    array(string) nv = ({});
    foreach (value, string s)
      nv += ({ ::screen_data(s) });

    return nv;
  }
}

class ENTITY
{
  inherit NCName;

  void create(string value)
  {
    ::init(NSQN(.IDREF_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    return ::screen_data(value);
  }
}


class ENTITIES
{
  inherit NCName;

  void create(string|array(string) value)
  {
    ::init(NSQN(.ENTITIES_LITERAL), value);
  }

  protected array screen_data(string|array(string) value)
  {
    if (stringp(value)) value = value/" ";
    array(string) nv = ({});
    foreach (value, string s)
      nv += ({ ::screen_data(s) });

    return nv;
  }
}

class Integer
{
  inherit Decimal;

  void create(string|int|float value)
  {
    ::init(NSQN(.INTEGER_LITERAL), value);
  }

  //! @note
  //!  Perhaps check for max and min
  protected int screen_data(string|int|float value)
  {
    return (int)value;
  }

  int(0..1) positive(int v)
  {
    return v >= 1;
  }
}

class NonPositiveInteger
{
  inherit Integer;

  void create(string|int|float value)
  {
    ::init(NSQN(.NON_POSITIVE_INTEGER_LITERAL), value);
  }

  //! @note
  //!  Perhaps check for max and min
  protected int screen_data(string|int|float value)
  {
    value = ::screen_data(value);
    if (value > 0 && !LOOSE_CHECK)
      error("%O(%d): Value must be less or equal to zero",
	    object_program(this), value);

    return value;
  }
}

class NegativeInteger
{
  inherit Integer;

  void create(string|int|float value)
  {
    ::init(NSQN(.NEGATIVE_INTEGER_LITERAL), value);
  }

  //! @note
  //!  Perhaps check for max and min
  protected int screen_data(string|int|float value)
  {
    value = (int)value;
    if (value >= 0 && !LOOSE_CHECK)
      error("%O(%d): Value must be negative", object_program(this), value);
    return value;
  }
}

class Long
{
  inherit Integer;

  void create(string|int|float value)
  {
    ::init(NSQN(.LONG_LITERAL), value);
  }
}

class Int
{
  inherit Long;

  void create(string|int|float value)
  {
    ::init(NSQN(.INT_LITERAL), value);
  }
}

class Short
{
  inherit Int;

  void create(string|int|float value)
  {
    ::init(NSQN(.SHORT_LITERAL), value);
  }
}

class Byte
{
  inherit Short;

  void create(string|int|float value)
  {
    ::init(NSQN(.BYTE_LITERAL), value);
  }
}

class NonNegativeInteger
{
  inherit Integer;

  void create(string|int|float value)
  {
    ::init(NSQN(.NON_NEGATIVE_INTEGER_LITERAL), value);
  }

  protected int screen_data(string|int|float value)
  {
    value = (int)value;
    if (value < 0 && !LOOSE_CHECK)
      error("%O(%d): Value must be greater or equal to zero", 
            object_program(this), value);
    return value;
  }
}

class UnsignedLong
{
  inherit NonNegativeInteger;

  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_LONG_LITERAL), value);
  }
}

class UnsignedInt
{
  inherit UnsignedLong;

  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_INT_LITERAL), value);
  }
}

class UnsignedShort
{
  inherit UnsignedInt;

  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_SHORT_LITERAL), value);
  }
}

class UnsignedByte
{
  inherit UnsignedShort;

  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_BYTE_LITERAL), value);
  }
}

class PositiveInteger
{
  inherit NonNegativeInteger;
  
  void create(string|int|float value)
  {
    ::init(NSQN(.POSITIVE_INTEGER_LITERAL), value);
  }
  
  protected int screen_data(string|int|float value)
  {
    value = (int)value;
    if (value <= 0 && !LOOSE_CHECK)
      error("%O(%d): Value must be greater than zero", 
            object_program(this), value);
    return value;
  }
}
