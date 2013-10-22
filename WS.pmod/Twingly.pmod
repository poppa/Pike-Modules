/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Twingly.pmod has methods for pinging your blog at Twingly.

import Protocols.XMLRPC;

private constant TWINGLY_URL = "http://rpc.twingly.com";
private constant METHOD_PING = "weblogUpdates.ping";
private constant METHOD_EXTENDED_PING = "weblogUpdates.extendedPing";
private int(0..1) print_error = 0;

//! If set to @tt{1@} any XML-RPC fault will be printed to @tt{stderr@}.
//!
//! @param value
void report_fault(int(0..1) value)
{
  print_error = value;
}

//! Tells Twingly you have new content on your blog.
//!
//! @seealso
//!  @[extended_ping], @url{http://rpc.twingly.com/@}
//!
//! @param blog_name
//! @param blog_url
//!
//! @returns
//!  @tt{1@} on success, @tt{0@} otherwise. If @[report_fault()] is set
//!  to @tt{1@} any fault message will be printed to @tt{stderr@}.
int(0..1) ping(string blog_name, string blog_url)
{
  Client c = Client(TWINGLY_URL);
  array|Fault res = c[METHOD_PING](safep(blog_name), safep(blog_url));
  if (objectp(res)) {
    if (print_error)
      werror("XML-RPC error (%d): %s\n", res->fault_code, res->fault_string);
    return 0;
  }

  return 1;
}

//! Tells Twingly you have new content on your blog.
//!
//! @seealso
//!  @[ping], @url{http://rpc.twingly.com/@}
//!
//! @param blog_name
//! @param blog_url
//! @param update_url
//! @param rss_url
//! @param tags
//!
//! @returns
//!  @tt{1@} on success, @tt{0@} otherwise. If @[report_fault()] is set
//!  to @tt{1@} any fault message will be printed to @tt{stderr@}.
int(0..1) extended_ping(string blog_name, string blog_url, string update_url,
                        string rss_url, string tags)
{
  Client c = Client(TWINGLY_URL);
  array|Fault res = c[METHOD_EXTENDED_PING](safep(blog_name), safep(blog_url),
                                            safep(update_url), safep(rss_url),
                                            safep(tags));

  if (objectp(res)) {
    if (print_error)
      werror("XML-RPC error (%d): %s\n", res->fault_code, res->fault_string);
    return 0;
  }

  return 1;
}

// Makes sure @[s] isn't null and tries to UTF8-encode it silently.
private string safep(string s)
{
  if (!s) return "";
  catch { return string_to_utf8(s); };
  return s;
}

