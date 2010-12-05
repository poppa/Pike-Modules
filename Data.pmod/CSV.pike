private string content_type = "text/csv";
private string coldelim;
private string rowdelim;
private array  rows = ({});
private array  current_row;
private int    index = 0;

void create(void|string column_delimiter, void|string row_delimiter)
{
  coldelim = column_delimiter || "\t";
  rowdelim = row_delimiter    || "\n";
}

array get_rows()
{
  return rows;
}

void add_row(mixed ... cells)
{
  if (cells) {
    for (int i = 0; i < sizeof(cells); i++)
      cells[i] = (string)cells[i];
  }

  current_row = cells||({});
  rows += ({ current_row });
  index++;
}

void add_cell(mixed v)
{
  if (!current_row)
    error("Can't add a cell to a non-existing row!\n");

  rows[index-1] += ({ (string)v });
}

void parse_file(string path)
{
  if (!Stdio.exist(path))
    error("File \"%s\" doesn't exist!\n", path);

  parse(Stdio.read_file(path));
}

void parse(string data)
{
  index = 0;
  rows  = ({});

  foreach (normalize_data(data)/rowdelim, string r) {
    index++;
    rows += ({ r/coldelim });
  }
}

void mk_mapping(void|int(0..1) lowercase)
{
  array keys = rows[0];
  array data = rows[1..];
  array out  = ({});

  if (lowercase)
    keys = map(keys, lower_case);

  int klen = sizeof(keys);
  
  foreach (data, array row) {
    if (sizeof(row) < klen)
      row += allocate(klen - sizeof(row));
    
    mapping tmp = ([]);
    for (int i = 0; i < klen; i++)
      tmp[keys[i]] = row[i] && sizeof( row[i] ) && row[i] || 0;

    out += ({ tmp });
  }

  rows = out;
}

string render(void|int trim)
{
  for (int i = 0; i < sizeof(rows); i++) {
    if (trim) rows[i] = map(rows[i], String.trim_all_whites);
    rows[i] = (rows[i] && (rows[i]*coldelim))||"";
  }

  return rows*rowdelim;
}

string render_file(string file_name, void|int trim)
{
  Stdio.write_file(file_name, render(trim));
}

int _sizeof()
{
  return sizeof(rows);
}

protected string normalize_data(string data)
{
  return replace(data, ({ "\r\n", "\r" }), ({ "\n", "\n" })); 
}
