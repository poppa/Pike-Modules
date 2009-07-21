import Standards.WSDL;
import Standards.XML.Namespace;

//string wsdl_location;
protected QName service;
protected Definitions wsdl;
protected Standards.WSDL.Service wsdl_service;
protected Standards.WSDL.Port service_port;
protected string endpoint;
protected string port_name;

//! Creates a new SOAP service
//!
//! @param _wsdl_location
//! @param _service
//!  The @[Standards.XML.Namespace.QName] should be the @tt{targetNamespace@}
//!  and the service name.
void create(string|Definitions|Standards.URI _wsdl, QName|string _service)
{
  if (objectp(_wsdl)) {
    if (_wsdl->get_target_namespace)
      wsdl = _wsdl;
  }
  if (!wsdl) {
    if (mixed e = catch(wsdl = Standards.WSDL.get_url(_wsdl)))
      error("Error fetching WSDL: %s\n", describe_error(e));
  }

  if (objectp(_service))
    service = _service;
  else {
    QName tns = wsdl->get_target_namespace();
    service = QName(tns && tns->get_namespace_uri(), _service);
  }

  mixed e = catch {
    wsdl_service = wsdl->get_service(service->get_local_name());
    if (!wsdl_service) wsdl_service = wsdl->get_services()[0];
  };

  if (e)
    error("Failed to resolv service: %s\n", describe_error(e));
}

void set_port(QName|string port)
{
  if (objectp(port))
    port_name = port->get_local_name();
  else 
    port_name = port;

  service_port = wsdl_service->get_port(port_name);
  if (!service_port)
    error("Failed to resolv port %O\n", port_name);
}

void call(string operation, array(.Param) params)
{
  Standards.WSDL.Binding b = 
    wsdl->get_binding(service_port->binding->get_local_name());

  if (!b)
    error("Failed to resolv binding for port %O\n", port_name);

  Standards.WSDL.PortType pt = wsdl->get_porttype(b->type->get_local_name());
  if (!pt)
    error("Failed to resolv port type for port %O\n", port_name);

  Standards.WSDL.Operation op = b->operations[operation];
  if (!op)
    error("Failed to resolv operation %O in port %O\n", operation, port_name);

  string input_use = op->input->use;
  string output_use = op->output->use;
  string soap_action = op->soap_action;

  op = pt->operations[operation];
  string input_message_name  = op->input->message && 
                               op->input->message->get_local_name();
  string output_message_name = op->output->message && 
                               op->output->message->get_local_name();

  Standards.WSDL.Message in_message, out_message;

  in_message = wsdl->get_message(input_message_name);
  if (!in_message)
    error("Failed to resolv input message!\n");

  out_message = wsdl->get_message(output_message_name);
  if (!out_message)
    error("Failed to resolv output message");

  array(Standards.WSDL.Part) parts = in_message->parts;
  array(object) input_types = ({});

  if (parts)
    foreach (parts->element->get_local_name(), string ele)
      if (object type = wsdl->get_type(ele))
	input_types += ({ type });

  werror("%O\n", params);
}


