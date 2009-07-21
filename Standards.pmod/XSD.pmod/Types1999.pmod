/*| Copyright © 2007 Pontus Östlund <pontus@poppa.se>
 *|
 *| The NSD module is free software; you can redistribute it and/or
 *| modify it under the terms of the GNU General Public License as published by
 *| the Free Software Foundation; either version 2 of the License, or (at your
 *| option) any later version.
 *|
 *| The NSD module is distributed in the hope that it will be useful,
 *| but WITHOUT ANY WARRANTY; without even the implied warranty of
 *| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 *| Public License for more details.
 *|
 *| You should have received a copy of the GNU General Public License
 *| along with this program; if not, write to the Free Software Foundation,
 *| Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

inherit .Types;

constant Standards.XSD.NAMESPACE          = "http://www.w3.org/1999/XMLSchema";
constant Standards.XSD.INSTANCE_NAMESPACE = "http://www.w3.org/1999/XMLSchema-instance";

constant Standards.XSD.NIL_VALUE               = "1";
constant Standards.XSD.ANY_TYPE_LITERAL        = "ur-type";
constant Standards.XSD.ANY_SIMPLE_TYPE_LITERAL = "ur-type";
constant Standards.XSD.NIL_LITERAL             = "null";
constant Standards.XSD.DATE_TIME_LITERAL       = "timeInstant";