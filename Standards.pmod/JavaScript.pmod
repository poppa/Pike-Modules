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

//! JavaScript stuff
 
//! Minifies JavaScript
//!
//! @throws
//!  An error if the parsing fails
//!
//! @param data
string minify(Stdio.File|string data)
{
  return JSMin(data)->minify();
}

//| Using the jsmin algorithm originally by Douglas Crockford
//|
//| Copyright © 2002 Douglas Crockford  (www.crockford.com)
//| Copyright © 2010 Pontus Östlund (http://www.poppa.se)
//|
//| Permission is hereby granted, free of charge, to any person obtaining a copy
//| of this software and associated documentation files (the "Software"), to
//| deal in the Software without restriction, including without limitation the
//| rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//| sell copies of the Software, and to permit persons to whom the Software is
//| furnished to do so, subject to the following conditions:
//|
//| The above copyright notice and this permission notice shall be included in
//| all copies or substantial portions of the Software.
//|
//| The Software shall be used for Good, not Evil.
//|
//| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//| IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//| FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//| AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//| LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//| FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//| IN THE SOFTWARE.
class JSMin
{
  constant EOF = '\0';

  private int a;
  private int b;
  private int lookahead = EOF;
  private Stdio.FakeFile input;
  private String.Buffer output;

#define add(C) output->add(sprintf("%c", (C)))

  void create(Stdio.File|string data)
  {
    if (stringp(data))
      input = Stdio.FakeFile(data);
    else
      input = data;

    output = String.Buffer();
  }

  string minify()
  {
    jsmin();
    // Remove the first newline added
    return output->get()[1..];
  }

  private int get()
  {
    int c = lookahead;
    lookahead = EOF;

    c == EOF && sscanf(input->read(1), "%c", c);

    if (c >= ' ' || c == '\n' || c == EOF)
      return c;

    return c == '\r' && '\n' || ' ';
  }

#define peek() (lookahead = get())

  private int next()
  {
    int c = get();
    if (c == '/') {
      switch (peek())
      {
      	case '/':
	  while (c = get())
	    if (c <= '\n')
	      return c;
	  break;

	case '*':
	  get();
	  while (1) {
	    switch (get())
	    {
	      case '*':
		if (peek() == '/') {
		  get();
		  return ' ';
		}
		break;

	      case EOF:
		error("Unterminated string literal! ");
	    }
	  }
	  break;

	default:
	  return c;
      }
    }

    return c;
  }

#define action(d)                                                          \
  do {                                                                     \
    switch ((int)d)                                                        \
    {                                                                      \
      case 1:                                                              \
	add(a);                                                            \
      case 2:                                                              \
	a = b;                                                             \
	if (a == '"' || a == '\'') {                                       \
	  while (1) {                                                      \
	    add(a);                                                        \
	    a = get();                                                     \
	    if (a == b)                                                    \
	      break;                                                       \
	    if (a == '\\') {                                               \
	      add(a);                                                      \
	      a = get();                                                   \
	    }                                                              \
	    if (a == EOF)                                                  \
	      error("Unterminated string literal! ");                      \
	  }                                                                \
	}                                                                  \
      case 3:                                                              \
	b = next();                                                        \
	if (b == '/' &&                                                    \
	   (< '(',',','=',':','[','!','&','|','?','{','}',';','\n' >)[a] ) \
	{                                                                  \
	  add(a);                                                          \
	  add(b);                                                          \
	  while (1) {                                                      \
	    a = get();                                                     \
	    if (a == '/')                                                  \
	      break;                                                       \
	    if (a == '\\') {                                               \
	      add(a);                                                      \
	      a = get();                                                   \
	    }                                                              \
	    if (a == EOF)                                                  \
	      error("Unterminated regular expression literal");            \
	    add(a);                                                        \
	  }                                                                \
	  b = next();                                                      \
	}                                                                  \
	break;                                                             \
    }                                                                      \
  } while(0)

#define is_alnum(c) ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || \
                     (c >= 'A' && c <= 'Z') || c == '_' || c == '$' ||   \
                      c == '\\' || c > 126)

  private void jsmin()
  {
    a = '\n';
    action(3);
    while (a != EOF) {
      switch (a)
      {
      	case ' ':
	  if (is_alnum(b))
	    action(1);
	  else 
	    action(2);
	  break;

	case '\n':
	  switch (b)
	  {
	    case '{':
	    case '[':
	    case '(':
	    case '+':
	    case '-':
	      action(1);
	      break;
	    case ' ':
	      action(3);
	      break;

	    default:
	      if (is_alnum(b))
	      	action(1);
	      else
	      	action(2);
	  }
	  break;

	default:
	  switch (b)
	  {
	    case ' ':
	      if (is_alnum(a)) {
	      	action(1);
	      	break;
	      }
	      action(3);
	      break;

	    case '\n':
	      switch (a)
	      {
	      	case '}':
	      	case ']':
	      	case ')':
	      	case '+':
	      	case '-':
	      	case '\'':
	      	case '"':
		  action(1);
		  break;
		default:
		  if (is_alnum(a))
		    action(1);
		  else
		    action(3);
	      }
	      break;

	    default:
	      action(1);
	  }
      }
    }
  }
}
