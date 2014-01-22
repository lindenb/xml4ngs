package com.github.lindenb.xml4ngs.entities;

import com.github.lindenb.jsonx.JsonFactory;
import com.github.lindenb.jsonx.JsonObject;

public abstract class AbstractHasProperties
	{
	protected static final JsonFactory JSON_FACTORY=new JsonFactory();
    protected JsonObject properties=JSON_FACTORY.newObject();
    
    
    /**
     * Gets the value of the properties property.
     * 
     * @return
     *     possible object is
     *     {@link PropertyMap }
     *     
     */
    public JsonObject getProperties()
    		{
    		return properties;
    		}

    public void setProperties(JsonObject properties)
    	{
		this.properties = properties;
		}
    

	}
