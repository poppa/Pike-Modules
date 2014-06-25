/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

//! Module for shortening long URL:s via goo.gl

constant ENDPOINT = "https://www.googleapis.com/urlshortener/v1/url";
constant OAUTH_SCOPE = "https://www.googleapis.com/auth/urlshortener";

#if constant(Standards.JSON)
function json_encode = Standards.JSON.encode;
function json_decode = Standards.JSON.decode;
#else
function json_encode = lambda (mixed p) {
  error("No JSON encode method defined. Set by defining "
        "WS.Google.UrlShortener.json_encode");
};
function json_decode = lambda (string p) {
  error("No JSON decode method defined. Set by defining "
        "WS.Google.UrlShortener.json_decode");
};
#endif

class Api
{
  protected string api_key;

  void create(void|string _api_key)
  {
    api_key = _api_key;
  }

  public mapping shorten(string url)
  {
    return call(([ "longUrl" : url ]));
  }

  public mapping expand(string url)
  {
    return call(([ "shortUrl" : url ]), "GET");
  }

  public mixed call(mapping params, string|void method)
  {
    method = method||"POST";

    if (api_key)
      params += ([ "key" : api_key ]);

    mapping headers = ([
      "Content-Type" : "application/json"
    ]);

    Protocols.HTTP.Query q;

    if (upper_case(method) == "GET")
      q = Protocols.HTTP.get_url(ENDPOINT, params, headers);
    else {
      string data = json_encode(params);
      q = Protocols.HTTP.do_method(method, ENDPOINT, 0, headers, 0, data);
    }

    if (q->status != 200)
      error("Bad status (%d) in HTTP response! ", q->status);

    mixed r = json_decode(q->data());

    return r;
  }
}

