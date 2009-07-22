/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{QName class@}
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! QName.pike is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! QName.pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with QName.pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

//! The QName namepace
protected string namespace;

//! The QName name
protected string local_name;

//! The QName prefix
protected string prefix;

//! Creates a new QName.
//!
//! @param _namespace
//! @param _local_name
//!  If @[_local_name] contains the namspace, e.g. @tt{{namespace}local_name@}, 
//!  the namespace will be substracted from the @[_local_name.
//!  If @[_local_name] contains the prefix, e.g. @tt{prefix:local_name@}, 
//!  the prefix will be subtracted from the @[_local_name]
void create(string _namespace, void|string _local_name,
            void|string _prefix)
{
  namespace  = _namespace;
  local_name = _local_name;
  prefix     = _prefix;

  if (namespace && !local_name && !prefix) {
    local_name = namespace;
    namespace = 0;
  }
  else if (namespace && sizeof(namespace) && namespace[0] == '{')
    sscanf(namespace, "{%s}%s", namespace, local_name);
  else if (local_name && search(local_name, ":") > -1 && 
           search(local_name, "://") == -1)
  {
    sscanf(local_name, "%s:%s", prefix, local_name);
  }
}

//! Returns the namespace URI
string get_namespace_uri()
{
  return namespace;
}

//! Returns the local name
string get_local_name()
{
  return local_name;
}

//! Returns the prefix
string get_prefix()
{
  return prefix;
}

//! Returns the full name, i.e. @tt{prefix:local_name@}
string get_full_name()
{
  string s = "";
  if (prefix) s += prefix + ":";
  return s + local_name;
}

//! Set the namespace uri
//!
//! @param uri
void set_namespace_uri(string uri)
{
  namespace = uri;
}

//! Set the local name
//!
//! @param name
void set_local_name(string name)
{
  local_name = name;
}

//! Set the prefix
//!
//! @param _prefix
void set_prefix(string _prefix)
{
  prefix = _prefix;
}

//! Returns the fully qualified name
string fqn()
{
  if (local_name && prefix)
    return sprintf("%s:%s", prefix, local_name);

  return namespace ? sprintf("{%s}%s", namespace, local_name) : local_name;
}

//! Comparer method
//!
//! @param qname
int(0..1) `==(object qname)
{
  if (object_program(qname) != object_program(this))
    return 0;

  return local_name == qname->get_local_name()    &&
         namespace  == qname->get_namespace_uri() &&
	 prefix     == qname->get_prefix();
}

//! Cast method
//!
//! @param how
mixed cast(string how)
{
  switch (how)
  {
    case "string": return fqn();
  }
  
  error("Can't cast %O() to %O\n", object_program(this), how);
}

string _sprintf(int t)
{
  switch (t)
  {
    case 's': return fqn();
    case 'O':
      return sprintf("%O(%O, %O, %O)", object_program(this), local_name, 
                     namespace, prefix);
  }
}
