import Standards.Constants;
import Standards.XML.Namespace;

protected QName encoding_style = QName(SOAP_ENCODING_URI,
                                       SOAP_ENCODING_PREFIX, "xmlns");

QName get_encoding()
{
  return encoding_style;
}
