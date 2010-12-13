/*| Copyright © 2009 Pontus Östlund <pontus@poppa.se>
 *|
 *| The XLS.pmod module is free software; you can redistribute it and/or
 *| modify it under the terms of the GNU General Public License as published by
 *| the Free Software Foundation; either version 2 of the License, or (at your
 *| option) any later version.
 *|
 *| The XLS.pmod module is distributed in the hope that it will be useful,
 *| but WITHOUT ANY WARRANTY; without even the implied warranty of
 *| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 *| Public License for more details.
 *|
 *| You should have received a copy of the GNU General Public License
 *| along with this program; if not, write to the Free Software Foundation,
 *| Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

//! The XML.pmod module provides an easy way to generate an Excel XML document.
//!
//! @xml{<code lang="pike" detab="3" tabsize="2">
//!   XLS.Workbook wb = XLS.Workbook();
//!   wb->add_worksheet("Data", 1);
//!   wb->add_row();
//!   wb->add_cell("ID");
//!   wb->add_cell("Name");
//!   wb->add_cell("Date");
//!
//!   foreach (some_array, mapping row) {
//!     wb->add_row();
//!     foreach (values(row), mixed val)
//!       wb->add_cell(val);
//!   }
//!
//!   write(wb->render());
//! </code>@}
 
#define DATE_P "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
#define TIME_P "[0-2][0-9]:[0-5][0-9]:[0-9][0-9](\.[0-9]+)*"

//! Regexp for checking if a value is an int or a float or any date/time type
private Regexp intre      = Regexp("^([0-9]+)(\.[0-9]+)$");
private Regexp datere     = Regexp("^(" DATE_P ")$");
private Regexp timere     = Regexp("^(" TIME_P ")$");
private Regexp datetimere = Regexp("^(" DATE_P ")[ T]+(" TIME_P ")$");

//! Valid Excel datatypes
private multiset data_types = (< "Number","String","DateTime","Date","Time" >);

//! Returns the style to use for @[type]
//!
//! @param type
//!  An Excel datatype
//!
//! @seealso 
//!  data_types 
private string get_style(string type)
{
  return ([ "DateTime" : "s22",
	    "Date"     : "s21",
	    "Time"     : "s23" ])[type];
}

//! Returns the Excel datatype for @[v]
//!
//! @param v
//!  Any value.
private string get_type(mixed v)
{
  if (stringp(v)) {
    if (is_numeric(v)) {
      if (search(v, ".") > -1)
	v = (float)v;
      else
	v = (int)v;
    }
  }

  if (intp(v) || floatp(v))
    return "Number";
  if (datetimere->match(v))
    return "DateTime";
  if (timere->match(v))
    return "Time";
  if (datere->match(v))
    return "Date";

  return "String";
}

int is_numeric(string s)
{
  if (!s || !sizeof(s))
    return 0;

  int c, i;
  c = s[0];

  if (!(c == '-' || c == '+' || c == '.' || c > 47 && c < 58))
    return 0;

  for (i = 1; i < sizeof(s); i++) {
    c = s[i];
    if ((c < 48 || c > 57) && c != '.')
      return 0;
  }
  
  return 1;
}

//! Main class for creating an Excel XML file
class Workbook
{
  private string _header = 
  "<?xml version=\"1.0\"?>\n"
  "<?mso-application progid=\"Excel.Sheet\"?>\n";
  
  private string _styles =
  " <Styles>\n"
  "  <Style ss:ID=\"Default\" ss:Name=\"Normal\">\n"
  "   <Alignment ss:Vertical=\"Bottom\"/>\n"
  "   <Borders/>\n"
  "   <Font/>\n"
  "   <Interior/>\n"
  "   <NumberFormat/>\n"
  "   <Protection/>\n"
  "  </Style>\n"
  "  <Style ss:ID=\"CHeader\">\n"
  "   <Borders>\n"
  "    <Border ss:Position=\"Bottom\" ss:LineStyle=\"Continuous\" "
  "ss:Weight=\"1\"/>\n"
  "   </Borders>\n"
  "   <Font x:Family=\"Swiss\" ss:Color=\"#0000FF\" ss:Bold=\"1\"/>\n"
  "  </Style>\n"
  "  <Style ss:ID=\"Bold\">\n"
  "   <Font x:Family=\"Swiss\" ss:Bold=\"1\"/>\n"
  "  </Style>\n"
  "  <Style ss:ID=\"s27\">\n"
  "   <Font x:Family=\"Swiss\" ss:Color=\"#0000FF\" ss:Bold=\"1\"/>\n"
  "  </Style>\n"
  "  <Style ss:ID=\"s21\">\n"
  "   <NumberFormat ss:Format=\"yyyy\\-mm\\-dd\"/>\n"
  "  </Style>\n"
  "  <Style ss:ID=\"s22\">\n"
  "   <NumberFormat ss:Format=\"yyyy\\-mm\\-dd\\ hh:mm:ss\"/>\n"
  "  </Style>\n"
  "  <Style ss:ID=\"s23\">\n"
  "   <NumberFormat ss:Format=\"hh:mm:ss\"/>\n"
  "  </Style>\n"
  " </Styles>\n";
  
  private string _workbook =
  "<Workbook\n"
  " xmlns:x=\"urn:schemas-microsoft-com:office:excel\"\n"
  " xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\"\n"
  " xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\">\n";
  
  private mapping   _worksheets = ([]);
  private Worksheet current_ws;
  private Row       current_row;
  private int(0..1) auto_encode_utf8 = 0;

  //! Create a new instance of @[Workbook()]
  //!
  //! @param utf8_encode
  //!  If @expr{1@} the data will be UTF8 encoded  
  void create(void|int(0..1) utf8_encode) 
  {
    auto_encode_utf8 = utf8_encode;
  }

  //! Append a @[Worksheet()] to the Workbook
  //!
  //! @param name
  //!  The name of the worksheet
  //! @param first_row_header
  //!  If @expr{1@} the first row will be treated as column headers and will
  //!  be "prettyfied"
  //!
  //! @returns
  //!  The created @[Worksheet()]
  Worksheet worksheet(string name, void|int(0..1) first_row_header)
  {
    Worksheet ws = current_ws = Worksheet(name, first_row_header);
    _worksheets[name] = ws;
    return ws;
  }
  
  //! Append a @[Row()] to the current @[Worksheet()]
  //!
  //! @param cells
  //!  If given the row will be populated with @[cells]
  //! @param style
  //!  If given all @[cells] will get the @[style]
  //!
  //! @returns
  //!  The created @[Row()]
  Row add_row(void|array cells, void|string style)
  {
    Row r = current_row = current_ws->add_row();

    if (cells)
      foreach (cells, mixed cell)
	add_cell(cell, style);

    return r;
  }

  //! Append a @[Cell()] to the current @[Row()]
  //!
  //! @param data
  //!  The cell data
  //! @param style
  //!  The style of the cell
  //! @param type
  //!  Force datatype @[type] on the cell
  void add_cell(mixed data, void|string style, void|string type)
  {
    current_row->add_cell(data, style, type);
  }

  //! Renders the @[Workbook()] to XML data.
  string render()
  {
    string x = _header + _workbook + _styles;
    foreach (_worksheets;;Worksheet sheet)
      x += sheet->to_xml();
    x += "</ss:Workbook>";
    return auto_encode_utf8 ? string_to_utf8(x) : x;
  }
}

//! Represents an Excel worksheet
class Worksheet
{
  private string    name;
  private array     rows = ({});
  private int(0..1) first_row_data = 1;

  //! Create a new instance of @[Worksheet()]
  //!
  //! @param name
  //!  The name of the worksheet
  //! @param first_row_header
  //!  If @expr{1@} the first row will be treated as column headers and will
  //!  be "prettyfied"
  void create(string _name, void|int first_row_header)
  {
    name = _name;
    first_row_data = !first_row_header;
  }

  //! Append a @[Row()] to the worksheet
  //!
  //! @returns
  //!  The created @[Row()]
  Row add_row()
  {
    Row r = Row((!sizeof(rows) && !first_row_data));
    rows += ({ r });
    return r;
  }
  
  //! Renders the worksheet to XML.
  string to_xml()
  {
    string x = " <ss:Worksheet ss:Name=\"" + name + "\">\n  <ss:Table>\n";
    foreach (rows, Row row)
      x += row->to_xml() + "\n";
    return x + "  </ss:Table>\n </ss:Worksheet>\n";
  }
}

// Represents a row in an Excel worksheet
class Row
{
  private array     cells = ({});
  private int(0..1) is_header = 0;
  
  //! Create a new instance of @[Row()]
  //!
  //! @param header
  //!  if @expr{1@} the cells will be treated as column headers  
  void create(void|int header)
  {
    is_header = header;
  }

  //! Append @[cells] to the row
  //!
  //! @param cells
  void add_cells(array(mixed) cells)
  {
    foreach (cells, mixed cell)
      add_cell(cell);
  }

  //! Append a @[Cell()] to the row
  //!
  //! @param data
  //!  The cell data
  //! @param style
  //!  The style of the cell
  //! @param type
  //!  Force datatype @[type] on the cell
  void add_cell(mixed data, void|string style, void|string type)
  {
    cells += ({ Cell(data, style ? style : is_header ? "CHeader" : 0, type) }); 
  }
  
  //! Render the row to XML
  string to_xml()
  {
    string x = "   <ss:Row>\n";
    foreach (cells, Cell cell)
      x += cell->to_xml() + "\n";
    return x + "   </ss:Row>";
  }

  //! Cast @[Row()] to @[t]
  //! Only @expr{string@} is implemented which will cast the object to XML
  mixed cast(string t)
  {
    if (t == "string") 
      return to_xml();

    error("Can't cast Row to \"%s\n", t);
  }
}

// Represents a data cell in a worksheet row.
class Cell
{
  private string style;
  private string type;
  private mixed  data;

  //! Create a new instance of @[Cell()]
  //!
  //! @param data
  //!  The value of the cell
  //! @param style
  //!  Force @[style] to cell
  //! @param style
  //!  Force Excel datatype @[type] on cell
  void create(mixed _data, void|string _style, void|string _type)
  {
    data  = _data;
    type  = _type && data_types[_type] ? _type : get_type(data);
    style = _style||get_style(type);

    if ( (< "DateTime", "Date", "Time" >)[type] ) {
      if (type == "Date")
	data += "T00:00:00";
      else if (type == "DateTime")
	data = replace(data, " ", "T");
      else if (type == "Time")
	data = "1899-12-31T" + data;

      if (!glob("*.???", data))
	data += ".000";

      type = "DateTime";
    }
  }

  //! Render the cell to XML
  string to_xml()
  {
    string x = "    <ss:Cell";
    if (style) x += " ss:StyleID=\"" + style + "\"";
    x += "><Data ss:Type=\""+type+"\">" + (string)data + "</Data></ss:Cell>";
    return x;
  }

  //! Cast @[Cell()] to @[t]
  //! Only @expr{string@} is implemented which will cast the object to XML
  mixed cast(string t)
  {
    if (t == "string") 
      return to_xml();

    error("Can't cast Cell to \"%s\n", t);
  }
}
