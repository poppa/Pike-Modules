/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Sql module with helper classes and such.
//!
//! @b{Example@}
//!
//! This is how the column type classes can be used.
//!
//! @code
//!  import DB.Sql;
//!
//!  array(Field) cols = ({
//!    Int("caliber", 45),
//!    String("firstname", "Harry"),
//!    String("lastname", "Callahan"),
//!    Enum("bad_ass", (&lt; "y","n" &gt;), "y")
//!  });
//!
//!  string sql = sprintf("INSERT INTO table (%s) VALUES (%s)",
//!                       cols->get_quoted_name()*",",
//!                       cols->get_quoted()*",");
//!  mydb->query(sql);
//! @endcode

#define THIS_OBJECT object_program(this)
#define QUOTE_SQL(X) replace((X),                                        \
                             ({ "\\","\"","\0","\'","\n","\r" }),        \
                             ({ "\\\\","\\\"","\\0","\\\'","\\n","\\r" }))
#define TYPEOF_SELF(OTHER) (object_program(this) == object_program((OTHER)))
#define INHERITS_THIS(CHILD) Program.inherits(object_program(CHILD),    \
                                              object_program(this))

//! Escapes @[s] for safe insertion into database
string quote(string s)
{
  return QUOTE_SQL(s);
}

//! MySQL data types
enum DataType {
  SQL_INT,
  SQL_STRING,
  SQL_DATE,
  SQL_DATETIME,
  SQL_FLOAT
}

string safe_quote_sql(string in)
{
  int len = in && sizeof(in);

  if (!len)
    return "";

  in += "\0";
  string b = "";

  for (int i = 0; i < len; i++) {
    if (i == len)
      break;

    if (in[i] == '%' && in[i+1] != '%')
      b += "%";

    b += in[i..i];
  }

  return b;
}

//! Class representing a SQL column
class Field
{
  protected string      name;
  protected mixed       value;
  protected DataType    type;
  protected int(0..1)   nullable = 1;

  //! Creates a new @[Field] object
  //!
  //! @param _name
  //! @param _type
  //! @param _value
  void create(string _name, DataType _type, void|mixed _value)
  {
    name = _name;
    type = _type;
    if (_value) set(_value);
  }

  //! Set the value
  //!
  //! @param _value
  void set(mixed _value)
  {
    switch (type)
    {
      case SQL_INT:    value = (int)_value;    break;
      case SQL_FLOAT:  value = (float)_value;  break;
      case SQL_STRING: value = (string)_value; break;
    }
  }

  //! Set whether or not the column is nullable or not
  //!
  //! @param nul
  void set_nullable(int(0..1) nul)
  {
    nullable = nul;
  }

  //! Returns the name and value for usage in an update query.
  //! @tt{`name`='quoted-value'@}.
  mixed get()
  {
    return sprintf("`%s`=%s", name, safe_quote_sql(get_quoted()));
  }

  //! Returns the name
  string get_name()
  {
    return name;
  }

  //! Returns the value
  mixed get_value()
  {
    return value;
  }

  //! Returns the data type
  int get_type()
  {
    return type;
  }

  //! Returns the name quoted for usage in a query
  string get_quoted_name()
  {
    return sprintf("`%s`", name);
  }

  //! Returns the value quoted
  string get_quoted()
  {
    switch (type)
    {
      case SQL_STRING:
        return value && "'" + QUOTE_SQL(value) + "'"
                     || nullable && "NULL"
                     || "''";

      case SQL_INT:
        /* Fall through */
      case SQL_FLOAT:
        if (value == UNDEFINED && nullable)
          return "NULL";

        return (string)value;
    }
  }

  //! Casting method.
  //!
  //! @param how
  //!  Supports @tt{string, float and int@}.
  mixed cast(string how)
  {
    switch (how)
    {
      case "string": return (string)value;
      case "float":  return (float)value;
      case "int":    return (int)value;
    }

    error("Can't cast %O() to \"%s\"! ", THIS_OBJECT, how);
  }

  //! Comparer method
  //!
  //! @param other
  int(0..1) `==(mixed other)
  {
    if (objectp(other)) {
      return (TYPEOF_SELF(other) || INHERITS_THIS(other)) &&
             name  == other->get_name()                   &&
             type  == other->get_type()                   &&
             value == other->get_value();
    }

    if (stringp(other)) {
      if (type != SQL_STRING)
        return 0;

      return other == value;
    }

    if (intp(other)) {
      if (type != SQL_INT)
        return 0;

      return other == value;
    }

    if (floatp(other)) {
      if (type != SQL_FLOAT)
        return 0;

      return other == value;
    }

    return other == value;
  }

  string _sprintf(int t)
  {
    switch (t)
    {
      case 'd': return sprintf("%d", value);
      case 'f': return sprintf("%f", value);
      case 's': return sprintf("%s", value);
      case 'O': return sprintf("%O(%s, %s)", THIS_OBJECT, name, get_quoted());
    }

    return "NULL";
  }
}

//! Represents an INT column
class Int
{
  inherit Field;

  //! Creates a new @[Int] object
  //!
  //! @param name
  //! @param value
  void create(string name, int|void value)
  {
    ::create(name, SQL_INT, value);
  }
}

//! Represents a FLOAT column
class Float
{
  inherit Field;

  //! Creates a new @[Float] object
  //!
  //! @param name
  //! @param value
  void create(string name, float|void value)
  {
    ::create(name, SQL_FLOAT, value);
  }
}

//! Represents a string column (VARCHAR, TEXT and alike).
class String
{
  inherit Field;

  //! Creates a new @[String] object
  //!
  //! @param name
  //! @param value
  void create(string name, string|void value)
  {
    ::create(name, SQL_STRING, value);
  }
}

//! Represents an ENUM column
class Enum
{
  inherit String;
  protected multiset fields;

  //! Creates a new @[Int] object
  //!
  //! @param name
  //! @param enum_fields
  //!  Possible values of this ENUM
  //! @param value
  void create(string name, multiset enum_fields, string|void value)
  {
    fields = enum_fields;
    ::create(name, value);
  }

  //! Setter
  //!
  //! @throws
  //!  An error if @[_value] isn't allowed according to the @tt{enum_fields@}
  //!  given in @[create()].
  //!
  //! @param _value
  void set(string _value)
  {
    if (!nullable && _value == UNDEFINED) {
      //TRACE("Trying to set VOID on %O\n", name);
      if ( !fields[_value] ) {
        error("\"%s\" is an illegal value. Expected %s",
              (string)_value, (array)fields*", ");
      }
    }

    ::set(_value);
  }
}

//! Represents a DATE or DATETIME column
class Date
{
  inherit String;

  //! Creates a new @[Date] object
  //!
  //! @param name
  //! @param value
  //! @param not_nullable
  void create(string name, void|string value, void|int(0..1) not_nullable)
  {
    ::create(name, value);
    nullable = !not_nullable;
  }

  //! Returns the value quoted
  string get_quoted()
  {
    if ((!value && !nullable) || lower_case(value) == "now()")
      return "NOW()";

    if (search(value, "(") > -1)
      return value;

    return value && "'" + QUOTE_SQL((string)value) + "'" || "NULL";
  }
}

