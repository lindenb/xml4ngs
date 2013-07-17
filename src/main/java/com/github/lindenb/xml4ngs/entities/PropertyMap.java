package com.github.lindenb.xml4ngs.entities;

import java.util.LinkedHashMap;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;


@SuppressWarnings("serial")
public class PropertyMap
	extends LinkedHashMap<String, ProjectProperty>
	implements ProjectProperty
	{
    public java.util.Map<String,ProjectProperty> getPropertyMap()
	  	{
	  	return this;
	  	}
    
    @Override
    public void write(XMLStreamWriter w,String key) throws XMLStreamException {
    	w.writeStartElement("properties");
    	if(key!=null) w.writeAttribute("key",key);
    	for(String k:this.keySet())
    		{
    		this.get(k).write(w, k);
    		}
    	w.writeEndElement();
    	}
	}
