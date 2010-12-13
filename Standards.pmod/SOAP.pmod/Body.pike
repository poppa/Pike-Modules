import Standards.XML.Namespace;

protected QName encoding_style = QName(.Constants.SOAP_ENCODING_URI,
                                       .Constants.SOAP_ENCODING_PREFIX, 
                                       "xmlns");

QName get_encoding()
{
  return encoding_style;
}
