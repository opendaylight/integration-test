/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.shell;

import com.google.common.base.Optional;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Command(scope = "vpnservice", name = "vpn-show", description = "Display all present vpnInstances with their " +
        "respective count of oper and config vpnInterfaces")
public class ShowVpn extends OsgiCommandSupport {

    @Option(name = "--detail", aliases = {"--vpninstance"}, description = "Display oper and config interfaces for " +
            "given vpnInstanceName", required = false, multiValued = false)
    String detail;

    final Logger LOG = LoggerFactory.getLogger(ShowVpn.class);
    private DataBroker dataBroker;
    int configCount = 0;
    int operCount = 0;
    int totalOperCount =  0;
    int totalConfigCount =  0;
    Integer ifPresent ;
    List<org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance> vpnInstanceList = new ArrayList<>();
    List<VpnInterface> vpnInterfaceConfigList = new ArrayList<>();
    List<VpnInterface> vpnInterfaceOperList = new ArrayList<>();

    public void setDataBroker(DataBroker broker) {
        this.dataBroker = broker;
    }

    @Override
    protected Object doExecute() throws Exception{
        try{

            Map<String, Integer> instanceNameToConfigInterfaceMap = new HashMap<>();
            Map<String, Integer> instanceNameToOperInterfaceMap = new HashMap<>();
            if (detail == null) {
                showVpn();
                for (VpnInterface vpnInterface : vpnInterfaceConfigList) {
                    ifPresent = instanceNameToConfigInterfaceMap.get(vpnInterface.getVpnInstanceName());
                    if(ifPresent == null) {
                        instanceNameToConfigInterfaceMap.put(vpnInterface.getVpnInstanceName(), 1);
                    }
                    else {instanceNameToConfigInterfaceMap.put(vpnInterface.getVpnInstanceName(),
                            instanceNameToConfigInterfaceMap.get(vpnInterface.getVpnInstanceName())+1);
                    }
                }
                for (VpnInterface vpnInterface : vpnInterfaceOperList) {
                    ifPresent = instanceNameToOperInterfaceMap.get(vpnInterface.getVpnInstanceName());
                    if(ifPresent == null) {
                        instanceNameToOperInterfaceMap.put(vpnInterface.getVpnInstanceName(), 1);
                    }
                    else {instanceNameToOperInterfaceMap.put(vpnInterface.getVpnInstanceName(),
                            instanceNameToOperInterfaceMap.get(vpnInterface.getVpnInstanceName())+1);
                    }
                }
                System.out.println("-----------------------------------------------------------------------");
                System.out.println(String.format("         %s   %14s  %5s  %5s", "VpnInstanceName", "RD", "Config " +
                        "Count", "Oper Count"));
                System.out.println("\n-----------------------------------------------------------------------");
                for (VpnInstance vpnInstance : vpnInstanceList) {
                    configCount = 0; operCount = 0;
                    Integer count = instanceNameToConfigInterfaceMap.get(vpnInstance.getVpnInstanceName());
                    if(count != null) {
                        configCount = instanceNameToConfigInterfaceMap.get(vpnInstance.getVpnInstanceName());
                        totalConfigCount = totalConfigCount + configCount;
                    }
                    count = instanceNameToOperInterfaceMap.get(vpnInstance.getVpnInstanceName());
                    if (count != null) {
                        operCount = instanceNameToOperInterfaceMap.get(vpnInstance.getVpnInstanceName());
                        totalOperCount = totalOperCount + operCount;
                    }
                    System.out.println(String.format("%-32s  %-10s  %-10s  %-10s", vpnInstance.getVpnInstanceName(),
                            vpnInstance.getIpv4Family().getRouteDistinguisher(), configCount, operCount));
                }
                System.out.println("-----------------------------------------------------------------------");
                System.out.println(String.format("Total Count:                    %19s    %8s", totalConfigCount,
                        totalOperCount));
                System.out.println(getshowVpnCLIHelp());
            }else {
                showVpn();
                System.out.println("Present Config VpnInterfaces are:");
                for (VpnInterface vpnInterface : vpnInterfaceConfigList) {
                    if (vpnInterface.getVpnInstanceName().equals(detail)) {
                        System.out.println(vpnInterface.getName());
                    }
                }
                System.out.println("Present Oper VpnInterfaces are:");
                for (VpnInterface vpnInterface : vpnInterfaceOperList) {
                    if (vpnInterface.getVpnInstanceName().equals(detail)) {
                        System.out.println(vpnInterface.getName());
                    }
                }
            }
        }catch (Exception e) {
            System.out.println("Error while fetching vpnInterfaces for " + detail);
            LOG.error("Failed to fetch parameters",e);
        }
        return null;
    }

    private <T extends DataObject> Optional<T> read(LogicalDatastoreType datastoreType,
                                                    InstanceIdentifier<T> path) {

        ReadOnlyTransaction tx = dataBroker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return result;
    }

    private void showVpn(){
        InstanceIdentifier<VpnInstances> vpnsIdentifier = InstanceIdentifier.builder(VpnInstances.class).build();
        InstanceIdentifier<VpnInterfaces> vpnInterfacesIdentifier = InstanceIdentifier.builder(VpnInterfaces
                .class).build();
        Optional<VpnInstances> optionalVpnInstances = read( LogicalDatastoreType.CONFIGURATION, vpnsIdentifier);

        if (!optionalVpnInstances.isPresent()) {
            LOG.trace("No VPNInstances configured.");
            System.out.println("No VPNInstances configured.");
        }else{
            vpnInstanceList = optionalVpnInstances.get().getVpnInstance();
        }

        Optional<VpnInterfaces> optionalVpnInterfacesConfig = read(LogicalDatastoreType.CONFIGURATION, vpnInterfacesIdentifier);

        if (!optionalVpnInterfacesConfig.isPresent()) {
            LOG.trace("No Config VpnInterface is present");
            System.out.println("No Config VpnInterface is present");
        }else{
            vpnInterfaceConfigList = optionalVpnInterfacesConfig.get().getVpnInterface();
        }

        Optional<VpnInterfaces> optionalVpnInterfacesOper = read(LogicalDatastoreType.OPERATIONAL, vpnInterfacesIdentifier);

        if (!optionalVpnInterfacesOper.isPresent()) {
            LOG.trace("No Oper VpnInterface is present");
            System.out.println("No Oper VpnInterface is present");
        }else{
            vpnInterfaceOperList = optionalVpnInterfacesOper.get().getVpnInterface();
        }
    }

    private String getshowVpnCLIHelp() {
        StringBuilder help = new StringBuilder("\nUsage:");
        help.append("To display vpn-interfaces for a particular vpnInstance vpn-show --detail [<vpnInstanceName>]");
        return help.toString();
    }
}
