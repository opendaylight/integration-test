/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.cli;

import java.util.List;
import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.elan.utils.ElanCLIUtils;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "elan", name = "show", description = "display Elan Instance")
public class ElanGet extends OsgiCommandSupport {

    private static final Logger LOG = LoggerFactory.getLogger(ElanGet.class);

    @Argument(index = 0, name = "elanName", description = "ELAN-NAME", required = false, multiValued = false)
    private String elanName;
    private IElanService elanProvider;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing Get ElanInstance command" + "\t" + elanName +  "\t");
        if (elanName != null) {
            ElanInstance elanInstance = elanProvider.getElanInstance(elanName);
            if (elanInstance == null) {
                session.getConsole().println("No Elan Instance present with name:" + elanName);
            } else {
                session.getConsole().println(getElanHeaderOutput());
                session.getConsole()
                        .println(String.format(ElanCLIUtils.ELAN_CLI_FORMAT, elanInstance.getElanInstanceName(),
                                elanInstance.getMacTimeout(), elanInstance.getElanTag(),
                                elanInstance.getDescription()));
            }

        } else {
            List<ElanInstance> elanInstanceList = elanProvider.getElanInstances();
            if (elanInstanceList != null && !elanInstanceList.isEmpty()) {
                session.getConsole().println(getElanHeaderOutput());
                for (ElanInstance elanInstance : elanInstanceList) {
                    session.getConsole()
                            .println(String.format(ElanCLIUtils.ELAN_CLI_FORMAT, elanInstance.getElanInstanceName(),
                                    elanInstance.getMacTimeout(), elanInstance.getElanTag(),
                                    elanInstance.getDescription()));
                }
            } else {
                session.getConsole().println("No Elan Instances are present");
            }
        }
        return null;
    }

    private Object getElanHeaderOutput() {
        StringBuilder headerBuilder = new StringBuilder();
        headerBuilder.append(String.format(ElanCLIUtils.ELAN_CLI_FORMAT, "Elan Instance", "Mac-TimeOut", "Tag"));
        headerBuilder.append('\n');
        headerBuilder.append(ElanCLIUtils.HEADER_UNDERLINE);
        return headerBuilder.toString();
    }
}

