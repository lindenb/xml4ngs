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
	public boolean isArray() { return false;}
	public boolean isObject() { return true;}
	public boolean isString() { return false;}

	
	public boolean hasProperty(String key)
		{
		while(key.startsWith("/")) key=key.substring(1);
		int i=key.indexOf('/');
		if(i==-1)
			{
			ProjectProperty pp= this.get(key);
			if(pp!=null) return true; //NO  && pp.isString()
			return false;
			}
		else
			{
			ProjectProperty pp= this.get(key.substring(0, i));
			if(pp==null || !pp.isObject()) return false;
			return ((PropertyMap)pp).hasProperty(key.substring(i+1));
			}
		}

	
	public String getProperty(String key)
		{
		while(key.startsWith("/")) key=key.substring(1);
		int i=key.indexOf('/');
		if(i==-1)
			{
			ProjectProperty pp= this.get(key);
			if(pp!=null && pp.isString()) return ((PropertyString)pp).getValue();
			return "";
			}
		else
			{
			ProjectProperty pp= this.get(key.substring(0, i));
			if(pp==null || !pp.isObject()) return "";
			return ((PropertyMap)pp).getProperty(key.substring(i+1));
			}
		}
	
	
	}
