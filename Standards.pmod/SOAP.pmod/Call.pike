
string method;
protected Standards.WSDL.Definitions wsdl;

void create()
{
}

mixed invoke(string|Standards.URI wsdl_url, string method, mixed params)
{
  if (mixed e = catch(wsdl = Standards.WSDL.get_url(wsdl_url)))
    error("Error fetching WSDL: %s\n", describe_error(e));
  
  werror("%O\n", wsdl->get_services());
}