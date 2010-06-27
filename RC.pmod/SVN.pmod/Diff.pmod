/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This module executes the @tt{svn diff@} command.
//|
//| Copyright © 2010, Pontus Östlund - http://www.poppa.se
//|
//| ============================================================================
//|
//|     GNU GPL version 3
//|
//| ============================================================================
//|
//| This file is part of SVN.pmod
//|
//| SVN.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| SVN.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with SVN.pmod. If not, see <http://www.gnu.org/licenses/>.

import Parser.XML.Tree;

// Hidden module constructor
protected local void create(mixed ... args) {}

//! Constructor for the @[Diff] object
//!
//! @param file
//! @param old_revision
//! @param new_revision
Diff `()(void|string file, void|int|string old_revision,
         void|int|string new_revision)
{
  return Diff(file, old_revision, new_revision);
}

// Resolves the revision numbers of the last and next last revision for
// @[path].
protected array parse_revision(string path, array args)
{
  // Only do this check when running agains the archive since that doesn't
  // handle "base, prev, next, committed"
  if (!.get_is_working_copy()) {
    path = path || .get_repository_base();

    array(int) head_prev = .Log.get_head_prev(path);

    // This probably means the file is only checked in once and therefore
    // we have no previous revision to compare it to
    if (sizeof(head_prev) != 2)
      return 0;

    [int head, int prev] = head_prev;

    for (int i; i < sizeof(args); i++) {
      string arg = lower_case( args[i] );
      if (search(arg, "prev") > -1)
      	args[i] = replace(arg, "prev", (string)prev);
      else if (search(arg, "committed") > -1)
      	args[i] = replace(arg, "committed", (string)prev);
    }
  }

  return args;
}

//! SVN diff class
class Diff
{
  inherit .AbstractSVN;

  protected array(Index) indexes = ({});

  //! Creates a new @[Diff] object
  //!
  //! @seealso
  //!  @[`()].
  //!
  //! @param file
  //! @param old_revision
  //! @param new_revision
  void create(void|string file, void|int|string old_revision, 
              void|int|string new_revision)
  {
    ::create(0, file);

    array(string) extra = ({});
    if (old_revision || new_revision) {
      extra = ({ "-r" });
      if (old_revision && new_revision)
	extra += ({ (string)old_revision + ":" + (string)new_revision });
      else if (old_revision)
	extra += ({ (string)old_revision });
      else
      	extra += ({ (string)new_revision });
    }
    else 
      extra = ({ "-r", "PREV:HEAD" });
    
    if (array flags = parse_revision(file, extra)) {
      string diff = exec("diff", file, 0, @flags);
      diff && parse(diff);
      return;
    }
    
    error("The file \"%s\" has no previous revisions to compare against! ",
          file);
  }

  //! Returns the array of @[Index] objects.
  array _values()
  {
    return indexes;
  }

  // Parse the diff
  private void parse(string s)
  {
    Index idx;
    array(string) lines = s/"\n";

    for (int i = 0; i < sizeof(lines); i++) {
      string line = lines[i];
      if (has_prefix(line, "Index:")) {
      	if (idx) indexes += ({ idx });
      	sscanf (line, "Index: %s", string file);
      	idx = Index(file);
      	i++; // Skip: ==============
      	continue;
      }

      if (!idx) continue;

      idx += line;
    }
    
    if (idx)
      indexes += ({ idx });
  }
}

//! This class contains the diff lines for a given path
class Index
{
  protected string path;
  protected array(string) diff = ({});
  
  //! Creates a new @[Index] object
  //!
  //! @param _path
  void create(string _path)
  {
    path = _path; //_path[sizeof(.get_repository_base())..];
  }

  //! Getter for the path
  string get_path()
  {
    return path;
  }

  //! Appends @[s] to the internal array of diff lines.
  //!
  //! @param s
  object_program `+(string s)
  {
    diff += ({ s });
    return this;
  }
  
  //! Returns the array of diff lines
  array(string) _values()
  {
    return diff;
  }
  
  string _sprintf(int t)
  {
    return sprintf("%O(%O)", object_program(this), path);
  }
}

//! Creates a side-by-side comparison of a @[Diff]
//!
//! @param diff
//!  A @[Diff] object
//!
//! @returns 
//!  An array of two indices where the first is the old revision and the
//!  second is the new revision. Each array row is a mapping with the following
//!  indices:
//!  @mapping
//!   @member string "line"
//!    The actual diff line
//!   @member string "type"
//!    Which can be @tt{normal, none, del, new or break@}
//!  @endmapping
array table(object_program diff)
{
  array old = ({});
  array new = ({});
  foreach (values(diff), Index idx) {
    foreach (values(idx), string line) {
      if (!sizeof(line)) {
      	continue;
      }
      if (line[0] == '-') {
      	if (sizeof(line) >= 3 && line[0..2] == "---")
      	  continue;

	old += ({ line });
      }
      else if (line[0] == '+') {
	if (sizeof(line) >= 3 && line[0..2] == "+++")
      	  continue;
	new += ({ line });
      }
      else {
	old += ({ line });
	new += ({ line });
      }
    }
  }
  
  [array diffnew, array diffold] = Array.diff(new, old);
  array old2 = ({});
  array new2 = ({});
  
  for (int i = 0; i < sizeof(diffold); i++) {
    array tmpold = diffold[i];
    array tmpnew = diffnew[i];
    int lenold = sizeof(tmpold);
    int lennew = sizeof(tmpnew);

    if (lenold == lennew) {
      old2 += tmpold;
      new2 += tmpnew;
    }
    else if (lenold < lennew) {
      new2 += tmpnew;
      for (int j = 0; j < lennew; j++) {
      	if (has_index(tmpold, j))
	  old2 += ({ tmpold[j] });
	else
	  old2 += ({ "\1" });
      }
    }
    else if (lennew < lenold) {
      old2 += tmpold;
      for (int j = 0; j < lenold; j++) {
      	if (has_index(tmpnew, j))
	  new2 += ({ tmpnew[j] });
	else
	  new2 += ({ "\2" });
      }
    }
  }
  
  array left = ({});
  array right = ({});
  
  int leno = 1;
  for (int i = 0; i < sizeof(old2); i++) {
    string ls = old2[i];
    int empty = 0;
    
    if (ls == "\1") {
      --leno;
      empty = 1;
    }
    
    if (ls[0] == '@') {
      if (i > 0) left += ({ ([ "lineno" : 0, "line" : "\3---" ]) });
      int start, end, k=-1, rmleno=0;
      sscanf(ls, "@@ -%d,%d", start, end);
      while (k++ < end-1) {
      	empty = 0;
      	leno = start + k;
      	ls = old2[i+1+k];
      	if (ls == "\1") {
      	  empty = 1;
      	  rmleno++;
      	  leno--;
      	}

	left += ({ ([ "lineno" : !empty&&(leno-rmleno), "line" : ls ]) });
      };
      if (empty)
	leno--;
      i += k;
    }
    else {
      left += ({ ([ "lineno" : !empty&&leno, "line" : ls ]) });
      leno++;
    }
  }

  leno = 1;
  for (int i = 0; i < sizeof(new2); i++) {
    string ls = new2[i];
    int empty = 0;
    
    if (ls == "\2") {
      --leno;
      empty = 1;
    }
    
    if (ls[0] == '@') {
      if (i > 0) right += ({ ([ "lineno" : 0, "line" : "\3---" ]) });
      int start, end, k=-1, rmleno=0;
      sscanf(ls, "@@ -%*d,%*d +%d,%d", start, end);
      while (k++ < end-1) {
      	empty = 0;
      	leno = start + k;
      	ls = new2[i+1+k];
      	if (ls == "\2") {
      	  empty = 1;
      	  rmleno++;
      	  leno--;
      	}

	right += ({ ([ "lineno" : !empty&&(leno-rmleno), "line" : ls ]) });
      } 
      if (empty)
	leno--;
      i += k;
    }
    else {
      right += ({ ([ "lineno" : !empty&&leno, "line" : ls ]) });
      leno++;
    }
  }

  array c = ({});

  function strcmp = lambda(string old, string new)
  {
    if (old == new)
      return 0;

    int olen = sizeof(old);
    int nlen = sizeof(new);
    mapping a = ([ "start" : ({}), "end" : ({}) ]);
    mapping b = ([ "start" : ({}), "end" : ({}) ]);
    int len = olen > nlen ? olen : nlen;

    int in_match = 1, i;
    for (; i < len; i++) {
      int co, cn;
      if (i < olen)
      	co = old[i];
      else {
      	a->end += ({ i });
      	b->end += ({ nlen });
      	break;
      }
      
      if (i < nlen)
      	cn = new[i];
      else {
      	a->end += ({ olen });
      	b->end += ({ i });
      	break;
      }
      
      if (co != cn) {
      	if (in_match) {
	  a->start += ({ i });
	  b->start += ({ i });
	}
      	in_match = 0;
      }
      else {
	if (!in_match) {
	  a->end += ({ i });
	  b->end += ({ i });
	}
      	in_match = 1;
      }
    }

    string s1 = " ";
    int j = 0;
    for (i = 0; i < sizeof(a->start); i++) {
      int sp = a->start[i];
      int ep = has_index(a->end, i) && a->end[i] || olen;
      for (; j <= ep; j++ ) {
      	if (j != sp && j != ep)
      	  s1 += old[j..j];
      	else if (j == sp) 
      	  s1 += "<span class='wd'>" + old[j..j];
      	else if (j == ep)
      	  s1 += "</span>" + old[j..j];
      }
    }
    
    if (j < olen)
      s1 += old[j..];
    
    string s2 = " ";
    j = 0;
    for (i = 0; i < sizeof(b->start); i++) {
      int sp = b->start[i];
      int ep = has_index(b->end, i) && b->end[i] || nlen;
      for (; j <= ep; j++ ) {
      	if (j != sp && j != ep)
      	  s2 += new[j..j];
      	else if (j == sp) 
      	  s2 += "<span class='wd'>" + new[j..j];
      	else if (j == ep)
      	  s2 += "</span>" + new[j..j];
      }
    }

    if (j < nlen)
      s2 += new[j..];

    return ({ s1, s2 });
  };

  old = ({});
  new = ({});

  for (int i; i < sizeof(left); i++) {
    mapping l = left[i];
    mapping r = right[i];
    
    string clsl = "normal";
    string clsr = "normal";
    
    if (l->line[0] == '\1')
      clsl = "none";
    else if (l->line[0] == '\3')
      clsl = "break";
    else if (l->line[0] == '-')
      clsl = "del";

    if (r->line[0] == '\2')
      clsr = "none";
    else if (r->line[0] == '\3')
      clsr = "break";
    else if (r->line[0] == '+')
      clsr = "new";

    l->line = replace(l->line, ({ "<", ">" }), ({ "&lt;", "&gt;" }));
    r->line = replace(r->line, ({ "<", ">" }), ({ "&lt;", "&gt;" }));
    
    if (r->line[0] == '+' && l->line[0] == '-') {
      clsl = clsr = "changed";
      [l->line, r->line] = strcmp( l->line[1..], r->line[1..] );
    }

    l->line = l->line[1..];
    l->type = clsl;
    r->line = r->line[1..];
    r->type = clsr;

    old += ({ l });
    new += ({ r });
  }
  
  return ({ old, new });
}
