/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! FTP client
//!
//! @code
//!  Protocols.FTP.Client cli = Protocols.FTP.Client("hostname");
//!
//!  if (!cli->login("username", "password")) {
//!    werror("Unable to login to remote server\n");
//!    return 0;
//!  }
//!
//!  cli->binary_mode();
//!  cli->cd("/my/dir");
//!  array(mapping) dir = cli->ls();
//!
//!  foreach (dir, mapping f) {
//!    write("%s: %s\n", f->type, f->path);
//!  }
//!
//!  f->put("my-local.file");
//!
//!  f->quit();
//! @endcode

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
    TRACE("low_write(%O)\n", what);
    last_cmd = trim(what);
    function wfun = s ? s->write : sock::write;
    int w = wfun(last_cmd + "\r\n");

    TRACE("wrote: %d\n", w);

    if (w != sizeof(last_cmd+"\r\n")) {
      error("Write command was truncated!\n");
    }
  }

  //!
  protected mapping read_list(void|Stdio.FILE fd)
  {
    TRACE("read_list(%O)\n", last_cmd);
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

    mapping r = last_read = ([ "code" : 226, "text" : collection ]);

    TRACE("ret: %O\n", r);

    return r;
  }

  //! Read a file from a secondary fd
  protected mapping read_file(Stdio.FILE fd)
  {
    TRACE("read_file(%O)\n", last_cmd);
    mapping m = low_read(0);
    string ret = fd->read();

    read_empty();

    if (search(m->text, "ASCII") > -1)
      ret = replace(ret, "\r", "\n");

    mapping r = last_read = ([ "code" : 226, "text" : ret ]);

    TRACE("ret: %O\n", r);

    return r;
  }

  //! Read result on the control connection after the data connection
  //! has been used.
  protected void read_empty()
  {
    TRACE("read_empty(%O)\n", last_cmd);

    while (string tmp = sock::gets()) {
      sscanf(tmp, "%d%c%s", int code, int c, string rest);
      TRACE("empty: %d, %c, %s\n", code, c, rest);

      if (code == 226) {
        TRACE("Done empty reading:%O\n", code);
        break;
      }
    }
  }

  //! Read server reply
  //!
  //! @param fd
  protected mapping read(void|Stdio.FILE fd)
  {
    string _cmd = upper_case((last_cmd/" ")[0]);
    mapping r;

    if ((< "MLST", "NLST", "MLSD", "LIST" >)[_cmd]) {
      r = read_list(fd);
    }
    else if ((< "RETR" >)[_cmd]) {
      r = read_file(fd);
    }
    else {
      r = low_read(fd);
    }

    return r;
  }

  //! Read from connection
  //!
  //! @param fd
  protected mapping low_read(void|Stdio.FILE fd)
  {
    TRACE("low_read(%O)\n", last_cmd);
    mapping ret = ([ "code" : 0, "text" : "" ]);
    int code, space;
    string s;
    function rfunc = fd ? fd->gets : sock::gets;
    array(string) collection = ({});

    space = '-';

    while (space == '-') {
      space = ' ';
      string tmp = rfunc();

      TRACE("low_read(%O)\n", tmp);

      if (!tmp) {
        break;
      }

      if (sscanf(tmp, "%d%c%s", code, space, s) != 3) {
        collection += ({ trim(tmp) });
      }

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
        error("FTP error %d: %s\n", ret->code||0, ret->text||"(unknown)");
        break;
    }

    if (ret->code == 227)
      create_fd2(ret);

    TRACE("ret: %O\n", ret);

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
  inherit BaseClient : sock;

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

  /* ALIASES */

  //! Begins transmission of a file to the remote site. Alias of @[stor()]
  //!
  //! @param local_file
  //! @param remote_path
  //!  If @tt{null@} a file with the same basename as @[local_file] will be
  //!  created in the current working directory
  string put(string local_file, void|string remote_path)
  {
    return stor(local_file, remote_path);
  }

  //! Deletes the file @[path] on the remote host. Alias of @[dele()]
  //!
  //! @param path
  int(0..1) rm(string path)
  {
    return dele(path);
  }

  //! Retrieve a remote file. Alias of @[retr()].
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
  string get(string path)
  {
    return retr(path);
  }

  //! Creates the directory @[path] on the remote host. Alias of @[mkd()]
  //!
  //! @param path
  //! @returns
  //!  The path to the created directory on the remote host
  string mkdir(string path)
  {
    return mkd(path);
  }

  //! Directory listing. Alias of @[mlsd()].
  //!
  //! @param path
  array(mapping) ls(void|string path)
  {
    return mlsd(path);
  }

  //! Deletes the directory @[path] on the remote host. Alias of @[rmd()].
  //!
  //! @param path
  int(0..1) rmdir(string path)
  {
    return rmd(path);
  }

  //! Rename @[from] to @[to]
  //!
  //! @param from
  //! @param to
  //! @returns
  //!  The new remote path
  string mv(string from, string to)
  {
    cmd("RNFR " + from);
    mapping r = cmd("RNTO " + to);

    if (r->code == 250) {
      if (dele(from)) {
        sscanf (r->text, "%*s %*s /%s", string p);

        if (p[-1] == '.')
          p = p[..<1];

        return "/" + p;
      }
    }
  }

  //! Copy @[from] to @[to].
  //!
  //! @param from
  //! @param to
  //! @returns
  //!  The new remote path
  string cp(string from, string to)
  {
    cmd("RNFR " + from);
    mapping r = cmd("RNTO " + to);

    if (r->code == 250) {
      sscanf (r->text, "%*s %*s /%s", string p);

      if (p[-1] == '.')
        p = p[..<1];

      return "/" + p;
    }
  }

  //! Change working directory. Alias of @[cwd()].
  //!
  //! @param path
  //!
  //! @returns
  //!  The new directory path
  string cd(string path)
  {
    return cwd(path);
  }

  string help(void|string command)
  {

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

  //! Deletes the file @[path] on the remote host.
  //!
  //! @param path
  int(0..1) dele(string path)
  {
    mapping r = cmd("DELE " + path);
    return r->code == 250;
  }

  //! If invoked without parameters, returns general status information about
  //! the FTP server process. If a parameter is given, acts like the LIST
  //! command, except that data is sent over the control connection (no PORT or
  //! PASV command is required).
  //!
  //! @param spec
  string stat(void|string spec)
  {
    mixed r = cmd("STAT " + (spec||""));
    return r->text;
  }

  //! Begins transmission of a file to the remote site.
  //!
  //! @param local_file
  //! @param remote_path
  //!  If @tt{null@} a file with the same basename as @[local_file] will be
  //!  created in the current working directory
  string stor(string local_file, void|string remote_path)
  {
    if (!remote_path)
      remote_path = basename(local_file);

    pasv();

    cmd("STOR " + remote_path);

    fd2->write(Stdio.read_file(local_file));

    close_fd2();

    read_empty();

    TRACE("Wrote file %O!\n", remote_path);

    return remote_path;
  }

  //! Append data to the end of a file on the remote host. If the file does not
  //! already exist, it is created.
  //!
  //! @param local_file
  //! @param remote_path
  //!  If @tt{null@} a file with the same basename as @[local_file] will be
  //!  used, or created, in the current working directory
  string appe(string local_file, void|string remote_path)
  {
    if (!remote_path)
      remote_path = basename(local_file);

    pasv();

    cmd("APPE " + remote_path);

    fd2->write(Stdio.read_file(local_file));

    close_fd2();

    read_empty();

    TRACE("Wrote file %O!\n", remote_path);

    return remote_path;
  }

  //! Sets the transfer mode to one of:
  //!
  //!   S - Stream
  //!   B - Block
  //!   C - Compressed
  //!
  //! The default mode is Stream.
  //!
  //! @param which
  //!  @tt{S, B or C@}
  int(0..1) mode(string which)
  {
    which = upper_case(which);
    if (!(< "S", "B", "C" >)[which]) {
      error("Unknown mode %O. Expected S, B or C!\n", which);
    }

    mapping r = cmd("MODE " + which);
    return 1;
  }

  //! Creates the directory @[path] on the remote host.
  //!
  //! @param path
  //! @returns
  //!  The path to the created directory on the remote host
  string mkd(string path)
  {
    mapping r = cmd("MKD " + path);

    if (r->code == 257) {
      sscanf (r->text, "\"%s\"", path);
      return path;
    }

    return 0;
  }

  //! Returns the last modified time of @[path]
  //!
  //! @param path
  Calendar.Second mdtm(string path)
  {
    mapping r = cmd("MDTM " + path);
    array tt = allocate(6);
    sscanf (r->text, "%4s%2s%2s%2s%2s%2s",
            tt[0], tt[1], tt[2], tt[3], tt[4], tt[5]);
    return Calendar.parse("%Y %M %D %h %m %s", tt * " ");
  }

  //! Makes the parent of the current directory be the current directory.
  //!
  //! @returns
  //!  The path of the parent directory
  string cdup()
  {
    mapping r = cmd("CDUP");
    sscanf (r->text, "%*s /%s", string p);

    if (has_suffix(p, ".")) {
      p = p[..<1];
    }

    return "/" + p;
  }

  //! Deletes the directory @[path] on the remote host.
  //!
  //! @param path
  int(0..1) rmd(string path)
  {
    mapping r = cmd("RMD " + path);
    return r->code == 250;
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
    mapping r = passive_cmd("LIST " + path);
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
    mapping r = passive_cmd("RETR " + remote_path);

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
    mapping r = passive_cmd("NLST " + path);
    return r->text;
  }

  //! Directory listing
  //!
  //! @param path
  array(mapping) mlsd(void|string path)
  {
    path = path || "";
    mapping r = passive_cmd("MLSD " + path);
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
    TRACE("cmd(%s)\n", c);
    low_write(c);
    return read();
  }

  //! Same as @[cmd()] except this uses a different connection if in
  //! passive mode. If the command @[c] needs passive mode and neither
  //! @[pasv()] nor @[port()] was called before @[pasv()] will be called
  //! automatically.
  //!
  //! @param c
  mapping passive_cmd(string c)
  {
    TRACE("passive_cmd(%s)\n", c);
    if (_use_passive_mode) {
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

#if 0
class AsyncClient
{
  inherit Client : client;
  inherit Protocols.NNTP.asyncprotocol : async;

  void create()
  {

  }

  int async_connect(string host, int port, function cb, mixed ... extra)
  {
    if (!host) {
      error("argument \"host\" can not be null! ");
    }

    if (!port) {
      port = 21;
    }

    return async::async_connect(host, port, lambda (int success) {
                          if (success) {
                            set_nonblocking(read_cb, write_cb, close_cb);
                            //client::read();
                            return cb(success, @extra);
                          }
                          error("Connection error!\n");
                        });
  }

  int read_cb(mixed id, string data)
  {
    TRACE("Read callback: %O: %O\n", id, data);
    async::read_cb(id, data);
    return 0;
  }

  int write_cb(mixed id)
  {
    TRACE("Write callback: %O\n", id);
    return 0;
  }

  int close_cb(mixed id)
  {
    TRACE("Close callback: %O\n", id);
    return 0;
  }
}
#endif
