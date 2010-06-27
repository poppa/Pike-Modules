/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! XSD types
//!
//! @note
//!  Not all types are fully implemented yet!
//!
//! @seealso
//!  @url{http://books.xmlschemata.org/relaxng/relax-CHP-19.html@}
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Types.pmod is part of XSD.pmod
//|
//| XSD.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| XSD.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with XSD.pmod. If not, see <http://www.gnu.org/licenses/>.

/* NOTE: Work in progress
 */

#define NSQN(V) Standards.XML.Namespace.QName(.NAMESPACE, (V), "xsd")

//! If @tt{1@} data verification failures won't throw an error
int(0..1) loose_check = 0;

//! Setter for @[loose_check]
//!
//! @param v
void set_loose_check(int(0..1) v) { loose_check = v; }

//! Base class
class NSDBase
{
  //! QName for type
  Standards.XML.Namespace.QName type;
  
  //! The data
  mixed data;
  
  //! Is the data nil or not
  int(0..1) is_nil;

  //! Initialize the class
  //!
  //! @param _type
  protected void init(Standards.XML.Namespace.QName _type)
  {
    type = _type;
  }
}

//! Class for @tt{<anySimpleType/>@}
class AnySimpleType
{
  inherit NSDBase;

  //! Creates a new @[AnySimpleType] object
  //!
  //! @param value
  void create(mixed value)
  {
    init(NSQN(.ANY_SIMPLE_TYPE_LITERAL), value);
  }

  //! Setter for the value
  //!
  //! @param value
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

  //! Returns the data
  mixed get()
  {
    return data;
  }

  //! Returns the type
  Standards.XML.Namespace.QName get_type()
  {
    return type;
  }

  //! Concider an abstract method. This should wash the value to conform to the
  //! data type.
  //!
  //! @param value
  protected mixed screen_data(mixed value)
  {
    return value;
  }

  //! Initialize the object
  //!
  //! @param type
  //! @param value;
  protected void init(Standards.XML.Namespace.QName type, mixed value)
  {
    ::init(type);
    set(value);
  }

  //! Sets the data variable
  //!
  //! @param value
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

//! Class representing a nil value
class Nil
{
  inherit AnySimpleType;

  //! Creates a @[Nil] object
  void create(void|mixed value)
  {
    ::init(NSQN(.NIL_LITERAL), .NIL_VALUE);
  }
}

//! Class representing a string value
class String
{
  inherit AnySimpleType;

  //! If @tt{1@} the data validation should be thorough and throw an error
  //! if the value doesn't conform the standard.
  int(0..1) strict_validation = 0;

  //! Create a new @[String] object
  //!
  //! @param value
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

//! Class representing a boolean value
class Boolean
{
  inherit AnySimpleType;

  //! Creates a new @[Boolean] object
  //!
  //! @param value
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
	if (!loose_check)
	  error("%O can not accept \"%s\"!", object_program(this), value);
    }

    return value;
  }
}

//! Class representing a decimal value
class Decimal
{
  inherit AnySimpleType;

  //! Creates a new @[Decimal] object
  //!
  //! @param value
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

  // @note Not implemented...
  protected float screen_string(string value)
  {
    if (stringp(value)) {
      if (!loose_check)
	werror("warning: %O(), screening of decmial value not implemented. "
               "Data will simply be casted to float!\n",
	       object_program(this));
    }
    return (float)value;
  }
}

//! Class representing a float value
class Float
{
  inherit AnySimpleType;

  //! Creates a new @[Float] object
  //!
  //! @param value
  void create(float|int|string value)
  {
    ::init(NSQN(.FLOAT_LITERAL), value);
  }

  protected float screen_data(string|float|int value)
  {
    if (stringp(value)) {
      if (!loose_check)
	werror("warning: %O(), screening of floating point values not "
	       "implemented. Data will simply be casted to float!\n", 
	       object_program(this));
    }
    return (float) value;
  }
}

//! Class representing a double value
class Double
{
  inherit Float;

  //! Creates a new @[Double] object
  //!
  //! @param value
  void create(string|float|int value)
  {
    ::init(NSQN(.DOUBLE_LITERAL), value);
  }
}

//! Class representing a duration value.
//!
//! @note
//!  Not implemented
class Duration
{
  inherit AnySimpleType;

  string sign;
  int year;
  int month;
  int day;
  int hour;
  int min;
  int sec;

  //! Creates a new @[Duration] object
  //!
  //! @param value
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

//! DateTime class
//!
//! @seealso
//!  http://books.xmlschemata.org/relaxng/ch19-77049.html
class DateTime
{
  inherit AnySimpleType;
  
  //! Creates a new @[DateTime] object
  //!
  //! @param value
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
      if (!loose_check)
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

//! Time class
class Time
{
  inherit DateTime;

  //! Creates a new @[Time] class
  //!
  //! @param value
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

//! Date class
class Date
{
  inherit DateTime;

  //! Creates a new @[Date] class
  //!
  //! @param value
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

//! Class representing a period of one calendar month of a given year
class GYearMonth
{
  inherit DateTime;

  //! Creates a new @[GYearMonth] object
  //!
  //! @param value
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

//! Class representing one calendar year
class GYear
{
  inherit DateTime;

  //! Create a new @[GYear] object
  //!
  //! @param value
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

//! Class representing a calendar day recurring each calendar year.
class GMonthDay
{
  inherit DateTime;

  
  //! Creates a new @[GMonthDay] object
  //!
  //! @param value
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

//! Class representing a monthly day
class GDay
{
  inherit DateTime;

  
  //! Create a new @[GDay] object
  //!
  //! @param value
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

//! Class representing a yearly month
class GMonth
{
  inherit DateTime;


  //! Create a new @[GMonth] object
  //!
  //! @param value
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

//! Class representing binary contents coded in hexadecimal
//!
//! @note
//!  not implemented
class HexBinary
{
  inherit AnySimpleType;

  //! Creates a new @[HexBinary] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.HEX_BINARY_LITERAL), value);
  }

  protected void screen_data(string value)
  {
    error("%O() not implemented yet!", object_program(this));
  }
}

//! Class representing namespaces in XML-qualified names
class QName
{
  inherit AnySimpleType;

  //! Creates a new @[QName] object
  //!
  //! @param value
  void create(string|Standards.XML.Namespace.QName value)
  {
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

//! Class representing binary content coded as @tt{base64@}
//!
//! @note
//!  not implemented
class Base64Binary
{
  inherit AnySimpleType;

  //! Creates a new @[Base64Binary] object
  //!
  //! @param data
  void create(string value)
  {
    ::init(NSQN(.BASE64_BINARY_LITERAL), value);
  }

  protected string screen_data(string data)
  {
    error("%O() not implemented yet!", object_program(this));
  }
}

//! Class representing a URI
class AnyURI
{
  inherit AnySimpleType;

  //! Creates a new @[AnyURI] object
  //!
  //! @param value
  void create(string|Standards.URI value)
  {
    ::init(NSQN(.ANY_URI_LITERAL), value);
  }

  protected Standards.URI screen_data(string|Standards.URI value)
  {
    if (stringp(value)) {
      if (catch(value = Standards.URI(value)))
	if (!loose_check)
	  error("%O(): can not accept \"%s\"!", object_program(this), value);
    }

    return value;
  }
}

/* Derived types */

//! Class representing whitespace-replaced strings
class NormalizedString
{
  inherit String;

  //! Create a new @[NormalizedString] object
  //!
  //! @param value
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

//! Class representing whitespace-replaced and collapsed strings
class Token
{
  inherit NormalizedString;

  //! Creates a new @[Token] object
  //!
  //! @param value
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

//! Class representing RFC 1766 language codes.
class Language
{
  inherit Token;

  //! Creates a new @[Language] object
  //!
  //! @param value
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
      if (!loose_check)
	error("%O(): can not accept %O!", object_program(this), value);
      else ln1 = "";
    }
    value = ln1 + (ln2 ? "-" + ln2 : "");
    return value;
  }
}

//! Class representing XML 1.0 name token (NMTOKEN)
class NMTOKEN
{
  inherit Token;

  //! Creates a new @[NMTOKEN] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.NMTOKEN_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    if (!value) return 0;
    // Sloppy
    return replace(::screen_data(value), ({ " ", "," }), ({ "", "" }));
  }
}

//! Class representing a list of XML 1.0 name tokens (NMTOKEN)
class NMTOKENS
{
  inherit NMTOKEN;

  //! Creates a new @[NMTOKENS] object
  //!
  //! @param value
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

//! Class representing XML 1.O name
class Name
{
  inherit NMTOKEN;

  //! Creates a new @[Name] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.NAME_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    value = ::screen_data(value);
    if ( (< '0','1','2','3','4','5','6','7','8','9' >)[value[0]] )
      if (!loose_check)
	error("%O(): Value %O can not start with a number!",
	      object_program(this), value);

    return value;
  }
}

//! Class representing unqualified names
class NCName
{
  inherit Name;

  //! Creates a new @[NCName] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.NCNAME_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    value = ::screen_data(value);
    if (search(value, ":") > -1)
      if (!loose_check)
	error("%O(%O): Value must not contain colons!",
	      object_program(this), value);

    return value;
  }
}

//! Class representing a definition of unique identifiers
class ID
{
  inherit NCName;

  //! Creates a new @[ID] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.ID_LITERAL), value);
  }

  // @note
  //  Perhaps check for uniqness?
  protected string screen_data(string value)
  {
    return ::screen_data(value);
  }
}

//! Class representing a definition of references to unique identifiers
class IDREF
{
  inherit NCName;

  //! Creates a new @[IDREF] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.IDREF_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    return ::screen_data(value);
  }
}

// Class representing a definition of lists of references to unique identifiers
class IDREFS
{
  inherit IDREF;

  //! Creates a new @[IDREFS] object
  //!
  //! @param value
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

//! Class representing a reference to an unparsed entity
class ENTITY
{
  inherit NCName;

  //! Creates a new @[ENTITY] object
  //!
  //! @param value
  void create(string value)
  {
    ::init(NSQN(.IDREF_LITERAL), value);
  }

  protected string screen_data(string value)
  {
    return ::screen_data(value);
  }
}

//! Class representing a whitespace-separated list of unparsed entity 
//! references
class ENTITIES
{
  inherit NCName;

  //! Creates a new @[ENTITIES] object
  //!
  //! @param value
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

//! Class representing signed integers of arbitrary length
class Integer
{
  inherit Decimal;

  //! Creates a new @[Integer] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.INTEGER_LITERAL), value);
  }

  // @note
  //  Perhaps check for max and min, and actually doing some checking that
  //  the value only contains integers.
  protected int screen_data(string|int|float value)
  {
    return (int)value;
  }

  //! Returns whether the value is positive or not
  //!
  //! @param v
  int(0..1) positive(int v)
  {
    return v >= 1;
  }
}

//! Class representing integers of arbitrary length negative or equal to zero
class NonPositiveInteger
{
  inherit Integer;

  //! Creates a new @[NonPositiveInteger] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.NON_POSITIVE_INTEGER_LITERAL), value);
  }

  // @note
  //  Perhaps check for max and min
  protected int screen_data(string|int|float value)
  {
    value = ::screen_data(value);
    if (value > 0 && !loose_check)
      error("%O(%d): Value must be less or equal to zero",
	    object_program(this), value);

    return value;
  }
}

//! Class representing strictly negative integers of arbitrary length
class NegativeInteger
{
  inherit Integer;

  //! Creates a new @[NegativeInteger] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.NEGATIVE_INTEGER_LITERAL), value);
  }

  // @note
  //  Perhaps check for max and min
  protected int screen_data(string|int|float value)
  {
    value = (int)value;
    if (value >= 0 && !loose_check)
      error("%O(%d): Value must be negative", object_program(this), value);
    return value;
  }
}

//! Class representing 64-bit signed integers
class Long
{
  inherit Integer;

  //! Creates a new @[Long] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.LONG_LITERAL), value);
  }
}

//! Class representing 32-bit signed integers
class Int
{
  inherit Long;

  //! Creates a new @[Int] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.INT_LITERAL), value);
  }
}

//! Class representing 16-bit signed integers
class Short
{
  inherit Int;

  //! Creates a new @[Short] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.SHORT_LITERAL), value);
  }
}

//! Class representing a signed value of 8 bits
class Byte
{
  inherit Short;

  //! Creates a new @[Byte] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.BYTE_LITERAL), value);
  }
}

//! Class representing integers of arbitrary length positive or equal to zero
class NonNegativeInteger
{
  inherit Integer;

  //! Creates a new @[NonNegativeInteger] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.NON_NEGATIVE_INTEGER_LITERAL), value);
  }

  protected int screen_data(string|int|float value)
  {
    value = (int)value;
    if (value < 0 && !loose_check)
      error("%O(%d): Value must be greater or equal to zero", 
            object_program(this), value);
    return value;
  }
}

//! Class representing unsigned integer of 64 bits
class UnsignedLong
{
  inherit NonNegativeInteger;

  //! Creates a new @[UnsignedLong] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_LONG_LITERAL), value);
  }
}

//! Class representing unsigned integer of 32 bits
class UnsignedInt
{
  inherit UnsignedLong;

  //! Creates a new @[UnsignedInt] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_INT_LITERAL), value);
  }
}

//! Class representing unsigned integer of 16 bits
class UnsignedShort
{
  inherit UnsignedInt;

  //! Creates a new @[UnsignedShort] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_SHORT_LITERAL), value);
  }
}

//! Class representing unsigned value of 8 bits
class UnsignedByte
{
  inherit UnsignedShort;

  //! Creates a new @[UnsignedByte] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.UNSIGNED_BYTE_LITERAL), value);
  }
}

//! Class representing strictly positive integers of arbitrary length
class PositiveInteger
{
  inherit NonNegativeInteger;
  
  //! Creates a new @[PositiveInteger] object
  //!
  //! @param value
  void create(string|int|float value)
  {
    ::init(NSQN(.POSITIVE_INTEGER_LITERAL), value);
  }
  
  protected int screen_data(string|int|float value)
  {
    value = (int)value;
    if (value <= 0 && !loose_check)
      error("%O(%d): Value must be greater than zero", 
            object_program(this), value);
    return value;
  }
}

