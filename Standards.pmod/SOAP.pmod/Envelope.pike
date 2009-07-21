import Standards.Constants;
import Standards.XML.Namespace;

protected array(QName) default_ns = ({
  QName(SOAP_NAMESPACE_URI, SOAP_NAMESPACE_PREFIX, "xmlns"),
  QName(SOAP_XSD_URI, SOAP_XSD_PREFIX, "xmlns"),
  QName(SOAP_XSI_URI, SOAP_XSI_PREFIX, "xmlns")
});
