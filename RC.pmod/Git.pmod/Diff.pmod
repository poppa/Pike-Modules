/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Diff@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Diff.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Diff.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Diff.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

protected void create(mixed ... args) {}

Diff `()(void|string path, void|string rev_a, void|string rev_b)
{
  return Diff(path, rev_a, rev_b);
}

class Diff
{
  inherit .AbstractGit;
  
  private array(Index) diffs = ({});
  
  void create(void|string path, void|string a, void|string b)
  {
    a = a||"HEAD^";
    b = b||"HEAD";
    
    string res = exec("diff", path, a, b);
    res && parse(res);
  }
  
  array(Index) _values()
  {
    return diffs;
  }
  
  private void parse(string s)
  {
    Index idx;
    array(string) lines = s/"\n";

    for (int i = 0; i < sizeof(lines); i++) {
      string line = lines[i];
      if (has_prefix(line, "diff --git")) {
      	if (idx) diffs += ({ idx });

      	sscanf (line, "diff --git %s", string cmd);

      	line = lines[++i];
      	sscanf (line, "index %s", string index);

      	line = lines[++i];
      	sscanf (line, "--- %s", string a);

      	line = lines[++i];
      	sscanf (line, "+++ %s", string b);

      	idx = Index(cmd, index, a, b);

      	continue;
      }

      if (!idx) continue;

      idx += line;
    }
  }
}

class Index
{
  private string command;
  private string index;
  private string a;
  private string b;

  private array(string) diff = ({});
  
  void create(string _command, string _index, string _a, string _b)
  {
    command = _command;
    index   = _index;
    a       = _a;
    b       = _b;
  }

  object_program `+(string s)
  {
    diff += ({ s });
    return this;
  }
  
  string _sprintf(int t)
  {
    return sprintf("%O(%O)", object_program(this), command);
  }
}
