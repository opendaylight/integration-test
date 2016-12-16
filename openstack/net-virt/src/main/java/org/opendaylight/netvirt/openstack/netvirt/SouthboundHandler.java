/*
 * Copyright (c) 2013, 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt;

import java.util.List;

import org.opendaylight.netvirt.openstack.netvirt.api.Action;
import org.opendaylight.netvirt.openstack.netvirt.api.BridgeConfigurationManager;
import org.opendaylight.netvirt.openstack.netvirt.api.ConfigurationService;
import org.opendaylight.netvirt.openstack.netvirt.api.Constants;
import org.opendaylight.netvirt.openstack.netvirt.api.EventDispatcher;
import org.opendaylight.netvirt.openstack.netvirt.api.NetworkingProviderManager;
import org.opendaylight.netvirt.openstack.netvirt.api.NodeCacheListener;
import org.opendaylight.netvirt.openstack.netvirt.api.NodeCacheManager;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbInventoryListener;
import org.opendaylight.netvirt.openstack.netvirt.api.OvsdbInventoryService;
import org.opendaylight.netvirt.openstack.netvirt.api.Southbound;
import org.opendaylight.netvirt.openstack.netvirt.api.TenantNetworkManager;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronNetwork;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronPort;
import org.opendaylight.netvirt.openstack.netvirt.impl.DistributedArpService;
import org.opendaylight.netvirt.openstack.netvirt.impl.NeutronL3Adapter;
import org.opendaylight.netvirt.utils.servicehelper.ServiceHelper;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbTerminationPointAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author Madhu Venugopal
 * @author Brent Salisbury
 * @author Dave Tucker
 * @author Sam Hague (shague@redhat.com)
 */
public class SouthboundHandler extends AbstractHandler
        implements ConfigInterface, NodeCacheListener, OvsdbInventoryListener {
    private static final Logger LOG = LoggerFactory.getLogger(SouthboundHandler.class);

    // The implementation for each of these services is resolved by the OSGi Service Manager
    private volatile ConfigurationService configurationService;
    private volatile BridgeConfigurationManager bridgeConfigurationManager;
    private volatile TenantNetworkManager tenantNetworkManager;
    private volatile NetworkingProviderManager networkingProviderManager;
    private volatile NeutronL3Adapter neutronL3Adapter;
    private volatile DistributedArpService distributedArpService;
    private volatile NodeCacheManager nodeCacheManager;
    private volatile OvsdbInventoryService ovsdbInventoryService;
    private volatile Southbound southbound;
    private volatile VLANProvider vlanProvider;

    private SouthboundEvent.Type ovsdbTypeToSouthboundEventType(OvsdbType ovsdbType) {
        SouthboundEvent.Type type = SouthboundEvent.Type.NODE;

        switch (ovsdbType) {
            case NODE:
                type = SouthboundEvent.Type.NODE;
                break;
            case BRIDGE:
                type = SouthboundEvent.Type.BRIDGE;
                break;
            case PORT:
                type = SouthboundEvent.Type.PORT;
                break;
            case CONTROLLER:
                type = SouthboundEvent.Type.CONTROLLER;
                break;
            case OPENVSWITCH:
                type = SouthboundEvent.Type.OPENVSWITCH;
                break;
            default:
                LOG.warn("Invalid OvsdbType: {}", ovsdbType);
                break;
        }
        return type;
    }

    @Override
    public void ovsdbUpdate(Node node, DataObject resourceAugmentationData, OvsdbType ovsdbType, Action action) {
        LOG.info("Received ovsdbUpdate for : {} with action : {} for the OVS node : {}"
                +"Resource Data  : {}", ovsdbType, action, node, resourceAugmentationData);
        enqueueEvent(new SouthboundEvent(node, resourceAugmentationData,
                ovsdbTypeToSouthboundEventType(ovsdbType), action));
    }

    private void handleInterfaceUpdate (Node node, OvsdbTerminationPointAugmentation tp, Action action) {
        NeutronNetwork network = tenantNetworkManager.getTenantNetwork(tp);
        if (network != null && !network.getRouterExternal()) {
            LOG.trace("InterfaceUpdate for OVS Node :{} OvsdbTerminationPointAugmentation :"        + " {} for the network : {}", node, tp, network.getNetworkUUID());
            if (bridgeConfigurationManager.createLocalNetwork(node, network)) {
                networkingProviderManager.getProvider(node).handleInterfaceUpdate(network, node, tp);
            }
        } else {
            LOG.debug("No tenant network found on node : {} for interface: {}", node, tp);
        }
        if (action.equals(Action.UPDATE)) {
            distributedArpService.processInterfaceEvent(node, tp, network, action);
        }
        neutronL3Adapter.handleInterfaceEvent(node, tp, network, Action.UPDATE);
    }

    private void handleInterfaceDelete (Node node, OvsdbTerminationPointAugmentation intf,
                                        boolean isLastInstanceOnNode, NeutronNetwork network) {
        LOG.debug("handleInterfaceDelete: node: <{}>, isLastInstanceOnNode: {}, interface: <{}>",
                node, isLastInstanceOnNode, intf);

        distributedArpService.processInterfaceEvent(node, intf, network, Action.DELETE);
        neutronL3Adapter.handleInterfaceEvent(node, intf, network, Action.DELETE);
        final NeutronPort neutronPort = tenantNetworkManager.getTenantPort(intf);
        programVLANNetworkFlowProvider(node, intf, network, neutronPort, false);
        List<String> phyIfName = bridgeConfigurationManager.getAllPhysicalInterfaceNames(node);
        if (isInterfaceOfInterest(intf, phyIfName)) {
            // delete tunnel or physical interfaces
            networkingProviderManager.getProvider(node).handleInterfaceDelete(network.getProviderNetworkType(),
                    network, node, intf, isLastInstanceOnNode);
        } else if (network != null) {
            // vlan doesn't need a tunnel endpoint
            if (!network.getProviderNetworkType().equalsIgnoreCase(NetworkHandler.NETWORK_TYPE_VLAN) &&
                    configurationService.getTunnelEndPoint(node) == null) {
                LOG.error("Tunnel end-point configuration missing. Please configure it in OpenVSwitch Table");
                return;
            }
            networkingProviderManager.getProvider(node).handleInterfaceDelete(network.getProviderNetworkType(),
                    network, node, intf, isLastInstanceOnNode);
        }
    }

    @Override
    public void triggerUpdates() {
        List<Node> ovsdbNodes = southbound.readOvsdbTopologyNodes();
        for (Node node : ovsdbNodes) {
            ovsdbUpdate(node, node.getAugmentation(OvsdbNodeAugmentation.class),
                    OvsdbInventoryListener.OvsdbType.NODE, Action.ADD);
        }
    }

    private void processPortDelete(Node node, OvsdbTerminationPointAugmentation ovsdbTerminationPointAugmentation,
                                   Object context) {
        LOG.debug("processPortDelete for Node : {} ovsdbTerminationPointAugmentation : {}",
                node, ovsdbTerminationPointAugmentation);
        NeutronNetwork network;
        if (context == null) {
            network = tenantNetworkManager.getTenantNetwork(ovsdbTerminationPointAugmentation);
        } else {
            network = (NeutronNetwork)context;
        }
        List<String> phyIfName = bridgeConfigurationManager.getAllPhysicalInterfaceNames(node);
        if (isInterfaceOfInterest(ovsdbTerminationPointAugmentation, phyIfName)) {
            if (network != null) {
                this.handleInterfaceDelete(node, ovsdbTerminationPointAugmentation, false, network);
            } else {
                LOG.warn("processPortDelete: network was null, ignoring update");
            }
        } else if (network != null && !network.getRouterExternal()) {
            LOG.debug("Network {}: Delete interface {} attached to bridge {}", network.getNetworkUUID(),
                    ovsdbTerminationPointAugmentation.getInterfaceUuid(), node.getNodeId());
            try {
                OvsdbBridgeAugmentation ovsdbBridgeAugmentation = southbound.getBridge(node);
                if (ovsdbBridgeAugmentation != null) {
                    List<TerminationPoint> terminationPoints = node.getTerminationPoint();
                    if (!terminationPoints.isEmpty()){
                        boolean isLastInstanceOnNode = true;
                        for (TerminationPoint terminationPoint : terminationPoints) {
                            OvsdbTerminationPointAugmentation tpAugmentation =
                                    terminationPoint.getAugmentation( OvsdbTerminationPointAugmentation.class);
                            if (tpAugmentation.getInterfaceUuid().equals(
                                    ovsdbTerminationPointAugmentation.getInterfaceUuid())) {
                                continue;
                            }
                            NeutronNetwork neutronNetwork = tenantNetworkManager.getTenantNetwork(tpAugmentation);
                            if (neutronNetwork != null) {
                                String neutronNetworkSegId = neutronNetwork.getProviderSegmentationID();
                                String networkSegId = network.getProviderSegmentationID();
                                // vxlan ports should not be removed in table 110 flow entry
                                // unless last VM instance removed from the openstack node(Bug# 5813)
                                if (neutronNetworkSegId != null && neutronNetworkSegId.equals(networkSegId)) {
                                    isLastInstanceOnNode = false;
                                    break;
                                }
                            }
                        }
                        this.handleInterfaceDelete(node, ovsdbTerminationPointAugmentation,
                                isLastInstanceOnNode, network);
                    }
                }
            } catch (Exception e) {
                LOG.error("Error fetching Interface Rows for node {}", node, e);
            }
        } else if (network != null && network.getRouterExternal()) {
                this.handleInterfaceDelete(node, ovsdbTerminationPointAugmentation, false, network);
        }
        //remove neutronPort from the CleanupCache, if it has the entry.
        NeutronPort neutronPort = null;
        String neutronPortId = southbound.getInterfaceExternalIdsValue(ovsdbTerminationPointAugmentation,
                Constants.EXTERNAL_ID_INTERFACE_ID);
        if (neutronPortId != null) {
            LOG.trace("Clean up the NeutronPortCache for {} ", neutronPortId);
            neutronPort = neutronL3Adapter.getPortFromCleanupCache(neutronPortId);
        }
        if (neutronPort != null) {
            LOG.debug("Clean up the NeutronPortCache ");
            neutronL3Adapter.removePortFromCleanupCache(neutronPort);
            neutronL3Adapter.removeNetworkFromCleanupCache(neutronPort.getNetworkUUID());
        } else {
            LOG.trace("Nothing to Clean up in the NeutronPortCache ");
        }

    }

    private boolean isInterfaceOfInterest(OvsdbTerminationPointAugmentation terminationPoint, List<String> phyIfName) {
        LOG.trace("SouthboundHandler#isInterfaceOfInterest: Interface : {}", terminationPoint);

        if(terminationPoint.getInterfaceType() == null){
            // This is OK since eth ports don't have an interface type
            return false;
        }
        return MdsalHelper.createOvsdbInterfaceType(
                terminationPoint.getInterfaceType()).equals(NetworkHandler.NETWORK_TYPE_VXLAN)
               ||
               MdsalHelper.createOvsdbInterfaceType(
                       terminationPoint.getInterfaceType()).equals(NetworkHandler.NETWORK_TYPE_GRE)
               ||
               phyIfName.contains(terminationPoint.getName());
    }

    /**
     * Notification about an OpenFlow Node
     *
     * @param node the {@link Node Node} of interest in the notification
     * @param action the {@link Action}
     * @see NodeCacheListener#notifyNode
     */
    @Override
    public void notifyNode (Node node, Action action) {
        LOG.info("notifyNode : action: {}, Node  : {} ", action, node);

        if ((action == Action.ADD) && (southbound.getBridge(node) != null)) {
            networkingProviderManager.getProvider(node).initializeOFFlowRules(node);
        }
    }

    /**
     * Process the event.
     *
     * @param abstractEvent the {@link AbstractEvent} event to be handled.
     * @see EventDispatcher
     */
    @Override
    public void processEvent(AbstractEvent abstractEvent) {
        if (!(abstractEvent instanceof SouthboundEvent)) {
            LOG.error("processEvent Unable to process abstract event : {}", abstractEvent);
            return;
        }
        SouthboundEvent ev = (SouthboundEvent) abstractEvent;
        LOG.trace("processEvent : {} for TransactionId : {}", ev, ev.getTransactionId());
        switch (ev.getType()) {
            case NODE:
                processOvsdbNodeEvent(ev);
                break;

            case BRIDGE:
                processBridgeEvent(ev);
                break;

            case PORT:
                processPortEvent(ev);
                break;

            case OPENVSWITCH:
                processOpenVSwitchEvent(ev);
                break;

            default:
                LOG.warn("Unable to process type : {} action : {} for node : {}", ev.getType(), ev.getAction(), ev.getNode());
                break;
        }
        LOG.trace("processEvent exit : {} for TransactionId : {}", ev, ev.getTransactionId());
    }

    private void processOvsdbNodeEvent(SouthboundEvent ev) {
        switch (ev.getAction()) {
            case ADD:
                processOvsdbNodeCreate(ev.getNode(), (OvsdbNodeAugmentation) ev.getAugmentationData());
                break;
            case UPDATE:
                processOvsdbNodeUpdate(ev.getNode(), (OvsdbNodeAugmentation) ev.getAugmentationData());
                break;
            case DELETE:
                processOvsdbNodeDelete(ev.getNode(), (OvsdbNodeAugmentation) ev.getAugmentationData());
                break;
        }
    }

    private void processOvsdbNodeCreate(Node node, OvsdbNodeAugmentation ovsdbNode) {
        LOG.info("processOvsdb Node Create : {} ", ovsdbNode);
        nodeCacheManager.nodeAdded(node);
        bridgeConfigurationManager.prepareNode(node);
    }

    private void processOvsdbNodeUpdate(Node node, OvsdbNodeAugmentation ovsdbNode) {
        LOG.info("processOvsdb Node Update : {} ", ovsdbNode);
        nodeCacheManager.nodeAdded(node);
    }

    private void processOvsdbNodeDelete(Node node, OvsdbNodeAugmentation ovsdbNode) {
        LOG.info("processOvsdb Node Delete : {} ", ovsdbNode);
        nodeCacheManager.nodeRemoved(node);
        /* TODO SB_MIGRATION
        * I don't think we want to do this yet
        InstanceIdentifier<Node> bridgeNodeIid =
                MdsalHelper.createInstanceIdentifier(ovsdbNode.getConnectionInfo(),
                        Constants.INTEGRATION_BRIDGE);
        southbound.delete(LogicalDatastoreType.CONFIGURATION, bridgeNodeIid);
        */
    }

    private void processPortEvent(SouthboundEvent ev) {
        switch (ev.getAction()) {
            case ADD:
            case UPDATE:
                processPortUpdate(ev.getNode(), (OvsdbTerminationPointAugmentation) ev.getAugmentationData(), ev.getAction());
                break;
            case DELETE:
                processPortDelete(ev.getNode(), (OvsdbTerminationPointAugmentation) ev.getAugmentationData(), null);
                break;
        }
    }

    private void processPortUpdate(Node node, OvsdbTerminationPointAugmentation port, Action action) {
        LOG.debug("processPortUpdate : {} for the Node: {}", port, node);
        NeutronNetwork network = tenantNetworkManager.getTenantNetwork(port);
        if (network != null) {
            final NeutronPort neutronPort = tenantNetworkManager.getTenantPort(port);
            if (!network.getRouterExternal()) {
                handleInterfaceUpdate(node, port, action);
            } else if (action != null && action.equals(Action.UPDATE)) {
                programVLANNetworkFlowProvider(node, port, network, neutronPort, true);
            }
        }
    }

    private void programVLANNetworkFlowProvider(final Node node, final OvsdbTerminationPointAugmentation port,
           final NeutronNetwork network, final NeutronPort neutronPort, final Boolean isWrite) {
        if (neutronPort != null && neutronPort.getDeviceOwner().equalsIgnoreCase(Constants.OWNER_ROUTER_GATEWAY) &&
                network.getProviderNetworkType().equalsIgnoreCase(NetworkHandler.NETWORK_TYPE_VLAN) &&
                configurationService.isL3MultipleExternalNetworkEnabled()) {
            vlanProvider.programProviderNetworkFlow(node, port, network, neutronPort, isWrite);
        }
    }

    private void processOpenVSwitchEvent(SouthboundEvent ev) {
        switch (ev.getAction()) {
            case ADD:
            case UPDATE:
                processOpenVSwitchUpdate(ev.getNode());
                break;
            case DELETE:
                break;
        }
    }

    private void processOpenVSwitchUpdate(Node node) {
        LOG.debug("processOpenVSwitchUpdate : {}", node);
        // TODO this node might be the OvsdbNode and not have termination points
        // Would need to change listener or grab tp nodes in here.
        List<TerminationPoint> terminationPoints = southbound.extractTerminationPoints(node);
        for (TerminationPoint terminationPoint : terminationPoints) {
            processPortUpdate(node, terminationPoint.getAugmentation(OvsdbTerminationPointAugmentation.class), null);
        }
    }

    private void processBridgeEvent(SouthboundEvent ev) {
        switch (ev.getAction()) {
            case ADD:
                processBridgeCreate(ev.getNode(), (OvsdbBridgeAugmentation) ev.getAugmentationData());
                break;
            case UPDATE:
                processBridgeUpdate(ev.getNode(), (OvsdbBridgeAugmentation) ev.getAugmentationData());
                break;
            case DELETE:
                processBridgeDelete(ev.getNode(), (OvsdbBridgeAugmentation) ev.getAugmentationData());
                break;
        }
    }

    private void processBridgeCreate(Node node, OvsdbBridgeAugmentation bridge) {
        LOG.debug("BridgeCreate : {} for the Node : {}", bridge, node);
        String datapathId = southbound.getDatapathId(bridge);
        // Having a datapathId means the ovsdb node has connected to ODL
        if (datapathId != null) {
            nodeCacheManager.nodeAdded(node);
        } else {
            LOG.debug("processBridgeCreate datapathId not found");
        }
    }

    private void processBridgeUpdate(Node node, OvsdbBridgeAugmentation bridge) {
        LOG.debug("BridgeUpdate : {} for the node : {}", bridge, node);
        String datapathId = southbound.getDatapathId(bridge);
        // Having a datapathId means the ovsdb node has connected to ODL
        if (datapathId != null) {
            nodeCacheManager.nodeAdded(node);
        } else {
            LOG.debug("processBridgeUpdate datapathId not found");
        }
    }

    private void processBridgeDelete(Node node, OvsdbBridgeAugmentation bridge) {
        LOG.debug("BridgeDelete: Delete bridge from config data store : {}"
                +"Node : {}", bridge, node);
        nodeCacheManager.nodeRemoved(node);
        // TODO SB_MIGRATION
        // Not sure if we want to do this yet
        southbound.deleteBridge(node);
    }

    @Override
    public void setDependencies(ServiceReference serviceReference) {
        configurationService =
                (ConfigurationService) ServiceHelper.getGlobalInstance(ConfigurationService.class, this);
        networkingProviderManager =
                (NetworkingProviderManager) ServiceHelper.getGlobalInstance(NetworkingProviderManager.class, this);
        tenantNetworkManager =
                (TenantNetworkManager) ServiceHelper.getGlobalInstance(TenantNetworkManager.class, this);
        bridgeConfigurationManager =
                (BridgeConfigurationManager) ServiceHelper.getGlobalInstance(BridgeConfigurationManager.class, this);
        nodeCacheManager =
                (NodeCacheManager) ServiceHelper.getGlobalInstance(NodeCacheManager.class, this);
        nodeCacheManager.cacheListenerAdded(serviceReference, this);
        neutronL3Adapter =
                (NeutronL3Adapter) ServiceHelper.getGlobalInstance(NeutronL3Adapter.class, this);
        distributedArpService =
                (DistributedArpService) ServiceHelper.getGlobalInstance(DistributedArpService.class, this);
        southbound =
                (Southbound) ServiceHelper.getGlobalInstance(Southbound.class, this);
        eventDispatcher =
                (EventDispatcher) ServiceHelper.getGlobalInstance(EventDispatcher.class, this);
        eventDispatcher.eventHandlerAdded(serviceReference, this);
        ovsdbInventoryService =
                (OvsdbInventoryService) ServiceHelper.getGlobalInstance(OvsdbInventoryService.class, this);
        ovsdbInventoryService.listenerAdded(this);
        vlanProvider = 
                (VLANProvider) ServiceHelper.getGlobalInstance(VLANProvider.class, this);
    }

    @Override
    public void setDependencies(Object impl) {
    }
}
