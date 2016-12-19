/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.handlers;

import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.GlobalAugmentationMerger;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.GlobalNodeMerger;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.PSAugmentationMerger;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.PSNodeMerger;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class OpNodeUpdatedHandler {

    GlobalAugmentationMerger globalAugmentationMerger = GlobalAugmentationMerger.getInstance();
    PSAugmentationMerger psAugmentationMerger     = PSAugmentationMerger.getInstance();
    GlobalNodeMerger globalNodeMerger         = GlobalNodeMerger.getInstance();
    PSNodeMerger psNodeMerger             = PSNodeMerger.getInstance();

    public void handle(Node updatedSrcNode, Node origSrcNode, InstanceIdentifier<Node> haPath, ReadWriteTransaction tx)
            throws ReadFailedException {
        if (updatedSrcNode.getAugmentation(HwvtepGlobalAugmentation.class) != null) {
            copyChildGlobalOpUpdateToHAParent(updatedSrcNode, origSrcNode, haPath, tx);
        } else {
            copyChildPsOpUpdateToHAParent(updatedSrcNode, origSrcNode, haPath, tx);
        }
    }

    /**
     * Copy HA ps node update to HA child ps node of operational data tree.
     *
     * @param updatedSrcPSNode Updated HA child ps node
     * @param origSrcPSNode Original HA ps node
     * @param haPath HA node path
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     */
    public void copyChildPsOpUpdateToHAParent(Node updatedSrcPSNode,
                                              Node origSrcPSNode,
                                              InstanceIdentifier<Node> haPath,
                                              ReadWriteTransaction tx) throws ReadFailedException {

        InstanceIdentifier<Node> haPSPath = HwvtepHAUtil.convertPsPath(updatedSrcPSNode, haPath);
        Node existingHAPSNode = HwvtepHAUtil.readNode(tx, LogicalDatastoreType.OPERATIONAL, haPSPath);

        PhysicalSwitchAugmentation updatedSrc   = HwvtepHAUtil.getPhysicalSwitchAugmentationOfNode(updatedSrcPSNode);
        PhysicalSwitchAugmentation origSrc      = HwvtepHAUtil.getPhysicalSwitchAugmentationOfNode(origSrcPSNode);
        PhysicalSwitchAugmentation existingData = HwvtepHAUtil.getPhysicalSwitchAugmentationOfNode(existingHAPSNode);

        psAugmentationMerger.mergeOpUpdate(existingData, updatedSrc, origSrc, haPSPath, tx);
        psNodeMerger.mergeOpUpdate(existingHAPSNode, updatedSrcPSNode, origSrcPSNode, haPSPath, tx);
    }

    /**
     * Copy updated data from HA node to child node of operational data tree.
     *
     * @param updatedSrcNode Updated HA child node
     * @param origSrcNode Original HA node
     * @param haPath HA node path
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     */
    public void copyChildGlobalOpUpdateToHAParent(Node updatedSrcNode,
                                                  Node origSrcNode,
                                                  InstanceIdentifier<Node> haPath,
                                                  ReadWriteTransaction tx) throws ReadFailedException {

        Node existingDstNode = HwvtepHAUtil.readNode(tx, LogicalDatastoreType.OPERATIONAL, haPath);
        if (existingDstNode == null) {
            //No dst present nothing to copy
            return;
        }
        HwvtepGlobalAugmentation existingData    = HwvtepHAUtil.getGlobalAugmentationOfNode(existingDstNode);
        HwvtepGlobalAugmentation updatedSrc = HwvtepHAUtil.getGlobalAugmentationOfNode(updatedSrcNode);
        HwvtepGlobalAugmentation origSrc    = HwvtepHAUtil.getGlobalAugmentationOfNode(origSrcNode);

        globalAugmentationMerger.mergeOpUpdate(existingData, updatedSrc, origSrc, haPath, tx);
        globalNodeMerger.mergeOpUpdate(existingDstNode, updatedSrcNode, origSrcNode, haPath, tx);
    }

}
