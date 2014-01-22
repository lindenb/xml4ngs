package com.github.lindenb.xml4ngs;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;

import javax.xml.namespace.QName;
import javax.xml.stream.XMLEventReader;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.Attribute;
import javax.xml.stream.events.StartElement;
import javax.xml.stream.events.XMLEvent;


import com.github.lindenb.jsonx.JsonConstants;
import com.github.lindenb.jsonx.io.JsonXmlReader;
import com.github.lindenb.xml4ngs.entities.Fastq;
import com.github.lindenb.xml4ngs.entities.Pair;
import com.github.lindenb.xml4ngs.entities.Project;
import com.github.lindenb.xml4ngs.entities.Sample;
import com.github.lindenb.xml4ngs.entities.Sequences;

public class ProjectReader
	{
	private XMLEventReader r;
	private JsonXmlReader jsonXmlReader=new JsonXmlReader();
	
	private ProjectReader()
		{
		}
	
	private void fatal(XMLEvent evt) throws XMLStreamException
		{
		throw new XMLStreamException("illegal state",evt.getLocation());
		}
	private String requiredAtt(StartElement E,String attName)throws XMLStreamException
		{
		Attribute att=E.getAttributeByName(new QName(attName));
		if(att==null) throw new XMLStreamException("attribute @"+attName+" missing int element "+E.getName(),E.getLocation());
		return att.getValue();
		}
	
	private void skip() throws XMLStreamException
		{
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				skip();
				}
			else if(evt.isEndElement())
				{
				return;
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	private Fastq readFastq(StartElement root)
		throws XMLStreamException
		{
		Fastq o=new Fastq();
		o.setIndex(Integer.parseInt(requiredAtt(root,"index")));
		o.setPath(new File(requiredAtt(root,"path")));
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(JsonConstants.XMLNS.equals(E.getName().getNamespaceURI()))
					{	
					o.setProperties(this.jsonXmlReader.any(r,E).getAsJsonObject());
					}
				else
					{
					fatal(evt);
					}
				}
			else if(evt.isEndElement())
				{
				if(evt.asEndElement().getName().equals(root.getName())) return o;
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	private Pair readPair(StartElement root)
			throws XMLStreamException
		{
		Pair o=new Pair();
		Attribute att=root.getAttributeByName(new QName("lane"));
		if(att!=null) o.setLane(Integer.parseInt(att.getValue()));
		att=root.getAttributeByName(new QName("sample-index"));
		if(att!=null) o.setSampleIndex(att.getValue());
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(E.getName().getLocalPart().equals("fastq"))
					{	
					Fastq fq=readFastq(E);
					fq.setPair(o);
					o.put(fq);
					}
				else if(JsonConstants.XMLNS.equals(E.getName().getNamespaceURI()))
					{	
					o.setProperties(this.jsonXmlReader.any(r,E).getAsJsonObject());
					}
				else
					{
					fatal(evt);
					}
				}
			else if(evt.isEndElement())
				{
				if(evt.asEndElement().getName().equals(root.getName())) return o;
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	 
	private Sequences readSequences(StartElement root) throws XMLStreamException
		{
		Sequences o=new Sequences();

		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(E.getName().getLocalPart().equals("pair"))
					{
					Pair pair=readPair(E);
					//if(pair.isEnabled()) NO!!!: keep for group-id
					o.getPair().add(pair);
					}
				else
					{
					fatal(evt);
					}
				}
			else if(evt.isEndElement())
				{
				if(evt.asEndElement().getName().equals(root.getName())) return o;
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	private Sample readSample(StartElement root) throws XMLStreamException
		{
		Sample o=new Sample();
		o.setName(requiredAtt(root, "name").trim());
		Attribute att=root.getAttributeByName(new QName("enabled"));
		if(att!=null && (att.getValue().equals("false") || att.getValue().equals("no")))
			{
			o.setEnabled(false);
			}
		
		
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(E.getName().getLocalPart().equals("sequences"))
					{	
					Sequences sequences=readSequences(E);
					o.setSequences(sequences);
					for(Pair p:sequences.getPair())
						{
						p.setSample(o);
						}
					}
				else if(JsonConstants.XMLNS.equals(E.getName().getNamespaceURI()))
					{	
					o.setProperties(this.jsonXmlReader.any(r,E).getAsJsonObject());

					}
				else
					{
					fatal(evt);
					}
				}
			else if(evt.isEndElement())
				{
				if(evt.asEndElement().getName().equals(root.getName())) return o;
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	
	
	
	
	private Project readProject(StartElement root) throws XMLStreamException
		{
		Project o=new Project();
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(E.getName().getLocalPart().equals("sample"))
					{	
					Sample sample=readSample(E);
					//if(sample.isEnabled()) NO: keep for Group-ID
					o.getSample().add(sample);
					sample.setProject(o);
					}
				else if(JsonConstants.XMLNS.equals(E.getName().getNamespaceURI()))
					{	
					o.setProperties(this.jsonXmlReader.any(r,E).getAsJsonObject());
					}
				else
					{
					skip();
					}
				}
			else if(evt.isEndElement())
				{
				if(evt.asEndElement().getName().equals(root.getName())) return o;
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	private Project readProject() throws XMLStreamException
		{
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(E.getName().getLocalPart().equals("project"))
					{	
					return readProject(E);
					}
				else
					{
					fatal(E);
					}
				}
			else if(evt.isEndElement())
				{
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	
	
	public static Project readProject(File f) throws XMLStreamException,IOException
		{
		ProjectReader pr=new ProjectReader();
		FileReader fr=new FileReader(f);
		XMLInputFactory xif=XMLInputFactory.newFactory();
		
		pr.r=xif.createXMLEventReader(fr);
		Project p=pr.readProject();
		pr.r.close();
		fr.close();
		return p;
		}
	
	
	}
