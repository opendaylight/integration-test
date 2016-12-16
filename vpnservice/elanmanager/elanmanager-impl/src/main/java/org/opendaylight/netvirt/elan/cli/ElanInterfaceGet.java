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
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.netvirt.elan.utils.ElanCLIUtils;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "elanInterface", name = "show", description = "display Elan Interfaces for the ElanInstance")
public class ElanInterfaceGet extends OsgiCommandSupport {

    private static final Logger LOG = LoggerFactory.getLogger(ElanInterfaceGet.class);

    @Argument(index = 0, name = "elanName", description = "ELAN-NAME", required = false, multiValued = false)
    private String elanName;
    private IInterfaceManager interfaceManager;
    public static int MAX_LENGTH = 31;
    private IElanService elanProvider;
    public static boolean isDisplay = true;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    public void setInterfaceManager(IInterfaceManager interfaceManager) {
        this.interfaceManager = interfaceManager;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing Get ElanInterface command for the corresponding Elan Instance"
                + "\t" + elanName + "\t");
        if (elanName != null) {
            ElanInstance elanInstance = elanProvider.getElanInstance(elanName);
            List<String> elanInterfaces = elanProvider.getElanInterfaces(elanName);
            if (elanInterfaces == null) {
                session.getConsole().println("No Elan Interfaces present for ELan Instance:" + elanName);
                return null;
            }
            session.getConsole().println(getElanInterfaceHeaderOutput());
            displayInterfaces(elanInstance, elanInterfaces);

        } else {
            List<ElanInstance> elanInstances = elanProvider.getElanInstances();
            if (!elanInstances.isEmpty()) {
                session.getConsole().println(getElanInterfaceHeaderOutput());
                for (ElanInstance elanInstance : elanInstances) {
                    List<String> elanInterfaces = elanProvider
                            .getElanInterfaces(elanInstance.getElanInstanceName());
                    displayInterfaces(elanInstance, elanInterfaces);
                    session.getConsole().println("\n");
                }
            }

        }
        return null;
    }

    private Object getElanInterfaceHeaderOutput() {
        StringBuilder headerBuilder = new StringBuilder();
        headerBuilder.append(String.format(ElanCLIUtils.ELAN_INTERFACE_CLI_FORMAT, "ElanInstance/Tag",
                "ElanInterface/Tag", "OpState", "AdminState"));
        headerBuilder.append('\n');
        headerBuilder.append(ElanCLIUtils.HEADER_UNDERLINE);
        return headerBuilder.toString();
    }

    private void displayInterfaces(ElanInstance elanInstance, List<String> interfaceList) {
        if (!interfaceList.isEmpty()) {
            for (String elanInterface : interfaceList) {
                InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(elanInterface);
                if (interfaceInfo != null) {
                    session.getConsole()
                            .println(String.format(ElanCLIUtils.ELAN_INTERFACE_CLI_FORMAT,
                                    elanInstance.getElanInstanceName() + "/" + elanInstance.getElanTag(),
                                    elanInterface + "/" + interfaceInfo.getInterfaceTag(), interfaceInfo.getOpState(),
                                    interfaceInfo.getAdminState()));
                }
            }
        }
    }
}
