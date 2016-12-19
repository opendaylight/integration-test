/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.jobs;

import com.google.common.collect.Lists;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.elan.l2gw.listeners.HwvtepRemoteMcastMacListener;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayMulticastUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.Devices;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The Class LogicalSwitchAddedWorker.
 */
public class LogicalSwitchAddedJob implements Callable<List<ListenableFuture<Void>>> {
    /** The logical switch name. */
    private String logicalSwitchName;

    /** The physical device. */
    private Devices physicalDevice;

    /** The l2 gateway device. */
    private L2GatewayDevice elanL2GwDevice;

    /** The default vlan id. */
    private Integer defaultVlanId;

    private static final Logger LOG = LoggerFactory.getLogger(LogicalSwitchAddedJob.class);

    private final DataBroker broker;
    private final ElanL2GatewayUtils elanL2GatewayUtils;
    private final ElanUtils elanUtils;
    private final ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils;

    public LogicalSwitchAddedJob(DataBroker dataBroker, ElanL2GatewayUtils elanL2GatewayUtils, ElanUtils elanUtils,
                                 ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils, String logicalSwitchName,
                                 Devices physicalDevice, L2GatewayDevice l2GatewayDevice,
                                 Integer defaultVlanId) {
        this.broker = dataBroker;
        this.elanL2GatewayUtils = elanL2GatewayUtils;
        this.elanUtils = elanUtils;
        this.elanL2GatewayMulticastUtils = elanL2GatewayMulticastUtils;
        this.logicalSwitchName = logicalSwitchName;
        this.physicalDevice = physicalDevice;
        this.elanL2GwDevice = l2GatewayDevice;
        this.defaultVlanId = defaultVlanId;
        LOG.debug("created logical switch added job for {} {}", logicalSwitchName, elanL2GwDevice.getHwvtepNodeId());
    }

    public String getJobKey() {
        return logicalSwitchName;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        LOG.debug("running logical switch added job for {} {}", logicalSwitchName,
                elanL2GwDevice.getHwvtepNodeId());
        List<ListenableFuture<Void>> futures = new ArrayList<>();
        String elan = ElanL2GatewayUtils.getElanFromLogicalSwitch(logicalSwitchName);

        LOG.info("creating vlan bindings for {} {}", logicalSwitchName, elanL2GwDevice.getHwvtepNodeId());
        futures.add(elanL2GatewayUtils.updateVlanBindingsInL2GatewayDevice(
            new NodeId(elanL2GwDevice.getHwvtepNodeId()), logicalSwitchName, physicalDevice, defaultVlanId));
        LOG.info("creating mast mac entries for {} {}", logicalSwitchName, elanL2GwDevice.getHwvtepNodeId());
        futures.add(elanL2GatewayMulticastUtils.handleMcastForElanL2GwDeviceAdd(logicalSwitchName, elanL2GwDevice));

        List<IpAddress> expectedPhyLocatorIps = Lists.newArrayList();
        HwvtepRemoteMcastMacListener list = new HwvtepRemoteMcastMacListener(broker,
                elanUtils, logicalSwitchName, elanL2GwDevice, expectedPhyLocatorIps,
            () -> {
                LOG.info("adding remote ucast macs for {} {}", logicalSwitchName,
                    elanL2GwDevice.getHwvtepNodeId());
                List<ListenableFuture<Void>> futures1 = new ArrayList<>();
                futures1.add(elanL2GatewayUtils.installElanMacsInL2GatewayDevice(
                    logicalSwitchName, elanL2GwDevice));
                return futures1;
            });

        return futures;
    }

}
