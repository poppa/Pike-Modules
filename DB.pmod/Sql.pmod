/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[MODULE-NAME]@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [MODULE-NAME].pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [MODULE-NAME].pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [MODULE-NAME].pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#define THIS_OBJECT object_program(this)
#define QUOTE_SQL(X) replace((X),                                        \
		             ({ "\\","\"","\0","\'","\n","\r" }),        \
		             ({ "\\\\","\\\"","\\0","\\\'","\\n","\\r" }))
#define TYPEOF_SELF(OTHER) (object_program(this) == object_program((OTHER)))
#define INHERITS_THIS(CHILD) Program.inherits(object_program(CHILD),    \
			                      object_program(this))
string quote(string s) // {{{
{
  return QUOTE_SQL(s);
} // }}}

enum DataType { // {{{
  SQL_INT,
  SQL_STRING,
  SQL_DATE,
  SQL_DATETIME,
  SQL_FLOAT
} // }}}

class Field // {{{
{
  protected string      name;
  protected mixed       value;
  protected DataType    type;
  protected int(0..1)   nullable = 1;

  void create(string _name, DataType _type, void|mixed _value)
  {
    name = _name;
    type = _type;
    if (_value) set(_value);
  }
  
  void set(mixed _value)
  {
    switch (type)
    {
      case SQL_INT:    value = (int)_value;    break;
      case SQL_FLOAT:  value = (float)_value;  break;
      case SQL_STRING: value = (string)_value; break;
    }
  }

  void set_nullable(int(0..1) nul)
  {
    nullable = nul;
  }

  mixed get()
  {
    return sprintf("`%s`=%s", name, get_quoted());
  }

  string get_name()
  {
    return name;
  }

  mixed get_value()
  {
    return value;
  }

  int get_type()
  {
    return type;
  }
  
  string get_quoted_name()
  {
    return sprintf("`%s`", name);
  }

  string get_quoted()
  {
    switch (type)
    {
      case SQL_STRING:
	return value && "'" + QUOTE_SQL((string)value) + "'"
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

    return 0;
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
} // }}}

class Int // {{{
{
  inherit Field;

  void create(string name, int|void value)
  {
    ::create(name, SQL_INT, value);
  }
} // }}}

class Float // {{{
{
  inherit Field;
  
  void create(string name, float|void value)
  {
    ::create(name, SQL_FLOAT, value);
  }
} // }}}

class String // {{{
{
  inherit Field;

  void create(string name, string|void value)
  {
    ::create(name, SQL_STRING, value);
  }
} // }}}

class Enum // {{{
{
  inherit String;
  protected multiset fields;
  
  void create(string name, multiset enum_fields, string|void value)
  {
    fields = enum_fields;
    ::create(name, value);
  }

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
} // }}}

class Date // {{{
{
  inherit String;

  void create(string name, void|string value, void|int(0..1) not_nullable)
  {
    ::create(name, value);
    nullable = !not_nullable;
  }

  string get_quoted()
  {
    if ((!value && !nullable) || lower_case(value) == "now()")
      return "NOW()";

    if (search(value, "(") > -1)
      return value;

    return value && "'" + QUOTE_SQL((string)value) + "'" || "NULL";
  }
} // }}}

