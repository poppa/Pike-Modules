/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! @note WORK IN PROGRESS WORK IN PROGRESS WORK IN PROGRESS WORK IN PROGRESS
//!       WORK IN PROGRESS WORK IN PROGRESS WORK IN PROGRESS WORK IN PROGRESS
//!       WORK IN PROGRESS WORK IN PROGRESS WORK IN PROGRESS WORK IN PROGRESS

#ifdef FTP_CLIENT_DEBUG
# define TRACE(X...) werror("%s:%-4d: %s",basename(__FILE__),__LINE__,sprintf(X))
#else
# define TRACE(X...) 0
#endif

#define trim String.trim_all_whites

class BaseClient
{
  inherit Stdio.FILE : sock;

  protected Stdio.FILE fd2;
  protected string last_cmd = "[NONE]";
  protected mapping last_read;
  protected int(0..1) _use_passive_mode = 1;

  //! Use passive mode as default or not. The default value is @tt{1@}.
  //! When in default passive mode @[pasv()] will be called i automatically
  //! if certain commands demands it, like @[list()] and @[mlst()] for
  //! example. If this is @tt{0@} and the client is behind a firewall for
  //! instance you have to call @[pasv()] your self prior to any command that
  //! will require passive mode.
  //!
  //! @param passive_mode
  void passive_mode(int(0..1) passive_mode)
  {
    _use_passive_mode = passive_mode;
  }

  //! Returns the result from the last command
  //!
  //! @returns
  //!  @mapping
  //!   @member int "code"
  //!    The return code
  //!   @member string|array(string) "text"
  //!    The content
  //!  @endmapping
  mapping(string:mixed) get_last_result()
  {
    return last_read;
  }

  //! Create another connection to use in passive mode
  //!
  //! @param r
  //!  The result from cmd("PASV")
  protected void create_fd2(mapping r)
  {
    close_fd2();

    if (_use_passive_mode && r->code == 227) {
      sscanf (r->text, "%*s(%s)", string p);
      array(string) parts = p/",";
      string ip = parts[..<2] * ".";

      parts = parts[<1..];

      int port = ((int)parts[0] * 256) + (int)parts[1];

      close_fd2();

      fd2 = Stdio.FILE();

      if (!fd2->connect(ip, port)) {
        error("Unable to connect in passive mode!\n");
      }

      TRACE("[*] fd2 connected to %s:%d\n", ip, port);
    }
  }

  //! Close the secondary connection if it's avaliable
  protected void close_fd2()
  {
    if (fd2 && fd2->is_open())
      fd2->close();

    fd2 = 0;
  }

  //! Write to the connection
  //!
  //! @param what
  //! @param s
  //!  If @tt{null@} the default connection is used
  protected void low_write(string what, void|Stdio.FILE s)
  {
    last_cmd = trim(what);
    function wfun = s ? s->write : sock::write;

    TRACE(">>> write: %s to %O\n", last_cmd, wfun);

    int w = wfun(last_cmd + "\r\n");

    if (w != sizeof(last_cmd+"\r\n")) {
      error("Write command was truncated!\n");
    }
  }

  //!
  protected mapping read_list(void|Stdio.FILE fd)
  {
    low_read(0);

    function my_gets = fd ? fd->gets : sock::gets;
    array(string) collection = ({});
    string tmp;

    while (tmp = my_gets()) {
      sscanf(tmp, "%d%c%s", int code, int s, string rest);

      if (code) {
        break;
      }

      collection += ({ trim(tmp) });
    }

    read_empty();

    return last_read = ([ "code" : 226, "text" : collection ]);
  }

  protected mapping read_file(void|Stdio.FILE fd)
  {
    TRACE("<<< Read file: %O\n", fd);

    low_read(0);

    function rfunc = fd ? fd->gets : sock::gets;
    string tmp, ret = "";

    while (tmp = rfunc()) {
      ret += tmp;
    }

    read_empty();

    TRACE("[%O]\n", ret);

    return last_read = ([ "code" : 226, "text" : ret ]);
  }

  protected void read_empty()
  {
    while (string tmp = sock::gets()) {
      sscanf(tmp, "%d%c%s", int code, int c, string rest);

      TRACE("<-> read_empty(%d, %c, %s)\n", code, c, trim(rest||""));

      if (code == 226) {
        TRACE("Done empty reading:%O\n", code);
        break;
      }
    }

    TRACE("End read_empty()\n");
  }

  //! Read server reply
  //!
  //! @param fd
  protected mapping read(void|Stdio.FILE fd)
  {
    string _cmd = upper_case((last_cmd/" ")[0]);

    if ((< "MLST", "NLST", "MLSD", "LIST" >)[_cmd]) {
      return read_list(fd);
    }
    else if ((< "RETR" >)[_cmd]) {
      return read_file(fd);
    }

    return low_read(fd);
  }

  //! Read from connection
  //!
  //! @param fd
  protected mapping low_read(void|Stdio.FILE fd)
  {
    mapping ret = ([ "code" : 0, "text" : "" ]);
    int code, space;
    string s;
    function rfunc = fd ? fd->gets : sock::gets;
    array(string) collection = ({});

    space = '-';

    TRACE("<<< start read: %s from %O\n", last_cmd, rfunc);

    while (space == '-') {
      space = ' ';
      string tmp = rfunc();

      if (!tmp) {
        TRACE("<<<! Nothing was read\n");
        break;
      }

      if (sscanf(tmp, "%d%c%s", code, space, s) != 3) {
        collection += ({ trim(tmp) });
      }

      TRACE("  <<< code: %d, space: %c:%[1]d, text: [%s], raw[%s]\n",
            code, space, trim(s||""), trim(tmp||""));

      // System status or feat or alike
      if (code == 211) {
        if (s == "END\r") {
          break;
        }

        space = '-';
      }

      if (!ret->code) {
        ret->code = code;
      }

      ret->text += replace(s||"", "\r", "\n");
    }

    if (sizeof(collection)) {
      ret->text = collection;
    }
    else if (sizeof(ret->text) && ret->text[-1] == '\n') {
      ret->text = ret->text[..<1];
    }

    switch (ret->code)
    {
      case 100..399:
        break;

      default:
        error("FTP error %d: %s\n", ret->code, ret->text);
        break;
    }

    if (ret->code == 227)
      create_fd2(ret);

    TRACE("<<< read done: %O\n", ret);

    return last_read = ret;
  }

  protected array(mapping) parse_mlist(array(string) lines)
  {
    array(mapping) ret = ({});

    foreach (lines, string line) {
      sscanf (line, "%{%s=%s%*[; ]%}%s", array m, string p);
      mapping t = ([ "path" : p ]);

      foreach (m, array part) {
        string k = part[0];
        string|int v = part[1];

        if (has_prefix(k, "UNIX.")) {
          k = k[5..];
        }

        if ((< "modify", "size", "mode" >)[k])
          v = (int) v;

        t[k] = v;
      }

      ret += ({ t });
    }

    return ret;
  }

  //! @ignore
  void destroy()
  {
    if (fd2) {
      if (fd2->is_open()) {
        fd2->close();
      }

      fd2 = 0;
    }

    if (is_open()) {
      close();
    }
  }
  //! @endignore
}

class Client
{
  inherit BaseClient;

  //! Create a FTP client
  //!
  //! @param host
  //! @param port
  //!
  //! @throws
  //!  An error if the connection fails
  void create(string host, void|int(0..) port)
  {
    if (!host) {
      error("argument \"host\" can not be null! ");
    }

    if (!port) {
      port = 21;
    }

    if (!connect(host, port)) {
      error("Unable to connect to %O! %s\n", host, strerror(sock::errno()));
    }

    read();
  }

  //! Login to the FTP server
  //!
  //! @param user
  //! @param pass
  int(0..1) login(string user, string pass)
  {
    mapping r;

    r = cmd("USER " + user);

    if (r->code == 331) {
      r = cmd("PASS " + pass);
    }

    return r->code == 230;
  }

  //! Change working directory
  //!
  //! @param path
  //!
  //! @returns
  //!  The new directory path
  string cwd(string path)
  {
    string s = cmd("CWD " + path)->text;
    sscanf (s, "%*s/%s.", s);
    return "/" + s;
  }

  //! Show the current working directory
  string pwd()
  {
    string s = cmd("PWD")->text;
    sscanf (s, "%s %*s", s);
    if (s[0] == '"') s = s[1..];
    if (s[-1] == '"') s = s[..<1];
    return s;
  }

  //! Enter passive mode
  int(0..1) pasv()
  {
    return cmd("PASV")->code == 227;
  }

  //! Returns information of a file or directory if specified, else information
  //! of the current working directory is returned. If the server supports the
  //! @tt{-R@} command (e.g. @tt{LIST -R@}) then a recursive directory listing
  //! will be returned.
  //!
  //! @param path
  //!  Either a path or @tt{-R@} for recursive listing
  array(string) list(void|string path)
  {
    path = path || "";
    mapping r = cmd2("LIST " + path);
    return r->text;
  }

  //! Retrieve a remote file
  //!
  //! @param remote_path
  //!  The file to retrieve
  //! @param local_path
  //!  If a directory the file will be written here with the same name
  //!  as the file in @[remote_path]. If it's not a directory a file with
  //!  this path/name will be written with the contents of @[remote_path].
  //!
  //! @returns
  //!  The file contents of @[remote_path]
  string retr(string remote_path, void|string local_path)
  {
    mapping r = cmd2("RETR " + remote_path);

    if (local_path && Stdio.exist(local_path)) {
      string local_name = local_path;

      if (Stdio.is_dir(local_path)) {
        local_name = combine_path(local_path, basename(remote_path));
      }

      Stdio.write_file(local_name, r->text);
    }

    return r->text;
  }

  //! Returns a list of file names in a specified directory.
  //!
  //! @param path
  //!  If not given the current workign directory will be listed
  array(mapping) nlst(void|string path)
  {
    path = path || "";
    mapping r = cmd2("NLST" + path);

    array(mapping) ret = ({});

    return ret;
  }

  //! Directory listing
  //!
  //! @param path
  array(mapping) mlsd(void|string path)
  {
    path = path || "";
    mapping r = cmd2("MLSD " + path);
    return parse_mlist(r->text);
  }

  //! Get the feature list implemented by the server.
  array(string) feat()
  {
    return cmd("FEAT")->text;
  }

  //! Set binary mode
  mapping binary_mode()
  {
    return cmd("TYPE I");
  }

  //! Set ASCII mode
  mapping ascii_mode()
  {
    return cmd("TYPE A");
  }

  //! Close the connection to the server
  mapping quit()
  {
    return cmd("QUIT");
  }

  //! Issue any command
  //!
  //! @param c
  //!
  //! @returns
  //!  @mapping
  //!   @member int "code"
  //!    The return code from the server
  //!   @member string|array(string) "text"
  //!    The response data
  //!  @endmapping
  mapping cmd(string c)
  {
    low_write(c);
    return read();
  }

  //! Same as @[cmd()] except this uses a different connection if in
  //! passive mode. If the command @[c] needs passive mode and neither
  //! @[pasv()] nor @[port()] was called before @[pasv()] will be called
  //! automatically.
  //!
  //! @param c
  mapping cmd2(string c)
  {
    if (_use_passive_mode) {
      TRACE(">>> passive mode: last_cmd(%O)\n", last_cmd);
      if (!has_prefix(upper_case(last_cmd), "PASV") &&
          !has_prefix(upper_case(last_cmd), "PORT"))
      {
        pasv();
      }

      if (!fd2 || !fd2->is_open()) {
        error("Trying to write to file 2 but that's not open. Have you called " +
              "%O::pasv()?\n", object_program(this));
      }
    }

    low_write(c);
    return read(fd2);
  }
}