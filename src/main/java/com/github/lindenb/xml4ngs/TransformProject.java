package com.github.lindenb.xml4ngs;

import java.io.PrintStream;
import java.io.PrintWriter;
import java.io.File;
import com.github.lindenb.xml4ngs.*;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.Velocity;
import org.apache.velocity.app.VelocityEngine;
import javax.xml.transform.stream.StreamSource;

import java.util.Properties;

public class TransformProject
	{
	public static class Utils
		{
		public void warning(Object o)
			{
			System.err.println("[WARNING] "+o);
			}
		public void error(Object o)
			{
			System.err.println("[ERROR] "+o);
			System.exit(-1);
			}
		}
	
	private TransformProject()
		{
		
		}
		
	protected void usage(PrintStream out)
		{

		
		out.println();
		out.println("$project is the structure passed to velocity.");

		}


	private void run(String args[]) throws Exception
		{
		int optind=0;
		while(optind< args.length)
			{
			if(args[optind].equals("-h"))
				{
				usage(System.out);
				return;
				}
			else if(args[optind].equals("-f") && optind+1< args.length)
				{
				
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
		
		if(optind+2!=args.length)
			{
			usage(System.out);
			System.exit(-1);
			}
	        javax.xml.bind.JAXBContext jaxbCtxt=javax.xml.bind.JAXBContext.newInstance(
				  	ProjectType.class
				  	);
				  	
		javax.xml.bind.Unmarshaller unmarshaller=jaxbCtxt.createUnmarshaller();
		ProjectType project=unmarshaller.unmarshal(new StreamSource(new File(args[optind++])),
					ProjectType.class
					).getValue();
		project.link();
		
		File  templateFile=new File(args[optind++]);
		
		
		
		Properties props = new Properties();
		props.put(Velocity.RESOURCE_LOADER, "file");
		if(templateFile.getParent()!=null)
			{
			props.put("file.resource.loader.path",templateFile.getParent());
			}
		
		VelocityEngine ve = new VelocityEngine();
		ve.init(props);

		VelocityContext ctx=new VelocityContext();
		ctx.put("now",new java.sql.Timestamp(System.currentTimeMillis()));
		ctx.put("utils",new Utils());
		ctx.put("project",project);
		
		Template template= ve.getTemplate(templateFile.getName());
		
		PrintWriter out=new PrintWriter(System.out);
		template.merge(ctx, out);

		out.flush();
		out.close();
		}
	public static void main(String args[]) throws Exception
		{
		new TransformProject().run(args);
		}
	}
