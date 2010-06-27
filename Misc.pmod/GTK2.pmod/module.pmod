/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Misc GTK2 extensions
//|
//| Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//|
//| License GNU GPL version 3
//|
//| GTK2.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| GTK2.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with GTK2.pmod. If not, see <http://www.gnu.org/licenses/>.

#define G GTK2

//! GTK2.TextView widget that handles simple HTML markup.
class HtmlTextView
{
  inherit G.TextView;
  
  private int(0..1) is_mouseover = 0;
  private int(0..1) cursor_changed = 0;

  void create(void|G.TextBuffer buffer_or_props)
  {
    ::create(buffer_or_props||([]));
    set_editable(0);
    set_buffer(HtmlTextBuffer(get_buffer()->get_tag_table()));
    signal_connect("motion-notify-event", on_motion_notify);
    signal_connect("enter-notify-event",  on_motion_notify);
    signal_connect("leave-notify-event",  on_leave_event);
  }

  void set_html_text(string text, void|function link_callback)
  {
    get_buffer()->set_html_text(text, link_callback);
  }
  
  private int on_leave_event(G.Widget widget, G.GdkEvent event)
  {
    if (cursor_changed) {
      widget->get_window(G.TEXT_WINDOW_TEXT)->set_cursor(G.GDK_XTERM);
      cursor_changed = 0;
    }

    return 0;
  }

  private int on_motion_notify(G.Widget widget, G.GdkEvent event)
  {
    mapping geo = (mapping)event[0];
    int x = (int)geo->x;
    int y = (int)geo->y;

    [x, y] = widget->window_to_buffer_coords(G.TEXT_WINDOW_TEXT, x, y);
    array(HtmlTextTag) tags = widget->get_iter_at_location(x, y)->get_tags();
    if (sizeof(tags)) {
      foreach (tags, HtmlTextTag tag) {
	if (tag->is_anchor) {
	  is_mouseover = 1;
	  break;
	}
      }
    }
    else
      is_mouseover = 0;
    
    if (!cursor_changed && is_mouseover) {
      widget->get_window(G.TEXT_WINDOW_TEXT)->set_cursor(G.GDK_HAND2);
      cursor_changed = 1;
    }
    else if (cursor_changed && !is_mouseover) {
      widget->get_window(G.TEXT_WINDOW_TEXT)->set_cursor(G.GDK_XTERM);
      cursor_changed = 0;
    }
    return 0;
  }
}

class HtmlTextTag
{
  inherit G.TextTag;
  public int(0..1) is_anchor = 0;
}

class HtmlTextBuffer
{
  inherit G.TextBuffer;

#ifdef TRIM
# define OLD_TRIM TRIM
# undef TRIM
#endif

#define TRIM String.trim_all_whites
#define NEW_TAG(TAG) { TAG = HtmlTextTag(([])); buf->get_tag_table()->add(TAG); }
#define SET_PROPERTY(PROP, TAG, VALUE) do                          \
  {                                                                \
    if (mixed e = catch ((TAG)->set_property((PROP), (VALUE))))    \
      werror("Unable to set %s: %s\n", (PROP), describe_error(e)); \
  } while(0)
/* End SET PROPERTY */

  private function link_callback;

  void create(G.TextTagTable table, void|function _link_callback)
  {
    link_callback = _link_callback;
    ::create(table);
  }

  void set_link_callback(function f)
  {
    link_callback = f;
  }

  void set_html_text(string text, void|function _link_callback)
  {
    if (_link_callback) link_callback = _link_callback;
    HtmlTextParser(this, text);
  }

  class HtmlTextParser
  {
    private HtmlTextBuffer   buf;
    private G.TextIter       iter;
    private Parser.HTML      parser;
    private ADT.Stack        styles = ADT.Stack();
    private String.Buffer    text;
    private function         add;

    private mapping(string:float) font_scale = ([
      "xx-small" : G.PANGO_SCALE_XX_SMALL,
      "x-small"  : G.PANGO_SCALE_X_SMALL,
      "small"    : G.PANGO_SCALE_SMALL,
      "medium"   : G.PANGO_SCALE_MEDIUM,
      "large"    : G.PANGO_SCALE_LARGE,
      "x-large"  : G.PANGO_SCALE_X_LARGE,
      "xx-large" : G.PANGO_SCALE_XX_LARGE
    ]);

    private mapping(string:int) font_style = ([
      "normal"  : G.PANGO_STYLE_NORMAL,
      "italic"  : G.PANGO_STYLE_ITALIC,
      "oblique" : G.PANGO_STYLE_OBLIQUE
    ]);

    private mapping(string:int) font_weight = ([
      "100"    : G.PANGO_WEIGHT_ULTRALIGHT,
      "200"    : G.PANGO_WEIGHT_ULTRALIGHT,
      "300"    : G.PANGO_WEIGHT_LIGHT,
      "400"    : G.PANGO_WEIGHT_NORMAL,
      "500"    : G.PANGO_WEIGHT_NORMAL,
      "600"    : G.PANGO_WEIGHT_BOLD,
      "700"    : G.PANGO_WEIGHT_BOLD,
      "800"    : G.PANGO_WEIGHT_ULTRABOLD,
      "900"    : G.PANGO_WEIGHT_HEAVY,
      "normal" : G.PANGO_WEIGHT_NORMAL,
      "bold"   : G.PANGO_WEIGHT_BOLD,
    ]);

    private mapping(string:int) font_align = ([
      "left"    : G.JUSTIFY_LEFT,
      "right"   : G.JUSTIFY_RIGHT,
      "center"  : G.JUSTIFY_CENTER,
      "justify" : G.JUSTIFY_FILL
    ]);

    void create(HtmlTextBuffer _buf, string html_text)
    {
      buf    = _buf;
      iter   = buf->get_end_iter();
      text   = String.Buffer();
      add    = text->add;
      parser = Parser.HTML();
      parser->_set_tag_callback(_tag);
      parser->_set_data_callback(_content);
      parser->finish(html_text);
      flush_text();
    }

    private int anchor_event(float whoot, array(object) gobj, string url)
    {
      if (((mapping)gobj[2] )->type == "button_release" && link_callback) {
	call_function(link_callback, url);
	return 0;
      }

      return 0;
    }

    private void set_font_color(G.TextTag tag, string color)
    {
      SET_PROPERTY("foreground", tag, color);
    }

    private void set_font_weight(G.TextTag tag, int weight)
    {
      SET_PROPERTY( "weight", tag, weight||font_weight["normal"] );
    }

    private void set_font_style(G.TextTag tag, int style)
    {
      SET_PROPERTY( "style", tag, style||font_style["normal"] );
    }

    private void flush_text()
    {
      if (!sizeof(text))
      	return;

      insert_text(text->get());
    }

    private void insert_text(string t)
    {
      array(G.TextTag) tags = values(styles);
      if (sizeof(tags))
      	buf.insert_with_tags(iter, t, sizeof(t), tags);
      else
      	buf.insert(iter, t, sizeof(t));
    }

    private void _tag(Parser.HTML p, string the_tag)
    {
      flush_text();

      mapping args = p->tag_args();
      string tag_name = p->tag_name();
      G.TextTag tag;

      switch (tag_name)
      {
      	case "a":
	  NEW_TAG(tag);
	  tag->is_anchor = 1;
	  SET_PROPERTY("underline", tag, G.PANGO_UNDERLINE_SINGLE);
	  SET_PROPERTY("foreground", tag, "blue");
	  if (args->style)
	    tag = parse_css(args->style, tag);
	  tag->signal_connect("event", anchor_event, args->href);
	  styles->push(tag);
	  break;

      	case "span":
	  if (args->style) {
	    tag = parse_css(args->style);
	    styles->push(tag);
	  }
	  break;

	case "b":
	case "strong":
	  NEW_TAG(tag);
	  set_font_weight(tag, font_weight->bold);
	  styles->push(tag);
	  break;

	case "i":
	case "em":
	  NEW_TAG(tag);
	  set_font_style(tag, font_style->italic);
	  styles->push(tag);
	  break;

	case "/a":
	case "/i":
	case "/b":
	case "/em":
	case "/strong":
	case "/span":
	  if (sizeof(styles)) styles->pop();
	  break;
      }
    }

    private G.TextTag parse_css(string style, void|G.TextTag tag)
    {
      if (!tag) NEW_TAG(tag);

      foreach (style/";", string part)
      {
	if (!sizeof(TRIM(part)) || search(part, ":") == -1) continue;
	[string a, string b] = map(part/":", TRIM);
	switch (lower_case(a))
	{
	  case "color":
	    set_font_color(tag, b);
	    break;

	  case "font-weight":
	    set_font_weight( tag, font_weight[b] );
	    break;

	  case "font-style":
	    set_font_style( tag, font_style[b] );
	    break;
	}
      }
      
      return tag;
    }

    private void _content(Parser.HTML p, string content)
    {
      add(content);
    }
  }

#undef  TRIM
#define TRIM OLD_TRIM
#undef  OLD_TRIM
#undef  SET_PROPERTY
}
