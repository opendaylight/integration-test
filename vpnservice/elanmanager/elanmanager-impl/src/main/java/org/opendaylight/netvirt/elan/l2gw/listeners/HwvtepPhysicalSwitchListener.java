/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elan.l2gw.listeners;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.ClusteredDataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.genius.datastoreutils.hwvtep.HwvtepAbstractDataTreeChangeListener;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.utils.hwvtep.HwvtepHACache;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundUtils;
import org.opendaylight.netvirt.elan.l2gw.ha.listeners.HAOpClusteredListener;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.L2GatewayConnectionUtils;
import org.opendaylight.netvirt.elan.utils.ElanClusterUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.l2gatewayconnections.L2gatewayConnection;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.TunnelIps;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Listener to handle physical switch updates.
 */
public class HwvtepPhysicalSwitchListener
        extends HwvtepAbstractDataTreeChangeListener<PhysicalSwitchAugmentation, HwvtepPhysicalSwitchListener>
        implements ClusteredDataTreeChangeListener<PhysicalSwitchAugmentation>, AutoCloseable {

    /** The Constant LOG. */
    private static final Logger LOG = LoggerFactory.getLogger(HwvtepPhysicalSwitchListener.class);

    /** The data broker. */
    private final DataBroker dataBroker;

    /** The itm rpc service. */
    private final ItmRpcService itmRpcService;

    /** The entity ownership service. */
    private final EntityOwnershipService entityOwnershipService;

    private final L2GatewayConnectionUtils l2GatewayConnectionUtils;

    private final HwvtepHACache hwvtepHACache = HwvtepHACache.getInstance();

    /**
     * Instantiates a new hwvtep physical switch listener.
     *
     * @param dataBroker
     *            the data broker
     * @param itmRpcService itm rpc
     * @param entityOwnershipService entity ownership service
     * @param elanUtils elan utils
     */
    public HwvtepPhysicalSwitchListener(final DataBroker dataBroker, ItmRpcService itmRpcService,
                                        EntityOwnershipService entityOwnershipService,
                                        ElanUtils elanUtils) {
        super(PhysicalSwitchAugmentation.class, HwvtepPhysicalSwitchListener.class);
        this.dataBroker = dataBroker;
        this.itmRpcService = itmRpcService;
        this.entityOwnershipService = entityOwnershipService;
        this.l2GatewayConnectionUtils = elanUtils.getL2GatewayConnectionUtils();
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<PhysicalSwitchAugmentation> getWildCardPath() {
        return InstanceIdentifier.create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID)).child(Node.class)
                .augmentation(PhysicalSwitchAugmentation.class);
    }

    @Override
    protected HwvtepPhysicalSwitchListener getDataTreeChangeListener() {
        return HwvtepPhysicalSwitchListener.this;
    }

    @Override
    protected void removed(InstanceIdentifier<PhysicalSwitchAugmentation> identifier,
            PhysicalSwitchAugmentation phySwitchDeleted) {
        NodeId nodeId = getNodeId(identifier);
        String psName = phySwitchDeleted.getHwvtepNodeName().getValue();
        LOG.info("Received physical switch {} removed event for node {}", psName, nodeId.getValue());

        L2GatewayDevice l2GwDevice = L2GatewayCacheUtils.getL2DeviceFromCache(psName);
        if (l2GwDevice != null) {
            if (!L2GatewayConnectionUtils.isGatewayAssociatedToL2Device(l2GwDevice)) {
                L2GatewayCacheUtils.removeL2DeviceFromCache(psName);
                LOG.debug("{} details removed from L2Gateway Cache", psName);
                InstanceIdentifier<Node> iid =
                        HwvtepSouthboundUtils.createInstanceIdentifier(new NodeId(l2GwDevice.getHwvtepNodeId()));
                boolean deleteNode = true;
                if (hwvtepHACache.isHAParentNode(iid)) {
                    Optional<Node> nodeOptional = null;
                    try {
                        nodeOptional = dataBroker.newReadWriteTransaction().read(
                                LogicalDatastoreType.CONFIGURATION, iid).checkedGet();
                    } catch (ReadFailedException e) {
                        nodeOptional = Optional.absent();
                    }
                    if (nodeOptional.isPresent()) {
                        Node node = nodeOptional.get();
                        NodeBuilder nodeBuilder = new NodeBuilder();
                        HwvtepGlobalAugmentationBuilder builder = new HwvtepGlobalAugmentationBuilder();
                        HwvtepGlobalAugmentation orig = node.getAugmentation(HwvtepGlobalAugmentation.class);
                        if (orig != null) {
                            deleteNode = false;
                            builder.setSwitches(orig.getSwitches());
                            builder.setManagers(orig.getManagers());
                            nodeBuilder.setKey(node.getKey());
                            nodeBuilder.setNodeId(node.getNodeId());
                            nodeBuilder.addAugmentation(HwvtepGlobalAugmentation.class, builder.build());
                            MDSALUtil.syncWrite(this.dataBroker, LogicalDatastoreType.CONFIGURATION,
                                    iid, nodeBuilder.build());
                        }
                    }
                }
                if (deleteNode) {
                    MDSALUtil.syncDelete(this.dataBroker, LogicalDatastoreType.CONFIGURATION,
                            HwvtepSouthboundUtils.createInstanceIdentifier(new NodeId(l2GwDevice.getHwvtepNodeId())));
                }
                MDSALUtil.syncDelete(this.dataBroker, LogicalDatastoreType.CONFIGURATION,
                        HwvtepSouthboundUtils.createInstanceIdentifier(nodeId));
            } else {
                LOG.debug("{} details are not removed from L2Gateway Cache as it has L2Gateway reference", psName);
            }

            l2GwDevice.setConnected(false);
            ElanL2GwCacheUtils.removeL2GatewayDeviceFromAllElanCache(psName);
        } else {
            LOG.error("Unable to find L2 Gateway details for {}", psName);
        }
    }

    @Override
    protected void updated(InstanceIdentifier<PhysicalSwitchAugmentation> identifier,
            PhysicalSwitchAugmentation phySwitchBefore, PhysicalSwitchAugmentation phySwitchAfter) {
        NodeId nodeId = getNodeId(identifier);
        LOG.trace("Received PhysicalSwitch Update Event for node {}: PhysicalSwitch Before: {}, "
                + "PhysicalSwitch After: {}", nodeId.getValue(), phySwitchBefore, phySwitchAfter);
        String psName = phySwitchBefore.getHwvtepNodeName().getValue();
        LOG.info("Received physical switch {} update event for node {}", psName, nodeId.getValue());

        if (isTunnelIpNewlyConfigured(phySwitchBefore, phySwitchAfter)) {
            final L2GatewayDevice l2GwDevice =
                    updateL2GatewayCache(psName, phySwitchAfter.getManagedBy(), phySwitchAfter.getTunnelIps());
            handleAdd(l2GwDevice);
        } else {
            LOG.debug("Other updates in physical switch {} for node {}", psName, nodeId.getValue());
            // TODO: handle tunnel ip change
        }
    }

    @Override
    protected void added(InstanceIdentifier<PhysicalSwitchAugmentation> identifier,
            final PhysicalSwitchAugmentation phySwitchAdded) {
        if (phySwitchAdded.getManagedBy() == null) {
            LOG.info("managed by field is missing ");
            return;
        }
        InstanceIdentifier<Node> globalNodeId = (InstanceIdentifier<Node>)phySwitchAdded.getManagedBy().getValue();
        NodeId nodeId = getNodeId(identifier);
        final String psName = phySwitchAdded.getHwvtepNodeName().getValue();
        LOG.info("Received physical switch {} added event received for node {}", psName, nodeId.getValue());

        try {
            if (updateHACacheIfHANode(dataBroker, globalNodeId)) {
                updateL2GatewayCache(psName, new HwvtepGlobalRef(hwvtepHACache.getParent(globalNodeId)),
                        phySwitchAdded.getTunnelIps());
                return;
            }
        } catch (ExecutionException e) {
            LOG.error("Failed to read operational node {}", globalNodeId);
            //TODO add retry mechanism
        } catch (InterruptedException e) {
            LOG.error("Failed to read operational node {}", globalNodeId);
            //TODO add retry mechanism
        }
        L2GatewayDevice l2GwDevice =
                updateL2GatewayCache(psName, phySwitchAdded.getManagedBy(), phySwitchAdded.getTunnelIps());
        handleAdd(l2GwDevice);
    }

    boolean updateHACacheIfHANode(DataBroker broker, InstanceIdentifier<Node> globalNodeId)
            throws ExecutionException, InterruptedException {
        ReadWriteTransaction transaction = broker.newReadWriteTransaction();
        Node node = transaction.read(LogicalDatastoreType.OPERATIONAL, globalNodeId).get().get();
        HAOpClusteredListener.addToCacheIfHAChildNode(globalNodeId, node);
        return hwvtepHACache.isHAEnabledDevice(globalNodeId);
    }

    /**
     * Handle add.
     *
     * @param l2GwDevice
     *            the l2 gw device
     */
    private void handleAdd(L2GatewayDevice l2GwDevice) {
        final String psName = l2GwDevice.getDeviceName();
        final String hwvtepNodeId = l2GwDevice.getHwvtepNodeId();
        Set<IpAddress> tunnelIps = l2GwDevice.getTunnelIps();
        if (tunnelIps != null) {
            for (final IpAddress tunnelIpAddr : tunnelIps) {
                if (L2GatewayConnectionUtils.isGatewayAssociatedToL2Device(l2GwDevice)) {
                    LOG.debug("L2Gateway {} associated for {} physical switch; creating ITM tunnels for {}",
                            l2GwDevice.getL2GatewayIds(), psName, tunnelIpAddr);

                    // It's a pre-provision scenario
                    // Initiate ITM tunnel creation
                    ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService,
                            "handling Physical Switch add create itm tunnels ",
                            new Callable<List<ListenableFuture<Void>>>() {
                                @Override
                                public List<ListenableFuture<Void>> call() throws Exception {
                                    ElanL2GatewayUtils.createItmTunnels(itmRpcService,
                                            hwvtepNodeId, psName, tunnelIpAddr);
                                    return Collections.emptyList();
                                }
                            });

                    // Initiate Logical switch creation for associated L2
                    // Gateway Connections
                    List<L2gatewayConnection> l2GwConns = L2GatewayConnectionUtils.getAssociatedL2GwConnections(
                            dataBroker, l2GwDevice.getL2GatewayIds());
                    if (l2GwConns != null) {
                        LOG.debug("L2GatewayConnections associated for {} physical switch", psName);

                        for (L2gatewayConnection l2GwConn : l2GwConns) {
                            LOG.trace("L2GatewayConnection {} changes executed on physical switch {}",
                                    l2GwConn.getL2gatewayId(), psName);

                            l2GatewayConnectionUtils.addL2GatewayConnection(l2GwConn, psName);
                        }
                    }
                    // TODO handle deleted l2gw connections while the device is
                    // offline
                }
            }
        }
    }


    private L2GatewayDevice updateL2GatewayCache(String psName, HwvtepGlobalRef globalRef, List<TunnelIps> tunnelIps) {
        L2GatewayDevice l2GwDevice = L2GatewayCacheUtils.getL2DeviceFromCache(psName);
        if (l2GwDevice == null) {
            LOG.debug("{} details are not present in L2Gateway Cache; added now!", psName);

            l2GwDevice = new L2GatewayDevice();
            l2GwDevice.setDeviceName(psName);
            L2GatewayCacheUtils.addL2DeviceToCache(psName, l2GwDevice);
        } else {
            LOG.debug("{} details are present in L2Gateway Cache and same reference used for updates", psName);
        }
        l2GwDevice.setConnected(true);
        String hwvtepNodeId = getManagedByNodeId(globalRef);
        l2GwDevice.setHwvtepNodeId(hwvtepNodeId);

        if (tunnelIps != null && !tunnelIps.isEmpty()) {
            for (TunnelIps tunnelIp : tunnelIps) {
                IpAddress tunnelIpAddr = tunnelIp.getTunnelIpsKey();
                l2GwDevice.addTunnelIp(tunnelIpAddr);
            }
        }
        LOG.trace("L2Gateway cache updated with below details: {}", l2GwDevice);
        return l2GwDevice;
    }

    /**
     * Gets the managed by node id.
     *
     * @param globalRef
     *            the global ref
     * @return the managed by node id
     */
    private String getManagedByNodeId(HwvtepGlobalRef globalRef) {
        InstanceIdentifier<?> instId = globalRef.getValue();
        return instId.firstKeyOf(Node.class).getNodeId().getValue();
    }

    /**
     * Gets the node id.
     *
     * @param identifier
     *            the identifier
     * @return the node id
     */
    private NodeId getNodeId(InstanceIdentifier<PhysicalSwitchAugmentation> identifier) {
        return identifier.firstKeyOf(Node.class).getNodeId();
    }

    /**
     * Checks if is tunnel ip newly configured.
     *
     * @param phySwitchBefore
     *            the phy switch before
     * @param phySwitchAfter
     *            the phy switch after
     * @return true, if is tunnel ip newly configured
     */
    private boolean isTunnelIpNewlyConfigured(PhysicalSwitchAugmentation phySwitchBefore,
            PhysicalSwitchAugmentation phySwitchAfter) {
        return (phySwitchBefore.getTunnelIps() == null || phySwitchBefore.getTunnelIps().isEmpty())
                && phySwitchAfter.getTunnelIps() != null && !phySwitchAfter.getTunnelIps().isEmpty();
    }

}
