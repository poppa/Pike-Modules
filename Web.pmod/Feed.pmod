/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */

/* This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

/* File licensing and authorship information block.
 *
 * Version: MPL 1.1/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Initial Developer of the Original Code is
 *
 * Pontus Östlund <pontus@poppa.se>
 *
 * Portions created by the Initial Developer are Copyright (C) Pontus Östlund
 * All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of the LGPL, and not to allow others to use your version
 * of this file under the terms of the MPL, indicate your decision by
 * deleting the provisions above and replace them with the notice
 * and other provisions required by the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL or the LGPL.
 *
 * Significant Contributors to this file are:
 *
 */

import Parser.XML.Tree;

#ifdef DEBUG
# define TRACE(X...) werror("%s:%d: %s",basename(__FILE__),__LINE__,sprintf(X))
#else  // DEBUG
# define TRACE(X...) 0
#endif // DEBUG

//! Mapping describing the root node of a feed, i.e. what type of feed
//! we're dealing with
private mapping node_to_class = ([
  "feed"    : ([ "node"            : "atom",
	         "attribute"       : "xmlns",
	         "attribute-value" : "http://www.w3.org/2005/Atom" ]),
  "rss"     : ([ "node"            : "rss",
	         "attribute"       : "version" ]),
  "rdf:rdf" : ([ "node"            : "rdf:rdf" ])
]);

object parse_url(Standards.URI|string uri, void|int recurse_count)
{
  if (zero_type(recurse_count))
    recurse_count = 0;

  if (recurse_count > 5)
    error("Recursion limit reached! ");

  if (stringp(uri))
    uri = Standards.URI(uri);

  Protocols.HTTP.Query q;
  q = Protocols.HTTP.get_url(uri);

  switch (q->status) 
  {
    case 200:
      string data = q->data();

      //werror("%O\n", q->headers);

      sscanf (q->headers["content-type"], "%*scharset=%s", string charset);

      if (charset) {
      	catch {
	  object encoder = Locale.Charset.encoder(lower_case(charset));
	  data = encoder->feed(data)->drain();
	};
      }

      return parse(data);

    case 301..302:
      string loc = q->headers->location;
      if (search(loc, "://") > -1)
      	return parse_url(loc, recurse_count++);

      error("Unhandled redirect! ");
      break;
  }

  error("Bad status (%d) in HTTP response! ", q->status);
}

//! Initially parses the @[data] wich should be the actual feed.
//! An object of the corresponding class will be returned if the feed
//! can be handled.
//!
//! @param data
//!   The XML feed
//!
//! @returns
//!   An object representing the feed. Either a @[Rss], @[Atom] or @[Rdf]
//!   object.
object parse(string|void data, int(0..1)|void normalize_names)
{
  Parser.HTML xp = Parser.get_xml_parser();
  xp->add_quote_tag("![CDATA[",
    lambda (Parser.HTML p, string content) {
      return ({ "<![CDATA[" + xmlify(content) + "]]>" });
    }, "]]"
  );

  catch {
    data = string_to_utf8(xp->finish(data)->read());
    data = data[search(data,"<")..];
  };

//  Stdio.write_file("xxx.xml", data);

  string type;
  Node root = parse_input(data);
  Node _root;

  root && root->walk_preorder(
    lambda(Node n) {
      string tag_name  = lower_case(n->get_full_name());
      if ( mapping rule = node_to_class[tag_name] ) {
	mapping attributes = n->get_attributes();
	_root = n;
	if ( rule->attribute ) {
	  if ( attributes[rule->attribute] ) {
	    if ( rule["attribute-value"] ) {
	      if ( attributes[rule->attribute] == rule["attribute-value"] ) {
		type = rule->node;
		return STOP_WALK;
	      }
	    }
	    else {
	      type = rule->node;
	      return STOP_WALK;
	    }
	  }
	}
	else {
	  type = rule->node;
	  return STOP_WALK;
	}
      }
    }
  );

  if (!type) error("Unknown feed format");

  switch (type)
  {
    case "rss":     return Rss(_root);
    case "atom":    return Atom(_root);
    case "rdf:rdf": return Rdf(_root);
  }
}

//! Works like @tt{<xsl:copy-of select="node()" />@} in XSL.
//! The content of the node will be returned as a string without the node
//! it self.
string copy_of_node(Node n, int(0..1)|void keep_root)
{
  if (keep_root)
    return n->render_xml();

  if (n->get_node_type() != XML_ELEMENT)
    error("Node given to \"copy_of_node()\" must be of type XML_ELEMENT");

  String.Buffer b = String.Buffer();

  foreach (n->get_children(), Node cn)
    b->add(xmlify(cn->render_xml()));

  return b->get();
}

//| {{{ strtotime
//
//! Converts a date string into a Calendar.Second.
//!
//! @param date
//!   A string reprsentation of a date.
//! @param retobj
//!   If 1 the @[Calendar.Second()] object will be returned
//! @returns
//!   Either an ISO formatted date string or the @[Calendar.Second()] object if
//!   @[retobj] is 1. If no conversion can be made @[date] will be returned.
string|Calendar.Second strtotime(string date, int|void retobj)
{
  if (!date || !sizeof(date))
    return 0;

  Calendar.Second cdate;

  string fmt = "%e, %D %M %Y %h:%m:%s %z";

  catch { cdate = Calendar.parse(fmt, date); };

  if (cdate)
    return retobj ? cdate : cdate->format_time();

  fmt = "%Y-%M-%D%*[T ]%h:%m:%s";

  date = replace(date, "Z", "");

  catch { cdate = Calendar.parse(fmt+"%z", date); };

  if (cdate)
    return retobj ? cdate : cdate->format_time();

  catch { cdate = Calendar.parse(fmt, date); };

  if (cdate)
    return retobj ? cdate : cdate->format_time();

  catch { cdate = Calendar.parse("%Y-%M-%D", date); };

  if (cdate)
    return retobj ? cdate : cdate->format_time();

  TRACE("Unknown date format: %s", date);

  return date;
} // }}}


private Parser.HTML xmlify_parser;

string xmlify(string str)
{
  catch (str = utf8_to_string(str));

  if (!xmlify_parser) {
    xmlify_parser = Parser.HTML();
    xmlify_parser->xml_tag_syntax(2);
    xmlify_parser->add_tags(([
      "img": fix_xml_tag,
      "br":  fix_xml_tag,
      "hr":  fix_xml_tag
    ]));
    xmlify_parser->add_containers(([
      "script" : quoted_content,
      "style"  : quoted_content
    ]));
  }

  str = xmlify_parser->feed(unquote_string(str))->finish()->read();
  return encode_entitites(str);
}

private array fix_xml_tag(Parser.HTML p, mapping args, string content)
{
  return ({ make_tag(p->tag_name(), args, content) });
}

private array quoted_content(Parser.HTML p, mapping args, string content)
{
  return ({ make_tag(p->tag_name(), args, content) });
}

string unquote_string(string str)
{
#if constant(roxen)
  return Roxen.html_decode_string(str);
#else
  return replace(str, ({ "&lt;","&gt;","&amp;" }), ({ "<",">","&" }));
#endif
}

string quote_string(string str)
{
#if constant(roxen)
  return Roxen.html_encode_string(str);
#else
  return replace(str, ({ "<",">","&" }), ({ "&lt;","&gt;","&amp;" }));
#endif
}

constant entities =
#if constant(roxen)
  Roxen.iso88591 + Roxen.international + Roxen.symbols + Roxen.greek;
#else
  Parser.html_entities;
#endif

string make_tag(string name, mapping args, string|void content)
{
  string r = "<" + name + " ";
  array(string) a = ({});

  foreach (args||([]); string k; string v)
    a += ({ quote_string(k) + "=\"" + quote_string(v) + "\"" });

  r += a*" ";

  if (content && sizeof(content))
    r += ">" + content + "</" + name + ">";
  else
    r += "/>";

  return r;
}

mapping get_entities()
{
  mapping m = ([]);
  foreach(indices(entities), string entity)
    m += ([ entity - "&" - ";" : "&#" + (int) entities[entity][0] + ";" ]);

  return m;
}

string encode_entitites(string data)
{
  if (!data || !sizeof(data))
    return data;

  String.Buffer sb = String.Buffer();
  function add     = sb->add;
  int pos          = 0;

  while ((pos = search(data, "&")) >= 0) {
    if ((sscanf(data[pos..], "&%[^ <>;&];", string ent)) == 1) {
      ent = "&" + ent + ";";
      add(data[..pos-1], ent);
      data = data[(pos + strlen(ent))..];
      continue;
    }
    add( replace(data[..pos], "&", "&#30;") );
    data = data[(pos+1)..];
  }

  add(data);
  return sb->get();
}

class AbstractThing
{
  constant type = "AbstractThing";

  multiset subnodes  = (<>);
  mapping  rename    = ([]);
  mapping  data      = ([]);
  Node     xml;

  void create(Node node)
  {
    xml = node;
    parse();
  }

  final int(0..1) is_namespace_node(string name)
  {
    return search(name, ":") > -1;
  }

  final mapping parse()
  {
    // If subnodes is empty we parse all element nodes
    int      check = sizeof(subnodes);
    string   name;
    function cb;

    foreach (xml->get_children(), Node cn) {
      if (cn->get_node_type() == XML_ELEMENT) {
	if ((name = cn->get_full_name()) && subnodes[name] || !check) {
	  if ( rename[name] )
	    name = rename[name];

	  ( cb = this_object()["parse_" + name] ) && cb(cn);
	}
      }
    }
  }

  mapping get_data()
  {
    return data;
  }

  mixed get_element(string which)
  {
    return data[which];
  }

  string get_type()
  {
    return type;
  }

  string get_title()
  {
    return data && data->title;
  }

  //! Default parser callback for simple string data.
  //!
  //! @param n
  //!   The element node to handle
  void _parse_string(Node n)
  {
    data[n->get_full_name()] = n->value_of_node();
  }

  //! Default parser callback for content/description nodes
  //!
  //! @param n
  //!   The element node to handle
  void _parse_content(Node n)
  {
    data->content = String.trim_all_whites(copy_of_node(n));
  }

  //! Default parser callback for data that should be put in an array.
  //!
  //! @param n
  //!   The element node to handle
  void _parse_array(Node n)
  {
    string name = n->get_full_name();
    if ( !data[name] ) data[name] = ({});
    data[name] += ({ n->value_of_node() });
  }

  //! Default parser callback for date nodes that should be normalized to
  //! an ISO formatted date.
  //!
  //! @note @[Feed.strtotime()] can be rather slow
  //! depending on the format of the date that's passed to it.
  //!
  //! @param n
  //!   The element node to handle
  void _parse_date(Node n)
  {
    string value = n->value_of_node();
    string|Calendar.Second date = strtotime(value, 1)||value;
    data->date = date;
  }

  string _sprintf(int m)
  {
    if (data && data->title)
      return type + "(" + (data->title||"") +")";

    return type + "(UNDEFINED)";
  }
}

class AbstractChannel
{
  inherit AbstractThing;

  constant type = "AbstractChannel";
  protected array(AbstractItem) items = ({});

  array(AbstractItem) get_items()
  {
    return items;
  }

  void add_item(AbstractItem item)
  {
    items += ({ item });
  }

  string get_last_build()
  {
    string v = data->lastBuildDate||data->updated||data->date;

    if (!v && sizeof(items))
      v = items[0]->get_element("date");

    return v;
  }

  string get_description()
  {
    string d = data["description"]||data["content"];
    return d;
  }
}

class AbstractItem
{
  inherit AbstractThing;

  constant type = "AbstractItem";

  Calendar.Second get_date()
  {
    if (data->date)
      return data->date;

    if (data->pubDate)
      return data->pubDate;
    
    if (data->created)
      return data->created;
  }
  
  string get_content()
  {
    return data["content"]||data["content:encoded"]||data["description"];
  }
}

class AbstractFeed
{
  // The type of feed
  constant type = "Feed";

  //! The main XML node that contains the data of this feed.
  //! This would normally be the top most node in the XML document like
  //! <rss/>, <feed/> or <rdf:rdf/>.
  Node xml;

  //! The channel of the feed
  AbstractChannel channel;

  //! Creates a new instance of this class.
  void create(Node node)
  {
    xml = node;
  }

  //! Returns the @[Channel()] object for this feed
  AbstractChannel get_channel()
  {
    if (channel)
      return channel;

    channel = Channel(xml);
    return channel;
  }

  //! Returns the items of this @[AbstractChannel()] object
  array(AbstractItem) get_items()
  {
    if (!channel)
      get_channel();

    return channel && channel->get_items();
  }

  //! Returns the type of feed
  string get_type()
  {
    return type;
  }

  class Channel
  {
    inherit AbstractChannel;
  }

  class Item
  {
    inherit AbstractItem;
  }
}

class Rss
{
  inherit AbstractFeed;

  constant type = "Rss";

  void create(Node node)
  {
    ::create(node);
  }

  //| {{{ Channel
  //
  //! @class Channel
  //! @seealso Feed.Channel
  //! @seealso AbstractChannel
  class Channel
  {
    inherit AbstractChannel;
    constant type = "Rss.Channel";

    //! Sub nodes to the channel node that should be caught.
    multiset subnodes = (< "title", "link", "description", "lastBuildDate",
			   "image", "cloud", "category", "item" >);

    function parse_title         = _parse_string;
    function parse_link          = _parse_string;
    function parse_description   = _parse_content;
    function parse_category      = _parse_array;
    function parse_lastBuildDate = _parse_date;

    void create(Node node)
    {
      foreach (node->get_children(), Node n) {
	if (n->get_full_name() == "channel") {
	  ::create(n);
	  return;
	}
      }

      error("Missing channel node in XML!");
    }

    void parse_image(Node n)
    {
      mapping m = ([]);
      foreach (n->get_children(), Node cn)
	if (cn->get_node_type() == XML_ELEMENT)
	  m[cn->get_tag_name()] = cn->value_of_node();

      data->image = m;
    }

    void parse_item(Node n)
    {
      items += ({ Item(n) });
    }

    string _sprintf(int m)
    {
      return ::_sprintf(m);
    }
  } // }}}

  //| {{{ Item
  //
  //! @class Item
  //! @seealso Feed.Item
  //! @seealso AbstractItem
  class Item
  {
    inherit AbstractItem;
    constant type = "Rss.Item";

    mapping  rename   = ([ "content:encoded" : "content",
                           "dc:date"         : "pubDate" ]);

    multiset subnodes = (< "title", "category", "link", "pubDate", "dc:date",
			   "author", "description", "content", "comments",
			   "content:encoded", "guid", "enclosure" >);

    function parse_title       = _parse_string;
    function parse_guid        = parse_link;
    function parse_category    = _parse_array;
    function parse_pubDate     = _parse_date;
    function parse_description = parse_content;

    void create(Node node)
    {
      ::create(node);
    }

    void parse_link(Node n)
    {
      data[n->get_tag_name()] = n->value_of_node();
    }

    void parse_enclosure(Node n)
    {
      mapping a = n->get_attributes();
      data->enclosure = ([
	"url"    : a->url,
	"type"   : a->type,
	"length" : a->length
      ]);
    }

    //! Handles both "description", "content" and "content:encoded"
    void parse_content(Node n)
    {
      string c = String.trim_all_whites(copy_of_node(n));
      data[n->get_full_name()] = c;
    }

    string _sprintf(int m)
    {
      return ::_sprintf(m);
    }
  } // }}}
}

class Atom
{
  inherit AbstractFeed;

  constant type = "Atom";

  void create(Node n)
  {
    ::create(n);
  }

  void handle_link(Node n, mapping ldata)
  {
    if (!ldata->link)
      ldata->link = ([]);

    mapping m = n->get_attributes();
    ldata->link[m["rel"]] = m["href"];
  }

  class Channel
  {
    inherit AbstractChannel;
    constant type = "Atom.Channel";

    multiset subnodes = (< "title", "author", "published", "updated", "link",
			   "entry" >);

    function parse_title   = _parse_string;
    function parse_updated = parse_published;

    void create(Node node)
    {
      ::create(node);
    }

    void parse_link(Node n)
    {
      handle_link(n, data);
    }

    void parse_published(Node n)
    {
      string v = n->value_of_node();
      handle_date(n->get_full_name(), n->value_of_node());
    }

    void handle_date(string type, string date)
    {
      if (type == "published")
	type = "date";

      data[type] = strtotime(date, 1) || date;
    }

    void parse_author(Node n)
    {
      mapping m = ([]);
      foreach (n->get_children(), Node cn)
	if (cn->get_node_type() == XML_ELEMENT)
	  m[cn->get_full_name()] = cn->value_of_node();

      data->author = m;
    }

    void parse_entry(Node n)
    {
      items += ({ Item(n) });
    }

    string _sprintf(int m)
    {
      return ::_sprintf(m);
    }
  }

  class Item
  {
    inherit AbstractItem;
    constant type = "Atom.Item";

    multiset subnodes = (< "title", "published", "updated", "category",
			   "link", "content" >);

    function parse_title     = _parse_string;
    function parse_content   = _parse_content;
    function parse_published = handle_date;
    function parse_updated   = handle_date;

    void create(Node node)
    {
      ::create(node);
    }

    void parse_link(Node n)
    {
      handle_link(n, data);
    }

    void handle_date(Node n)
    {
      string name  = n->get_tag_name();
      string value = n->value_of_node();

      if (name == "published")
	name = "date";

      data[name] = strtotime(value, 1)||value;
    }

    void parse_category(Node n)
    {
      if (!data->category)
	data->category = ({});

      data->category += ({ n->get_attributes()["label"] });
    }

    string _sprintf(int m)
    {
      return ::_sprintf(m);
    }
  }
}

class Rdf
{
  inherit Rss;

  constant type = "Rdf";

  void create(Node node)
  {
    ::create(node);
  }

  class Channel
  {
    inherit AbstractChannel;

    constant type = "Rdf.Channel";

    void create(Node node)
    {
      foreach (node->get_children(), Node cn) {
	if (cn->get_tag_name() == "channel") {
	  ::create(cn);
	  break;
	}
      }

      ::create(node);
    }

    //! Sub nodes to the channel node that should be caught.
    multiset subnodes = (< "title", "link", "description", "lastBuildDate",
			   "image", "cloud", "category", "item" >);

    function parse_title         = _parse_string;
    function parse_link          = _parse_string;
    function parse_description   = _parse_content;
    function parse_category      = _parse_array;
    function parse_lastBuildDate = _parse_date;

    void parse_image(Node n)
    {
      mapping m = ([]);
      foreach (n->get_children(), Node cn)
	if (cn->get_node_type() == XML_ELEMENT)
	  m[cn->get_tag_name()] = cn->value_of_node();

      data->image = m;
    }

    void parse_item(Node n)
    {
      items += ({ Item(n) });
    }
  }
}
