/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{Desktop module@}
//!
//! This is a helper module for developing desktop/console applications on the
//! Social.pmod modules
//!
//! Copyright © 2009, Pontus Östlund - @url{www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! Desktop.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! Desktop.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with Desktop.pmod. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

#ifdef DESKTOP_DEBUG
# define TRACE(X...) werror("> %d: %s", __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define TRIM(S) String.trim_all_whites(S)

//! Default browser command
string default_browser_cmd = "firefox";

//! Set default browser command to use in @[launch_browser()].
//!
//! @param browser_cmd
//!  Like @tt{opera@} or @tt{/usr/bin/opera@} or alike. 
void set_default_browser_cmd(string browser_cmd)
{
  default_browser_cmd = browser_cmd;
}

//! Launch a browser and point it to @[url]
//!
//! @param url
//! @param browser_cmd
//!  Overrides @[default_browser_cmd]. 
//!  @seealso 
//!   @[set_default_browser_cmd()]
int launch_browser(void|string url, void|string browser_cmd)
{
  return low_launch_browser(browser_cmd, url);
}

//! Low level browser launcher. If the given @[browser] doesn't exist the user
//! will be promted to write a browser command.
//!
//! @param browser
//! @param @url
protected int low_launch_browser(void|string browser, void|string url)
{
  string bcmd = browser||default_browser_cmd;
  Proc p = Proc(({ "which", bcmd }), 5);
  int v = p->run();

  browser = v == 0 && TRIM(p->result);

  if (!browser || !sizeof(browser)) {
    write("You don't seem to have \"%s\" on your computer\n", bcmd);
    while (!browser || !sizeof(browser)) {
      write("Write your browser's command: ");
      browser = TRIM(Stdio.stdin.gets());
    }

    return low_launch_browser(browser, url);
  }

  // Open the browser and point it to authenticate the application.
  p = Proc(({ browser, url||"" }), 5);
  return p->run() == 0;
}

//! Subprocess class
//!
//! @note
//!  I take no credit for this class. It's mainly from the Roxen tag
//!  @tt{emit#exec@} by Marcus Wellhardt at Roxen Internet Sowftware AB
//!  @url{http://roxen.com@}
class Proc
{
  string result = "";
  protected Process.create_process p;
  protected int           timeout;
  protected int           retval;
  protected int(0..1)     done;
  protected array(string) args;

  private Pike.Backend backends = Thread.Local();

  void create(array(string) _args, void|int _timeout)
  {
    args = _args;
    timeout = _timeout||30;
  }

  protected void on_data(int id, string data)
  {
    TRACE("Data in subprocess (%d): %s\n", id, data);
    result += data;
  }

  protected void on_close(int id)
  {
    TRACE("Subprocess closed: %d\n", id);
    done = 1;
  }

  protected void on_timeout()
  {
    TRACE("Timeout in subprocess #%d\n", p->pid());
    p->kill(9);
    done = 1;
  }

  int run()
  {
    Stdio.File stdout = Stdio.File();

    mixed e = catch {
      p = Process.create_process(args, ([ 
	"stdout" : stdout->pipe(),
	"callback" : lambda(Process.Process pp) {
	  TRACE("Process callback called: %O\n", pp);
	}
      ]));
    };

    if (e) error("Unable to create process: %s\n", describe_error(e));

    Pike.Backend backend = backends->get();

    if (!backend)
      backends->set(backend = Pike.Backend());

    backend->add_file(stdout);
    mixed to = backend->call_out(on_timeout, timeout);
    stdout->set_nonblocking(on_data, 0, on_close);

    while (!done) {
      TRACE("Running backend\n");
      float time = backend(0);
      TRACE("Backend run %O sec\n", time);
    }

    int rv = p->wait();
    stdout->close();
    backend->remove_call_out(on_timeout);

    return rv;
  }
}