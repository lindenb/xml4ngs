package com.github.lindenb.xml4ngs;

import java.io.PrintStream;
import java.io.PrintWriter;
import java.io.File;
import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.Velocity;
import org.apache.velocity.app.VelocityEngine;
import org.w3c.dom.Document;

import com.github.lindenb.jsonx.DomParser;
import com.github.lindenb.jsonx.JsonElement;
import com.github.lindenb.jsonx.JsonObject;
import com.github.lindenb.xml4ngs.entities.Project;


import java.util.Properties;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

public class TransformProject
	{
	@SuppressWarnings("unused")
	private com.github.lindenb.xml4ngs.InlineJsonDirective _fool_javac=null;
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
		out.println("Usage : java -jar transform.jar project.xml template.vm");
		out.println();
		out.println("$project is the structure passed to velocity.");
		out.println();
		}
	

	
	private void run(String args[]) throws Exception
		{
		File configFile=null;
		int optind=0;
		while(optind< args.length)
			{
			if(args[optind].equals("-h"))
				{
				usage(System.out);
				return;
				}
			else if(args[optind].equals("-c") && optind+1< args.length)
				{
				configFile=new File(args[++optind]);
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
		
		if(configFile==null)
			{
			System.err.println("Config file is not defined -c config.xml");
			System.exit(-1);
			}
		//load config
		DocumentBuilderFactory dbf=DocumentBuilderFactory.newInstance();
		dbf.setValidating(false);
		dbf.setXIncludeAware(true);
		dbf.setNamespaceAware(true);
		DocumentBuilder db=dbf.newDocumentBuilder();
		Document dom=db.parse(configFile);
		JsonElement config=new DomParser().parse(dom);
		
		if(optind+2!=args.length)
			{
			usage(System.out);
			System.exit(-1);
			}

		Project project=ProjectReader.readProject(new File(args[optind++]));
		File  templateFile=new File(args[optind++]);
		
		
		
		Properties props = new Properties();
		props.put(Velocity.RESOURCE_LOADER, "file");
		if(templateFile.getParent()!=null)
			{
			props.put("file.resource.loader.path",templateFile.getParent());
			}
		props.put("userdirective","com.github.lindenb.xml4ngs.InlineJsonDirective");

		VelocityEngine ve = new VelocityEngine();
		ve.init(props);

		VelocityContext ctx=new VelocityContext();
		ctx.put("config", config);
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

