/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Helper module for the Java binding in Pike.

#ifdef JDEBUG
# define TRACE(X...) werror("%s:%d: %s",basename(__FILE__),__LINE__,sprintf(X))
#else
# define TRACE(X...) 0
#endif

//! Creates a Java @tt{Hashtable@} from a Pike @tt{mapping@}
//!
//! @param m
object JHashtable(mapping m) // {{{
{
  object ht = Java.pkg["java/util/Hashtable"]();
  foreach (m; mixed k; mixed v)
    ht->put(encode(k), encode(v));

  return ht;
} // }}}

//! Creates a Java @tt{ArrayList@} from a Pike @tt{mapping@}
//!
//! @param a
object JArrayList(array a) // {{{
{
  object al = Java.pkg["java/util/ArrayList"]();

  foreach (a, mixed v)
    al->add(encode(v));

  return al;
} // }}}

//! Creates a Java String object.
//! This is the same as @[Java.JString]
constant JString = Java.JString;

//! Creates a Java Integer object.
//! This is the same as @[Java.JInteger]
constant JInteger = Java.JInteger;

//! Creates a Java Float object.
//! This is the same as @[Java.JFloat]
constant JFloat = Java.JFloat;

//! Creates a Java Boolean object.
//! This is the same as @[Java.JBoolean]
constant JBoolean = Java.JBoolean;

//! Creates a Java Array object.
//! This is the same as @[Java.JArray]
constant JArray = Java.JArray;

//! Creates a Java HashMap object.
//! This is the same as @[Java.JHashMap]
constant JHashMap = Java.JHashMap;

//! Encodes Pike data types to Java objects which can be passed as aguments
//! to Java methods.
//!
//! @param pike
object encode(mixed pike) // {{{
{
  if (stringp(pike))
    return JString(pike);

  else if (intp(pike))
    return JInteger(pike);

  else if (floatp(pike))
    return JFloat(pike);

  else if (arrayp(pike))
    return JArrayList(pike);

  else if (mappingp(pike))
    return JHashMap(pike);

  else if (multisetp(pike))
    return JArrayList((array) pike);

  else if (objectp(pike)) {
    if (sprintf("%O", object_program(pike)) == "Java.jobject")
      return pike;
  }

  error("Unhandled Pike type: %O\n", pike);
} // }}}

//! Decodes a result from Java to Pike datatypes.
//!
//! Handles:
//! @ul
//!  @item
//!   java.util.ArrayList
//!  @item
//!   java.util.Hashtable
//!  @item
//!   java.lang.String
//!  @item
//!   java.lang.Integer
//!  @item
//!   java.lang.Double
//!  @item
//!   java.lang.Boolean
//!  @item
//!   java.util.Date
//! @endul
//!
//! @param jobj
//!  Result from a Java method call
mixed decode(mixed jobj) // {{{
{
  mixed ret;
  string type;
  if (objectp(jobj))
    type = (string)jobj->getClass()->getName();
  else
    return jobj;

  TRACE("Java type is: %s\n", type);

  switch (type)
  {
    case "java.util.ArrayList":
      ret = ({});
      foreach (values(jobj->toArray()), object o)
        ret += ({ decode(o) });

      break;

    case "java.util.HashMap":
    case "java.util.Hashtable":
      ret = ([]);
      foreach (values(jobj->entrySet()->toArray()), object set)
        ret[decode(set->getKey())] = decode(set->getValue());

      break;

    case "java.lang.String":
      return string_to_utf8((string)jobj);

    case "java.lang.Integer":
      return jobj->intValue();

    case "java.lang.Float":
    case "java.lang.Double":
      return jobj->floatValue();

    case "java.lang.Boolean":
      return jobj->booleanValue();

    case "java.util.Date":
      string f = sprintf("%d-%d-%d %d:%d:%d",
                         jobj->getYear()+1900,
                         jobj->getMonth()+1,
                         jobj->getDate(),
                         jobj->getHours(),
                         jobj->getMinutes(),
                         jobj->getSeconds());
      return Calendar.parse("%Y-%M-%D %h:%m:%s", f);

    default:
      error("Unhandled Java type: %O\n", type);
  }

  return ret;
} // }}}

//! Reflects a Java object. Prints to stdout.
//!
//! @param instance
//!  The Java object to reflect
//! @param _glob
//!  Search for constructors, fields and methods matching the glob @[_glob]
//! @param _return
//!  If @tt{1@} the values will be returned rather than printed to stdout
//! @returns
//!  if @[_return] is @tt{1@} a mapping will be returned.
//!  @mapping
//!   @member array "constructors"
//!    A list of constructors
//!   @member array "fields"
//!    A list of object/class fields
//!   @member array "methods"
//!    A list of object/class methods
//!  @endmapping
void|mapping reflect(object instance, void|string _glob,
                     void|int(0..1) _return) // {{{
{
  if (sprintf("%O", object_program(instance)) != "Java.jobject") {
    werror("%O is not a Java.jobject object!\n", instance);
    return;
  }

  mapping(string:array(string)) retval = ([
    "constructors" : ({}),
    "fields" : ({}),
    "methods" : ({})
  ]);

  object klass = instance->getClass();

  foreach (values(klass->getConstructors()), object o) {
    string name = (string)o->toGenericString();
    if (!_glob || glob(_glob, name))
      retval->constructors += ({ name });
  }

  foreach (values(klass->getFields()), object o) {
    string name = (string)o->toGenericString();
    if (!_glob || glob(_glob, name))
      retval->fields += ({ name });
  }

  foreach (values(klass->getMethods()), object o) {
    string name = (string)o->toGenericString();

    if (!_glob || glob(_glob, name))
      retval->methods += ({ name });
  }

  if (!_return) {
    write("\nReflect Java class %O\n\n", (string)klass->getName());
    write("Constructors (%d)\n", sizeof(retval->constructors));
    foreach (retval->constructors, string s)
      write("  * %s\n", s);

    write("\nFields (%d)\n", sizeof(retval->fields));
    foreach (retval->fields, string s)
      write("  * %s\n", s);

    write("\nMethods (%d)\n", sizeof(retval->methods));
    foreach (retval->methods, string s)
      write("  * %s\n", s);
  }
  else
    return retval;
} // }}}
