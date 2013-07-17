
package com.github.lindenb.xml4ngs.entities;

import java.util.ArrayList;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;


@SuppressWarnings("serial")
public class PropertyList
extends ArrayList<ProjectProperty>
implements ProjectProperty
	{
	@Override
	public void write(XMLStreamWriter w, String key) throws XMLStreamException {
    	w.writeStartElement("list");
    	if(key!=null) w.writeAttribute("key",key);
    	for(ProjectProperty o:this)
    		{
    		o.write(w,null);
    		}
    	w.writeEndElement();
		}
  
	}
