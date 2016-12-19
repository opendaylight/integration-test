/*
 * Copyright (c) 2015 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.impl;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.opendaylight.netvirt.openstack.netvirt.NodeCacheManagerEvent;
import org.opendaylight.netvirt.openstack.netvirt.api.NodeCacheManager;
import org.opendaylight.netvirt.openstack.netvirt.AbstractEvent;
import org.opendaylight.netvirt.openstack.netvirt.AbstractHandler;
import org.opendaylight.netvirt.openstack.netvirt.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.api.Action;
import org.opendaylight.netvirt.openstack.netvirt.api.EventDispatcher;
import org.opendaylight.netvirt.openstack.netvirt.api.NodeCacheListener;
import org.opendaylight.netvirt.openstack.netvirt.api.Southbound;
import org.opendaylight.netvirt.utils.servicehelper.ServiceHelper;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;

import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

/**
 * @author Flavio Fernandes (ffernand@redhat.com)
 * @author Sam Hague (shague@redhat.com)
 */
public class NodeCacheManagerImpl extends AbstractHandler implements NodeCacheManager, ConfigInterface {
    private static final Logger LOG = LoggerFactory.getLogger(NodeCacheManagerImpl.class);
    private Map<NodeId, Node> nodeCache = new ConcurrentHashMap<>();
    private Map<Long, NodeCacheListener> handlers = Maps.newHashMap();
    private volatile Southbound southbound;

    @Override
    public void nodeAdded(Node node) {
        LOG.trace("nodeAdded: {}", node);
        enqueueEvent(new NodeCacheManagerEvent(node, Action.UPDATE));
    }

    @Override
    public void nodeRemoved(Node node) {
        LOG.trace("nodeRemoved: {}", node);
        enqueueEvent(new NodeCacheManagerEvent(node, Action.DELETE));
    }

    // TODO SB_MIGRATION
    // might need to break this into two different events
    // notifyOvsdbNode, notifyBridgeNode or just make sure the
    // classes implementing the interface check for ovsdbNode or bridgeNode
    private void processNodeUpdate(Node node) {
        Action action = Action.UPDATE;

        NodeId nodeId = node.getNodeId();
        if (nodeCache.get(nodeId) == null) {
            action = Action.ADD;
        } else {
            long oldDpid = southbound.getDataPathId(nodeCache.get(nodeId));
            long newDpid = southbound.getDataPathId(node);
            LOG.info("oldDpid == {}, newDpid == {}", oldDpid, newDpid);
            if (oldDpid != newDpid) {
                action = Action.ADD;
            }
        }
        nodeCache.put(nodeId, node);

        LOG.debug("processNodeUpdate: size= {}, Node type= {}, action= {}, node= {}",
                nodeCache.size(),
                southbound.getBridge(node) != null ? "BridgeNode" : "OvsdbNode",
                action == Action.ADD ? "ADD" : "UPDATE",
                node);

        for (NodeCacheListener handler : handlers.values()) {
            try {
                handler.notifyNode(node, action);
            } catch (Exception e) {
                LOG.error("Failed notifying node add event", e);
            }
        }
        LOG.trace("processNodeUpdate: Done processing");
    }

    private void processNodeRemoved(Node node) {
        nodeCache.remove(node.getNodeId());
        for (NodeCacheListener handler : handlers.values()) {
            try {
                handler.notifyNode(node, Action.DELETE);
            } catch (Exception e) {
                LOG.error("Failed notifying node remove event", e);
            }
        }
        LOG.trace("processNodeRemoved: Done processing");
    }

    /**
     * Process the event.
     *
     * @param abstractEvent the {@link AbstractEvent} event to be handled.
     * @see EventDispatcher
     */
    @Override
    public void processEvent(AbstractEvent abstractEvent) {
        if (!(abstractEvent instanceof NodeCacheManagerEvent)) {
            LOG.error("Unable to process abstract event {}", abstractEvent);
            return;
        }
        NodeCacheManagerEvent ev = (NodeCacheManagerEvent) abstractEvent;
        LOG.trace("NodeCacheManagerImpl: dequeue Event: {}", ev.getAction());
        switch (ev.getAction()) {
            case DELETE:
                processNodeRemoved(ev.getNode());
                break;
            case UPDATE:
                processNodeUpdate(ev.getNode());
                break;
            default:
                LOG.warn("Unable to process event action {}", ev.getAction());
                break;
        }
    }

    public void cacheListenerAdded(final ServiceReference ref, NodeCacheListener handler){
        Long pid = (Long) ref.getProperty(org.osgi.framework.Constants.SERVICE_ID);
        handlers.put(pid, handler);
        LOG.info("Node cache listener registered, pid : {} handler : {}", pid,
                handler.getClass().getName());
    }

    public void cacheListenerRemoved(final ServiceReference ref){
        Long pid = (Long) ref.getProperty(org.osgi.framework.Constants.SERVICE_ID);
        handlers.remove(pid);
        LOG.debug("Node cache listener unregistered, pid {}", pid);
    }

    @Override
    public Map<NodeId,Node> getOvsdbNodes() {
        Map<NodeId,Node> ovsdbNodesMap = new ConcurrentHashMap<>();
        for (Map.Entry<NodeId, Node> ovsdbNodeEntry : nodeCache.entrySet()) {
            if (southbound.extractOvsdbNode(ovsdbNodeEntry.getValue()) != null) {
                ovsdbNodesMap.put(ovsdbNodeEntry.getKey(), ovsdbNodeEntry.getValue());
            }
        }
        return ovsdbNodesMap;
    }

    @Override
    public List<Node> getBridgeNodes() {
        List<Node> nodes = Lists.newArrayList();
        for (Node node : nodeCache.values()) {
            if (southbound.getBridge(node) != null) {
                nodes.add(node);
            }
        }
        return nodes;
    }

    @Override
    public List <Long> getBridgeDpids(final String bridgeName) {
        List<Long> dpids = Lists.newArrayList();
        for (Node node : nodeCache.values()) {
            if (bridgeName == null || southbound.getBridge(node, bridgeName) != null) {
                long dpid = southbound.getDataPathId(node);
                if (dpid != 0L) {
                    dpids.add(dpid);
                }
            }
        }
        return dpids;
    }

    @Override
    public List<Node> getNodes() {
        List<Node> nodes = Lists.newArrayList();
        for (Node node : nodeCache.values()) {
            nodes.add(node);
        }
        return nodes;
    }

    private void populateNodeCache() {
        LOG.debug("populateNodeCache : Populating the node cache");
        List<Node> nodes = southbound.readOvsdbTopologyNodes();
        for(Node ovsdbNode : nodes) {
            this.nodeCache.put(ovsdbNode.getNodeId(), ovsdbNode);
        }
        nodes = southbound.readOvsdbTopologyBridgeNodes();
        for(Node bridgeNode : nodes) {
            this.nodeCache.put(bridgeNode.getNodeId(), bridgeNode);
        }
        LOG.debug("populateNodeCache : Node cache population is done. Total nodes : {}",this.nodeCache.size());
    }

    @Override
    public void setDependencies(ServiceReference serviceReference) {
        southbound =
                (Southbound) ServiceHelper.getGlobalInstance(Southbound.class, this);
        eventDispatcher =
                (EventDispatcher) ServiceHelper.getGlobalInstance(EventDispatcher.class, this);
        eventDispatcher.eventHandlerAdded(serviceReference, this);
        populateNodeCache();
    }

    @Override
    public void setDependencies(Object impl) {}
}
