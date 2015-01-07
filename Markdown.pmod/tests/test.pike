/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.
*/

constant tmpl = #"<!doctype html>
<html>
  <head>
    <meta charset=\"utf-8\">
    <title>Test: %s</title>
    <style>
      body { font: 100%%/140%% arial, sans-serif; }
      .md .content { white-space: pre-wrap; font-family: monospace; font-size: 14px; }
      .box {
        display: flex;
        flex-flow: row wrap;
        overflow: hidden;
        border-radius: 5px;
      }
      .column {
        flex: 2 50%%;
        background: #f1f1f1;
      }
      .column:first-child {
        border-right: 1px solid #ccc;
        margin-right: -1px;
      }
      .column:last-child {
        border-left: 1px solid #ccc;
        margin-left: -1px;
      }
      .wrapper { padding: 0 24px 24px;}
      h1.header {
        margin: 0px -24px 24px;
        padding: 24px 24px;
        background: #474777;
        color: white;
      }

      .md .header { background: #C58C00; }
      .html .header { background: #0085C5; }

      hr {
        border: none;
        color: #ccc;
        background: #ccc;
        height: 1px;
      }

      blockquote {
        padding-left: 12px;
        border-left: 5px solid #ccc;
        margin-left: 0;
      }

      blockquote blockquote { margin-left: 0px; }

      p code {
        background: #ddd;
        color: #930;
        border-radius: 3px;
        padding: 0 4px;
      }

      table {
        width: 100%%;
        border: 1px solid #ccc;
        border-radius: 3px;
      }

      th, td { padding: 6px 12px; }
      tbody td {
        border: 1px solid #ddd;
      }

      thead th { text-align: left; background: #e1e1e1; }
      thead th[align=center] { text-align: center; }
      thead th[align=right] { text-align: right; }

    </style>
  </head>
  <body>
    <div class=\"box\">
      <div class=\"md column\">
        <div class=\"wrapper\">
          <h1 class=\"header\">Markdown</h1>
          <div class=\"content\">%s</div>
        </div>
      </div>
      <div class=\"html column\">
        <div class=\"wrapper\">
          <h1 class=\"header\">HTML</h1>
          <div class=\"content\">%s</div>
        </div>
      </div>
    </div>
  </body>
</html>";

int main(int argc, array(string) argv)
{
  Markdown.set_newline(0);
  string base = combine_path(__DIR__, "md");
  string result = combine_path(base, "results");

  if (!Stdio.exist(result))
    mkdir(result);

  foreach (sort(glob("*.md", get_dir(base))), string file) {
    string dots = "." * (25 - sizeof(file));
    write("* Generating %s%s", file, dots);

    string md = Stdio.read_file(combine_path(base, file));
    string data;

    float t = gauge {
      data = Markdown.transform(md);
    };

    data = sprintf(tmpl, file, Markdown.text_quote(md), data);

    Stdio.write_file(combine_path(result, file-".md"+".html"), data);

    write("in %f s\n", t);
  }
	return 0;
}
