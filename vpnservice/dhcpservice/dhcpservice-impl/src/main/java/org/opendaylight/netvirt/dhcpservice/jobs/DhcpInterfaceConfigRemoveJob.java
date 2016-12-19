/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice.jobs;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.dhcpservice.DhcpExternalTunnelManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfTunnel;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.ParentRefs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpInterfaceConfigRemoveJob implements Callable<List<ListenableFuture<Void>>> {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpInterfaceConfigRemoveJob.class);
    DhcpExternalTunnelManager dhcpExternalTunnelManager;
    DataBroker dataBroker;
    Interface iface;

    public DhcpInterfaceConfigRemoveJob(DhcpExternalTunnelManager dhcpExternalTunnelManager, DataBroker dataBroker,
            Interface iface) {
        super();
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        this.dataBroker = dataBroker;
        this.iface = iface;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        List<ListenableFuture<Void>> futures = new ArrayList<>();
        IfTunnel tunnelInterface = iface.getAugmentation(IfTunnel.class);
        if (tunnelInterface != null && !tunnelInterface.isInternal()) {
            IpAddress tunnelIp = tunnelInterface.getTunnelDestination();
            ParentRefs interfce = iface.getAugmentation(ParentRefs.class);
            if (interfce != null) {
                LOG.trace("Calling handleTunnelStateDown for tunnelIp {} and interface {}", tunnelIp, iface.getName());
                dhcpExternalTunnelManager.handleTunnelStateDown(tunnelIp,
                        interfce.getDatapathNodeIdentifier(), futures);
            }
        }
        return futures;
    }
}