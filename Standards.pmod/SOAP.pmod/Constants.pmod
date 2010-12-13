/* -*- Mode: Pike; indent-tabs-mode: t; c-basic-offset: 2; tab-width: 8 -*- */
//! Constants
//|
//| Copyright © 2009, Pontus Östlund - www.poppa.se
//|
//| Various constants
//|
//| License GNU GPL version 3
//|
//| Consants.pmod is free software: you can redistribute it and/or modify
//| it under the terms of the GNU General Public License as published by
//| the Free Software Foundation, either version 3 of the License, or
//| (at your option) any later version.
//|
//| Consants.pmod is distributed in the hope that it will be useful,
//| but WITHOUT ANY WARRANTY; without even the implied warranty of
//| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//| GNU General Public License for more details.
//|
//| You should have received a copy of the GNU General Public License
//| along with Consants.pmod. If not, see <http://www.gnu.org/licenses/>


constant SOAP_NAMESPACE_URI = "http://schemas.xmlsoap.org/soap/envelope/";
constant SOAP_NAMESPACE_PREFIX = "soapenv";

constant SOAP_ENCODING_URI = "http://schemas.xmlsoap.org/soap/encoding/";
constant SOAP_ENCODING_PREFIX = "soapenc";

constant SOAP_HTTP_NAMESPACE_URI = "http://schemas.xmlsoap.org/soap/http/";
constant SOAP_HTTP_NAMESPACE_PREFIX = "http";

constant WSDL_NAMESPACE_URI = "http://schemas.xmlsoap.org/wsdl/";
constant WSDL_NAMESPACE_PREFIX = "wsdl";

constant WSDLSOAP_NAMESPACE_URI = "http://schemas.xmlsoap.org/wsdl/soap/";
constant WSDLSOAP_NAMESPACE_PREFIX = "soap";

constant WSDLSOAP12_NAMESPACE_URI = "http://schemas.xmlsoap.org/wsdl/soap12/";
constant WSDLSOAP12_NAMESPACE_PREFIX = "soap12";

constant WSDLHTTP_NAMESPACE_URI = "http://schemas.xmlsoap.org/wsdl/http/";
constant WSDLHTTP_NAMESPACE_PREFIX = "http";

constant WSDLMIME_NAMESPACE_URI = "http://schemas.xmlsoap.org/wsdl/mime/";
constant WSDLMIME_NAMESPACE_PREFIX = "mime";

constant SOAP_XSD_URI = "http://www.w3.org/2001/XMLSchema";
constant SOAP_XSD_PREFIX = "xsd";

constant SOAP_XSI_URI = "http://www.w3.org/2001/XMLSchema-instance";
constant SOAP_XSI_PREFIX = "xsi";

constant URI_TO_NS = ([
  SOAP_NAMESPACE_URI       : SOAP_NAMESPACE_PREFIX,
  SOAP_ENCODING_URI        : SOAP_ENCODING_PREFIX,
  WSDL_NAMESPACE_URI       : WSDL_NAMESPACE_PREFIX,
  WSDLSOAP_NAMESPACE_URI   : WSDLSOAP_NAMESPACE_PREFIX,
  WSDLSOAP12_NAMESPACE_URI : WSDLSOAP12_NAMESPACE_PREFIX,
  WSDLHTTP_NAMESPACE_URI   : WSDLHTTP_NAMESPACE_PREFIX,
  WSDLMIME_NAMESPACE_URI   : WSDLMIME_NAMESPACE_PREFIX,
  SOAP_XSD_URI             : SOAP_XSD_PREFIX,
  SOAP_XSI_URI             : SOAP_XSI_PREFIX,
  SOAP_HTTP_NAMESPACE_URI  : SOAP_HTTP_NAMESPACE_PREFIX
]);

constant NS_TO_URI = ([
  SOAP_NAMESPACE_PREFIX       : SOAP_NAMESPACE_URI,
  SOAP_ENCODING_PREFIX        : SOAP_ENCODING_URI,
  WSDL_NAMESPACE_PREFIX       : WSDL_NAMESPACE_URI,
  WSDLSOAP_NAMESPACE_PREFIX   : WSDLSOAP_NAMESPACE_URI,
  WSDLSOAP12_NAMESPACE_PREFIX : WSDLSOAP12_NAMESPACE_URI,
  WSDLHTTP_NAMESPACE_PREFIX   : WSDLHTTP_NAMESPACE_URI,
  WSDLMIME_NAMESPACE_PREFIX   : WSDLMIME_NAMESPACE_URI,
  SOAP_XSD_PREFIX             : SOAP_XSD_URI,
  SOAP_XSI_PREFIX             : SOAP_XSI_URI
]);
