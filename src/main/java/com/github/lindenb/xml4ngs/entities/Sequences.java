//
// This file was generated by the JavaTM Architecture for XML Binding(JAXB) Reference Implementation, v2.2.4-2 
// See <a href="http://java.sun.com/xml/jaxb">http://java.sun.com/xml/jaxb</a> 
// Any modifications to this file will be lost upon recompilation of the source schema. 
// Generated on: 2013.06.14 at 03:51:18 PM CEST 
//


package com.github.lindenb.xml4ngs.entities;

import java.util.ArrayList;
import java.util.List;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;



public class Sequences {

    protected List<Pair> pair=new ArrayList<Pair>();

    public List<Pair> getPair()
    	{
        return this.pair;
    	}

    public void write(XMLStreamWriter w) throws XMLStreamException
  	{
  	 w.writeStartElement("sequences");
  	 for(Pair p:getPair()) p.write(w);
  	 w.writeEndElement();
  	}

    
}