
package com.github.lindenb.xml4ngs.entities;

import java.io.IOException;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;

import javax.xml.stream.XMLOutputFactory;
import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;



public class Project {

    protected PropertyMap properties=new PropertyMap();
    protected List<Sample> sample=new ArrayList<Sample>();

    /**
     * Gets the value of the properties property.
     * 
     * @return
     *     possible object is
     *     {@link PropertyMap }
     *     
     */
    public PropertyMap getProperties() {
        return properties;
    }

    /**
     * Sets the value of the properties property.
     * 
     * @param value
     *     allowed object is
     *     {@link PropertyMap }
     *     
     */
    public void setProperties(PropertyMap value) {
        this.properties = value;
    }


    public List<Sample> getSample() {
      
        return this.sample;
    }
    
  
  public PropertyMap getPropertyMap()
  	{
  	return properties;
  	}
  	
  public String getPropertyByName(String key,String def)
  	{
  	ProjectProperty v=this.properties.get(key);
  	return v==null?def:v.toString();
  	}
  
  public boolean hasProperty(String key)
  	{
	return getProperties().hasProperty(key);
  	}
  
  public String getProperty(String key)
	{
	return getProperties().getProperty(key);
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
	
	private static class ManyToMany
		{
		private java.util.Map<String,java.util.Set<String>> group2chroms=new java.util.HashMap<String, java.util.Set<String>>();
		private java.util.Map<String,String> chrom2group=new java.util.HashMap<String, String>();
		public void set(String group,String chrom)
			{
			if(containsChrom(chrom)) throw new IllegalArgumentException("chrom "+chrom+" already defined for group "+ chrom2group.get(chrom));
			java.util.Set<String> set=group2chroms.get(group);
			if(set==null)
				{
				set=new java.util.LinkedHashSet<String>();
				group2chroms.put(group,set);
				}
			set.add(chrom);
			chrom2group.put(chrom,group);
			}
		public boolean containsGroup(String s)
			{
			return group2chroms.containsKey(s);
			}
		public boolean containsChrom(String s)
			{
			return chrom2group.containsKey(s);
			}
		
		}	
	
	
  @javax.xml.bind.annotation.XmlTransient
  private ManyToMany many2many = null;
  
  @javax.xml.bind.annotation.XmlTransient
  public java.util.List<String> getChromosomeGroups() throws java.io.IOException
   	{
	if(this.many2many==null)
		{
		this.many2many=new ManyToMany();

		
		ProjectProperty groupPty = this.getPropertyMap().get("chromosomes.groups");
		if(groupPty==null)
			{
			System.err.println("[WARNING] chromosomes.groups undefined: will use one chromosome per file");
			}
		else if(!(groupPty instanceof PropertyString))
			{
			throw new IOException("not a string property");
			}
		else
			{
			String groupFile=((PropertyString)groupPty).getValue().trim();
			java.util.Set<String> all_chromosomes=new java.util.HashSet<String>(this.getRefChromosomes() );
			java.io.BufferedReader r=new java.io.BufferedReader(new java.io.FileReader(groupFile));
			String line;
			while((line=r.readLine())!=null)
				{
				if(line.isEmpty() || line.startsWith("#")) continue;
				String tokens[] =line.split("[ \t,]+");
				String groupName=tokens[0].trim();
				if(groupName.isEmpty())
					{
					r.close();
					throw new java.io.IOException("Empty group name in "+line);
					}
				if(many2many.containsGroup(groupName))
					{
					r.close();
					throw new java.io.IOException("Group defined twice "+groupName);
					}
				for(int i=1;i< tokens.length;i++)
					{
					String chromName=tokens[i].trim();
					if(!all_chromosomes.contains(chromName))
						{
						r.close();
						 throw new java.io.IOException("chrom "+chromName+" undefined in ref dict");
						}
					if(chromName.isEmpty()) continue;
					many2many.set(groupName,chromName);
					}
				}
			r.close();
			}		


		for(String chromName: this.getRefChromosomes() )
			{
			if(many2many.containsChrom(chromName)) continue;
			if(many2many.containsGroup(chromName)) 
				{
				throw new java.io.IOException("cannot create chrom group "+chromName+" because it is already defined.");
				}
			many2many.set(chromName,chromName);
			}
		if(this.many2many.group2chroms.isEmpty()) throw new java.io.IOException("empty chrom group");
		}
		
	return new java.util.ArrayList<String>(many2many.group2chroms.keySet());
	}
  
  /* same as getChromosomeGroups but add the "UNmapped"; */
  @javax.xml.bind.annotation.XmlTransient
  public java.util.List<String> getAllChromosomeGroups() throws java.io.IOException
   	{
   	
   	java.util.List<String> L=getChromosomeGroups();
   	if(L.isEmpty()) throw new java.io.IOException("empty getAllChromosomeGroups");
   	L.add(getUnmappedChromosomeName());
   	return L;
   	}
  
  
  /* return a list rather than a set please, because I need to acces the first one in velocity */
  public java.util.List<String> getChromosomesByGroup(String group) throws java.io.IOException
	{
	getChromosomeGroups();//force reading data
	java.util.Set<String> chroms=many2many.group2chroms.get(group);
	if(chroms==null) throw new IllegalStateException("Undefined group "+group);
	return  new java.util.ArrayList<String>(chroms);
	}
	
  private java.util.List<String> _chromosomes=null;
  
  public java.util.List<String> getRefChromosomes() throws java.io.IOException
  	{
  	if(_chromosomes==null)
  		{
	  	ProjectProperty f=this.getPropertyMap().get("genome.reference.path");
	  	if(f==null) throw new java.io.IOException("Undefined property \"genome.reference.path\"");
	  	if(!(f instanceof PropertyString)) throw new IOException("property is not a string");
	  	java.io.File fai=new java.io.File(((PropertyString)f).getValue().trim()+".fai");
	  	if(!fai.exists()) throw new java.io.IOException("file missing:"+fai+". Is it indexed with \"samtools faidx\" ?");
	  	java.io.BufferedReader in=new java.io.BufferedReader(new java.io.FileReader(fai));
	  	String line;
	  	this._chromosomes= new java.util.ArrayList<String>();
	  	while((line=in.readLine())!=null)
	  		{
	  		if(line.isEmpty()) continue;
	  		String tokens[]=line.split("[\t]");
	  		this._chromosomes.add(tokens[0]);
	  		}
	  	in.close();
  		}
  	return _chromosomes;
  	}
  
  public String getUnmappedChromosomeName()
  	{
  	return "Unmapped";
  	}
  
  @javax.xml.bind.annotation.XmlTransient
  public java.util.List<String> getAllChromosomes() throws java.io.IOException
  	{
  	java.util.List<String> L= new java.util.ArrayList<String>(this.getRefChromosomes());
  	L.add(this.getUnmappedChromosomeName());
  	return L;
  	}
  
   @javax.xml.bind.annotation.XmlTransient
  public java.util.Set<String> getGenotypeMethods()
  	{
  	String methods[]=new String[]{"samtools", "gatk","freebayes"};
  	java.util.Set<String> S= new java.util.HashSet<String>(methods.length);
  	for(String m:methods)
  		{
  		if(getPropertyByName("disable."+m+".calling","no").equals("yes"))
  			{
  			continue;
  			}
  		S.add(m);
  		}
  	return S;
  	}
  
  public void write(XMLStreamWriter w) throws XMLStreamException
  	{
	 w.writeStartElement("project");
	 properties.write(w, null);
	 for(Sample S:getSample()) S.write(w);
	 w.writeEndElement();
  	}
  
  public void write(PrintStream out) throws XMLStreamException
  {
	  XMLOutputFactory xof=XMLOutputFactory.newFactory();
	  XMLStreamWriter sw=xof.createXMLStreamWriter(out, "UTF-8");
		sw.writeStartDocument( "UTF-8","1.0");
		this.write(sw);
		sw.writeEndDocument();
		sw.flush();
		sw.close();
  }
}
