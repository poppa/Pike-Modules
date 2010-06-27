/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! XSD Types1999
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| Types1999.pmod is part of XSD.pmod
//|
//| XSD.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| XSD.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with XSD.pmod. If not, see <http://www.gnu.org/licenses/>.

inherit .Types;

constant Standards.XSD.NAMESPACE          = "http://www.w3.org/1999/XMLSchema";
constant Standards.XSD.INSTANCE_NAMESPACE = "http://www.w3.org/1999/XMLSchema"
                                            "-instance";

constant Standards.XSD.NIL_VALUE               = "1";
constant Standards.XSD.ANY_TYPE_LITERAL        = "ur-type";
constant Standards.XSD.ANY_SIMPLE_TYPE_LITERAL = "ur-type";
constant Standards.XSD.NIL_LITERAL             = "null";
constant Standards.XSD.DATE_TIME_LITERAL       = "timeInstant";
