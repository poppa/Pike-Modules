/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! XSD module
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| License GNU GPL version 3
//|
//| SimpleSOAP.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| SimpleSOAP.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with SimpleSOAP.pmod. If not, see
//| <http://www.gnu.org/licenses/>.

// QName shortcut.
constant QName = Standards.XML.Namespace.QName;

//! Default namespace
constant NAMESPACE = "http://www.w3.org/2001/XMLSchema";

//! Default instance namespace
constant INSTANCE_NAMESPACE = "http://www.w3.org/2001/XMLSchema-instance";

//! Type attribute name
constant ATTR_TYPE = "type";

//! NIL value
constant NIL_VALUE = "true";
							      // Class
//------------------------------------------------------------------------------

//!
constant ANY_TYPE_LITERAL             = "anyType";	      // (None)

//!
constant ANY_SIMPLE_TYPE_LITERAL      = "anySimpleType";      // AnySimpleType

//!
constant NIL_LITERAL                  = "nil";		      // Nil

//!
constant STRING_LITERAL               = "string";	      // String

//!
constant BOOLEAN_LITERAL              = "boolean";	      // Boolean

//!
constant DECIMAL_LITERAL              = "decimal";	      // Decimal

//!
constant FLOAT_LITERAL                = "float";	      // Float

//!
constant DOUBLE_LITERAL               = "double";	      // Double

//!
constant DURATION_LITERAL             = "duration";	      // Duration

//!
constant DATE_TIME_LITERAL            = "dateTime";	      // DateTime

//!
constant DATE_LITERAL                 = "date";		      // Date

//!
constant TIME_LITERAL                 = "time";		      // Time

//!
constant GYEAR_MONTH_LITERAL          = "gYearMonth";	      // GYearMonth

//!
constant GYEAR_LITERAL                = "gYear";	      // GYear

//!
constant GMONTH_DAY_LITERAL           = "gMonthDay";	      // GMonthDay

//!
constant GDAY_LITERAL                 = "gDay";		      // GDay

//!
constant GMONTH_LITERAL               = "gMonth";	      // GMonth

//!
constant HEX_BINARY_LITERAL           = "hexBinary";	      // HexBinary

//!
constant BASE64_BINARY_LITERAL        = "base64Binary";	      // Base64Binary

//!
constant ANY_URI_LITERAL              = "anyURI";	      // AnyURI

//!
constant QNAME_LITERAL                = "QName";	      // QName

/* Derived */

//!
constant NORMALIZED_STRING_LITERAL    = "normalizedString";   // NormalizedString

//!
constant TOKEN_LITERAL                = "token";	      // Token

//!
constant LANGUAGE_LITERAL             = "language";	      // Language

//!
constant NMTOKEN_LITERAL              = "NMTOKEN";	      // NMTOKEN

//!
constant NMTOKENS_LITERAL             = "NMTOKENS";	      // NMTOKENS

//!
constant NAME_LITERAL                 = "Name";		      // Name

//!
constant NCNAME_LITERAL               = "NCName";	      // NCName

//!
constant ID_LITERAL                   = "ID";		      // ID

//!
constant IDREF_LITERAL                = "IDREF";	      // IDREF

//!
constant IDREFS_LITERAL               = "IDREFS";	      // IDREFS

//!
constant ENTITY_LITERAL               = "ENTITY";	      // ENTITY

//!
constant ENTITIES_LITERAL             = "ENTITIES";	      // ENTITIES

//!
constant INTEGER_LITERAL              = "integer";	      // Integer

//!
constant NON_POSITIVE_INTEGER_LITERAL = "nonPositiveInteger"; // NonPositiveInteger

//!
constant NEGATIVE_INTEGER_LITERAL     = "negativeInteger";    // NegativeInteger

//!
constant LONG_LITERAL                 = "long";		      // Long

//!
constant INT_LITERAL                  = "int";		      // Int

//!
constant SHORT_LITERAL                = "short";	      // Short

//!
constant BYTE_LITERAL                 = "byte";		      // Byte

//!
constant NON_NEGATIVE_INTEGER_LITERAL = "nonNegativeInteger"; // NonNegativeInteger

//!
constant UNSIGNED_LONG_LITERAL        = "unsignedLong";	      // UnsignedLong

//!
constant UNSIGNED_INT_LITERAL         = "unsignedInt";	      // UnsignedInt

//!
constant UNSIGNED_SHORT_LITERAL       = "unsignedShort";      // UnsignedShort

//!
constant UNSIGNED_BYTE_LITERAL        = "unsignedByte";	      // UnsignedByte

//!
constant POSITIVE_INTEGER_LITERAL     = "positiveInteger";    // PositiveInteger 

//! QName for type attribute
QName ATTR_TYPE_NAME = QName(INSTANCE_NAMESPACE, ATTR_TYPE);

//! QName for nil attribute
QName ATTR_NIL_NAME = QName(INSTANCE_NAMESPACE, NIL_LITERAL);

//! QName for any typ
QName ANY_TYPE_NAME = QName(NAMESPACE, ANY_TYPE_LITERAL);

//! QName for any simple type
QName ANY_SIMPLE_TYPE_NAME = QName(NAMESPACE, ANY_SIMPLE_TYPE_LITERAL);

