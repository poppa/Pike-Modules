// QName
import Standards.XML.Namespace;
import Parser.XML.Tree;
inherit .BaseObject;

QName target_namespace;
string element_form_default;
string attribute_form_default;
array  complex_types = ({});
array  simple_types = ({});
array  elements = ({});
array  imports = ({});

object get_element(string name)
{
  foreach (get_all_elements(), object e) {
    if (e->name && e->name == name)
      return e;
  }

  return 0;
}

array(object) get_all_elements()
{
  return complex_types + simple_types + elements + imports;
}

protected void decode(Node n)
{
  mapping a = n->get_attributes();

  if (a) {
    target_namespace = QName(a->targetNamespace, "targetNamespace");
    element_form_default = a->elementFormDefault;
    attribute_form_default = a->attributeFormDefault;
  }

  foreach (n->get_children(), Node cn) {
    if (cn->get_node_type() == XML_ELEMENT) {
      mapping a = cn->get_attributes();
      string tag = cn->get_tag_name();

      switch (tag)
      {
	case "complexType":
	  complex_types += ({ .Types.ComplexType(cn, owner_document) });
	  break;

	case "element":
	  elements += ({ .Types.Element(cn, owner_document) });
	  break;

	case "simpleType":
	  simple_types += ({ .Types.SimpleType(cn, owner_document) });
	  break;
	  
	default:
	  werror("Unhandled type node: %O\n", cn);
      }
    }
  }
}
