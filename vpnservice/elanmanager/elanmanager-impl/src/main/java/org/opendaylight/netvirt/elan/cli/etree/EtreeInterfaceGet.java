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
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.netvirt.elan.utils.ElanCLIUtils;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "etreeInterface", name = "show", description = "display Etree Interfaces for the EtreeInstance")
public class EtreeInterfaceGet extends OsgiCommandSupport {

    private static final Logger LOG = LoggerFactory.getLogger(EtreeInterfaceGet.class);

    @Argument(index = 0, name = "etreeName", description = "ETREE-NAME", required = false, multiValued = false)
    private String etreeName;
    private IInterfaceManager interfaceManager;
    public static int MAX_LENGTH = 31;
    private IElanService elanProvider;
    //private ElanUtils elanUtils;
    public static boolean isDisplay = true;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    public void setInterfaceManager(IInterfaceManager interfaceManager) {
        this.interfaceManager = interfaceManager;
    }

    /*public void setElanUtils(ElanUtils elanUtils) {
        this.elanUtils = elanUtils;
    }*/

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing Get EtreeInterface command for the corresponding Etree Instance" + "\t" + etreeName
                + "\t");
        if (etreeName != null) {
            ElanInstance elanInstance = elanProvider.getElanInstance(etreeName);
            if (elanInstance == null || elanInstance.getAugmentation(EtreeInstance.class) == null) {
                session.getConsole().println("Etree instance doesn't exist or isn't configured as etree: " + etreeName);
                return null;
            }
            List<String> elanInterfaces = elanProvider.getElanInterfaces(etreeName);
            if (elanInterfaces == null) {
                session.getConsole().println("No Etree Interfaces present for ELan Instance:" + etreeName);
                return null;
            }
            session.getConsole().println(getEtreeInterfaceHeaderOutput());
            displayInterfaces(elanInstance, elanInterfaces);

        } else {
            List<ElanInstance> elanInstances = elanProvider.getElanInstances();
            if (!elanInstances.isEmpty()) {
                session.getConsole().println(getEtreeInterfaceHeaderOutput());
                for (ElanInstance elanInstance : elanInstances) {
                    List<String> elanInterfaces =
                            elanProvider.getElanInterfaces(elanInstance.getElanInstanceName());
                    displayInterfaces(elanInstance, elanInterfaces);
                    session.getConsole().println("\n");
                }
            }

        }
        return null;
    }

    private Object getEtreeInterfaceHeaderOutput() {
        StringBuilder headerBuilder = new StringBuilder();
        headerBuilder.append(String.format(ElanCLIUtils.ETREE_INTERFACE_CLI_FORMAT, "EtreeInstance/Tag",
                "EtreeInterface/Tag", "OpState", "AdminState", "Root/Leaf"));
        headerBuilder.append('\n');
        headerBuilder.append(ElanCLIUtils.HEADER_UNDERLINE);
        return headerBuilder.toString();
    }

    private void displayInterfaces(ElanInstance elanInstance, List<String> interfaceList) {
        if (!interfaceList.isEmpty()) {
            for (String elanInterface : interfaceList) {
                InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(elanInterface);
                EtreeInterface etreeInterface = elanProvider.getEtreeInterfaceByElanInterfaceName(elanInterface);
                if (interfaceInfo != null) {
                    session.getConsole().println(String.format(ElanCLIUtils.ETREE_INTERFACE_CLI_FORMAT,
                            elanInstance.getElanInstanceName() + "/" + elanInstance.getElanTag(),
                            elanInterface + "/" + interfaceInfo.getInterfaceTag(), interfaceInfo.getOpState(),
                            interfaceInfo.getAdminState(), etreeInterface.getEtreeInterfaceType().getName()));
                }
            }
        }
    }
}
