/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.handlers;

import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.CONFIGURATION;
import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.OPERATIONAL;

import com.google.common.base.Optional;
import com.google.common.collect.Sets;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.utils.hwvtep.HwvtepHACache;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.netvirt.elan.l2gw.ha.listeners.HAJobScheduler;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.GlobalAugmentationMerger;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.GlobalNodeMerger;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.PSAugmentationMerger;
import org.opendaylight.netvirt.elan.l2gw.ha.merge.PSNodeMerger;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Switches;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NodeConnectedHandler {

    static Logger LOG = LoggerFactory.getLogger(NodeConnectedHandler.class);

    GlobalAugmentationMerger globalAugmentationMerger = GlobalAugmentationMerger.getInstance();
    PSAugmentationMerger psAugmentationMerger = PSAugmentationMerger.getInstance();
    GlobalNodeMerger globalNodeMerger = GlobalNodeMerger.getInstance();
    PSNodeMerger psNodeMerger = PSNodeMerger.getInstance();
    DataBroker db;
    HwvtepHACache hwvtepHACache = HwvtepHACache.getInstance();

    public NodeConnectedHandler(DataBroker db) {
        this.db = db;
    }

    /**
     * Takes care of merging the data when a node gets connected.
     * When a ha child node gets connected , we perform the following.
     * Merge the ha parent config data to child node.
     * Merge the ha parent physical node config data to child physical node.
     * Merge the child operational data to parent operational data.
     * Merge the child physical switch node operational data to parent physical switch operational node .
     *
     * @param childNode   Ha child node
     * @param childNodePath Ha child Iid
     * @param haNodePath  Ha Iid
     * @param haGlobalCfg Ha Global Config Node
     * @param haPSCfg Ha Physical Config Node
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    public void handleNodeConnected(Node childNode,
                                    InstanceIdentifier<Node> childNodePath,
                                    InstanceIdentifier<Node> haNodePath,
                                    Optional<Node> haGlobalCfg,
                                    Optional<Node> haPSCfg,
                                    ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException, InterruptedException {
        HwvtepHAUtil.buildGlobalConfigForHANode(tx, childNode, haNodePath, haGlobalCfg);
        copyChildOpToHA(childNode, haNodePath, tx);
        readAndCopyChildPSOpToHAPS(childNode, haNodePath, tx);
        if (haGlobalCfg.isPresent()) {
            //copy ha config to newly connected child case of reconnected child
            if (haPSCfg.isPresent()) {
                /*
                 copy task of physical switch node is done in the next transaction
                 The reason being if it is done in the same transaction,
                 hwvtep plugin is not able to proess this update and send vlanbindings to device
                 as it is expecting the logical switch to be already present in operational ds
                 (created in the device )
                 */
                HAJobScheduler.getInstance().submitJob(new Runnable() {
                    public void run() {
                        try {
                            hwvtepHACache.updateConnectedNodeStatus(childNodePath);
                            LOG.info("HA child reconnected handleNodeReConnected {}",
                                    childNode.getNodeId().getValue());
                            ReadWriteTransaction tx = db.newReadWriteTransaction();
                            copyHAPSConfigToChildPS(haPSCfg.get(), childNodePath, tx);
                            tx.submit().checkedGet();
                        } catch (InterruptedException | ExecutionException | ReadFailedException
                                | TransactionCommitFailedException e) {
                            LOG.error("Failed to process ", e);
                        }
                    }
                });

            }
            copyHANodeConfigToChild(haGlobalCfg.get(), childNodePath, tx);
        }
        deleteChildPSConfigIfHAPSConfigIsMissing(haGlobalCfg, childNode, tx);
    }

    private void deleteChildConfigIfHAConfigIsMissing(Optional<Node> haGlobalCfg,
                                                      InstanceIdentifier<Node> childNodePath,
                                                      ReadWriteTransaction tx) throws ReadFailedException {
        if (!haGlobalCfg.isPresent()) {
            LOG.info("HA global node not present cleaning up child {}" , childNodePath);
            HwvtepHAUtil.deleteNodeIfPresent(tx, CONFIGURATION, childNodePath);
        }
    }

    private void deleteChildPSConfigIfHAPSConfigIsMissing(Optional<Node> haPSCfg,
                                                          Node childNode,
                                                          ReadWriteTransaction tx) throws ReadFailedException {
        if (haPSCfg.isPresent()) {
            return;
        }
        LOG.info("HA ps node not present cleanup child {}" , childNode);
        HwvtepGlobalAugmentation augmentation = childNode.getAugmentation(HwvtepGlobalAugmentation.class);
        if (augmentation != null) {
            List<Switches> switches = augmentation.getSwitches();
            if (switches != null) {
                for (Switches ps : switches) {
                    HwvtepHAUtil.deleteNodeIfPresent(tx, CONFIGURATION, ps.getSwitchRef().getValue());
                }
            }
        } else {
            LOG.info("Global augumentation not present for connected ha child node {}" , childNode);
        }
    }

    /**
     * Merge data of child PS node to HA ps node .
     *
     * @param childGlobalNode Ha Global Child node
     * @param haNodePath Ha node path
     * @param tx  Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    void readAndCopyChildPSOpToHAPS(Node childGlobalNode,
                                    InstanceIdentifier<Node> haNodePath,
                                    ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException, InterruptedException {

        if (childGlobalNode == null || childGlobalNode.getAugmentation(HwvtepGlobalAugmentation.class) == null) {
            return;
        }
        List<Switches> switches = childGlobalNode.getAugmentation(HwvtepGlobalAugmentation.class).getSwitches();
        if (switches == null) {
            return;
        }
        for (Switches ps : switches) {
            Node childPsNode = HwvtepHAUtil.readNode(tx, OPERATIONAL,
                    (InstanceIdentifier<Node>) ps.getSwitchRef().getValue());
            if (childPsNode != null) {
                InstanceIdentifier<Node> haPsPath = HwvtepHAUtil.convertPsPath(childPsNode, haNodePath);
                copyChildPSOpToHAPS(childPsNode, haNodePath, haPsPath, tx);
            }
        }
    }

    /**
     * Copy HA global node data to Child HA node of config data tree .
     *
     * @param srcNode Node which to be transformed
     * @param childPath Path to which source node will be transformed
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    private void copyHANodeConfigToChild(Node srcNode,
                                         InstanceIdentifier<Node> childPath,
                                         ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException, InterruptedException {
        if (srcNode == null) {
            return;
        }
        HwvtepGlobalAugmentation src = srcNode.getAugmentation(HwvtepGlobalAugmentation.class);
        if (src == null) {
            return;
        }
        NodeBuilder nodeBuilder = HwvtepHAUtil.getNodeBuilderForPath(childPath);
        HwvtepGlobalAugmentationBuilder dstBuilder = new HwvtepGlobalAugmentationBuilder();

        NodeId nodeId = srcNode.getNodeId();
        Set<NodeId> nodeIds = Sets.newHashSet();
        nodeIds.add(nodeId);

        globalAugmentationMerger.mergeConfigData(dstBuilder, src, childPath);
        globalNodeMerger.mergeConfigData(nodeBuilder, srcNode, childPath);
        nodeBuilder.addAugmentation(HwvtepGlobalAugmentation.class, dstBuilder.build());
        Node dstNode = nodeBuilder.build();
        tx.put(CONFIGURATION, childPath, dstNode, true);
    }

    /**
     * Copy HA child node to HA node of Operational data tree.
     *
     * @param childNode HA Child Node
     * @param haNodePath HA node path
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    private void copyChildOpToHA(Node childNode,
                                 InstanceIdentifier<Node> haNodePath,
                                 ReadWriteTransaction tx)
            throws ReadFailedException, ExecutionException, InterruptedException {
        if (childNode == null) {
            return;
        }
        HwvtepGlobalAugmentation childData = childNode.getAugmentation(HwvtepGlobalAugmentation.class);
        if (childData == null) {
            return;
        }
        NodeBuilder haNodeBuilder = HwvtepHAUtil.getNodeBuilderForPath(haNodePath);
        HwvtepGlobalAugmentationBuilder haBuilder = new HwvtepGlobalAugmentationBuilder();

        Optional<Node> existingHANodeOptional = tx.read(OPERATIONAL, haNodePath).checkedGet();
        Node existingHANode = existingHANodeOptional.isPresent() ? existingHANodeOptional.get() : null;
        HwvtepGlobalAugmentation existingHAData = HwvtepHAUtil.getGlobalAugmentationOfNode(existingHANode);

        globalAugmentationMerger.mergeOperationalData(haBuilder, existingHAData, childData, haNodePath);
        globalNodeMerger.mergeOperationalData(haNodeBuilder, existingHANode, childNode, haNodePath);

        haBuilder.setManagers(HwvtepHAUtil.buildManagersForHANode(childNode, existingHANodeOptional));
        haBuilder.setSwitches(HwvtepHAUtil.buildSwitchesForHANode(childNode, haNodePath, existingHANodeOptional));
        haNodeBuilder.addAugmentation(HwvtepGlobalAugmentation.class, haBuilder.build());
        Node haNode = haNodeBuilder.build();
        tx.merge(OPERATIONAL, haNodePath, haNode, true);
    }

    /**
     * Merge data to Physical switch from HA node path .
     *
     * @param psAugmentation  Physical Switch Augmation of Node
     * @param builder Physical Switch Augmentation Builder
     * @param haNodePath HA node Path
     */
    public void mergeOpManagedByAttributes(PhysicalSwitchAugmentation psAugmentation,
                                           PhysicalSwitchAugmentationBuilder builder,
                                           InstanceIdentifier<Node> haNodePath) {
        builder.setManagedBy(new HwvtepGlobalRef(haNodePath));
        builder.setHwvtepNodeName(psAugmentation.getHwvtepNodeName());
        builder.setHwvtepNodeDescription(psAugmentation.getHwvtepNodeDescription());
        builder.setTunnelIps(psAugmentation.getTunnelIps());
        builder.setPhysicalSwitchUuid(HwvtepHAUtil.getUUid(psAugmentation.getHwvtepNodeName().getValue()));
    }

    /**
     * Copy HA physical switch data to Child Physical switch node of config data tree.
     *
     * @param haPsNode HA physical Switch Node
     * @param childPath HA Child Node path
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    public void copyHAPSConfigToChildPS(Node haPsNode,
                                        InstanceIdentifier<Node> childPath,
                                        ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {
        InstanceIdentifier<Node> childPsPath = HwvtepHAUtil.convertPsPath(haPsNode, childPath);

        NodeBuilder childPsBuilder = HwvtepHAUtil.getNodeBuilderForPath(childPsPath);
        PhysicalSwitchAugmentationBuilder dstBuilder = new PhysicalSwitchAugmentationBuilder();
        PhysicalSwitchAugmentation src = haPsNode.getAugmentation(PhysicalSwitchAugmentation.class);

        psAugmentationMerger.mergeConfigData(dstBuilder, src, childPath);
        psNodeMerger.mergeConfigData(childPsBuilder, haPsNode, childPath);

        childPsBuilder.addAugmentation(PhysicalSwitchAugmentation.class, dstBuilder.build());
        Node childPSNode = childPsBuilder.build();
        tx.put(CONFIGURATION, childPsPath, childPSNode, true);
    }

    /**
     * Copy child physical switch node data to HA physical switch data of Operational data tree.
     *
     * @param childPsNode HA child PS node
     * @param haPath  HA node path
     * @param haPspath Ha Physical Switch Node path
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    public void copyChildPSOpToHAPS(Node childPsNode,
                                    InstanceIdentifier<Node> haPath,
                                    InstanceIdentifier<Node> haPspath,
                                    ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {

        NodeBuilder haPSNodeBuilder = HwvtepHAUtil.getNodeBuilderForPath(haPspath);
        PhysicalSwitchAugmentationBuilder dstBuilder = new PhysicalSwitchAugmentationBuilder();

        PhysicalSwitchAugmentation src = childPsNode.getAugmentation(PhysicalSwitchAugmentation.class);

        Node existingHAPSNode = HwvtepHAUtil.readNode(tx, OPERATIONAL, haPspath);
        PhysicalSwitchAugmentation existingHAPSAugumentation =
                HwvtepHAUtil.getPhysicalSwitchAugmentationOfNode(existingHAPSNode);

        psAugmentationMerger.mergeOperationalData(dstBuilder, existingHAPSAugumentation, src, haPath);
        psNodeMerger.mergeOperationalData(haPSNodeBuilder, existingHAPSNode, childPsNode, haPath);
        mergeOpManagedByAttributes(src, dstBuilder, haPath);

        haPSNodeBuilder.addAugmentation(PhysicalSwitchAugmentation.class, dstBuilder.build());
        Node haPsNode = haPSNodeBuilder.build();
        tx.merge(OPERATIONAL, haPspath, haPsNode, true);
    }

}
