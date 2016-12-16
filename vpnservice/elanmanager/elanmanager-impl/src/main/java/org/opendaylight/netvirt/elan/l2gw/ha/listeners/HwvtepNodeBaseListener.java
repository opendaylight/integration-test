/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.listeners;

import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataObjectModification;
import org.opendaylight.controller.md.sal.binding.api.DataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.binding.api.DataTreeModification;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.genius.datastoreutils.TaskRetryLooper;
import org.opendaylight.genius.utils.hwvtep.HwvtepHACache;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class HwvtepNodeBaseListener implements DataTreeChangeListener<Node>, AutoCloseable {

    public static final Logger LOG = LoggerFactory.getLogger(HwvtepNodeBaseListener.class);
    private static final int STARTUP_LOOP_TICK = 500;
    private static final int STARTUP_LOOP_MAX_RETRIES = 8;

    static HwvtepHACache hwvtepHACache = HwvtepHACache.getInstance();

    private ListenerRegistration<HwvtepNodeBaseListener> registration;
    DataBroker db;

    public HwvtepNodeBaseListener(LogicalDatastoreType datastoreType, DataBroker dataBroker) throws Exception {
        db = dataBroker;
        registerListener(datastoreType, db);
    }

    public void registerListener(LogicalDatastoreType dsType, final DataBroker db) throws Exception {
        final DataTreeIdentifier<Node> treeId = new DataTreeIdentifier<>(dsType, getWildcardPath());
        TaskRetryLooper looper = new TaskRetryLooper(STARTUP_LOOP_TICK, STARTUP_LOOP_MAX_RETRIES);
        registration = looper.loopUntilNoException(() ->
                db.registerDataTreeChangeListener(treeId, HwvtepNodeBaseListener.this));
    }

    @Override
    public void onDataTreeChanged(final Collection<DataTreeModification<Node>> changes) {
        HAJobScheduler.getInstance().submitJob(new Runnable() {
            @Override
            public void run() {
                ReadWriteTransaction tx = getTx();
                try {
                    processConnectedNodes(changes, tx);
                    processUpdatedNodes(changes, tx);
                    processDisconnectedNodes(changes, tx);
                    tx.submit().get();
                } catch (InterruptedException e) {
                    LOG.error("InterruptedException " + e.getMessage());
                } catch (ExecutionException e) {
                    LOG.error("ExecutionException" + e.getMessage());
                } catch (ReadFailedException e) {
                    LOG.error("ReadFailedException" + e.getMessage());
                }
            }
        });
    }

    private void processUpdatedNodes(Collection<DataTreeModification<Node>> changes,
                                     ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException, InterruptedException {
        for (DataTreeModification<Node> change : changes) {
            final InstanceIdentifier<Node> key = change.getRootPath().getRootIdentifier();
            final DataObjectModification<Node> mod = change.getRootNode();
            String nodeId = key.firstKeyOf(Node.class).getNodeId().getValue();
            Node updated = HwvtepHAUtil.getUpdated(mod);
            Node original = HwvtepHAUtil.getOriginal(mod);
            if (updated != null && original != null) {
                if (updated != null && original != null) {
                    if (nodeId.indexOf(HwvtepHAUtil.PHYSICALSWITCH) < 0) {
                        onGlobalNodeUpdate(key, updated, original, tx);
                    } else {
                        onPsNodeUpdate(key, updated, original, tx);
                    }
                }
            }
        }
    }

    private void processDisconnectedNodes(Collection<DataTreeModification<Node>> changes,
                                          ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {

        for (DataTreeModification<Node> change : changes) {
            final InstanceIdentifier<Node> key = change.getRootPath().getRootIdentifier();
            final DataObjectModification<Node> mod = change.getRootNode();
            Node deleted = HwvtepHAUtil.getRemoved(mod);
            String nodeId = key.firstKeyOf(Node.class).getNodeId().getValue();
            if (deleted != null) {
                if (nodeId.indexOf(HwvtepHAUtil.PHYSICALSWITCH) < 0) {
                    LOG.info("Handle global node delete {}", deleted.getNodeId().getValue());
                    onGlobalNodeDelete(key, deleted, tx);
                } else {
                    LOG.error("Handle ps node node delete {}", deleted.getNodeId().getValue());
                    onPsNodeDelete(key, deleted, tx);
                }
            }
        }
    }

    void processConnectedNodes(Collection<DataTreeModification<Node>> changes,
                               ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException,
    InterruptedException {
        Map<String, Boolean> processedNodes = new HashMap<>();
        for (DataTreeModification<Node> change : changes) {
            InstanceIdentifier<Node> key = change.getRootPath().getRootIdentifier();
            DataObjectModification<Node> mod = change.getRootNode();
            Node node = HwvtepHAUtil.getCreated(mod);
            String nodeId = key.firstKeyOf(Node.class).getNodeId().getValue();
            if (node != null) {
                if (nodeId.indexOf(HwvtepHAUtil.PHYSICALSWITCH) < 0) {
                    LOG.info("Handle global node add {}", node.getNodeId().getValue());
                    onGlobalNodeAdd(key, node, tx);
                } else {
                    LOG.error("Handle ps node add {}", node.getNodeId().getValue());
                    onPsNodeAdd(key, node, tx);
                }
            }
        }
    }

    private InstanceIdentifier<Node> getWildcardPath() {
        InstanceIdentifier<Node> path = InstanceIdentifier
                .create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID))
                .child(Node.class);
        return path;
    }

    @Override
    public void close() throws Exception {
        if (registration != null) {
            registration.close();
        }
    }

    ReadWriteTransaction getTx() {
        return db.newReadWriteTransaction();
    }

    //default methods
    void onGlobalNodeDelete(InstanceIdentifier<Node> key, Node added, ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {
    }

    void onPsNodeDelete(InstanceIdentifier<Node> key, Node addedPSNode, ReadWriteTransaction tx)
            throws ReadFailedException {

    }

    void onGlobalNodeAdd(InstanceIdentifier<Node> key, Node added, ReadWriteTransaction tx) {

    }

    void onPsNodeAdd(InstanceIdentifier<Node> key, Node addedPSNode, ReadWriteTransaction tx)
            throws ReadFailedException, InterruptedException, ExecutionException {

    }

    void onGlobalNodeUpdate(InstanceIdentifier<Node> key, Node updated, Node original, ReadWriteTransaction tx)
            throws ReadFailedException, InterruptedException, ExecutionException {

    }

    void onPsNodeUpdate(InstanceIdentifier<Node> key, Node updated, Node original, ReadWriteTransaction tx)
            throws ReadFailedException, InterruptedException, ExecutionException {

    }

}
