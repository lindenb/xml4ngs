package com.github.lindenb.xml4ngs;

import com.github.lindenb.xml4ngs.ObjectFactory;
import java.io.*;
import java.util.regex.Pattern;
import javax.xml.bind.*;
import javax.xml.namespace.QName;
import java.util.*;

public class Ilmn2Project
	{
	private static final String SUFFIX=".fastq.gz";
	private ProjectType project= new ProjectType();
	private Pattern uscore=Pattern.compile("_");
	private Set<String> seqIndexes=new TreeSet<String>();
	private Set<Integer> lanes=new TreeSet<Integer>();
	private PropertiesType properties=null;
	private Ilmn2Project()
		{
		
		}

	private void scan(File dir) throws IOException
		{
		if(dir==null) return;
		File sub[]=dir.listFiles();
		if(sub==null)
			{
			System.err.println("Cannot get files under "+dir);
			return;
			}
		for(File f:sub)
			{
			if(f==null)
				{
				System.err.println("WTF "+dir);
				continue;
				}
			if(f.isDirectory())
				{
				scan(f);
				}
			else if(f.getName().endsWith(SUFFIX))
				{
				//SAMPLENAME_GATCAG_L007_R2_001.fastq.gz
				String tokens[]=uscore.split(f.getName());
				if(tokens[1].equals("Undetermined")) continue;
			
				if(tokens.length!=5)
					{
					 System.err.println("Illegal name "+f);
					continue;
					}
				if(!tokens[2].startsWith("L"))
					{
					System.err.println("Illegal lane");
					continue;
					}	
				String seqIndex=tokens[1];
				this.seqIndexes.add(seqIndex);
				int lane=Integer.parseInt(tokens[2].substring(1));
				this.lanes.add(lane);
				int split=Integer.parseInt(tokens[4].substring(0,tokens[4].length()-SUFFIX.length()));
				if(tokens[3].equals("R1"))
					{
					//ok
					}
				else if(tokens[3].equals("R2"))
					{
					continue;//ignore
					}
				else
					{
					System.err.println("Illegal name "+f);
					System.exit(-1);
					}
				SampleType sample=null;
				for(SampleType S: project.getSample())
					{
					if(S.getName().equals(tokens[0]))
						{
						sample=S;
						break;
						}
					}
				if(sample==null)
					{
					sample=new SampleType();
					sample.setName(tokens[0]);
					project.getSample().add(sample);
					SequencesType sequences=new SequencesType();
					sample.setSequences(sequences);
					}
				PairType p=new PairType();
				p.setLane(lane);
				p.setSplitIndex(split);
				p.setSampleIndex(seqIndex);
				sample.getSequences().getPair().add(p);
				
				FastqType fq=new FastqType();
				fq.setIndex(1);
				fq.setPath(f.getPath());
				
				p.getFastq().add(fq);
			
				fq=new FastqType();
				fq.setIndex(2);
				File mate=new File(f.getParentFile(),tokens[0]+"_"+tokens[1]+"_"+tokens[2]+"_R2_"+tokens[4]);
				if(!mate.exists())
					{
					System.err.println("Cannot find "+mate);
					System.exit(-1);
					}
				fq.setPath(mate.getPath());
				p.getFastq().add(fq);
				}
			}
		}
	private void dump() throws Exception
		{
		JAXBContext jaxbContext = JAXBContext.newInstance(ProjectType.class);
		Marshaller jaxbMarshaller = jaxbContext.createMarshaller();
		jaxbMarshaller.setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true);
		jaxbMarshaller.setProperty(Marshaller.JAXB_SCHEMA_LOCATION,
			"https://raw.github.com/lindenb/xml4ngs/master/src/main/resources/xsd/project.xsd"
			);
		jaxbMarshaller.marshal(
			new JAXBElement<ProjectType>(new QName("project"), ProjectType.class, project),
			System.out
			);
		}
	private void readPropertyFile(File f)  throws Exception
		{
		JAXBContext jaxbContext = JAXBContext.newInstance(ProjectType.class);
		Unmarshaller unmarshaller=jaxbContext.createUnmarshaller();
		this.properties=(PropertiesType)((javax.xml.bind.JAXBElement)unmarshaller.unmarshal(
			f)).getValue();
		}
	
	private void run(String args[]) throws Exception
		{
		int optind=0;
		while(optind< args.length)
			{
			if(args[optind].equals("-h"))
				{
				System.out.println(" -h help (this screen)");
				System.out.println(" -p (properties.xml)");
				return;
				}
			else if(args[optind].equals("-p") && optind+1< args.length)
				{
				readPropertyFile(new File(args[++optind]));
				}
			else if(args[optind].equals("--"))
				{
				++optind;
				break;
				}
			else if(args[optind].startsWith("-"))
				{
				System.err.println("Unknown option "+args[optind]);
				System.exit(-1);
				}
			else
				{
				break;
				}
			++optind;
			}
		if(optind==args.length)
			{
			System.err.println("Illegal parameters.");
			System.exit(-1);
			}
		while(optind< args.length)
			{
			File file=new File(args[optind++]);
			if(!file.isDirectory())
				{
				System.err.println("not a directory:"+file);
				}
			scan(file);
			}
		
				
		
		/* finalize object : add lanes */
		LanesType lanes=new LanesType();
		for(Integer i:this.lanes)
			{
			lanes.getLane().add(String.valueOf(i));
			}
		this.project.setLanes(lanes);
		if(this.properties!=null)
			{
			this.project.setProperties(this.properties);
			}
		dump();
		}
	public static void main(String args[]) throws Exception
		{
		new Ilmn2Project().run(args);
		}
	}
