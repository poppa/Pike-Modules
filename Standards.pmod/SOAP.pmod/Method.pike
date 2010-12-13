import Standards.WSDL;
import Standards.XML.Namespace;

protected string operation;
protected string action;

void create(string operation_name, string soap_action)
{
  operation = operation_name;
  action = soap_action;
}
