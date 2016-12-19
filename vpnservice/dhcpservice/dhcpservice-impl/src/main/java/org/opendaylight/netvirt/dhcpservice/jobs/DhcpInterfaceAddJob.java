/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice.jobs;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MDSALDataStoreUtils;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.dhcpservice.DhcpExternalTunnelManager;
import org.opendaylight.netvirt.dhcpservice.DhcpManager;
import org.opendaylight.netvirt.dhcpservice.DhcpServiceUtils;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.dhcpservice.api.rev150710.InterfaceNameMacAddresses;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.dhcpservice.api.rev150710._interface.name.mac.addresses.InterfaceNameMacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.dhcpservice.api.rev150710._interface.name.mac.addresses.InterfaceNameMacAddressBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.dhcpservice.api.rev150710._interface.name.mac.addresses.InterfaceNameMacAddressKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpInterfaceAddJob implements Callable<List<ListenableFuture<Void>>> {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpInterfaceAddJob.class);
    DhcpManager dhcpManager;
    DhcpExternalTunnelManager dhcpExternalTunnelManager;
    DataBroker dataBroker;
    String interfaceName;
    BigInteger dpnId;
    IInterfaceManager interfaceManager;
    private static final FutureCallback<Void> DEFAULT_CALLBACK = new FutureCallback<Void>() {
        @Override
        public void onSuccess(Void result) {
            LOG.debug("Success in Datastore write operation");
        }

        @Override
        public void onFailure(Throwable error) {
            LOG.error("Error in Datastore write operation", error);
        }
    };

    public DhcpInterfaceAddJob(DhcpManager dhcpManager, DhcpExternalTunnelManager dhcpExternalTunnelManager,
                               DataBroker dataBroker, String interfaceName, BigInteger dpnId,
                               IInterfaceManager interfaceManager) {
        super();
        this.dhcpManager = dhcpManager;
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        this.dataBroker = dataBroker;
        this.interfaceName = interfaceName;
        this.dpnId = dpnId;
        this.interfaceManager = interfaceManager;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        List<ListenableFuture<Void>> futures = new ArrayList<>();
        LOG.trace("Received add DCN for interface {}, dpid {}", interfaceName, dpnId);
        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface iface =
                interfaceManager.getInterfaceInfoFromConfigDataStore(interfaceName);
        if (iface != null) {
            IfTunnel tunnelInterface = iface.getAugmentation(IfTunnel.class);
            if (tunnelInterface != null && !tunnelInterface.isInternal()) {
                IpAddress tunnelIp = tunnelInterface.getTunnelDestination();
                List<BigInteger> dpns = DhcpServiceUtils.getListOfDpns(dataBroker);
                if (dpns.contains(dpnId)) {
                    dhcpExternalTunnelManager.handleTunnelStateUp(tunnelIp, dpnId, futures);
                }
                return futures;
            }
        }
        if (!dpnId.equals(DhcpMConstants.INVALID_DPID)) {
            Port port = dhcpManager.getNeutronPort(interfaceName);
            Subnet subnet = dhcpManager.getNeutronSubnet(port);
            if (null != subnet && subnet.isEnableDhcp()) {
                LOG.info("DhcpInterfaceEventListener add isEnableDhcp" + subnet.isEnableDhcp());
                installDhcpEntries(interfaceName, dpnId, futures);
            }
        }
        return futures;
    }

    private void installDhcpEntries(String interfaceName, BigInteger dpId, List<ListenableFuture<Void>> futures) {
        String vmMacAddress = getAndUpdateVmMacAddress(interfaceName);
        WriteTransaction flowTx = dataBroker.newWriteOnlyTransaction();
        WriteTransaction bindServiceTx = dataBroker.newWriteOnlyTransaction();
        DhcpServiceUtils.bindDhcpService(interfaceName, NwConstants.DHCP_TABLE, bindServiceTx);
        dhcpManager.installDhcpEntries(dpId, vmMacAddress, flowTx);
        futures.add(bindServiceTx.submit());
        futures.add(flowTx.submit());
    }

    private String getAndUpdateVmMacAddress(String interfaceName) {
        InstanceIdentifier<InterfaceNameMacAddress> instanceIdentifier =
                InstanceIdentifier.builder(InterfaceNameMacAddresses.class)
                        .child(InterfaceNameMacAddress.class, new InterfaceNameMacAddressKey(interfaceName)).build();
        Optional<InterfaceNameMacAddress> existingEntry =
                MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, instanceIdentifier);
        if (!existingEntry.isPresent()) {
            LOG.trace("Entry for interface {} missing in InterfaceNameVmMacAddress map", interfaceName);
            String vmMacAddress = getNeutronMacAddress(interfaceName);
            if (vmMacAddress == null || vmMacAddress.isEmpty()) {
                return null;
            }
            LOG.trace("Updating InterfaceNameVmMacAddress map with {}, {}", interfaceName,vmMacAddress);
            InterfaceNameMacAddress interfaceNameMacAddress =
                    new InterfaceNameMacAddressBuilder()
                            .setKey(new InterfaceNameMacAddressKey(interfaceName))
                            .setInterfaceName(interfaceName).setMacAddress(vmMacAddress).build();
            MDSALDataStoreUtils.asyncUpdate(dataBroker, LogicalDatastoreType.OPERATIONAL, instanceIdentifier,
                    interfaceNameMacAddress, DEFAULT_CALLBACK);
            return vmMacAddress;
        }
        return existingEntry.get().getMacAddress();
    }

    private String getNeutronMacAddress(String interfaceName) {
        Port port = dhcpManager.getNeutronPort(interfaceName);
        if (port != null) {
            LOG.trace("Port found in neutron. Interface Name {}, port {}", interfaceName, port);
            return port.getMacAddress().getValue();
        }
        return null;
    }
}