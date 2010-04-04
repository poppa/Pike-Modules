/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{SVN@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! SVN.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! SVN.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with SVN.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}


#include "svn.h"
import Parser.XML.Tree;

//! The base path to the repository to work on
protected string repository_base;
protected int(0..1) is_working_copy = 1;

//! Sets the path to the repository to work on
void set_repository_base(string path)
{
  if (path[-1] != '/')
    path += "/";
  
  if (has_prefix(path, "file:"))
    is_working_copy = 0;

  repository_base = path;
}

//! Returns the base path to the current repository
string get_repository_base()
{
  return repository_base;
}

int(0..1) get_is_working_copy()
{
  return is_working_copy;
}

string get_abs_path(string p)
{
  if (has_prefix(p, "file:")) return p;
  if (p) return join_paths(repository_base, p);
  else return repository_base;
}

string join_paths(mixed ... paths)
{
  paths = map(paths, 
    lambda(string p) {
      if (p[-1] == FILE_SEPARATOR)
      	p = p[0..sizeof(p)-2];
      return p;
    }
  );

  return paths*FILE_SEPARATOR_S;
}

class Proc // {{{
{
  //! The result from the sub process
  string result = "";
  
  //! Did we end up with a timeout?
  int(0..1) is_timeout = 0;

  protected Process.create_process p;
  protected int           timeout;
  protected int           retval;
  protected int(0..1)     done;
  protected array(string) args;

  private Pike.Backend backends = Thread.Local();

  //! Creates a new @[Proc] class
  //!
  //! @param _args
  //!  Array of arguments. The first index should be the program to run and
  //!  there after argument to pass to the program. 
  //! @param _timeout
  //!  Maximimum number of seconds the process can run. Default is @tt{30@}
  void create(array(string) _args, void|int _timeout)
  {
    args = _args;
    timeout = _timeout||30;
  }

  protected void on_data(int id, string data)
  {
    result += data;
  }

  protected void on_close(int id)
  {
    done = 1;
  }

  protected void on_timeout()
  {
    is_timeout = 1;
    p->kill(9);
    done = 1;
  }

  //! Run the process
  //!
  //! @throws
  //!  An error if the creation of a subprocess fails
  //!
  //! @returns
  //!  The return value of the subprocess. To get the data from the process
  //!  use @[Proc()->result].
  int run()
  {
    is_timeout = 0;
    done = 0;
    result = "";

    Stdio.File stdout = Stdio.File();

    if (mixed e = catch(p = Process.create_process(args, 
                            ([ "stdout" : stdout->pipe() ]))))
    {
      error("Unable to create process: %s\n", describe_error(e));
    }

    Pike.Backend backend = backends->get();

    if (!backend)
      backends->set(backend = Pike.Backend());

    backend->add_file(stdout);
    mixed to = backend->call_out(on_timeout, timeout);
    stdout->set_nonblocking(on_data, 0, on_close);

    while (!done)
      float time = backend(0);

    int rv = p->wait();
    stdout->close();
    backend->remove_call_out(on_timeout);

    return rv;
  }
} // }}}
