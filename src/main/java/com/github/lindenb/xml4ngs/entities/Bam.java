package com.github.lindenb.xml4ngs.entities;

import java.io.File;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamWriter;

public class Bam {
private Sample sample;
private File path;
public void setSample(Sample sample)
	{
	this.sample = sample;
	}

public Sample getSample() {
	return sample;
	}

public File getPath() {
	return path;
}

public void setPath(File path) {
	this.path = path;
}


public void write(XMLStreamWriter w) throws XMLStreamException
	{
	 w.writeEmptyElement("bam");
	if(getPath()!=null)	 w.writeAttribute("path",getPath().getPath());
	 }

}
