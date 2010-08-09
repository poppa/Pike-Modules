/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! wsdl.h
//!
//! Copyright © 2009, Pontus Östlund - www.poppa.se
//!
//! License GNU GPL version 3
//!
//! wsdl.h is part of WSDL.pmod
//!
//! WSDL.pmod is free software: you can redistribute it and/or modify
//! it under the terms of the GNU General Public License as published by
//! the Free Software Foundation, either version 3 of the License, or
//! (at your option) any later version.
//!
//! WSDL.pmod is distributed in the hope that it will be useful,
//! but WITHOUT ANY WARRANTY; without even the implied warranty of
//! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//! GNU General Public License for more details.
//!
//! You should have received a copy of the GNU General Public License
//! along with WSDL.pmod. If not, see <http://www.gnu.org/licenses/>.

#ifndef WSDL_H
#define WSDL_H

#define WHERESTR "%s:%d # "
#define WHEREARG basename(__FILE__), __LINE__

#ifdef WSDL_DEBUG
# define TRACE(X...) dtrace("### %s:%d: %s", WHEREARG, sprintf(X))
#else
# define TRACE(S...)
#endif

#ifdef WSDL_DEBUG
private Stdio.File dfh;
void dtrace(mixed ... args) 
{
  if (!dfh) {
# ifdef __NT__
    mapping env = getenv();
    string p = combine_path(env->TEMP||env->TMP||"\\Temp", "wsdl.log");
    dfh = Stdio.File(p, "wac");
# else
    dfh = Stdio.File("/tmp/wsdl.log", "wac", 00666);
# endif
  }
  dfh->write(@args); 
}

void set_debug_fh(Stdio.File fh) 
{
  if (dfh) dfh->close();
  dfh = fh;
}
#else   /* WSDL_DEBUG */
void dtrace(mixed ... args) {}
#endif  /* WSDL_DEBUG */

#endif /* WSDL_H */