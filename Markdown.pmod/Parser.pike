//! This class converts Markdown text to HTML.

/*
  Author: Pontus Östlund <https://profiles.google.com/poppanator>

  Permission to copy, modify, and distribute this source for any legal
  purpose granted as long as my name is still attached to it. More
  specifically, the GPL, LGPL and MPL licenses apply to this software.

  This is a port of Parsedown (https://github.com/erusev/parsedown) by
  Emanuil Rusev.

  Original copyright:
  (c) Emanuil Rusev
  http://erusev.com
*/

//#define PARSERDOWN_DEBUG

import Regexp.PCRE;

#define TRIM String.trim_all_whites
#define DIE exit(0)

#ifdef PARSERDOWN_DEBUG
# define TRACE(X...) werror("Parserdown.pike:%d: %s", __LINE__,sprintf(X))
#else
# define TRACE(X...) 0
#endif

enum HtmlVersion {
  HTML,
  HTML5,
  XHTML
}

constant R = Re;

// Shortened regexp options
constant RM   = OPTION.MULTILINE;
constant RX   = OPTION.EXTENDED;
constant RS   = OPTION.DOTALL;
constant RI   = OPTION.CASELESS;
constant RU   = OPTION.UNGREEDY;
constant RMX  = RM|RX;
constant RXS  = RX|RS;
constant RMS  = RM|RS;
constant RMXS = RMX|RS;

#define REGEX(PATTERN, ARGS...) \
  (re_cache[PATTERN + #ARGS] || \
  (re_cache[PATTERN + #ARGS] = R(PATTERN, ARGS)))

//! Convert Markdown text @[t] to HTML
//!
//! @seealso
//!  Markdown.transform
//!
//! @param t
public string text(string t)
{
  if (!t || !sizeof(t))
    return t;

  definitions = ([]);

  t = replace(TRIM(t), ([ "\r\n" : "\n", "\r" : "\n", "\t" : "    " ]));
  t = lines(t/"\n");
  t = TRIM(t);

  re_cache = ([]);
  definitions = ([]);

  return t;
}

//! If set to @tt{1@} all single linebreaks will be replaced with a @tt{<br>@}
//! tag. Default is @tt{0@}.
//!
//! @param enabled
public void set_breaks_enabled(int(0..1) enabled)
{
  breaks_enabled = enabled;
}

//! Determines how empty element tags, e.g. @tt{br, hr, img@}, are closed.
//! The default behaviour is HTML/HTML5 style, i.e @tt{<br>, <hr>@} and so on.
//! If @[Parser.XHTML@] is used empty element tags will be closed in @tt{XML@}
//! style, i.e @tt{<br />, <hr />@} and so on.
//!
//! @param v
public void set_html_version(HtmlVersion v)
{
  html_version = v;
  empty_elem_suffix = v == XHTML ? "/>" : ">";
}

//! If set to @tt{1@} all HTML markup in the MD file will be escaped and not
//! treated as HTML. Default is @tt{0@}
//!
//! @param escaped
public void set_markup_escaped(int(0..1) escaped)
{
  markup_escaped = escaped;
}

//! Set how newlines between generated tags should be handled. The default
//! behaviour is to add newlines between tags but if you wan't the result
//! on one line set this to @tt{0@}.
//!
//! @param nl
public void set_newline(int(0..1) nl)
{
  trim_newline = nl;
  newline = nl ? "\n" : "";
}

//!
//!
protected string lines(array(string) lines)
{
  mapping cur_block;
  array elements = ({ 0 });

  outer: foreach (lines, string line) {
    if (rtrim(line) == "") {
      if (cur_block) {
        cur_block->interupted = 1;
      }

      continue;
    }

    int indent = 0;

    while (has_index(line, indent) && line[indent] == ' ') {
      indent += 1;
    }

    string text = indent > 0 ? line[indent..] : line;

    mapping m_line = ([ "body" : line, "indent" : indent, "text" : text ]);

    if (cur_block && cur_block->incomplete) {
      if (function fun = addto_func[cur_block->type]) {
        mapping block = fun(m_line, cur_block);

        if (block) {
          cur_block = block;
          continue;
        }
        else {
          if (fun = complete_func[cur_block->type]) {
            cur_block = fun(cur_block);
          }

          m_delete(cur_block, "incomplete");
        }
      }
    }

    int marker = text[0];

    if (definition_types[marker]) {
      foreach (definition_types[marker], string definition_type) {
        if (function fun = type_funcs[definition_type]) {
          mapping definition;

          if (definition = fun(m_line, cur_block)) {
            if (!definitions[definition_type]) {
              definitions[definition_type] = ([]);
            }

            definitions[definition_type][definition->id] = definition->data;

            continue outer;
          }
        }
      }
    }

    array(string) b_types = unmarked_block_types;

    if (block_types[marker]) {
      foreach (block_types[marker], string block_type) {
        b_types += ({ block_type });
      }
    }

    foreach (b_types, string block_type) {
      if (function fun = type_funcs[block_type]) {
        if (mapping block = fun(m_line, cur_block)) {
          block->type = block_type;

          if (!block->identified) {
            if (cur_block)
              elements += ({ cur_block->element });

            block->identified = 1;
          }

          if (fun = addto_func[block_type]) {
            block->incomplete = 1;
          }

          cur_block = block;
          continue outer;
        }
      }
    }

    if (cur_block && !cur_block->type && !cur_block->interupted) {
      //! @note There's a newline here in the original implementation
      cur_block->element->text += " " + text;
    }
    else {
      if (cur_block && cur_block->element)
        elements += ({ cur_block->element });

      cur_block = build_paragraph(m_line);
      cur_block->identified = 1;
    }
  }

  function fun;
  if (cur_block && cur_block->incomplete &&
     (fun = complete_func[cur_block->type]))
  {
    cur_block = fun(cur_block);
  }

  elements += ({ cur_block->element });
  elements = elements[1..];

  return build_elements(elements);
}

protected string build_elements(array elems)
{
  string ret = "";

  foreach (elems, mapping elem) {
    if (!elem) continue;
    ret += newline + build_element(elem);
  }

  return ret + newline;
}

protected string build_element(mapping elem)
{
  string ret = "";

  if (elem->name) {
    ret += "<" + elem->name;

    if (elem->attributes) {
      foreach (elem->attributes; string name; string value) {
        if (!value) continue;
        ret += " " + name + "=\"" + value + "\"";
      }
    }

    if (elem->text) {
      ret += ">";
    }
    else {
      ret += empty_elem_suffix;
      return ret;
    }
  }

  if (elem->text) {
    if (elem->handler) {
      if (function fun = handler_func[elem->handler]) {
        ret += fun(elem->text);
      }
      else {
        ret += "[[ .. add handler for " + elem->handler + " .. ]]";
      }
    }
    else {
      ret += elem->text;
    }
  }

  if (elem->name) {
    ret += "</" + elem->name + ">";
  }

  //TRACE("Element: %O\n", elem);

  return ret;
}

protected mapping build_paragraph(mapping line)
{
  return ([
    "element" : ([
      "name" : "p",
      "text" : line->text,
      "handler" : "line"
    ])
  ]);
}

protected mapping identify_codeblock(mapping line, void|mapping cur_block)
{
  if (cur_block && !cur_block->type && !cur_block->interupted) {
    return 0;
  }

  if (line->indent >= 4) {
    string text = line->body[4..];

    return ([
      "element" : ([
        "name" : "pre",
        "handler" : "element",
        "text" : ([
          "name" : "code",
          "text" : text
        ])
      ])
    ]);
  }
}

protected mapping add_to_codeblock(mapping line, void|mapping cblock)
{
  if (line->indent >= 4) {
    if (cblock && cblock->interupted) {
      cblock->element->text->text += "\n";
      m_delete(cblock, "interupted");
    }

    cblock->element->text->text += "\n" + line->body[4..];
    return cblock;
  }
}

protected mapping complete_codeblock(mapping block)
{
  string text = block->element->text->text;
  text = .text_quote(text);
  block->element->text->text = text;
  return block;
}

protected mapping identify_header(mapping line, void|mapping cur_block)
{
  string text = line->text;

  if (text && sizeof(text) > 1) {
    int level = 1;
    while (has_index(text, level) && text[level] == '#')
      level++;

    text = trim(text, "# ");

    return ([
      "element" : ([
        "name" : "h" + min(6, level),
        "text" : text,
        "handler" : "line"
      ])
    ]);
  }
}

protected mapping identify_rule(mapping line, void|mapping cur_block)
{
  R re = REGEX("^([" + line->text[0..0] + "])([ ]{0,2}\\1){2,}[ ]*$");

  if (re->match(line->text)) {
    return ([ "element" : ([ "name" : "hr" ]) ]);
  }
}

protected mapping identify_list(mapping line, void|mapping cblock)
{
  [string name, string pattern] =
    line->text[0] <= '-' ? ({ "ul", "[*+-]" }) : ({ "ol", "[0-9]+[.]" });

  pattern = "^(" + pattern + "[ ]+)(.*)";
  R re = REGEX(pattern);

  mapping block;
  array(string) m;

  if (m = re->match2(line->text)) {
    block = ([
      "indent"  : line->indent,
      "pattern" : pattern,
      "element" : ([
        "name"    : name,
        "handler" : "elements"
      ])
    ]);

    block->li = ([
      "name"    : "li",
      "handler" : "li",
      "text"    : ({ m[2] })
    ]);

    block->element->text = ({ block->li });
  }

  //TRACE("Block: %O\n", block);

  return block;
}

protected mapping add_to_list(mapping line, mapping block)
{
  //mapping block = copy_value(cur_block);
  R re = REGEX(block->pattern);
  array(string) m;

  if (re && (line->indent == block->indent) && (m = re->match2(line->text))) {
    if (block->interupted) {
      block->li->text += ({ "" });
      m_delete(block, "interupted");
    }

    m_delete(block, "li");

    block->li = ([
      "name"    : "li",
      "handler" : "li",
      "text"    : ({ m[2] })
    ]);

    block->element->text += ({ block->li });

    return block;
  }

  if (!block->interupted) {
    re = REGEX("^[ ]{0,4}");
    string text = re->replace(line->body, "");
    block->li->text += ({ text });

    return block;
  }

  if (line->indent > 0) {
    block->li->text += ({ "" });

    re = REGEX("^[ ]{0,4}");

    string text = re->replace(line->body, "");
    block->li->text += ({ text });

    m_delete(block, "interupted");

    return block;
  }
}

protected mapping identify_setext(mapping line, void|mapping cblock)
{
  if (!cblock || cblock->type || cblock->interupted) {
    return 0;
  }

  if (rtrim(line->text, line->text[0..0]) == "") {
    cblock->element->name = line->text[0] == '=' ? "h1" : "h2";
    return cblock;
  }
}

protected mapping identify_table(mapping line, void|mapping cur_block)
{
  if (!cur_block || cur_block->type || cur_block->interupted) {
    return 0;
  }

  if (search(cur_block->element->text, "|") > -1 &&
      rtrim(line->text, " -:|") == "")
  {
    array(string) alignments = ({});
    string divider = trim(TRIM(line->text), "|");

    foreach (divider/"|", string divcell) {
      divcell = TRIM(divcell);

      if (!sizeof(divcell)) {
        continue;
      }

      string alignment;

      if (divcell[0] == ':') {
        alignment = "left";
      }

      if (divcell[sizeof(divcell)-1] == ':') {
        alignment = alignment == "left" ? "center" : "right";
      }

      alignments += ({ alignment });
    }

    array header_elements = ({});
    string header = cur_block->element->text;
    header = trim(TRIM(header), "|");

    foreach (header/"|"; int index; string cell) {
      cell = TRIM(cell);
      mapping header_element = ([
        "name" : "th",
        "text" : cell,
        "handler" : "line"
      ]);

      if (has_index(alignments, index)) {
        header_element->attributes = ([
          "align" : alignments[index]
        ]);
      }

      header_elements += ({ header_element });
    }

    mapping block = ([
      "alignments" : alignments,
      "identified" : 1,
      "element" : ([
        "name" : "table",
        "handler" : "elements"
      ])
    ]);

    block->element->text = ({
      ([ "name" : "thead", "handler" : "elements", "text" : ({}) ]),
      ([ "name" : "tbody", "handler" : "elements", "text" : ({}) ]),
    });

    block->element->text[0]->text += ({
      ([ "name" : "tr", "handler" : "elements", "text" : header_elements ])
    });

    return block;
  }
}

protected mapping add_to_table(mapping line, void|mapping cblock)
{
  if (line->text[0] == '|' || search(line->text, "|") > -1) {
    array elements = ({});

    string row = trim(TRIM(line->text), "|");

    array(string) alignments = cblock->alignments;

    foreach (row/"|"; int index; string cell) {
      cell = TRIM(cell);
      mapping element = ([
        "name" : "td",
        "handler" : "line",
        "text" : cell
      ]);

      if (alignments && has_index(alignments, index)) {
        element->attributes = ([ "align" : alignments[index] ]);
      }

      elements += ({ element });
    }

    mapping element = ([
      "name"    : "tr",
      "handler" : "elements",
      "text"    : elements
    ]);

    cblock->element->text[1]->text += ({ element });

    return cblock;
  }
}

protected mapping identify_comment(mapping line, void|mapping cblock)
{
  if (markup_escaped) {
    return 0;
  }

  string text = line->text;

  if (text && sizeof(text) > 3 && text[0..3] == "<!--") {
    mapping block = ([ "element" : ([ "text" : line->body ]) ]);

    if (REGEX("-->$")->match2(text)) {
      block->closed = 1;
    }

    return block;
  }
}

protected mapping add_to_comment(mapping line, void|mapping cblock)
{
  if (cblock->closed) {
    return 0;
  }

  cblock->element->text += "\n" + line->body;

  if (REGEX("-->$")->match2(line->text)) {
    cblock->closed = 1;
  }

  return cblock;
}

protected mapping identify_markup(mapping line, void|mapping cur_block)
{
  if (markup_escaped) {
    return 0;
  }

  string sre_attr_name = "[a-zA-Z_:][\\w:.-]*";
  string sre_attr_value = "(?:[^\"'=<>`\\s]+|\".*?\"|'.*?')";
  string sre = "^<(\\w[\\d\\w]*)((?:\\s" + sre_attr_name +
               "(?:\\s*=\\s*" + sre_attr_value + ")?)*)\\s*(/?)>";

  array(string) m;
  m = REGEX(sre)->match2(line->text);

  if (!m || sizeof(m) < 2 || text_level_elements[m[1]]) {
    return 0;
  }

  mapping block = ([
    "depth" : 0,
    "element" : ([
      "name" : m[1],
      "text" : 0
    ])
  ]);

  string rem = line->text[sizeof(m[0]) .. ];

  if (!sizeof(TRIM(rem))) {
    if (has_index(m, 3) && sizeof(m[3]) || void_elements[m[1]]) {
      block->closed = 1;
    }
  }
  else {
    if (has_index(m, 3) || void_elements[m[1]]) {
      return 0;
    }

    R re = REGEX("(.*)</" + m[1] + ">\\s*$", RI);
    array(string) nested_m = re->match2(rem);

    if (nested_m) {
      block->closed = 1;
      block->element->text = nested_m[1];
    }
    else {
      block->element->text = rem;
    }
  }

  if (!has_index(m, 2) || !sizeof(m[2])) {
    return block;
  }

  string sre2 = "\\s("+sre_attr_name+")(?:\\s*=\\s*("+sre_attr_value+"))?";

  REGEX(sre2)->matchall(m[2], lambda (array(string) mm) {
    if (!block->element->attributes) {
      block->element->attributes = ([]);
    }

    if (!mm[2]) {
      block->element->attributes[mm[1]] = "";
    }
    else if (mm[2][0] == '"' || mm[2][0] == '\'') {
      block->element->attributes[mm[1]] = mm[2][1..<1];
    }
    else {
      block->element->attributes[mm[1]] = mm[2];
    }
  });

  return block;
}

protected mapping add_to_markup(mapping line, void|mapping cblock)
{
  //TRACE("Add to markup: %O\n", line);

  if (cblock->closed) {
    return 0;
  }

  string sre = "^<" + cblock->element->name + "(?:\\s.*['\"])?\\s*>";
  R re = REGEX(sre, RI);

  if (re->match2(line->text)) {
    cblock->depth += 1;
  }

  array(string) m;
  sre = "(.*?)</" + cblock->element->name + ">\\s*$";

  if (!cblock->element->text)
    cblock->element->text = "";

  if (m = REGEX(sre, RI)->match2(line->text)) {
    if (cblock->depth > 0) {
      cblock->depth -= 1;
    }
    else {
      cblock->element->text += "\n";
      cblock->closed = 1;
    }

    cblock->element->text += m[1];
  }

  if (cblock->interupted) {
    cblock->element->text += "\n";
    m_delete(cblock, "interupted");
  }

  if (!cblock->closed) {
    cblock->element->text += "\n" + line->body;
  }

  return cblock;
}

protected mapping identify_quote(mapping line, void|mapping cur_block)
{
  R re = REGEX("^>[ ]?(.*)");
  array(string) m;

  if (m = re->match2(line->text)) {
    return ([
      "element" : ([
        "name"    : "blockquote",
        "handler" : "lines",
        "text"    : ({ m[1] })
      ])
    ]);
  }
}

protected mapping add_to_quote(mapping line, void|mapping cblock)
{
  R re = REGEX("^>[ ]?(.*)");
  array(string) m;

  if (line->text[0] == '>' && (m = re->match2(line->text))) {
    if (cblock->interupted) {
      cblock->element->text += ({ "" });
      m_delete(cblock, "interupted");
    }

    cblock->element->text += ({ m[1] });

    return cblock;
  }

  if (!cblock->interupted) {
    cblock->element->text += ({ line->text });
    return cblock;
  }
}

protected mapping identify_fenced_code(mapping line, void|mapping cur_block)
{
  string sre = "^([" + line->text[0..0] + "]{3,})[ ]*([\\w-]+)?[ ]*$";

  if (array(string) m = REGEX(sre)->match2(line->text)) {
    mapping elem = ([ "name" : "code", "text" : "" ]);

    if (m[2] && sizeof(m[2])) {
      elem->attributes = ([ "class" : "language-" + m[2] ]);
    }

    return ([
      "char" : line->text[0..0],
      "element" : ([
        "name" : "pre",
        "handler" : "element",
        "text" : elem
      ])
    ]);
  }
}

protected mapping add_to_fenced_code(mapping line, mapping block)
{
  if (block->complete) {
    return 0;
  }

  if (block->interupted) {
    block->element->text->text += "\n";
    m_delete(block, "interupted");
  }

  if (REGEX("^" + block->char + "{3,}[ ]*$")->match(line->text)) {
    block->element->text->text = block->element->text->text[1..];
    block->complete = 1;

    return block;
  }

  block->element->text->text += "\n" + line->body;

  return block;
}

protected mapping complete_fenced_code(mapping block)
{
  block->element->text->text = .text_quote(block->element->text->text);
  return block;
}

protected mapping identify_reference(mapping line, void|mapping block)
{
  string s_re = "^\\[(.+?)\\]:[ ]*<?(\\S+?)>?(?:[ ]+[\"'(](.+)[\"')])?[ ]*$";
  R re = REGEX(s_re);
  array(string) m;

  if ((m = re->match2(line->text))) {
    mapping def = ([
      "id": lower_case(m[1]),
      "data" : ([
        "url" : m[2],
        "title" : 0
      ])
    ]);

    if (m[3]) def->data->title = m[3];

    return def;
  }
}

protected mapping identify_inline_code(mapping excerpt)
{
  string marker = excerpt->text[0..0];
  string rs = sprintf("^(%s+)[ ]*(.+?)[ ]*(?<!%[0]s)\\1(?!%[0]s)", marker);

  R re = REGEX(rs, RS);

  if (array(string) m = re->match2(excerpt->text)) {
    string text = .text_quote(m[2]);
    text = REGEX("[ ]*\\n")->replace(text, " ");

    return ([
      "extent" : sizeof(m[0]),
      "element" : ([
        "nonl" : 1,
        "name" : "code",
        "text" : text
      ])
    ]);
  }
}

protected mapping identify_emphasis(mapping excerpt)
{
  if (!excerpt->text || sizeof(excerpt->text) < 2) {
    return 0;
  }

  int marker = excerpt->text[0];
  string smarker = excerpt->text[0..0];
  array(string) m;
  R sre = strong_regex[smarker], ere = em_regex[smarker];
  string em;

  if (excerpt->text[1] == marker && sre && (m = sre->match2(excerpt->text))) {
    em = "strong";
  }
  else if (ere && (m = ere->match2(excerpt->text))) {
    em = "em";
  }
  else {
    return 0;
  }

  return ([
    "extent" : m && sizeof(m[0]),
    "element" : ([
      "name" : em,
      "handler" : "line",
      "text" : m[1]
    ])
  ]);
}

protected mapping identify_url(mapping excerpt)
{
  string text = excerpt->text;

  if (!text || sizeof(text) < 2 || text[1] != '/') {
    return 0;
  }

  mapping ret;

  R re = REGEX("\\bhttps?:[/]{2}[^\\s<]+\\b/*", RI);
  re->matchall(excerpt->context, lambda (array m) {
    int pos = search(excerpt->context, m[0]);
    string url = replace(m[0], ([ "&" : "&amp;", "<" : "&lt;"]));

    ret = ([
      "extent" : sizeof(m[0]),
      "position" : pos,
      "element" : ([
        "name" : "a",
        "text" : url,
        "attributes" : ([ "href" : url ])
      ])
    ]);
  });

  return ret;
}

protected mapping identify_ampersand(mapping excerpt)
{
  if (!REGEX("^&#?\w+;")->match2(excerpt->text)) {
    return ([
      "markup" : "&amp;",
      "extent" : 1
    ]);
  }
}

protected mapping identify_strikethrough(mapping excerpt)
{
  string text = excerpt->text;

  if (!text || sizeof(text) < 2) {
    return 0;
  }

  R re = REGEX("~~(?=\\S)(.+?)(?<=\\S)~~");
  array(string) m;

  if (text[0] == '~' && (m = re->match2(text))) {
    return ([
      "extent" : sizeof(m[0]),
      "element" : ([
        "name" : "del",
        "text" : m[1],
        "handler" : "line"
      ])
    ]);
  }
}

protected mapping identify_image(mapping excerpt)
{
  string text = excerpt->text;

  if (!text || sizeof(text) < 2 || text[1] != '[') {
    return 0;
  }

  excerpt->text = text[1..];

  mapping span = identify_link(excerpt);

  if (!span) {
    return 0;
  }

  span->extent += 1;

  span->element = ([
    "name" : "img",
    "attributes" : ([
      "src" : span->element->attributes->href,
      "alt" : span->element->text,
      "title" : span->element->title
    ])
  ]);

  return span;
}

protected mapping identify_link(mapping excerpt)
{
  mapping elem = ([
    "name" : "a",
    "handler" : "line",
    "text" : 0,
    "attributes" : ([ "href" : 0, "title" : 0 ])
  ]);

  int extent = 0;
  string rem = excerpt->text;
  array(string) m;

  if ((m = REGEX("^\\[(" + nested_brackets_re + ")\\]", RXS)->match2(rem))) {
    elem->text = m[1];
    extent += sizeof(m[0]);
    rem = rem[extent..];
  }
  else {
    return 0;
  }

  string re = "^\\([ ]*([^ ]+?)(?:[ ]+(\".+?\"|'.+?'))?[ ]*\\)";

  if ((m = REGEX(re)->match2(rem))) {
    elem->attributes->href = m[1];
    if (m[2]) {
      elem->attributes->title = m[2][1..<1];
    }

    extent += sizeof(m[0]);
  }
  else {
    string def;
    if ((m = REGEX("^\\s*\\[(.*?)\\]")->match2(rem))) {
      def = lower_case(m[1] ? m[1] : elem->text);
      extent += sizeof(m[0]);
    }
    else {
      def = lower_case(elem->text);
    }

    if (!definitions->Reference || !definitions->Reference[def]) {
      return 0;
    }

    mapping def2 = definitions->Reference[def];
    elem->attributes->href = def2->url;
    elem->attributes->title = def2->title;
  }

  elem->attributes->href = replace(elem->attributes->href, ([ "&" : "&amp;",
                                                              "<" : "&lt;" ]));
  return ([
    "extent"  : extent,
    "element" : elem
  ]);
}

protected mapping identify_escape_sequence(mapping excerpt)
{
  if (excerpt->text && sizeof(excerpt->text) > 0 &&
      special_chars[excerpt->text[1]])
  {
    return ([
      "markup" : excerpt->text[1..1],
      "extent" : 2
    ]);
  }
}

protected mapping identify_less_than(mapping excerpt)
{
  return ([ "markup" : "&lt;", "extent" : 1 ]);
}

protected mapping identify_greater_than(mapping excerpt)
{
  return ([ "markup" : "&gt;", "extent" : 1 ]);
}

protected mapping identify_quotation_mark(mapping excerpt)
{
  return ([ "markup" : "&quot;", "extent" : 1 ]);
}

protected mapping identify_url_tag(mapping excerpt)
{
  R re = REGEX("<(https?:[/]{2}[^\\s]+?)>", RI);
  array(string) m;

  if (search(excerpt->text, ">") > -1 && (m = re->match2(excerpt->text))) {
    string url = .attr_quote(m[1]);
    return ([
      "extent" : sizeof(m[0]),
      "element" : ([
        "name" : "a",
        "text" : url,
        "attributes" : ([ "href" : url ])
      ])
    ]);
  }
}

protected mapping identify_email_tag(mapping excerpt)
{
  R re = REGEX("<((mailto:)?\\S+?@\\S+?)>", RI);
  array(string) m;

  if (search(excerpt->text, ">") > -1 && (m = re->match2(excerpt->text))) {
    string url = .attr_quote(m[1]);

    if (!m[2]) {
      url = "mailto:" + url;
    }

    [url, string text] = .encode_email(url);

    return ([
      "extent" : sizeof(m[0]),
      "element" : ([
        "name" : "a",
        "text" : text,
        "attributes" : ([ "href" : url ])
      ])
    ]);
  }
}

protected mapping identify_tag(mapping excerpt)
{
  if (markup_escaped) {
    return 0;
  }

  array(string) m;
  R re = REGEX("^</?\\w.*?>", RS);

  if (search(excerpt->text, ">") > -1 && (m = re->match2(excerpt->text))) {
    return ([
      "markup" : m[0],
      "extent" : sizeof(m[0])
    ]);
  }
}

//- Handlers

//!
//!
protected string build_li(array data)
{
  string ret = lines(data);
  string trimmed_ret = TRIM(ret);

  if (!has_value(data, 0) && trimmed_ret[0..2] == "<p>") {
    ret = trimmed_ret[3..];
    int pos = search(ret, "</p>");
    ret = ret[0..pos-1] + ret[pos+4..];
  }

  return ret;
}

protected string span_marker_list = "!\"*_&[<>/`~\\";
//!
//!
protected string build_line(string text)
{
  string markup = "";
  string remainder = text;
  string excerpt;
  int markerpos;

  outer: while (excerpt = strpbrk(remainder, span_marker_list)) {
    int marker = excerpt[0];

    markerpos += search(remainder, sprintf("%c", marker));

    mapping m_excerpt = ([
      "text" : excerpt,
      "context" : text
    ]);

    foreach (span_types[marker], string spantype) {
      if (function fun = type_funcs[spantype]) {
        mapping span = fun(m_excerpt);

        if (!span || (span->position && span->position > markerpos)) {
          continue;
        }

        if (!span->position) {
          span->position = markerpos;
        }

        string plaintext = text[0..span->position-1];

        markup += read_plaintext(plaintext);
        markup += span->markup || build_element(span->element);

        //TRACE(">>>> %s\n", markup);

        text = text[span->position + span->extent ..];
        remainder = text;
        markerpos = 0;

        continue outer;
      }
    }

    remainder = excerpt[1..];
    markerpos += 1;
  }

  markup += read_plaintext(text);
  return markup;
}

string read_plaintext(string text)
{
  if (search(text, "\n") < 0) {
    return text;
  }

  if (breaks_enabled) {
    text = REGEX("[ ]*\\n")->replace(text, "<br" + empty_elem_suffix + "\n");
  }
  else {
    text = REGEX("(?:[ ][ ]+|[ ]*\\\\)\\n")
            ->replace(text, "<br" + empty_elem_suffix + "\n");
    text = replace(text, " \n", "\n");
  }

  return text;
}

protected int html_version = HTML5;
protected int(0..1) trim_newline = 0;
protected int(0..1) breaks_enabled = 0;
protected int(0..1) markup_escaped = 0;
protected string empty_elem_suffix = ">";
protected string newline = "\n";
protected mapping(string:Re) re_cache = ([]);
protected mapping(string:mixed) definitions;

protected mapping(string:function) type_funcs = ([
  "Header"         : identify_header,
  "Rule"           : identify_rule,
  "List"           : identify_list,
  "Setext"         : identify_setext,
  "Table"          : identify_table,
  "Comment"        : identify_comment,
  "Markup"         : identify_markup,
  "Quote"          : identify_quote,
  "FencedCode"     : identify_fenced_code,
  "CodeBlock"      : identify_codeblock,
  "InlineCode"     : identify_inline_code,
  "Emphasis"       : identify_emphasis,
  "Url"            : identify_url,
  "UrlTag"         : identify_url_tag,
  "EmailTag"       : identify_email_tag,
  "Ampersand"      : identify_ampersand,
  "Strikethrough"  : identify_strikethrough,
  "Link"           : identify_link,
  "Reference"      : identify_reference,
  "Image"          : identify_image,
  "EscapeSequence" : identify_escape_sequence,
  "LessThan"       : identify_less_than,
  "GreaterThan"    : identify_greater_than,
  "QuotationMark"  : identify_quotation_mark,
  "Tag"            : identify_tag
]);

protected mapping(string:function) addto_func = ([
  "List"       : add_to_list,
  "CodeBlock"  : add_to_codeblock,
  "Table"      : add_to_table,
  "Quote"      : add_to_quote,
  "Comment"    : add_to_comment,
  "Markup"     : add_to_markup,
  "FencedCode" : add_to_fenced_code
]);

protected mapping(string:function) complete_func = ([
  "CodeBlock"  : complete_codeblock,
  "FencedCode" : complete_fenced_code
]);

protected mapping(string:function) handler_func = ([
  "li"       : build_li,
  "line"     : build_line,
  "lines"    : lines,
  "element"  : build_element,
  "elements" : build_elements
]);

protected mapping(int:array(string)) block_types = ([
  '#' : ({ "Header" }),
  '*' : ({ "Rule", "List" }),
  '+' : ({ "List" }),
  '-' : ({ "Setext", "Table", "Rule", "List" }),
  '0' : ({ "List" }),
  '1' : ({ "List" }),
  '2' : ({ "List" }),
  '3' : ({ "List" }),
  '4' : ({ "List" }),
  '5' : ({ "List" }),
  '6' : ({ "List" }),
  '7' : ({ "List" }),
  '8' : ({ "List" }),
  '9' : ({ "List" }),
  ':' : ({ "Table" }),
  '<' : ({ "Comment", "Markup" }),
  '=' : ({ "Setext" }),
  '>' : ({ "Quote" }),
  '_' : ({ "Rule" }),
  '`' : ({ "FencedCode" }),
  '|' : ({ "Table" }),
  '~' : ({ "FencedCode" }),
]);

protected mapping(int:array(string)) span_types = ([
  '"'  : ({ "QuotationMark" }),
  '!'  : ({ "Image" }),
  '&'  : ({ "Ampersand" }),
  '*'  : ({ "Emphasis" }),
  '/'  : ({ "Url" }),
  '<'  : ({ "UrlTag", "EmailTag", "Tag", "LessThan" }),
  '>'  : ({ "GreaterThan" }),
  '['  : ({ "Link" }),
  '_'  : ({ "Emphasis" }),
  '`'  : ({ "InlineCode" }),
  '~'  : ({ "Strikethrough" }),
  '\\' : ({ "EscapeSequence" })
]);

protected mapping(int:array(string)) definition_types = ([
  '[' : ({ "Reference" })
]);

protected array(string) unmarked_block_types = ({ "CodeBlock" });

protected multiset(int) special_chars = (<
  '\\', '`', '*', '_', '{', '}', '[', ']', '(', ')', '>', '#',
  '+', '-', '.', '!' >);

protected mapping(string:Widestring) strong_regex = ([
  "*" : R("[*]{2}((?:\\\\\\*|[^*]|[*][^*]*[*])+?)[*]{2}(?![*])", RS),
  "_" : R("^__((?:\\\\_|[^_]|_[^_]*_)+?)__(?!_)", RU|RS)
]);

protected mapping(string:Widestring) em_regex = ([
  "*" : R("[*]((?:\\\\\\*|[^*]|[*][*][^*]+?[*][*])+?)[*](?![*])", RS),
  "_" : R("^_((?:\\\\_|[^_]|__[^_]*__)+?)_(?!_)\b", RS|RU)
]);

protected multiset(string) void_elements = (<
  "area", "base", "br", "col", "command", "embed", "hr", "img",
  "input", "link", "meta", "param", "source" >);

protected multiset(string) text_level_elements = (<
  "a", "br", "bdo", "abbr", "blink", "nextid", "acronym", "basefont",
  "b", "em", "big", "cite", "small", "spacer", "listing",
  "i", "rp", "del", "code",          "strike", "marquee",
  "q", "rt", "ins", "font",          "strong",
  "s", "tt", "sub", "mark",
  "u", "xm", "sup", "nobr",
             "var", "ruby",
             "wbr", "span",
                    "time" >);

protected string nested_brackets_re =
        ("(?>[^\\[\\]]+|\\[" * 4) +
        ("\\])*" * 4);

protected string nested_url_parenthesis_re =
        ("(?>[^()\\s]+|\\(" * 4) +
        ("(?>\\)))*" * 4);

protected string ltrim(string in, string|void char)
{
  if (char && sizeof(char)) {
    if (has_value(char, "-"))
      char = (char - "-") + "-";
    if (has_value(char, "]"))
      char = "]" + (char - "]");
    if (char == "^") {
      //  Special case for ^ since that can't be represented in the sscanf
      //  set. We'll expand the set with a wide character that is illegal
      //  Unicode and hence won't be found in regular strings.
      char = "\xFFFFFFFF^";
    }
    sscanf(in, "%*[" + char + "]%s", in);
  } else
    sscanf(in, "%*[ \n\r\t\0]%s", in);
  return in;
}

protected string rtrim(string in, string|void char)
{
  return reverse(ltrim(reverse(in), char));
}

protected string trim(string in, string|void char)
{
  return ltrim(rtrim(in, char), char);
}

protected string strpbrk(string s, string list)
{
  string a, b, c;
  if (sscanf (s, "%s%[" + list + "]%s", a, b, c) == 3) {
    if (sizeof(b))
      return b+c;
  }

  return 0;
}

class Re
{
  inherit Widestring;

  array(string) match2(string subject)
  {
    array(string) success;
    this->matchall(subject, lambda (array(string) m) {
      success = m;
    });

    return success;
  }
}
