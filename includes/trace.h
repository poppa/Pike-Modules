/*| Copyright © 2007 Pontus Östlund <pontus@poppa.se>
 *|
 *| The SimpleSoap module is free software; you can redistribute it and/or
 *| modify it under the terms of the GNU General Public License as published by
 *| the Free Software Foundation; either version 2 of the License, or (at your
 *| option) any later version.
 *|
 *| The SimpleSoap module is distributed in the hope that it will be useful,
 *| but WITHOUT ANY WARRANTY; without even the implied warranty of
 *| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 *| Public License for more details.
 *|
 *| You should have received a copy of the GNU General Public License
 *| along with this program; if not, write to the Free Software Foundation,
 *| Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#ifndef TRACE_H
#define TRACE_H

#define WHERESTR "%s:%d # "
#define WHEREARG basename(__FILE__), __LINE__

#ifdef TRACE_DEBUG
# define TRACE(X...) werror("### %s:%d: %s", WHEREARG, sprintf(X))
#else
# define TRACE(S...)
#endif

#endif /* TRACE_H */