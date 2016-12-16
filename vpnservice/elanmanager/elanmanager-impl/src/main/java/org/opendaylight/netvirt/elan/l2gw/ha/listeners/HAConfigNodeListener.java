/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.listeners;

import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.CONFIGURATION;

import java.util.Set;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.genius.utils.hwvtep.HwvtepHACache;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.netvirt.elan.l2gw.ha.handlers.ConfigNodeUpdatedHandler;
import org.opendaylight.netvirt.elan.l2gw.ha.handlers.HAEventHandler;
import org.opendaylight.netvirt.elan.l2gw.ha.handlers.IHAEventHandler;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HAConfigNodeListener extends HwvtepNodeBaseListener {
    private static final Logger LOG = LoggerFactory.getLogger(HAConfigNodeListener.class);

    static HwvtepHACache hwvtepHACache = HwvtepHACache.getInstance();

    IHAEventHandler haEventHandler;
    ConfigNodeUpdatedHandler configNodeUpdatedHandler = new ConfigNodeUpdatedHandler();

    public HAConfigNodeListener(DataBroker db, HAEventHandler haEventHandler) throws Exception {
        super(LogicalDatastoreType.CONFIGURATION, db);
        this.haEventHandler = haEventHandler;
    }

    @Override
    void onPsNodeAdd(InstanceIdentifier<Node> key,
                     Node haPSNode,
                     ReadWriteTransaction tx) throws InterruptedException, ExecutionException, ReadFailedException {
        //copy the ps node data to children
        String psId = haPSNode.getNodeId().getValue();
        Set<InstanceIdentifier<Node>> childSwitchIds = HwvtepHAUtil.getPSChildrenIdsForHAPSNode(psId);
        for (InstanceIdentifier<Node> childSwitchId : childSwitchIds) {
            haEventHandler.copyHAPSUpdateToChild(haPSNode, null/*haOriginal*/, childSwitchId, tx);
        }
        LOG.info("Handle config ps node add {}", psId);
    }

    @Override
    void onPsNodeUpdate(InstanceIdentifier<Node> key,
                        Node haPSUpdated,
                        Node haPSOriginal,
                        ReadWriteTransaction tx) throws InterruptedException, ExecutionException, ReadFailedException {
        //copy the ps node data to children
        String psId = haPSUpdated.getNodeId().getValue();
        Set<InstanceIdentifier<Node>> childSwitchIds = HwvtepHAUtil.getPSChildrenIdsForHAPSNode(psId);
        for (InstanceIdentifier<Node> childSwitchId : childSwitchIds) {
            haEventHandler.copyHAPSUpdateToChild(haPSUpdated, haPSOriginal, childSwitchId, tx);
        }
    }

    @Override
    void onGlobalNodeUpdate(InstanceIdentifier<Node> key,
                            Node haUpdated,
                            Node haOriginal,
                            ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {
        //copy the ha node data to children
        Set<InstanceIdentifier<Node>> childNodeIds = hwvtepHACache.getChildrenForHANode(key);
        for (InstanceIdentifier<Node> haChildNodeId : childNodeIds) {
            haEventHandler.copyHAGlobalUpdateToChild(haUpdated, haOriginal, haChildNodeId, tx);
        }
    }

    @Override
    void onPsNodeDelete(InstanceIdentifier<Node> key,
                        Node deletedPsNode,
                        ReadWriteTransaction tx) throws ReadFailedException {
        //delete ps children nodes
        String psId = deletedPsNode.getNodeId().getValue();
        Set<InstanceIdentifier<Node>> childPsIds = HwvtepHAUtil.getPSChildrenIdsForHAPSNode(psId);
        for (InstanceIdentifier<Node> childPsId : childPsIds) {
            HwvtepHAUtil.deleteNodeIfPresent(tx, CONFIGURATION, childPsId);
        }
    }

    @Override
    void onGlobalNodeDelete(InstanceIdentifier<Node> key,
                            Node haNode,
                            ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException, InterruptedException {
        //delete child nodes
        String deletedNodeId = key.firstKeyOf(Node.class).getNodeId().getValue();
        Set<InstanceIdentifier<Node>> children = hwvtepHACache.getChildrenForHANode(key);
        for (InstanceIdentifier<Node> childId : children) {
            HwvtepHAUtil.deleteNodeIfPresent(tx, CONFIGURATION, childId);
        }
        HwvtepHAUtil.deletePSNodesOfNode(key, haNode, tx);
    }
}
