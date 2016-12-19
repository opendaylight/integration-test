/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.natservice.internal;

import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SubnetGwMacChangeListener
        extends AsyncDataTreeChangeListenerBase<VpnPortipToPort, SubnetGwMacChangeListener> {
    private static final Logger LOG = LoggerFactory.getLogger(SubnetGwMacChangeListener.class);

    private final DataBroker broker;
    private final INeutronVpnManager nvpnManager;
    private final ExternalNetworkGroupInstaller extNetworkInstaller;

    public SubnetGwMacChangeListener(final DataBroker broker, final INeutronVpnManager nvpnManager,
            final ExternalNetworkGroupInstaller extNetworkInstaller) {
        super(VpnPortipToPort.class, SubnetGwMacChangeListener.class);
        this.broker = broker;
        this.nvpnManager = nvpnManager;
        this.extNetworkInstaller = extNetworkInstaller;
    }

    public void start() {
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }

    @Override
    protected InstanceIdentifier<VpnPortipToPort> getWildCardPath() {
        return InstanceIdentifier.builder(NeutronVpnPortipPortData.class).child(VpnPortipToPort.class).build();
    }

    @Override
    protected void remove(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort vpnPortipToPort) {
    }

    @Override
    protected void update(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort origVpnPortipToPort,
            VpnPortipToPort updatedVpnPortipToPort) {
        handleSubnetGwIpChange(updatedVpnPortipToPort);
    }

    @Override
    protected void add(InstanceIdentifier<VpnPortipToPort> key, VpnPortipToPort vpnPortipToPort) {
        handleSubnetGwIpChange(vpnPortipToPort);
    }

    @Override
    protected SubnetGwMacChangeListener getDataTreeChangeListener() {
        return this;
    }

    private void handleSubnetGwIpChange(VpnPortipToPort vpnPortipToPort) {
        String macAddress = vpnPortipToPort.getMacAddress();
        if (macAddress == null) {
            LOG.trace("Mac address is null for VpnPortipToPort");
            return;
        }

        String fixedIp = vpnPortipToPort.getPortFixedip();
        if (fixedIp == null) {
            LOG.trace("Fixed ip is null for VpnPortipToPort");
            return;
        }

        try {
            InetAddress address = InetAddress.getByName(fixedIp);
            if (address instanceof Inet6Address) {
                // TODO: Revisit when IPv6 North-South communication support is added.
                LOG.debug("Skipping ipv6 address {}.", address);
                return;
            }
        } catch (UnknownHostException e) {
            LOG.warn("Invalid ip address {}", fixedIp, e);
            return;
        }

        for (Uuid subnetId : nvpnManager.getSubnetIdsForGatewayIp(new IpAddress(new Ipv4Address(fixedIp)))) {
            LOG.trace("Updating MAC resolution for GW ip {} to {}", fixedIp, macAddress);
            extNetworkInstaller.installExtNetGroupEntries(subnetId, macAddress);
        }
    }

}
