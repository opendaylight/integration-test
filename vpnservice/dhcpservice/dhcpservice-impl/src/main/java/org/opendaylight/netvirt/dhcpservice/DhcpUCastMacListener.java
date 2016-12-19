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
import org.apache.commons.lang3.tuple.ImmutablePair;
import org.apache.commons.lang3.tuple.Pair;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpUCastMacListener
        extends AsyncClusteredDataTreeChangeListenerBase<LocalUcastMacs, DhcpUCastMacListener>
        implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpUCastMacListener.class);

    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;
    private final DhcpManager dhcpManager;
    private final DataBroker broker;

    public DhcpUCastMacListener(DhcpManager dhcpManager,DhcpExternalTunnelManager dhcpExtTunnelMgr,
                                DataBroker dataBroker) {
        super(LocalUcastMacs.class, DhcpUCastMacListener.class);
        this.broker = dataBroker;
        this.dhcpExternalTunnelManager = dhcpExtTunnelMgr;
        this.dhcpManager = dhcpManager;
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }

    @Override
    protected InstanceIdentifier<LocalUcastMacs> getWildCardPath() {
        return InstanceIdentifier.create(NetworkTopology.class).child(Topology.class).child(Node.class)
                .augmentation(HwvtepGlobalAugmentation.class).child(LocalUcastMacs.class);
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.info("DhcpUCastMacListener Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<LocalUcastMacs> identifier,
            LocalUcastMacs del) {
        // Flow removal for table 18 is handled in Neutron Port delete.
        //remove the new CR-DHCP
        NodeId torNodeId = identifier.firstKeyOf(Node.class).getNodeId();
        LogicalSwitches logicalSwitch = getLogicalSwitches(del);
        if (null == logicalSwitch) {
            LOG.error("DhcpUCastMacListener remove :Logical Switch ref doesn't have data {}", logicalSwitch);
            return;
        }
        String elanInstanceName = logicalSwitch.getHwvtepNodeName().getValue();
        L2GatewayDevice device = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanInstanceName, torNodeId.getValue());
        if (device == null) {
            LOG.error("Logical Switch Device with name {} is not present in L2GWCONN cache", elanInstanceName);
            return;
        }
        IpAddress tunnelIp = device.getTunnelIp();
        Pair<IpAddress, String> tunnelIpElanName = new ImmutablePair<IpAddress, String>(tunnelIp, elanInstanceName);
        dhcpExternalTunnelManager.removeFromAvailableCache(tunnelIpElanName);
    }

    @Override
    protected void update(InstanceIdentifier<LocalUcastMacs> identifier,
            LocalUcastMacs original, LocalUcastMacs update) {
        // TODO Auto-generated method stub

    }

    @Override
    protected void add(InstanceIdentifier<LocalUcastMacs> identifier,
            LocalUcastMacs add) {
        NodeId torNodeId = identifier.firstKeyOf(Node.class).getNodeId();
        InstanceIdentifier<LogicalSwitches> logicalSwitchRef =
                (InstanceIdentifier<LogicalSwitches>) add.getLogicalSwitchRef().getValue();
        Optional<LogicalSwitches> logicalSwitchOptional =
                MDSALUtil.read(broker, LogicalDatastoreType.OPERATIONAL, logicalSwitchRef);
        if ( !logicalSwitchOptional.isPresent() ) {
            LOG.error("Logical Switch ref doesn't have data {}", logicalSwitchRef);
            return;
        }
        LogicalSwitches logicalSwitch = logicalSwitchOptional.get();
        String elanInstanceName = logicalSwitch.getHwvtepNodeName().getValue();
        String macAddress = add.getMacEntryKey().getValue();
        BigInteger vni = new BigInteger(logicalSwitch.getTunnelKey());
        Port port = dhcpExternalTunnelManager.readVniMacToPortCache(vni, macAddress);
        if (port == null) {
            LOG.trace("No neutron port created for macAddress {}, tunnelKey {}", macAddress, vni);
            return;
        }
        L2GatewayDevice device = ElanL2GwCacheUtils.getL2GatewayDeviceFromCache(elanInstanceName, torNodeId.getValue());
        if (device == null) {
            LOG.error("Logical Switch Device with name {} is not present in L2GWCONN cache", elanInstanceName);
            return;
        }
        IpAddress tunnelIp = device.getTunnelIp();
        Subnet subnet = dhcpManager.getNeutronSubnet(port);
        if (null != subnet && !subnet.isEnableDhcp()) {
            dhcpExternalTunnelManager.updateExistingVMTunnelIPCache(tunnelIp, elanInstanceName, macAddress);
            LOG.warn("DhcpUCastMacListener add: flag for the subnetId {} is False so Table 18 entries are not added",
                     subnet.getUuid());
            return;
        }
        BigInteger designatedDpnId =
                dhcpExternalTunnelManager.readDesignatedSwitchesForExternalTunnel(tunnelIp, elanInstanceName);
        if (designatedDpnId == null || designatedDpnId.equals(DhcpMConstants.INVALID_DPID)) {
            LOG.trace("Unable to install flows for macAddress {}. TunnelIp {}, elanInstanceName {}, designatedDpn {} ",
                    macAddress, tunnelIp, elanInstanceName, designatedDpnId);
            dhcpExternalTunnelManager.updateLocalCache(tunnelIp, elanInstanceName, macAddress);
            return;
        }
        dhcpExternalTunnelManager.installDhcpFlowsForVms(tunnelIp, elanInstanceName,
                DhcpServiceUtils.getListOfDpns(broker), designatedDpnId, macAddress);
    }

    private LogicalSwitches getLogicalSwitches(LocalUcastMacs ucastMacs) {
        LogicalSwitches logicalSwitch = null;
        InstanceIdentifier<LogicalSwitches> logicalSwitchRef =
                (InstanceIdentifier<LogicalSwitches>)ucastMacs.getLogicalSwitchRef().getValue();
        Optional<LogicalSwitches> logicalSwitchOptional =
                MDSALUtil.read(broker, LogicalDatastoreType.OPERATIONAL,
                logicalSwitchRef);
        if (logicalSwitchOptional.isPresent()) {
            logicalSwitch = logicalSwitchOptional.get();
        }
        return logicalSwitch;
    }

    @Override
    protected DhcpUCastMacListener getDataTreeChangeListener() {
        return DhcpUCastMacListener.this;
    }
}