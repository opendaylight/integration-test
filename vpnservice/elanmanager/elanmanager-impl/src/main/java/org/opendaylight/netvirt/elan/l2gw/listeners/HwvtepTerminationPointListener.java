/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.listeners;

import com.google.common.collect.Lists;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.hwvtep.HwvtepClusteredDataTreeChangeListener;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundUtils;
import org.opendaylight.genius.utils.hwvtep.HwvtepUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayUtils;
import org.opendaylight.netvirt.elan.l2gw.utils.L2GatewayConnectionUtils;
import org.opendaylight.netvirt.elan.utils.ElanClusterUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.Devices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.devices.Interfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.l2gatewayconnections.L2gatewayConnection;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateways.attributes.l2gateways.L2gateway;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalPortAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindings;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Listener for physical locator presence in operational datastore.
 */
public class HwvtepTerminationPointListener
        extends HwvtepClusteredDataTreeChangeListener<TerminationPoint, HwvtepTerminationPointListener>
        implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(HwvtepTerminationPointListener.class);

    private DataBroker broker;
    private ListenerRegistration<DataChangeListener> lstnerRegistration;
    private final ElanL2GatewayUtils elanL2GatewayUtils;
    private final EntityOwnershipService entityOwnershipService;

    public HwvtepTerminationPointListener(DataBroker broker, ElanUtils elanUtils,
                                          EntityOwnershipService entityOwnershipService) {
        super(TerminationPoint.class, HwvtepTerminationPointListener.class);

        this.broker = broker;
        this.elanL2GatewayUtils = elanUtils.getElanL2GatewayUtils();
        this.entityOwnershipService = entityOwnershipService;
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
        LOG.debug("created HwvtepTerminationPointListener");
    }

    static Map<InstanceIdentifier<TerminationPoint>, List<Runnable>> waitingJobsList = new ConcurrentHashMap<>();
    static Map<InstanceIdentifier<TerminationPoint>, Boolean> teps = new ConcurrentHashMap<>();

    public static void runJobAfterPhysicalLocatorIsAvialable(InstanceIdentifier<TerminationPoint> key,
            Runnable runnable) {
        if (teps.get(key) != null) {
            LOG.debug("physical locator already available {} running job ", key);
            runnable.run();
            return;
        }
        synchronized (HwvtepTerminationPointListener.class) {
            List<Runnable> list = waitingJobsList.get(key);
            if (list == null) {
                waitingJobsList.put(key, Lists.newArrayList(runnable));
            } else {
                list.add(runnable);
            }
            LOG.debug("added the job to wait list of physical locator {}", key);
        }
    }

    @Override
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void close() throws Exception {
        if (lstnerRegistration != null) {
            try {
                // TODO use https://git.opendaylight.org/gerrit/#/c/44145/ when merged, and remove @SuppressWarnings
                lstnerRegistration.close();
            } catch (final Exception e) {
                LOG.error("Error when cleaning up DataChangeListener.", e);
            }
            lstnerRegistration = null;
        }
    }

    @Override
    protected void removed(InstanceIdentifier<TerminationPoint> identifier, TerminationPoint del) {
        LOG.trace("physical locator removed {}", identifier);
        teps.remove(identifier);
    }

    @Override
    protected void updated(InstanceIdentifier<TerminationPoint> identifier, TerminationPoint original,
            TerminationPoint update) {
        LOG.trace("physical locator available {}", identifier);
    }

    @Override
    protected void added(InstanceIdentifier<TerminationPoint> identifier, final TerminationPoint add) {
        final HwvtepPhysicalPortAugmentation portAugmentation =
                add.getAugmentation(HwvtepPhysicalPortAugmentation.class);
        if (portAugmentation != null) {
            final NodeId nodeId = identifier.firstIdentifierOf(Node.class).firstKeyOf(Node.class).getNodeId();
            ElanClusterUtils.runOnlyInLeaderNode(entityOwnershipService, HwvtepSouthboundConstants.ELAN_ENTITY_NAME,
                    "handling Physical Switch add", () -> handlePortAdded(portAugmentation, add, nodeId));
            return;
        }

        LOG.trace("physical locator available {}", identifier);
        teps.put(identifier, true);
        List<Runnable> runnableList = null;
        synchronized (HwvtepTerminationPointListener.class) {
            runnableList = waitingJobsList.get(identifier);
            waitingJobsList.remove(identifier);
        }
        if (runnableList != null) {
            LOG.debug("physical locator available {} running jobs ", identifier);
            for (Runnable r : runnableList) {
                r.run();
            }
        } else {
            LOG.debug("no jobs are waiting for physical locator {}", identifier);
        }
    }

    @Override
    protected InstanceIdentifier<TerminationPoint> getWildCardPath() {
        return InstanceIdentifier.create(NetworkTopology.class).child(Topology.class).child(Node.class)
                .child(TerminationPoint.class);
    }

    @Override
    protected HwvtepTerminationPointListener getDataTreeChangeListener() {
        return this;
    }

    private List<ListenableFuture<Void>> handlePortAdded(HwvtepPhysicalPortAugmentation portAugmentation,
            TerminationPoint portAdded, NodeId psNodeId) {
        Node psNode = HwvtepUtils.getHwVtepNode(broker, LogicalDatastoreType.OPERATIONAL, psNodeId);
        if (psNode != null) {
            String psName = psNode.getAugmentation(PhysicalSwitchAugmentation.class).getHwvtepNodeName().getValue();
            L2GatewayDevice l2GwDevice = L2GatewayCacheUtils.getL2DeviceFromCache(psName);
            if (l2GwDevice != null) {
                if (isL2GatewayConfigured(l2GwDevice)) {
                    List<L2gatewayConnection> l2GwConns = L2GatewayConnectionUtils.getAssociatedL2GwConnections(broker,
                            l2GwDevice.getL2GatewayIds());
                    if (l2GwConns != null) {
                        String newPortId = portAdded.getTpId().getValue();
                        NodeId hwvtepNodeId = new NodeId(l2GwDevice.getHwvtepNodeId());
                        List<VlanBindings> vlanBindings = getVlanBindings(l2GwConns, hwvtepNodeId, psName, newPortId);
                        List<ListenableFuture<Void>> futures = new ArrayList<>();
                        futures.add(elanL2GatewayUtils.updateVlanBindingsInL2GatewayDevice(hwvtepNodeId, psName,
                                newPortId, vlanBindings));
                        return futures;
                    }
                }
            } else {
                LOG.error("{} details are not present in L2Gateway Cache", psName);
            }
        } else {
            LOG.error("{} entry not in config datastore", psNodeId);
        }
        return Collections.emptyList();
    }

    private List<VlanBindings> getVlanBindings(List<L2gatewayConnection> l2GwConns, NodeId hwvtepNodeId, String psName,
            String newPortId) {
        List<VlanBindings> vlanBindings = new ArrayList<>();
        for (L2gatewayConnection l2GwConn : l2GwConns) {
            L2gateway l2Gateway = L2GatewayConnectionUtils.getNeutronL2gateway(broker, l2GwConn.getL2gatewayId());
            if (l2Gateway == null) {
                LOG.error("L2Gateway with id {} is not present", l2GwConn.getL2gatewayId().getValue());
            } else {
                String logicalSwitchName = ElanL2GatewayUtils.getLogicalSwitchFromElan(
                        l2GwConn.getNetworkId().getValue());
                List<Devices> l2Devices = l2Gateway.getDevices();
                for (Devices l2Device : l2Devices) {
                    String l2DeviceName = l2Device.getDeviceName();
                    if (l2DeviceName != null && l2DeviceName.equals(psName)) {
                        for (Interfaces deviceInterface : l2Device.getInterfaces()) {
                            if (deviceInterface.getInterfaceName().equals(newPortId)) {
                                if (deviceInterface.getSegmentationIds() != null
                                        && !deviceInterface.getSegmentationIds().isEmpty()) {
                                    for (Integer vlanId : deviceInterface.getSegmentationIds()) {
                                        vlanBindings.add(HwvtepSouthboundUtils.createVlanBinding(hwvtepNodeId, vlanId,
                                                logicalSwitchName));
                                    }
                                } else {
                                    // Use defaultVlanId (specified in L2GatewayConnection) if Vlan
                                    // ID not specified at interface level.
                                    Integer segmentationId = l2GwConn.getSegmentId();
                                    int defaultVlanId = segmentationId != null ? segmentationId : 0;
                                    vlanBindings.add(HwvtepSouthboundUtils.createVlanBinding(hwvtepNodeId,
                                            defaultVlanId, logicalSwitchName));
                                }
                            }
                        }
                    }
                }
            }
        }
        return vlanBindings;
    }

    private boolean isL2GatewayConfigured(L2GatewayDevice l2GwDevice) {
        return l2GwDevice.getHwvtepNodeId() != null && l2GwDevice.isConnected()
                && l2GwDevice.getL2GatewayIds().size() > 0 && l2GwDevice.getTunnelIp() != null;
    }
}
