
package com.github.lindenb.xml4ngs.entities;


import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;

import javax.xml.stream.XMLOutputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;

import com.github.lindenb.jsonx.io.JsonXmlReader;
import com.github.lindenb.jsonx.io.JsonXmlWriter;



public class Project extends AbstractHasProperties
	{
    protected List<Sample> sample=new ArrayList<Sample>();


    public List<Sample> getEnabledSamples()
    	{
    	List<Sample> L=new ArrayList<>(this.getSample());
    	int i=0;
    	while(i<L.size())
    		{
    		if(L.get(i).isDisabled())
    			{
    			L.remove(i);
    			}
    		else
    			{
    			++i;
    			}
    		}
    	return L;
    	}

    public List<Sample> getSample() {
      
        return this.sample;
    }
    
  
  
  public String getGenerateId()
  	{
  	return "p1";
  	}
  
  public void link()
  	{
  	for(Sample o: getSample())
  		{
  		o.setProject(this);
  		o.link();
  		}
  	}

  public void readPropertyFile(File f) throws XMLStreamException,IOException
  	{
	 JsonXmlReader r=new JsonXmlReader();
	 this.properties=r.parse(f).getAsJsonObject();
  	}
  
  
  public void write(XMLStreamWriter w) throws XMLStreamException
  	{
	 w.writeStartElement("project");
	 if(!properties.isEmpty()) new JsonXmlWriter().write(w, properties);
	 for(Sample S:getSample()) S.write(w);
	 w.writeEndElement();
  	}
  
  public void write(PrintStream out) throws XMLStreamException
  {
	  XMLOutputFactory xof=XMLOutputFactory.newFactory();
	  xof.setProperty(XMLOutputFactory.IS_REPAIRING_NAMESPACES, Boolean.TRUE);
	  XMLStreamWriter sw=xof.createXMLStreamWriter(out, "UTF-8");
		sw.writeStartDocument( "UTF-8","1.0");
		this.write(sw);
		sw.writeEndDocument();
		sw.flush();
		sw.close();
  }
  
  
}
