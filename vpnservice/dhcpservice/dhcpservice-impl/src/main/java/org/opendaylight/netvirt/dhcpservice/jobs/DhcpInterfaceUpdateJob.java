/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice.jobs;

import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.netvirt.dhcpservice.DhcpExternalTunnelManager;
import org.opendaylight.netvirt.dhcpservice.DhcpManager;
import org.opendaylight.netvirt.dhcpservice.DhcpServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.Tunnel;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface.OperStatus;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfTunnel;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpInterfaceUpdateJob implements Callable<List<ListenableFuture<Void>>> {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpInterfaceUpdateJob.class);
    DhcpManager dhcpManager;
    DhcpExternalTunnelManager dhcpExternalTunnelManager;
    DataBroker dataBroker;
    String interfaceName;
    BigInteger dpnId;
    OperStatus operStatus;
    IInterfaceManager interfaceManager;

    public DhcpInterfaceUpdateJob(DhcpManager dhcpManager, DhcpExternalTunnelManager dhcpExternalTunnelManager,
                                  DataBroker dataBroker, String interfaceName, BigInteger dpnId,
                                  OperStatus operStatus, IInterfaceManager interfaceManager) {
        super();
        this.dhcpManager = dhcpManager;
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        this.dataBroker = dataBroker;
        this.interfaceName = interfaceName;
        this.dpnId = dpnId;
        this.operStatus = operStatus;
        this.interfaceManager = interfaceManager;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        List<ListenableFuture<Void>> futures = new ArrayList<>();
        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface iface =
                interfaceManager.getInterfaceInfoFromConfigDataStore(interfaceName);
        if (iface == null) {
            LOG.trace("Interface {} is not present in the config DS", interfaceName);
            return futures;
        }
        if (Tunnel.class.equals(iface.getType())) {
            IfTunnel tunnelInterface = iface.getAugmentation(IfTunnel.class);
            if (tunnelInterface != null && !tunnelInterface.isInternal()) {
                IpAddress tunnelIp = tunnelInterface.getTunnelDestination();
                List<BigInteger> dpns = DhcpServiceUtils.getListOfDpns(dataBroker);
                if (dpns.contains(dpnId)) {
                    if (operStatus == OperStatus.Down) {
                        dhcpExternalTunnelManager.handleTunnelStateDown(tunnelIp, dpnId, futures);
                    } else if (operStatus == OperStatus.Up) {
                        dhcpExternalTunnelManager.handleTunnelStateUp(tunnelIp, dpnId, futures);
                    }
                }
            }
        }
        return futures;
    }
}