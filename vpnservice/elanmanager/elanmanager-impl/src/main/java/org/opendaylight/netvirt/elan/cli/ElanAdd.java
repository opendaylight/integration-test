/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.cli;

import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "elan", name = "add", description = "adding Elan Instance")
public class ElanAdd extends OsgiCommandSupport {

    @Argument(index = 0, name = "elanName", description = "ELAN-NAME", required = true, multiValued = false)
    private String elanName;
    @Argument(index = 1, name = "macTimeOut", description = "MAC Time-Out", required = false, multiValued = false)
    private long macTimeOut = 30;
    @Argument(index = 2, name = "elanDescr", description = "ELAN-Description", required = false, multiValued = false)
    private String elanDescr;
    private static final Logger LOG = LoggerFactory.getLogger(ElanAdd.class);
    private IElanService elanProvider;
    public static int MAX_LENGTH = 31;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing create ElanInstance command" + "\t" + elanName + "\t" + macTimeOut + "\t" + elanDescr
                + "\t");
        if (elanName.length() <= MAX_LENGTH) {
            boolean isSuccess = elanProvider.createElanInstance(elanName, macTimeOut, elanDescr);
            if (isSuccess) {
                session.getConsole().println("Elan Instance is created successfully");
            }
        } else {
            session.getConsole().println("Failed to create Elan Instance, max length is allowed 1 .. 31");
        }
        return null;
    }
}
