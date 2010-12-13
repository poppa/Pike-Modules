import Standards.XML.Namespace;

protected array(QName) default_ns = ({
  QName(.Constants.SOAP_NAMESPACE_URI, .Constants.SOAP_NAMESPACE_PREFIX, "xmlns"),
  QName(.Constants.SOAP_XSD_URI, .Constants.SOAP_XSD_PREFIX, "xmlns"),
  QName(.Constants.SOAP_XSI_URI, .Constants.SOAP_XSI_PREFIX, "xmlns")
});
