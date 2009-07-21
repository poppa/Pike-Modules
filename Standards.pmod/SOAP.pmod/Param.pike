
string name;
mixed value;
object|program|function type;
string encoding_style_uri;

void create(string _name, mixed _value, object|program|function _type, 
            void|string _encoding_style_uri)
{
  name = _name;
  value = _value;
  type = _type;
  encoding_style_uri = _encoding_style_uri;
}