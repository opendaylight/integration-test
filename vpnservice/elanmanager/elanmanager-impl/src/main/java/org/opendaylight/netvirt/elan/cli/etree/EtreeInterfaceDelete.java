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
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "etreeInterface", name = "delete", description = "deleting Etree Interface")
public class EtreeInterfaceDelete extends OsgiCommandSupport {

    @Argument(index = 0, name = "etreeName", description = "ETREE-NAME", required = true, multiValued = false)
    private String etreeName;
    @Argument(index = 1, name = "interfaceName", description = "InterfaceName", required = true, multiValued = false)
    private String interfaceName;
    private static final Logger LOG = LoggerFactory.getLogger(EtreeInterfaceDelete.class);
    private IElanService elanProvider;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Deleting EtreeInterface command" + "\t" + etreeName + "\t" + interfaceName + "\t");
        ElanInterface existingInterface =
                elanProvider.getElanInterfaceByElanInterfaceName(interfaceName);
        if (existingInterface == null || existingInterface.getAugmentation(EtreeInterface.class) == null) {
            session.getConsole()
                    .println("Etree interface doesn't exist or isn't configured as etree: " + interfaceName);
        }
        elanProvider.deleteEtreeInterface(etreeName, interfaceName);
        session.getConsole().println("Deleted the Etree interface succesfully");
        return null;
    }
}
