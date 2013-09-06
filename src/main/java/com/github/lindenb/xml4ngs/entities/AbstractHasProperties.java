package com.github.lindenb.xml4ngs.entities;

public abstract class AbstractHasProperties
	{
    protected PropertyMap properties=new PropertyMap();
    
    public abstract AbstractHasProperties getParentProperties();
  

    
    /**
     * Gets the value of the properties property.
     * 
     * @return
     *     possible object is
     *     {@link PropertyMap }
     *     
     */
    public PropertyMap getProperties()
    		{
    		return properties;
    		}

    
    public PropertyMap getPropertyMap()
      	{
      	return properties;
      	}
      	
      public String getPropertyByName(String key,String def)
      	{
      	ProjectProperty v=this.properties.get(key);
      	if(v!=null) return v.toString();
      	if(getParentProperties()!=null) return getParentProperties().getPropertyByName(key, def);
      	return def;
      	}
      
      public boolean hasProperty(String key)
      	{
    	if( this.properties.hasProperty(key)) return true;
    	if(getParentProperties()!=null && getParentProperties().hasProperty(key)) return true;
    	return false;
      	}
      
      public String getProperty(String key)
    	{
    	if( this.properties.hasProperty(key)) 
    		{
    		return this.properties.getProperty(key);
    		}
    	if(getParentProperties()!=null && getParentProperties().hasProperty(key))
    		{
    		return getParentProperties().getProperty(key);
    		}
    	return "";
    	}

	}
