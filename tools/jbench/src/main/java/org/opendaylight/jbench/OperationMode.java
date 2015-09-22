/*
 * Copyright (c) 2015 Intel Corp. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.jbench;

import com.beust.jcommander.IParameterValidator;
import com.beust.jcommander.ParameterException;

/**
 * <p>This class overrides <i>validate</i> method of IParameterValidator interface to ensure the value passed for
 * Operation mode by the user is either latency or throughput.</p>
 * @author Raksha Madhava Bangera
 *
 */
public class OperationMode implements IParameterValidator {

    /* (non-Javadoc)
     * @see com.beust.jcommander.IParameterValidator#validate(java.lang.String, java.lang.String)
     */
    @Override
    public void validate(String name, String value) throws ParameterException {
        if (!value.equalsIgnoreCase("latency") && !value.equalsIgnoreCase("throughput")) {
            throw new ParameterException("Parameter " + name + " should be either latency or throughput");
        }
    }
}
