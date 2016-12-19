/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.List;
import java.util.concurrent.ConcurrentMap;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpLogicalSwitchListener
        extends AsyncDataTreeChangeListenerBase<LogicalSwitches, DhcpLogicalSwitchListener>
        implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpLogicalSwitchListener.class);

    private final DataBroker dataBroker;
    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;

    public DhcpLogicalSwitchListener(DhcpExternalTunnelManager dhcpManager, DataBroker dataBroker) {
        super(LogicalSwitches.class, DhcpLogicalSwitchListener.class);
        this.dhcpExternalTunnelManager = dhcpManager;
        this.dataBroker = dataBroker;
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.info("DhcpLogicalSwitchListener Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<LogicalSwitches> identifier,
            LogicalSwitches del) {
        LOG.trace("Received LogicalSwitch remove DCN");
        String elanInstanceName = del.getHwvtepNodeName().getValue();
        ConcurrentMap<String, L2GatewayDevice> devices = L2GatewayCacheUtils.getCache();
        String nodeId = identifier.firstKeyOf(Node.class).getNodeId().getValue();
        L2GatewayDevice targetDevice = null;
        for (L2GatewayDevice device : devices.values()) {
            if (nodeId.equals(device.getHwvtepNodeId())) {
                targetDevice = device;
                break;
            }
        }
        IpAddress tunnelIp;
        if (targetDevice != null) {
            LOG.trace("Logical Switch Device with name {} is found in L2GW cache", elanInstanceName);
            tunnelIp = targetDevice.getTunnelIp();
        } else {
            LOG.trace("Logical Switch Device with name {} is not present in L2GW cache", elanInstanceName);
            tunnelIp = getTunnelIp(nodeId);
        }
        if (tunnelIp == null) {
            LOG.trace("tunnelIp is not found");
            return;
        }
        handleLogicalSwitchRemove(elanInstanceName, tunnelIp);
    }

    private IpAddress getTunnelIp(String nodeId) {
        NodeKey nodeKey = new NodeKey(new NodeId(nodeId));
        InstanceIdentifier<HwvtepGlobalAugmentation> nodeIdentifier = InstanceIdentifier.create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID))
                .child(Node.class, nodeKey).augmentation(HwvtepGlobalAugmentation.class);
        Optional<HwvtepGlobalAugmentation> hwvtepNode =
                MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, nodeIdentifier);
        if (!hwvtepNode.isPresent()) {
            LOG.trace("Hwvtep node not found!");
            return null;
        }
        return hwvtepNode.get().getConnectionInfo().getRemoteIp();
    }

    @Override
    protected void update(InstanceIdentifier<LogicalSwitches> identifier,
            LogicalSwitches original, LogicalSwitches update) {
        LOG.trace("Received LogicalSwitch update DCN");
    }

    @Override
    protected void add(InstanceIdentifier<LogicalSwitches> identifier,
            LogicalSwitches add) {
        LOG.trace("Received LogicalSwitch add DCN");
        String elanInstanceName = add.getHwvtepNodeName().getValue();
        ConcurrentMap<String, L2GatewayDevice> devices  = L2GatewayCacheUtils.getCache();
        String nodeId = identifier.firstKeyOf(Node.class).getNodeId().getValue();
        L2GatewayDevice targetDevice = null;
        for (L2GatewayDevice device : devices.values()) {
            if (nodeId.equals(device.getHwvtepNodeId())) {
                targetDevice = device;
                break;
            }
        }
        if (targetDevice == null) {
            LOG.error("Logical Switch Device with name {} is not present in L2GW cache", elanInstanceName);
            return;
        }
        IpAddress tunnelIp = targetDevice.getTunnelIp();
        handleLogicalSwitchAdd(elanInstanceName, tunnelIp);
    }

    private void handleLogicalSwitchRemove(String elanInstanceName, IpAddress tunnelIp) {
        BigInteger designatedDpnId;
        designatedDpnId = dhcpExternalTunnelManager.readDesignatedSwitchesForExternalTunnel(tunnelIp, elanInstanceName);
        if (designatedDpnId == null) {
            LOG.info("Could not find designated DPN ID elanInstanceName {}, tunnelIp {}", elanInstanceName, tunnelIp);
            return;
        }
        dhcpExternalTunnelManager.removeDesignatedSwitchForExternalTunnel(designatedDpnId, tunnelIp, elanInstanceName);
    }

    private void handleLogicalSwitchAdd(String elanInstanceName, IpAddress tunnelIp) {
        List<BigInteger> dpns = DhcpServiceUtils.getListOfDpns(dataBroker);
        BigInteger designatedDpnId;
        designatedDpnId = dhcpExternalTunnelManager.designateDpnId(tunnelIp, elanInstanceName, dpns);
        if (designatedDpnId == null || designatedDpnId.equals(DhcpMConstants.INVALID_DPID)) {
            LOG.info("Unable to designate a DPN");
            return;
        }
    }

    @Override
    protected InstanceIdentifier<LogicalSwitches> getWildCardPath() {
        return InstanceIdentifier.create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID))
                .child(Node.class).augmentation(HwvtepGlobalAugmentation.class)
                .child(LogicalSwitches.class);
    }

    @Override
    protected DhcpLogicalSwitchListener getDataTreeChangeListener() {
        return DhcpLogicalSwitchListener.this;
    }
}