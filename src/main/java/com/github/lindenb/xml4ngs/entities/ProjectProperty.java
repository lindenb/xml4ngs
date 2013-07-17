package com.github.lindenb.xml4ngs.entities;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;

public interface ProjectProperty {
	  public void write(XMLStreamWriter w,String key) throws XMLStreamException;
}
