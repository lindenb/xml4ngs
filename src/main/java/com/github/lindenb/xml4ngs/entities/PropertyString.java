//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2013.06.14 at 03:51:18 PM CEST 
//


package com.github.lindenb.xml4ngs.entities;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;



public class PropertyString
	implements ProjectProperty
	{
	private String value;
	public PropertyString(String value)
		{
		this.value=value;
		}
    /**
     * Gets the value of the value property.
     * 
     * @return
     *     possible object is
     *     {@link String }
     *     
     */
    public String getValue() {
        return value;
    }

  
  @Override
  public String toString()
  	{
  	return value;
  	}
  
  @Override
public void write(XMLStreamWriter w, String key) throws XMLStreamException {
	w.writeStartElement("property");
	if(key!=null) w.writeAttribute("key", key);
	w.writeCharacters(value);
	w.writeEndElement();
  	}
  
  
}
