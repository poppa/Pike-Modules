/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! JavaScript stuff
//|
//| Copyright © 2010 Pontus Östlund (http://www.poppa.se)
//|
//| License GNU GPL version 3
//|
//| JavaScript.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| JavaScript.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with JavaScript.pmod. If not, see
//| <http://www.gnu.org/licenses/>.

//! Minifies JavaScript
//!
//! @throws
//!  An error if the parsing fails
//!
//! @param data
string minify(string data)
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
  private function _add;

#define add(C) _add(sprintf("%c", (C)))

  void create(string data)
  {
    data = replace(data, "\r\n", "\n");
    input = Stdio.FakeFile(data);
    output = String.Buffer();
    _add = output->add;
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

    if (c == EOF)
      sscanf(input->read(1), "%c", c);

    if (c >= ' ' || c == '\n' || c == EOF)
      return c;

    if (c == '\r') return '\n';

    return ' ';
  }

  private int peek()
  {
    return lookahead = get();
  }

  private int next()
  {
    int c = get();
    if (c == '/') {
      switch (peek())
      {
      	case '/':
	  for (;;) {
	    c = get();
	    if (c <= '\n')
	      return c;
	  }
	  break;

	case '*':
	  get();
	  for (;;) {
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

  void action(int d)
  {
    switch (d)
    {
      case 1: add(a);
      case 2:
	a = b;
	if (a == '"' || a == '\'') {
	  for (;;) {
	    add(a);
	    a = get();
	    if (a == b)
	      break;

	    if (a == '\\') {
	      add(a);
	      a = get();
	    }

	    if (a == EOF)
	      error("Unterminated string literal! ");
	  }
	}

      case 3:
	b = next();
	if (b == '/' &&
	   (< '(',',','=',':','[','!','&','|','?','{','}',';','\n' >)[a] )
	{
	  add(a);
	  add(b);
	  for (;;) {
	    a = get();
	    if (a == '/')
	      break;

	    if (a == '\\') {
	      add(a);
	      a = get();
	    }
	    if (a == EOF)
	      error("Unterminated regular expression literal");

	    add(a);
	  }

	  b = next();
	}
	break;
    }
  }

  private int(0..1) is_alnum(int c)
  {
    return ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') ||
            (c >= 'A' && c <= 'Z') || c == '_' || c == '$' || c == '\\' ||
             c > 126);
  }

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

		  break;
	      }
	      break;

	    default:
	      action(1);
	      break;
	  }
	  break;
      }
    }
  }
}

