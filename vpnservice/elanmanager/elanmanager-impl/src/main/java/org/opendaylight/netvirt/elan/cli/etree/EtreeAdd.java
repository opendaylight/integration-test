/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.cli.etree;

import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "etree", name = "add", description = "adding Etree Instance")
public class EtreeAdd extends OsgiCommandSupport {

    @Argument(index = 0, name = "etreeName", description = "ETREE-NAME", required = true, multiValued = false)
    private String etreeName;
    @Argument(index = 1, name = "macTimeOut", description = "MAC Time-Out", required = false, multiValued = false)
    private long macTimeOut = 30;
    @Argument(index = 2, name = "elanDescr", description = "ELAN-Description", required = false, multiValued = false)
    private String etreeDescr;
    private static final Logger LOG = LoggerFactory.getLogger(EtreeAdd.class);
    private IElanService elanProvider;
    public static int MAX_LENGTH = 31;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing create EtreeInstance command" + "\t" + etreeName + "\t" + macTimeOut + "\t"
                + etreeDescr + "\t");
        if (etreeName.length() <= MAX_LENGTH) {
            boolean isSuccess = elanProvider.createEtreeInstance(etreeName, macTimeOut, etreeDescr);
            if (isSuccess) {
                session.getConsole().println("Etree Instance was created successfully");
            }
        } else {
            session.getConsole().println("Failed to create Etree Instance, max length is allowed 1 .. 31");
        }
        return null;
    }
}
