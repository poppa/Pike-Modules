class DataPoint
{
  private int type;
  private string color;
  
  void create(int _type, string void|string _color)
  {
    type = _type;
    color = _color && .normalize_color(_color);
    
  }
  
  private string type_to_string()
  {
    switch (type)
    {
      case .DATAPOINT_FLAG:    return "f";
      case .DATAPOINT_NUMERIC: return "N";
      case .DATAPOINT_TEXT:    return "t";
    }

    error("Unknown data point type! ");
  }
}