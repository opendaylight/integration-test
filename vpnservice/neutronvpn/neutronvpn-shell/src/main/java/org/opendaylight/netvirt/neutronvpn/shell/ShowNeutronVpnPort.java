/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn.shell;

import com.google.common.base.Optional;
import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortKey;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

@Command(scope = "vpnservice", name = "neutronvpn-ports-show", description = "Displays all ports configured by neutron per vpn instance")
public class ShowNeutronVpnPort extends OsgiCommandSupport {

    @Argument(index = 0, name = "--vpn-name", description = "Name of the Vpn Instance", required = false, multiValued = false)
    private String vpnName;
    @Argument(index = 1, name = "--ip-address", description = "Ip address assigned to the port", required = false, multiValued = false)
    private String portFixedIp;

    final Logger LOG = LoggerFactory.getLogger(ShowNeutronVpnPort.class);
    private DataBroker dataBroker;
    List<VpnPortipToPort> vpnPortipToPortList = new ArrayList<>();

    public void setDataBroker(DataBroker broker) {
        this.dataBroker = broker;
    }
    @Override
    protected Object doExecute() throws Exception{

        try{
            if (vpnName == null && portFixedIp == null) {
                getNeutronVpnPort();
                System.out.println(vpnPortipToPortList.size() + " Entries are present: ");
                System.out.println("-----------------------------------------------------------------------");
                System.out.println(String.format("             %s   %24s", "VpnName", "PortFixedip"));
                System.out.println("-----------------------------------------------------------------------");
                for (VpnPortipToPort vpnPortipToPort : vpnPortipToPortList){
                    System.out.println(String.format("%-32s  %-10s", vpnPortipToPort.getVpnName(), vpnPortipToPort.getPortFixedip()));
                }
                System.out.println("\n" + getshowVpnCLIHelp());
            }else if (portFixedIp == null || vpnName == null) {
                System.out.println("Insufficient arguments" + "\nCorrect Usage : neutronvpn-port-show [<vpnName> <portFixedIp>]");
            }else{
                InstanceIdentifier<VpnPortipToPort> id = InstanceIdentifier.builder(NeutronVpnPortipPortData.class).child
                        (VpnPortipToPort.class, new VpnPortipToPortKey(portFixedIp, vpnName)).build();
                Optional<VpnPortipToPort> vpnPortipToPortData = read(LogicalDatastoreType.OPERATIONAL, id);
                if (vpnPortipToPortData == null) {
                    System.out.println(" Data not present");
                }else {
                    VpnPortipToPort data = vpnPortipToPortData.get();
                    System.out.println("\n-------------------------------------------------------------------------------------------");
                    System.out.println("Key: " + data.getKey() + "\nMacAddress: " + data.getMacAddress() + "\nPortFixedip: " +
                            data.getPortFixedip() + "\nPortName: " + data.getPortName() + "\nVpnName: " + data.getVpnName());
                    System.out.println("-------------------------------------------------------------------------------------------");
                }
            }
        }catch (Exception e) {
            System.out.println("Error fetching vpnPortIpToPortData for [vpnName=" + vpnName + ", portFixedip=" + portFixedIp + "]");
            LOG.error("Error Fetching Data",e);
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

    private void getNeutronVpnPort(){

        InstanceIdentifier<NeutronVpnPortipPortData> neutronVpnPortipPortDataIdentifier = InstanceIdentifier
                .builder(NeutronVpnPortipPortData.class).build();
        Optional<NeutronVpnPortipPortData> optionalNeutronVpnPort = read(LogicalDatastoreType.OPERATIONAL,
                neutronVpnPortipPortDataIdentifier);
        if (!optionalNeutronVpnPort.isPresent()) {
            System.out.println("No NeutronVpnPortIpData configured.");
        }else {
            vpnPortipToPortList = optionalNeutronVpnPort.get().getVpnPortipToPort();
        }
    }

    private String getshowVpnCLIHelp() {
        StringBuilder help = new StringBuilder("Usage:");
        help.append("To display ports and their associated vpn instances neutronvpn-port-show [<vpnName> <portFixedIp>]");
        return help.toString();
    }
}
