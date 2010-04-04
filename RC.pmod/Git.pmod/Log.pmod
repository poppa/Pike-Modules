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

protected void create(mixed ... args) { }

Log `()(void|string path)
{
  return Log(path);
}

class Log
{
  inherit .AbstractGit;

  private array(Entry) entries = ({});

  void create(string path)
  {
    string res = exec("log", path);
    res && parse(res);
  }

  array(Entry) _values()
  {
    return entries;
  }
  
  private void parse(string text)
  {
    array(string) lines = text/"\n";
    mapping(string:string) tmp;

    foreach (lines, string line)
    {
      if (has_prefix(line, "commit ")) {
      	if (tmp)
      	  entries += ({ Entry()->from_mapping(tmp) });

      	sscanf(line, "commit %s", string id);
      	tmp = ([ "commit" : id, "data" : "" ]);
      	continue;
      }

      string k, v;
      if (sscanf(line, "%s: %s", k, v) > 1)
      	tmp[lower_case(k)] = String.trim_all_whites(v);
      else 
      	tmp->data += line;
    }

    if (tmp)
      entries += ({ Entry()->from_mapping(tmp) });
  }
}

class Entry
{
  inherit .AbstractEntry;

  object_program from_mapping(mapping m)
  {
    set_commit(m->commit);
    set_author(m->author);
    set_date(m->date);
    set_message(m->data);
    
    return this;
  }
}
