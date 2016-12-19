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
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Command(scope = "vpnservice", name = "vpninstance-op-show", description = "List name of all vpnInstances that is " +
        "present or absent in vpnInstanceOpDataEntry")
public class ShowVpnInstanceOpData extends OsgiCommandSupport {

    @Option(name = "--detail", aliases = {"--vpnInstanceOp"}, description = "Display vpnInstanceOpDataEntry detail " +
            "for" +
            " given vpnInstanceName", required = false, multiValued = false)
    String detail;
    final Logger LOG = LoggerFactory.getLogger(ShowVpnInstanceOpData.class);
    private DataBroker dataBroker;
    List<VpnInstance> vpnInstanceList = new ArrayList<>();
    Map<String, VpnInstanceOpDataEntry> vpnInstanceOpDataEntryMap = new HashMap<>();

    public void setDataBroker(DataBroker broker) {
        this.dataBroker = broker;
    }

    @Override
    protected Object doExecute() throws Exception{
        try{
            if (detail == null) {
                getVpnInstanceOpData();
                System.out.println("For following vpnInstances vpnInstanceOpDataEntry is present: \n");
                for (VpnInstance vpnInstance : vpnInstanceList) {
                    VpnInstanceOpDataEntry check = vpnInstanceOpDataEntryMap.get(vpnInstance.getVpnInstanceName());
                    if (check != null) {
                        System.out.println(vpnInstance.getVpnInstanceName() + "\n");
                    }
                }
                System.out.println("\n\nFor following vpnInstances vpnInstanceOpDataEntry is not present: \n");
                for (VpnInstance vpnInstance : vpnInstanceList) {
                    VpnInstanceOpDataEntry check = vpnInstanceOpDataEntryMap.get(vpnInstance.getVpnInstanceName());
                    if (check == null) {
                        System.out.println(vpnInstance.getVpnInstanceName() + "\n");
                    }
                }
                System.out.println(getshowVpnCLIHelp());
            } else {
                getVpnInstanceOpData();
                System.out.println("Fetching details of given vpnInstance\n");
                System.out.println("------------------------------------------------------------------------------");
                VpnInstanceOpDataEntry check = vpnInstanceOpDataEntryMap.get(detail);
                System.out.println("VpnInstanceName: " + check.getVpnInstanceName() + "\n" + "VpnId: " + check
                        .getVpnId() + "\n" + "VrfId: " + check.getVrfId() + "\n" + "Key: " + check.getKey() + "\n" +
                        "VpnInterfaceCount: " + check.getVpnInterfaceCount() + "\n" + "VpnToDpnList: " + check.getVpnToDpnList() +
                        "\n");
                System.out.println("------------------------------------------------------------------------------");
            }

        }catch (Exception e) {
            System.out.println("Error fetching vpnInstanceOpDataEntry for " + detail);
            LOG.error("Failed to fetch parameters",e);
        }

        return null;
    }

    private void getVpnInstanceOpData(){
        List<VpnInstanceOpDataEntry> vpnInstanceOpDataEntryList = new ArrayList<>();
        InstanceIdentifier<VpnInstances> vpnsIdentifier = InstanceIdentifier.builder(VpnInstances.class).build();
        InstanceIdentifier<VpnInstanceOpData> vpnInstanceOpDataEntryIdentifier = InstanceIdentifier.builder
                (VpnInstanceOpData.class).build();
        Optional<VpnInstances> optionalVpnInstances = read( LogicalDatastoreType.CONFIGURATION, vpnsIdentifier);

        if (!optionalVpnInstances.isPresent() || optionalVpnInstances.get().getVpnInstance() == null ||
                optionalVpnInstances.get().getVpnInstance().isEmpty()) {
            LOG.trace("No VPNInstances configured.");
            System.out.println("No VPNInstances configured.");
        }else {
            vpnInstanceList = optionalVpnInstances.get().getVpnInstance();
        }

        Optional<VpnInstanceOpData> optionalOpData = read(LogicalDatastoreType.OPERATIONAL,
                vpnInstanceOpDataEntryIdentifier);

        if (!optionalOpData.isPresent()) {
            LOG.trace("No VPNInstanceOpDataEntry present.");
            System.out.println("No VPNInstanceOpDataEntry present.");
        }else {
            vpnInstanceOpDataEntryList = optionalOpData.get().getVpnInstanceOpDataEntry();
        }

        for(VpnInstanceOpDataEntry vpnInstanceOpDataEntry : vpnInstanceOpDataEntryList){
            vpnInstanceOpDataEntryMap.put(vpnInstanceOpDataEntry.getVpnInstanceName(), vpnInstanceOpDataEntry);
        }
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

    private String getshowVpnCLIHelp() {
        StringBuilder help = new StringBuilder("\nUsage:");
        help.append("To display vpn-instance-op-data for given vpnInstanceName vpnInstanceOpData-show --detail [<vpnInstanceName>]");
        return help.toString();
    }
}
