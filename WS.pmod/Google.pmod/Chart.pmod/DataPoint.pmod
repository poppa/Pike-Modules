//! Class representing a DataPoint

constant TYPE_FLAG    = 0;
constant TYPE_TEXT    = 1;
constant TYPE_NUMERIC = 2;

constant NUMTYPE_FLOAT        = "f";
constant NUMTYPE_PERCENT      = "p";
constant NUMTYPE_SCIENTIFIC   = "e";
constant NUMTYPE_CURRENCY_EUR = "cEUR";
constant NUMTYPE_CURRENCY_GBP = "cGBP";
constant NUMTYPE_CURRENCY_SEK = "cSEK";
constant NUMTYPE_CURRENCY_USD = "cUSD";

protected class Point
{
  protected int        type;
  protected string     color;
  protected int        index;
  protected string     point;
  protected int        size;
  protected int(-1..1) priority;

  protected void create(int             _type,
                        int             _index,
                        void|string     _color,
                        void|int|string _point,
			void|int        _size,
			void|int(-1..1) _priority)
  {
    type     = _type;
    index    = _index;
    color    = _color && .normalize_color(_color);
    point    = _point && (string)_point;
    size     = _size||10;
    priority = _priority;
  }

  protected string type_to_string()
  {
    switch (type)
    {
      case TYPE_FLAG:    return "f";
      case TYPE_NUMERIC: return "N";
      case TYPE_TEXT:    return "t";
    }

    error("Unknown data point type! ");
  }
}

class Any
{
  inherit Point;
  protected string contents;

  void set_index(int idx)
  {
    ::index = idx;
  }

  string get()
  {
    string s = "";
    if (type == TYPE_NUMERIC)
      s = internal_get();
    else
      s = type_to_string() + contents;

    s += "," + (color||"000000") +
         "," + (string)index     +
	 "," + (string)point     +
	 "," + (string)size      +
	 "," + (string)priority;
    
    return s;
  }

  string internal_get();
}

class Flag
{
  inherit Any;

  void create(int             index,
              string          content,
              void|string     color,
	      void|int|string data_point,
              void|int        size,
	      void|int(-1..1) priority)
  {
    ::create(TYPE_FLAG, index, color, data_point, size, priority);
    contents = content;
  }
}

class Number
{
  inherit Any;

  private string    subtype;
  private int       zeros;
  private int(0..1) group_sep;
  private string    coord;

  void create(int             index,
              string          num_type,
              void|int        trailing_zeros,
	      void|int(0..1)  group_separators,
              void|string     color,
	      void|int|string data_point,
              void|int        size,
	      void|int(-1..1) priority)
  {
    ::create(TYPE_NUMERIC, index, color, data_point, size, priority);

    subtype   = num_type;
    zeros     = trailing_zeros;
    group_sep = group_separators;
  }

  string internal_get()
  {
    return "N*" + subtype + (string)zeros + (string)(group_sep||"") +
           (coord||"") + "*";
  }
}
