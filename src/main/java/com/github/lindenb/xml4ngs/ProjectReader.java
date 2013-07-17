package com.github.lindenb.xml4ngs;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;

import javax.xml.namespace.QName;
import javax.xml.stream.XMLEventReader;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLOutputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;
import javax.xml.stream.events.Attribute;
import javax.xml.stream.events.StartElement;
import javax.xml.stream.events.XMLEvent;


import com.github.lindenb.xml4ngs.entities.Fastq;
import com.github.lindenb.xml4ngs.entities.Pair;
import com.github.lindenb.xml4ngs.entities.Project;
import com.github.lindenb.xml4ngs.entities.ProjectProperty;
import com.github.lindenb.xml4ngs.entities.PropertyList;
import com.github.lindenb.xml4ngs.entities.PropertyMap;
import com.github.lindenb.xml4ngs.entities.PropertyString;
import com.github.lindenb.xml4ngs.entities.Sample;
import com.github.lindenb.xml4ngs.entities.Sequences;

public class ProjectReader
	{
	private XMLEventReader r;
	
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
				fatal(evt);
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
				else if(E.getName().getLocalPart().equals("properties"))
					{	
					PropertyMap pm=readPropertyMap(E);
					o.getProperties().putAll(pm);
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
	
	private PropertyList readPropertyList(StartElement root) throws XMLStreamException
		{
		PropertyList o=new PropertyList();
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				o.add(anyProperty(E));
				}
			else if(evt.isEndElement())
				{
				if(evt.asEndElement().getName().equals(root.getName())) return o;
				fatal(evt);
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	private ProjectProperty anyProperty(StartElement E) throws XMLStreamException
		{
		if(E.getName().getLocalPart().equals("list"))
			{
			return readPropertyList(E);
			}
		else if(E.getName().getLocalPart().equals("properties"))
			{	
			return readPropertyMap(E);
			}
		else if(E.getName().getLocalPart().equals("property"))
			{	
			return readPropertyString(E);
			}
		else
			{
			throw new XMLStreamException("bad property",E.getLocation());
			}
		}
	
	private PropertyString readPropertyString(StartElement root) throws XMLStreamException
		{
		StringBuilder b=null;
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				fatal(evt);
				}
			else if(evt.isEndElement())
				{
				if(!evt.asEndElement().getName().equals(root.getName())) fatal(evt);	
				if(b==null) throw new XMLStreamException("empty element",evt.getLocation());
				return new PropertyString(b.toString());
				}
			else if(evt.isCharacters())
				{
				if(b==null) b=new StringBuilder();
				b.append(evt.asCharacters().getData());
				}
			}
		throw new XMLStreamException("illegal state");
		}
	
	
	private PropertyMap readPropertyMap(StartElement root) throws XMLStreamException
		{
		PropertyMap o=new PropertyMap();
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				ProjectProperty pp=anyProperty(E);
				Attribute att=E.getAttributeByName(new QName("key"));
				if(att==null) throw new XMLStreamException("key missing",evt.getLocation());
				if(o.containsKey(att.getValue()))
					{
					throw new XMLStreamException("duplicate key "+att.getValue(),root.getLocation());
					}
				o.put(att.getValue(), pp);
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
					o.getSample().add(sample);
					sample.setProject(o);
					}
				else if(E.getName().getLocalPart().equals("properties"))
					{	
					PropertyMap pm=readPropertyMap(E);
					o.getProperties().putAll(pm);
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
	
	private PropertyMap readPropertyMap() throws XMLStreamException
		{
		while(r.hasNext())
			{
			XMLEvent evt=r.nextEvent();
			if(evt.isStartElement())
				{
				StartElement E=evt.asStartElement();
				if(E.getName().getLocalPart().equals("properties"))
					{	
					return readPropertyMap(E);
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
	
	public static PropertyMap readProperties(File f) throws XMLStreamException,IOException
		{
		ProjectReader pr=new ProjectReader();
		FileReader fr=new FileReader(f);
		XMLInputFactory xif=XMLInputFactory.newFactory();
		pr.r=xif.createXMLEventReader(fr);
		PropertyMap p=pr.readPropertyMap();
		pr.r.close();
		fr.close();
		return p;
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
	
	
	public static void main(String[] args) throws Exception
		{
		Project p=readProject(new File("/commun/data/projects/20130710.EXOMESJJS/script/project.xml"));
		
		XMLOutputFactory xof=XMLOutputFactory.newFactory();
		XMLStreamWriter sw=xof.createXMLStreamWriter(System.out, "UTF-8");
		sw.writeStartDocument( "UTF-8","1.0");
		p.write(sw);
		sw.writeEndDocument();
		sw.flush();
		sw.close();
		}
	}
