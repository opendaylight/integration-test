package jbench;
import java.util.ArrayList;
import java.util.List;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;
import com.beust.jcommander.ParameterException;

public class Jbench {
	
	@Parameter(names = { "-c", "--controller" }, variableArity = true, description = "controller ip and port number")
	private List<String> controllerIp = new ArrayList<>();
	
	@Parameter(names = { "-d", "--debug" }, description = "enable debugging")
	private int debug = 0;
	
	@Parameter(names = {"-h", "--help" }, help = true, description = "print this message")
	private boolean help;
	
	@Parameter(names = { "-l", "--loops" }, description = "loops per test")
	private int loops = 16;
	
	@Parameter(names = { "-m", "--ms-per-test" }, description = "test length in ms")
	private int msPerTest = 1000;
	
	@Parameter(names = { "-n", "--number" }, description = "number of controllers")
	private int numControllers = 1;
	
	@Parameter(names = { "-s", "--switches" }, description = "number of switches")
	private int numSwitches = 16;
	
	@Parameter(names = { "-w", "--warmup" }, description = "loops to be disregarded on test start (warmup)")
	private int warmup = 1;
	
	@Parameter(names = { "-C", "--cooldown" }, description = "loops to be disregarded at test end (cooldown)")
	private int cooldown = 0;
	
	@Parameter(names = { "-D", "--delay" }, description = "delay starting testing after features_reply is received (in ms)")
	private int delay = 0;
	
	@Parameter(names = { "-M", "--mac-addresses" }, description = "unique source mac addresses per switch")
	private int macCountPerSwitch = 100000;
	
	@Parameter(names = { "-O", "--operation-mode" }, required = true, validateWith = OperationMode.class, description = "latency or throughput mode")
	private String operationMode;
	
	public static void main(String[] args) {
		
		Jbench options = new Jbench();
		JCommander cmd = new JCommander(options);
		cmd.setProgramName("Jbench");
		try {
	        cmd.parse(args);
	        if ( options.help ) {
	        	System.out.println("help message");
	            cmd.usage();
	            return;
	         }
	        
	        ControllerInfo[] controller = options.processControllerInfo();
	        System.out.println("Jbench: Java-based controller benchmarking tool");
	        System.out.println("\trunning in mode '"+options.operationMode.toLowerCase()+"'");
	        System.out.println("\tconnecting to controller at:");
	        for(int i = 0; i < options.numControllers; i++)
	        {
	        	System.out.println("\t"+controller[i].getHost()+":"+controller[i].getPort());
	        }
	        System.out.println("\tfaking "+options.numSwitches+" switches, "+options.loops+" tests each, "
	        		+options.msPerTest+" ms per test");
	        System.out.println("\twith "+options.macCountPerSwitch+" unique source MACs per switch");
	        System.out.println("\tstarting test with "+options.delay+ " ms delay after features_reply");
	        System.out.println("\tignoring first "+options.warmup+" warmup and last "+options.cooldown+" cooldown loops");
	        if( options.debug == 0) {
	        	System.out.println("\tdebugging info is off");
	        } else {
	        	System.out.println("\tdebugging info is on");
	        }
	    } catch (ParameterException ex) {
	        System.out.println(ex.getMessage());
	        cmd.usage();
	    }
		
	}
	public ControllerInfo[] processControllerInfo()
	{
		ControllerInfo[] controller = new ControllerInfo[numControllers];
		int j = 0;
		
		if( (numControllers - controllerIp.size()) > 0)
		{
			j = numControllers - controllerIp.size();
		}
		for(int i = 0; i < numControllers; i++)
		{
			controller[i] = new ControllerInfo();
		}
		
		for(int i = 0; i < (numControllers - controllerIp.size()); i++)
		{
			controller[i].setHost("localhost");
			controller[i].setPort(6640);
		}
		
		for(int i = j; i < numControllers; i++)
		{
			String[] s = controllerIp.get(i-j).split(":");
			if(s[0] != null)
			{
				controller[i].setHost(s[0]);
			}
			else
			{
				controller[i].setHost("localhost");
			}
			if(s.length > 1 && s[1] !=null)
			{
				controller[i].setPort(Integer.parseInt(s[1]));
			}
			else
			{
				controller[i].setPort(6640);
			}
		}
		return controller;
	}
}

class ControllerInfo
{
	private String host;
	private Integer port;
	
	public void setHost( String s)
	{
		host = s;
	}
	public void setPort( Integer p)
	{
		port = p;
	}
	public String getHost()
	{
		return host;
	}
	public Integer getPort()
	{
		return port;
	}
	
}

