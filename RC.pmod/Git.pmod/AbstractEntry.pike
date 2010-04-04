//#!/usr/bin/env pike
/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! @b{[PROG-NAME]@}
//!
//! Copyright © 2010, Pontus Östlund - @url{http://www.poppa.se@}
//!
//! @pre{@b{License GNU GPL version 3@}
//!
//! [PROG-NAME].pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! [MODULE-NAME].pike is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with [PROG-NAME].pike. If not, see <@url{http://www.gnu.org/licenses/@}>.
//! @}

protected string commit;
protected string author;
protected Calendar.Fraction date;
protected string message;

void set_commit(string _commit)
{
  commit = _commit;
}

void set_author(string _author)
{
  author = _author;
}

void set_date(string|Calendar.Fraction _date)
{
  if (!objectp(_date)) {
    date = Calendar.parse("%e %M %D %h:%m:%s %Y %z", _date)
                          ->set_timezone(Calendar.Timezone.locale);
  }
  else
    date = _date;
}

void set_message(string _message)
{
  message = String.trim_all_whites(_message);
}

string get_commit()
{
  return commit;
}

string get_author()
{
  return author;
}

Calendar.Fraction get_date()
{
  return date;
}

string get_message()
{
  return message;
}

