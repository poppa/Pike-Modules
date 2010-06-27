/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! This is a helper module for developing desktop/console applications on the
//! Social.pmod modules
//|
//| Copyright © 2009, Pontus Östlund - http://www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Desktop.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Desktop.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Desktop.pmod. If not, see <http://www.gnu.org/licenses/>.

#ifdef DESKTOP_DEBUG
# define TRACE(X...) werror("> %d: %s", __LINE__, sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define TRIM(S) String.trim_all_whites(S)

//! Default browser command (@tt{firefox@})
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
//! @note
//!  This won't work on Windows
//!
//! @seealso 
//!  @[set_default_browser_cmd()]
//!
//! @param url
//! @param browser_cmd
//!  Overrides @[default_browser_cmd].
int launch_browser(void|string url, void|string browser_cmd)
{
  return low_launch_browser(browser_cmd, url);
}

//! Low level browser launcher. If the given @[browser] doesn't exist the user
//! will be promted to write a browser command.
//!
//! @param browser
//! @param url
protected int low_launch_browser(void|string browser, void|string url)
{
  string bcmd = browser||default_browser_cmd;
  Misc.Proc p = Misc.Proc(({ "which", bcmd }), 5);
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
  p = Misc.Proc(({ browser, url||"" }), 5);
  return p->run() == 0;
}

