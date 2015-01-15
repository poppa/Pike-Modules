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

class Client
{
  inherit Stdio.FILE : sock;

  private Stdio.FILE fd2;
  private string last_cmd = "[NONE]";
  private mapping last_read;
  private int(0..1) _use_passive_mode = 1;

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

  //! Use passive mode as default or not. The default value is @tt{1@}.
  //! When in default passive mode @[pasv()] will be called i automatically
  //! if certain commands demands it, like @[list()] and @[mlst()] for
  //! example. If this is @tt{0@} and the client is behind a firewall for
  //! instance you have to call @[pasv()] your self prior to any command that
  //! will require passive mode.
  //!
  //! @param passive_mode
  void use_passive_mode(int(0..1) passive_mode)
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
  array(mapping) list(void|string path)
  {
    string c = "LIST";

    if (path) {
      c += " " + path;
    }

    mapping r = cmd2(c);

    werror("%O\n", r);

    read();

    return 0;
  }

  //! Returns a list of file names in a specified directory.
  //!
  //! @param path
  //!  If not given the current workign directory will be listed
  array(mapping) nlst(void|string path)
  {
    string c = "NLST";

    if (path) {
      c += " " + path;
    }

    mapping r = cmd2("NLST");

    array(mapping) ret = ({});

    read();

    return ret;
  }

  //! Provides data about exactly the object @[path] or the current working
  //! directory if @[path] is omitted.
  //!
  //! @param path
  mapping mlst(void|string path)
  {
    mapping r;

    r = cmd2("MLST");

    read();

    array(mapping) ret = ({});

    string s = r->text;
    sscanf (s, "%{%s=%s%*[; ]%}%s", array m, string p);
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

    return t;
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
      if (!has_prefix(upper_case(last_cmd), "PASV") ||
          !has_prefix(upper_case(last_cmd), "PORT"))
      {
        pasv();
      }

      if (!fd2 || !fd2->is_open()) {
        error("Trying to write to file 2 but that's not open. Have you called " +
              "%O::pasv()?\n", object_program(this));
      }
    }

    low_write(c, fd2);
    return read(fd2);
  }

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

      TRACE("FD2 connected ok\n");
    }
  }

  protected void close_fd2()
  {
    if (fd2 && fd2->is_open())
      fd2->close();

    fd2 = 0;
  }

  protected void low_write(string what, void|Stdio.FILE s)
  {
    last_cmd = what;

    if (s) {
      s->write(what + "\r\n");
    }
    else {
      sock::write(what + "\r\n");
    }
  }

  protected mapping read_list(void|Stdio.FILE fd)
  {
    function my_gets = fd ? fd->gets : sock::gets;
    array(string) collection = ({});
    string tmp;

    while (tmp = my_gets()) {
      TRACE("read_list: %s\n", tmp);
    }
  }

  protected mapping read(void|Stdio.FILE fd)
  {
#if 0
    if ((< "MLST", "LIST" >)[upper_case(last_cmd)]) {
      return read_list(fd);
    }
#endif

    mapping ret = ([ "code" : 0, "text" : "" ]);
    int code,  space;
    string s;
    function my_gets = fd ? fd->gets : sock::gets;
    array(string) collection = ({});

    space = '-';

    TRACE("Read cmd: %s\n", last_cmd);

    while (space == '-') {
      space = ' ';
      string tmp = my_gets();
      if (!tmp) break;

      if (sscanf (tmp, "%d%c%s", code, space, s) != 3) {
        collection += ({ trim(tmp) });
      }

#if 1
      TRACE("code: %d, space: %c:%[1]d, text: [%s], raw[%s]\n",
            code, space, trim(s), trim(tmp));
#endif

      if (code == 211) {
        if (s == "END\r") {
          break;
        }

        space = '-';
      }

      if (!ret->code) {
        ret->code = code;
      }

      ret->text += replace(s, "\r", "\n");
    }

    if (sizeof(collection)) {
      ret->text = collection;
    }
    else if (sizeof(ret->text) && ret->text[-1] == '\n') {
      ret->text = ret->text[..<1];
    }

    switch (ret->code)
    {
      case 200..399:
        break;

      default:
        error("FTP error %d: %s\n", ret->code, ret->text);
        break;
    }

    if (ret->code == 227)
      create_fd2(ret);

    TRACE("read: %O\n", ret);

    return last_read = ret;
  }

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
}