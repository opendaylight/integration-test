/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.jobs;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayMulticastUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.Devices;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
* Created by ekvsver on 4/15/2016.
*/
public class DisAssociateHwvtepFromElanJob implements Callable<List<ListenableFuture<Void>>> {
    private static final Logger LOG = LoggerFactory.getLogger(DisAssociateHwvtepFromElanJob.class);

    private final DataBroker broker;
    private final ElanL2GatewayUtils elanL2GatewayUtils;
    private final ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils;
    private final L2GatewayDevice l2GatewayDevice;
    private final String elanName;
    private final Devices l2Device;
    private final Integer defaultVlan;
    private final boolean isLastL2GwConnDeleted;

    public DisAssociateHwvtepFromElanJob(DataBroker broker, ElanL2GatewayUtils elanL2GatewayUtils,
                                         ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils,
                                         L2GatewayDevice l2GatewayDevice,  String elanName,
                                         Devices l2Device, Integer defaultVlan, boolean isLastL2GwConnDeleted) {
        this.broker = broker;
        this.elanL2GatewayUtils = elanL2GatewayUtils;
        this.elanL2GatewayMulticastUtils = elanL2GatewayMulticastUtils;
        this.l2GatewayDevice = l2GatewayDevice;
        this.elanName = elanName;
        this.l2Device = l2Device;
        this.defaultVlan = defaultVlan;
        this.isLastL2GwConnDeleted = isLastL2GwConnDeleted;
        LOG.info("created disassosiate l2gw connection job for {} {}", elanName ,
                l2GatewayDevice.getHwvtepNodeId());
    }

    public String getJobKey() {
        return elanName;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        String strHwvtepNodeId = l2GatewayDevice.getHwvtepNodeId();
        NodeId hwvtepNodeId = new NodeId(strHwvtepNodeId);
        LOG.info("running disassosiate l2gw connection job for {} {}", elanName, strHwvtepNodeId);

        List<ListenableFuture<Void>> futures = new ArrayList<>();

        // Remove remote MACs and vlan mappings from physical port
        // Once all above configurations are deleted, delete logical
        // switch
        LOG.info("delete vlan bindings for {} {}", elanName, strHwvtepNodeId);
        futures.add(elanL2GatewayUtils.deleteVlanBindingsFromL2GatewayDevice(hwvtepNodeId, l2Device, defaultVlan));

        if (isLastL2GwConnDeleted) {
            LOG.info("delete remote ucast macs {} {}", elanName, strHwvtepNodeId);
            futures.add(elanL2GatewayUtils.deleteElanMacsFromL2GatewayDevice(l2GatewayDevice, elanName));

            LOG.info("delete mcast mac for {} {}", elanName, strHwvtepNodeId);
            futures.addAll(elanL2GatewayMulticastUtils.handleMcastForElanL2GwDeviceDelete(this.elanName,
                    l2GatewayDevice));

            LOG.info("delete local ucast macs {} {}", elanName, strHwvtepNodeId);
            futures.addAll(elanL2GatewayUtils.deleteL2GwDeviceUcastLocalMacsFromElan(l2GatewayDevice, elanName));

            LOG.info("scheduled delete logical switch {} {}", elanName, strHwvtepNodeId);
            elanL2GatewayUtils.scheduleDeleteLogicalSwitch(hwvtepNodeId,
                    ElanL2GatewayUtils.getLogicalSwitchFromElan(elanName));
        }

        return futures;
    }
}
