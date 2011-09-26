#define EMPTY(S) !((S) && sizeof((S)))
protected constant decode_string = Protocols.HTTP.uri_decode;

string data;
string method;
string query;

mapping(string:mixed) misc = ([]);
mapping(string:mixed) variables = ([]);
mapping cookies = ([]);
mapping server = ([]);

void create()
{
  server = getenv();

  if (!EMPTY(server->CONTENT_LENGTH))
    misc->len = (int)(server->CONTENT_LENGTH - " ");
  
  query = server->QUERY_STRING;
  method = server->REQUEST_METHOD||"GET";
  
  if ((int)server->CONTENT_LENGTH)
    data = Stdio.stdin->read((int)server->CONTENT_LENGTH);

  if ( server["HTTP_COOKIE"] && sizeof( server["HTTP_COOKIE"] ))
    decode_cookies( server["HTTP_COOKIE"] );

  decode_query();

  if (misc->len && method == "POST")
    decode_post();
}

protected void decode_cookies(string data)
{
  foreach(data/";", string c) {
    string name, value;
    sscanf(c, "%*[ ]%s", c);
    if (sscanf(c, "%s=%s", name, value) == 2) {
      value = decode_string(value);
      name = decode_string(name);
      cookies[name] = value;
    }
  }
}

protected void decode_query()
{
  if (EMPTY(query)) return;
  string a, b;
  foreach (query/"&", string v) {
    sscanf(v, "%s=%s", a, b);
    if (!a) a = v;
    if (!EMPTY(a)) {
      a = decode_string(replace(a, "+", " "));
      b = decode_string(replace(b||"", "+", " "));
      add_variable(a, b);
    }
  }
}

protected void decode_post()
{
  if (EMPTY(data)) return;
  if (sizeof(data) < misc->len) {
    werror("%O: Short stdin read!\n", object_program(this));
    return;
  }
  
  string a, b;
  data = data[..misc->len];
  switch(lower_case(((server->CONTENT_TYPE||"")/";")[0]-" "))
  {
    default:
      if (misc->len < 200000) {
	foreach (replace(data-"\n", "+", " ")/"&", string v) {
	  sscanf(v, "%s=%s", a, b);

	  if (a)
	    add_variable(decode_string(a), decode_string(b||""));
	}
      }
      break;

    case "multipart/form-data":
      error("multipart/form-data not implemented\n");
      break;
  }
}

protected void add_variable(string a, string b)
{
  b = b || "";
  if ( variables[a] ) {
    if (!arrayp( variables[a] ))
      variables[a] = ({ variables[a] });

    variables[a] += ({ b });
  }
  else
    variables[a] = b;
}
