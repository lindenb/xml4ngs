package com.github.lindenb.xml4ngs;

import java.io.IOException;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;

import org.apache.velocity.context.InternalContextAdapter;
import org.apache.velocity.exception.MethodInvocationException;
import org.apache.velocity.exception.ParseErrorException;
import org.apache.velocity.exception.ResourceNotFoundException;
import org.apache.velocity.exception.TemplateInitException;
import org.apache.velocity.runtime.RuntimeServices;
import org.apache.velocity.runtime.directive.Directive;
import org.apache.velocity.runtime.log.Log;
import org.apache.velocity.runtime.parser.node.ASTBlock;
import org.apache.velocity.runtime.parser.node.Node;

import com.github.lindenb.jsonx.JsonElement;
import com.github.lindenb.jsonx.parser.JsonParser;
//http://www.sergiy.ca/how-to-create-custom-directives-for-apache-velocity/
public class InlineJsonDirective extends Directive{
	 private Log log;
	@Override
	public String getName() {
		return "inlineJson";
	}
	@Override
	public int getType()
		{
		return BLOCK;
		}

	@Override
	public void init(RuntimeServices service, InternalContextAdapter context,
			Node node) throws TemplateInitException
		{
		super.init(service, context, node);
		this.log=service.getLog();
		}
	
	
	@Override
	public boolean render(InternalContextAdapter ctx, Writer arg1, Node node)
			throws IOException, ResourceNotFoundException, ParseErrorException,
			MethodInvocationException
		{
        log.debug("start render");
        String variableName=null;
        JsonElement E=null;
        for(int i=0; i<node.jjtGetNumChildren(); i++)
        	{
        	 if(!(node.jjtGetChild(i) instanceof ASTBlock))
        	 	{
        		variableName=String.valueOf(node.jjtGetChild(i).value(ctx));
        	 	}
        	 else
        	 	{
        		StringWriter blockContent = new StringWriter();
                node.jjtGetChild(i).render(ctx, blockContent);
                JsonParser parser=new JsonParser(new StringReader(blockContent.toString()));
                try
                	{
                	E=parser.parse();
                	}
                catch(Exception err)
                	{
                	throw new RuntimeException(err);
                	}
        		break; 
        	 	}
        	}
        if(variableName!=null && E!=null)
        	{
        	ctx.put(variableName, E);
        	}	
        log.debug("end render");
		return false;
		}
	
	
	

}
