package jbench;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.ParameterException;

public class OperationMode implements IParameterValidator {
	
	 public void validate(String name, String value) throws ParameterException {
	     if (!value.equalsIgnoreCase("latency") && !value.equalsIgnoreCase("throughput")) {
	         throw new ParameterException("Parameter " + name + " should be either latency or throughput");
	    }
	 }
}
