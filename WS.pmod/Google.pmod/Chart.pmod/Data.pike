//! Chart data class

//! Used to simple encode data
protected constant ALNUMS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
			    "abcdefghijklmnopqrstuvwxyz"
			    "0123456789"/1;

//! Used to exteded encode data
protected constant EXTENDED_MAP = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                                  "abcdefghijklmnopqrstuvwxyz"
				  "0123456789-."/1;

protected constant EXTENDED_MAP_LEN = 64;

//! Actual values
protected array(float) values = ({});

//! Data group. Array of instances of self
protected array(object_program) group  = ({});

//! Minimum value
protected int|float min_value  = 0;

//! Maximum value
protected int|float max_value  = 100;

//! Chart color of this data set
protected string color   = "FFCC33";

//! Data legend
protected .Legend legend  = .Legend();

//! Data labels
protected array labels   = ({});

protected .DataPoint.Any datapoint;

//! Creates a new @[Data] object.
//!
//! @param ... args
void create(int|float|string ... args)
{
  values = map( args, lambda (int|float|string v){ return (float)v; } );
  [min_value, max_value] = low_get_min_max();
}

//! Appends to object.
//!
//! @param value
//!  If @[value] is an instance of @[Data] a data group will be created.
//!  Else @[value] will be appended to the internal data set.
object `+(int|float|string|object value)
{
  if (objectp(value)) {
    if (object_program(value) == object_program(this)) {
      group += ({ value });
      [min_value, max_value] = low_get_min_max();
      value->set_scale(min_value, max_value);
    }
  }
  else {
    float v = (float)value;
    if (v < min_value) min_value = v;
    if (v > max_value) max_value = v;
    values += ({ v });
  }

  return this;
}

//! Set the color of the chart items this data set represents (pie slice,
//! bar, line etc).
//!
//! @param _color
//!  Hexadecimal
void set_color(string _color)
{
  color = .normalize_color(_color);
}

void set_data_point(.DataPoint.Any data_point)
{
  datapoint = data_point;
}

//! Returns the color
string get_color()
{
  return color;
}

array get_values()
{
  return values;
}

//! Clear the data group
void clear_group()
{
  group = ({});
}

array(float) get_min_max()
{
  return ({ min_value, max_value });
}

protected array(float) low_get_min_max()
{
  array(float) all_values = values;
  if (sizeof(group))
    foreach (group->get_values(), array(float) v)
      all_values += v;

  float mi, ma;
  mi = min(@all_values);
  ma = max(@all_values);
  return ({ mi, ma });
}

//! Set the scale of the data values.
//!
//! @param _min
//! @param _max
void set_scale(int|float _min, int|float _max)
{
  min_value = (int)_min;
  max_value = (int)_max;
}

//! Returns the minimum value
int get_min()
{
  return min_value;
}

//! Returns the maximum value
int get_max()
{
  return max_value;
}

//! Returns the labels
array get_labels()
{
  return labels;
}

//! Returns the data point
.DataPoint.Any get_data_point()
{
  return datapoint;
}

//! Sets the legend for the data set
//!
//! @param text
//! @param position
//!  See @[Legend] for available positions
void set_legend(string text, void|string|int position)
{
  legend->text = text;
  if (position)
    legend->position = position;
}

//! Returns the legend
.Legend get_legend()
{
  return legend;
}

string extended_encode()
{
  return "e:" + low_extended_encode(); 
}

string low_extended_encode(void|int _max)
{
  _max = _max || max_value;
  if (!_max) return "";
  array(string) data = ({});
  array(string) all_data = ({});
  foreach (values, float val) {
    float scaled_val = floor(EXTENDED_MAP_LEN * EXTENDED_MAP_LEN * val/_max);
    if (scaled_val > (EXTENDED_MAP_LEN * EXTENDED_MAP_LEN) - 1)
      data += ({ ".." });
    else if (scaled_val < 0)
      data += ({ "__" });
    else {
      float quotient = floor(scaled_val / EXTENDED_MAP_LEN);
      float remainder = scaled_val - EXTENDED_MAP_LEN * quotient;
      data += ({ EXTENDED_MAP[(int)quotient] + EXTENDED_MAP[(int)remainder] });
    }
  }

  all_data += ({ data*"" });

  if (sizeof(group))
    all_data += group->low_extended_encode();

  return all_data*",";
}

// Simple encode the data.
string simple_encode()
{
  return "s:" + low_simple_encode();
}

string low_simple_encode(void|int _max)
{
  int vlen = sizeof(ALNUMS)-1;
  _max = _max || max_value;
  array(string) all_data = ({});
  array(string) data = ({});

  foreach (values, float value) {
    if (value > _max)
      value = (float)_max;

    if (value > 0.0)
      data += ({ ALNUMS[ (int)round(vlen * (value/_max)) ] });
    else
      data += ({ "_" });
  }

  all_data += ({ data*"" });

  if (sizeof(group))
    all_data += group->low_simple_encode();

  return all_data*",";
}

//! Checks if this object is a group of @[Data] obejcts
int(0..1) is_group()
{
  return sizeof(group) > 0;
}

// Turs the @[min] and @[max] values into a query variable
string scale_to_url()
{
  array(string) data = ({ low_get_scale() });

  if (sizeof(group))
    data += group->low_get_scale();

  return "chds=" + (data*"|");
}

string low_get_scale()
{
  return sprintf("%d,%d", (int)min_value, (int)max_value);
}

string color_to_url()
{
  array clr = ({ color });
  if (sizeof(group))
    clr += group->get_color();
  return "chco=" + (clr*",");
}

string labels_to_url()
{
  if (sizeof(labels))
    return "chl=" + labels*"|";

  return "";
}

string legend_to_url()
{
  array l = ({ legend->text });
  if (sizeof(group))
    l += group->get_legend()->text;

  string p = "";
  if (legend->position)
    p = "&amp;chdlp=" + legend->position;

  return "chdl=" + l*"|" + p;
}

string datapoints_to_url()
{
  array dps = ({ datapoint && datapoint->get() });
  if (sizeof(group))
    dps += group->get_data_point()->get();

  dps -= ({ 0 });
  if (sizeof(dps))
    return "chm=" + (dps*"|");

  return "";
}

//! Cast method
//!
//! @param how
mixed cast(string how)
{
  array vals = map(values, lambda(float v) { return sprintf("%.1f", v); } );

  switch (how)
  {
    case "string":
      string s = extended_encode() + "&amp;" +
		 scale_to_url()  + "&amp;" +
		 color_to_url();

      if (legend && legend->text)
	s += "&amp;" + legend_to_url();

      if (sizeof(labels))
	s += "&amp;" + labels_to_url();

      if (datapoint)
	s += "&amp;" + datapoints_to_url();

      return "chd=" + s;

    case "array":
      return values;
  }

  error("Can't cast Data() to \"%s\"!\n", how);
}

string _sprintf(int t)
{
  return t == 'O' && sprintf("Data(%s)", cast("string"));
}
