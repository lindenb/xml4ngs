package com.github.lindenb.xml4ngs;

import java.io.InputStream;
import java.io.PrintStream;
import java.io.PrintWriter;
import java.io.File;
import java.net.URL;

import org.apache.velocity.Template;
import org.apache.velocity.VelocityContext;
import org.apache.velocity.app.Velocity;
import org.apache.velocity.app.VelocityEngine;
import org.w3c.dom.Document;

import com.github.lindenb.jsonx.DomParser;
import com.github.lindenb.jsonx.JsonElement;
import com.github.lindenb.jsonx.JsonObject;
import com.github.lindenb.jsonx.io.JsonXmlWriter;
import com.github.lindenb.xml4ngs.entities.Project;


import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.Properties;
import java.util.jar.Manifest;
import java.util.regex.Pattern;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

public class TransformProject
	{
	private Project project=null;
	
	@SuppressWarnings("unused")
	private com.github.lindenb.xml4ngs.InlineJsonDirective _fool_javac=null;
	public class Utils
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
	
	private String version=null;
    private String getVersion()
	    {
    	if(version!=null) return version;
    	version="undefined";
	    try
	            {
	
	                    Enumeration<URL> resources = getClass().getClassLoader()
	                                      .getResources("META-INF/MANIFEST.MF");//not '/META-INF'
	                    while (resources.hasMoreElements() && version==null)
	                            {
	                            URL url=resources.nextElement();
	                            InputStream in=url.openStream();
	                            if(in==null)
	                                    {
	                                    continue;
	                                    }
	
	                            Manifest m=new Manifest(in);
	                            in.close();
	                            in=null;
	                            java.util.jar.Attributes attrs=m.getMainAttributes();
	                            if(attrs==null)
	                                    {
	                                    continue;
	                                    }
	                            String s =attrs.getValue("Git-Hash");
	                            if(s!=null && !s.isEmpty() && !s.contains("$")) //ant failed
	                                    {
	                                    this.version=s;
	                                    }
	
	                           
	                            }
	            }
	    catch(Exception err)
	            {
	    	
	            }
	    return version;
	    }

	
	private void alterConfig(
			JsonElement parent,
			String key,
			JsonElement E,
			String path)
			 throws Exception
		{
		int slash=key.indexOf('/');
		if(slash==-1) slash=key.indexOf('.');
		if(slash==0) { alterConfig(parent,key.substring(1),E,path); return ;}
		if(slash==-1)
			{
			path+="/"+key;
			if(!parent.isJsonObject())
				{
				parent=parent.getParent();
				}
			JsonObject object=parent.getAsJsonObject();
			JsonElement oldElement=object.get(key);
			object.put(key, E);
			System.err.println("For \""+path+"\" replaced "+oldElement+" with "+E);
			}
		else
			{
			String left=key.substring(0, slash);
			String right=key.substring(slash+1);
			if(!parent.getAsJsonObject().containsKey(left)) throw new Exception("No key "+left+" defined in "+parent);
			path+="/"+left;
			JsonElement child=parent.getAsJsonObject().get(left);
			alterConfig(child,right,E,path);
				
			
			
			}
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
		JsonObject config=new DomParser().parse(dom).getAsJsonObject();
		config.put("version", getVersion());
		String dateStr=new SimpleDateFormat("yyyyMMddHHmm").format(new Date());
		config.put("date", dateStr);
		
		if(optind+2!=args.length)
			{
			usage(System.out);
			System.exit(-1);
			}

		this.project=ProjectReader.readProject(new File(args[optind++]));
		File  templateFile=new File(args[optind++]);
		
		for(String keyPath: new ArrayList<String>(this.project.getProperties().keySet()))
			{
			
			alterConfig(config,keyPath,this.project.getProperties().get(keyPath),"");
			}
		
		Properties props = new Properties();
		props.put(Velocity.RESOURCE_LOADER, "file");
		if(templateFile.getParent()!=null)
			{
			props.put("file.resource.loader.path",templateFile.getParent());
			}
		props.put("userdirective","com.github.lindenb.xml4ngs.InlineJsonDirective");
		
		
		String configAsString=new JsonXmlWriter().toString(config).
				replaceAll(Pattern.quote("\\"), "\\\\").
				replaceAll(Pattern.quote("\n"), "\\n").
				replaceAll(Pattern.quote("\t"), "\\t").
				replaceAll(Pattern.quote("'"), "\\\'").
				replaceAll(Pattern.quote(String.valueOf('$')), "$$").
				replaceAll(Pattern.quote(String.valueOf('#')), "\\#").
				replaceAll(Pattern.quote(String.valueOf('"')), "\\\\\"")
				;
		
		VelocityEngine ve = new VelocityEngine();
		ve.init(props);

		VelocityContext ctx=new VelocityContext();
		ctx.put("config", config);
		ctx.put("now",dateStr);
		ctx.put("utils",new Utils());
		ctx.put("project",this.project);
		ctx.put("configAsString",configAsString);
		
		
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

