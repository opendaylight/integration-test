/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.cli.etree;

import java.util.List;
import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.elan.utils.ElanCLIUtils;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "etree", name = "show", description = "display Etree Instance")
public class EtreeGet extends OsgiCommandSupport {

    private static final Logger LOG = LoggerFactory.getLogger(EtreeGet.class);

    @Argument(index = 0, name = "etreeName", description = "ETREE-NAME", required = false, multiValued = false)
    private String etreeName;
    private IElanService elanProvider;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing Get EtreeInstance command" + "\t" + etreeName + "\t");
        if (etreeName != null) {
            ElanInstance elanInstance = elanProvider.getElanInstance(etreeName);
            if (elanInstance == null || elanInstance.getAugmentation(EtreeInstance.class) == null) {
                session.getConsole().println("No Etree Instance present with name:" + etreeName);
            } else {
                session.getConsole().println(getEtreeHeaderOutput());
                session.getConsole()
                        .println(String.format(ElanCLIUtils.ETREE_CLI_FORMAT, elanInstance.getElanInstanceName(),
                                elanInstance.getMacTimeout(), elanInstance.getElanTag(),
                                elanInstance.getDescription()));
            }

        } else {
            List<ElanInstance> elanInstanceList = elanProvider.getElanInstances();
            if (elanInstanceList != null && !elanInstanceList.isEmpty()) {
                session.getConsole().println(getEtreeHeaderOutput());
                for (ElanInstance elanInstance : elanInstanceList) {
                    if (elanInstance.getAugmentation(EtreeInstance.class) != null) {
                        session.getConsole().println(String.format(ElanCLIUtils.ETREE_CLI_FORMAT,
                                elanInstance.getElanInstanceName(), elanInstance.getMacTimeout(),
                                elanInstance.getElanTag(),
                                elanInstance.getAugmentation(EtreeInstance.class).getEtreeLeafTagVal().getValue(),
                                elanInstance.getDescription()));
                    }
                }
            } else {
                session.getConsole().println("No Etree Instances are present");
            }

        }
        return null;
    }

    private Object getEtreeHeaderOutput() {
        StringBuilder headerBuilder = new StringBuilder();
        headerBuilder.append(String.format(ElanCLIUtils.ETREE_CLI_FORMAT, "Etree Instance", "Mac-TimeOut", "Etree Tag",
                "Etree Leaves Tag"));
        headerBuilder.append('\n');
        headerBuilder.append(ElanCLIUtils.HEADER_UNDERLINE);
        return headerBuilder.toString();
    }
}
