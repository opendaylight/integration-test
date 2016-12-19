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
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface.EtreeInterfaceType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "etreeInterface", name = "add", description = "adding Etree Interface")
public class EtreeInterfaceAdd extends OsgiCommandSupport {

    @Argument(index = 0, name = "etreeName", description = "ETREE-NAME", required = true, multiValued = false)
    private String elanName;
    @Argument(index = 1, name = "interfaceName", description = "InterfaceName", required = true, multiValued = false)
    private String interfaceName;
    @Argument(index = 2, name = "interfaceType", description = "root or leaf", required = true, multiValued = false)
    private String interfaceType;
    @Argument(index = 3, name = "staticMacAddresses", description = "StaticMacAddresses", required = false,
            multiValued = true)
    private List<String> staticMacAddresses;
    @Argument(index = 4, name = "elanInterfaceDescr", description = "ELAN Interface-Description", required = false,
            multiValued = false)
    private String elanInterfaceDescr;
    private static final Logger LOG = LoggerFactory.getLogger(EtreeInterfaceAdd.class);
    private IElanService elanProvider;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        EtreeInterfaceType inputType = null;
        for (EtreeInterfaceType type : EtreeInterfaceType.values()) {
            if (interfaceType.equals(type.getName())) {
                inputType = type;
                break;
            }
        }
        if (inputType == null) {
            session.getConsole().println("interfaceType must be one of: leaf/root, but was: " + interfaceType);
            return null;
        }

        ElanInstance elanInstance = elanProvider.getElanInstance(elanName);
        if (elanInstance == null) {
            session.getConsole().println("Etree instance " + elanName + " does not exist.");
            return null;
        } else {
            if (elanInstance.getAugmentation(EtreeInstance.class) == null) {
                session.getConsole().println("Etree instance " + elanName + " exists but isn't configured as Etree.");
                return null;
            }
        }

        LOG.debug("Executing create EtreeInterface command" + "\t" + elanName + "\t" + interfaceName + "\t"
                + interfaceType + "\t" + staticMacAddresses + "\t" + elanInterfaceDescr + "\t");
        elanProvider.addEtreeInterface(elanName, interfaceName, inputType, staticMacAddresses, elanInterfaceDescr);
        session.getConsole().println("Created etree interface successfully");

        return null;
    }
}
