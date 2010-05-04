string name;
string value;

protected void create(string _name, mixed ... rest)
{
  name = _name;
  value = rest && map( rest, lambda(string s){ return (string)s; } )*"";
}

object_program `+(mixed val)
{
  if (!value) value = "";
  value += (string)val;

  return this;
}

mixed cast(string how)
{
  string r = name;
  if (value && sizeof(value))
    r += "=" + value;
  return r;
}

string _sprintf(int t)
{
  return t == 'O' && sprintf("Param(%O, %O)", name, value);
}
