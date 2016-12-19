/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha;

import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.CONFIGURATION;
import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.OPERATIONAL;

import com.google.common.base.Optional;
import com.google.common.collect.Lists;
import com.google.common.collect.Sets;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ExecutionException;

import org.opendaylight.controller.md.sal.binding.api.DataObjectModification;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.genius.utils.hwvtep.HwvtepHACache;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.SwitchesCmd;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitchesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Managers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.ManagersBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.ManagersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Switches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.managers.ManagerOtherConfigs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.managers.ManagerOtherConfigsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.managers.ManagerOtherConfigsKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TpId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HwvtepHAUtil {

    static Logger LOG = LoggerFactory.getLogger(HwvtepHAUtil.class);

    //TODO reuse HWvtepSouthboundConstants
    public static final String HA_ENABLED = "ha_enabled";
    public static final String HWVTEP_ENTITY_TYPE = "hwvtep";
    public static final String TEP_PREFIX = "vxlan_over_ipv4:";
    public static final String HA_ID = "ha_id";
    public static final String HA_CHILDREN = "ha_children";
    public static final String PHYSICALSWITCH = "/physicalswitch/";
    public static final TopologyId HWVTEP_TOPOLOGY_ID = new TopologyId(new Uri("hwvtep:1"));
    public static final String UUID = "uuid";
    public static final String HWVTEP_URI_PREFIX = "hwvtep";
    public static final String MANAGER_KEY = "managerKey";

    static HwvtepHACache hwvtepHACache = HwvtepHACache.getInstance();

    public static HwvtepPhysicalLocatorRef buildLocatorRef(InstanceIdentifier<Node> nodeIid, String tepIp ) {
        InstanceIdentifier<TerminationPoint> tepId = buildTpId(nodeIid, tepIp);
        return new HwvtepPhysicalLocatorRef(tepId);
    }

    public static String getNodeIdVal(InstanceIdentifier<?> iid) {
        return iid.firstKeyOf(Node.class).getNodeId().getValue();
    }

    public static Uuid getUUid(String key) {
        return new Uuid(java.util.UUID.nameUUIDFromBytes(key.getBytes()).toString());
    }

    public static InstanceIdentifier<TerminationPoint> buildTpId(InstanceIdentifier<Node> nodeIid,String tepIp ) {
        String tpKeyStr = TEP_PREFIX + tepIp;
        TerminationPointKey tpKey = new TerminationPointKey(new TpId(tpKeyStr));
        InstanceIdentifier<TerminationPoint> plIid = nodeIid.child(TerminationPoint.class, tpKey);
        return plIid;
    }

    public static String getTepIpVal(HwvtepPhysicalLocatorRef locatorRef) {
        InstanceIdentifier<TerminationPoint> tpId = (InstanceIdentifier<TerminationPoint>) locatorRef.getValue();
        return tpId.firstKeyOf(TerminationPoint.class).getTpId().getValue().substring("vxlan_over_ipv4:".length());
    }

    public static String getLogicalSwitchSwitchName(HwvtepLogicalSwitchRef logicalSwitchRef) {
        InstanceIdentifier<LogicalSwitches> id = (InstanceIdentifier<LogicalSwitches>) logicalSwitchRef.getValue();
        return id.firstKeyOf(LogicalSwitches.class).getHwvtepNodeName().getValue();
    }

    public static String getNodeIdFromLocatorRef(HwvtepPhysicalLocatorRef locatorRef) {
        InstanceIdentifier<TerminationPoint> tpId = (InstanceIdentifier<TerminationPoint>) locatorRef.getValue();
        return tpId.firstKeyOf(Node.class).getNodeId().getValue();
    }

    public static String getNodeIdFromLogicalSwitches(HwvtepLogicalSwitchRef logicalSwitchRef) {
        InstanceIdentifier<LogicalSwitches> id = (InstanceIdentifier<LogicalSwitches>) logicalSwitchRef.getValue();
        return id.firstKeyOf(Node.class).getNodeId().getValue();
    }

    public static InstanceIdentifier<Node> createInstanceIdentifierFromHAId(String haUUidVal) {
        String nodeString = HWVTEP_URI_PREFIX + "://"
                + UUID + "/" + java.util.UUID.nameUUIDFromBytes(haUUidVal.getBytes()).toString();
        NodeId nodeId = new NodeId(new Uri(nodeString));
        NodeKey nodeKey = new NodeKey(nodeId);
        TopologyKey topoKey = new TopologyKey(HWVTEP_TOPOLOGY_ID);
        return InstanceIdentifier.builder(NetworkTopology.class)
                .child(Topology.class, topoKey)
                .child(Node.class, nodeKey)
                .build();
    }

    public static InstanceIdentifier<Node> convertToInstanceIdentifier(String nodeIdString) {
        NodeId nodeId = new NodeId(new Uri(nodeIdString));
        NodeKey nodeKey = new NodeKey(nodeId);
        TopologyKey topoKey = new TopologyKey(HWVTEP_TOPOLOGY_ID);
        return InstanceIdentifier.builder(NetworkTopology.class)
                .child(Topology.class, topoKey)
                .child(Node.class, nodeKey)
                .build();
    }

    /**
     * Build other config data for HA node .
     *
     * @param key The key as in HA child device other config
     * @param val The value as in HA child device other config
     * @return return other config object
     */
    public static ManagerOtherConfigsBuilder getOtherConfigBuilder(String key, String val) {
        ManagerOtherConfigsBuilder otherConfigsBuilder = new ManagerOtherConfigsBuilder();
        ManagerOtherConfigsKey otherConfigsKey = new ManagerOtherConfigsKey(key);
        otherConfigsBuilder.setKey(otherConfigsKey);
        otherConfigsBuilder.setOtherConfigKey(key);
        otherConfigsBuilder.setOtherConfigValue(val);
        return otherConfigsBuilder;
    }

    public static Node readNode(ReadWriteTransaction tx, LogicalDatastoreType storeType,
                                InstanceIdentifier<Node> nodeId)
            throws ReadFailedException {
        Optional<Node> optional = tx.read(storeType, nodeId).checkedGet();
        if (optional.isPresent()) {
            return optional.get();
        }
        return null;
    }

    public static String convertToGlobalNodeId(String psNodeId) {
        int idx = psNodeId.indexOf(PHYSICALSWITCH);
        if (idx > 0) {
            return psNodeId.substring(0, idx);
        }
        return psNodeId;
    }

    /**
     * Trnaform logical switch to nodepath passed .
     *
     * @param src {@link HwvtepLogicalSwitchRef} Logical Switch Ref which needs to be transformed
     * @param nodePath {@link InstanceIdentifier} src needs to be transformed to this path
     * @return ref {@link HwvtepLogicalSwitchRef} the transforrmed result
     */
    public static HwvtepLogicalSwitchRef convertLogicalSwitchRef(HwvtepLogicalSwitchRef src,
                                                                 InstanceIdentifier<Node> nodePath) {
        InstanceIdentifier<LogicalSwitches> srcId = (InstanceIdentifier<LogicalSwitches>)src.getValue();
        HwvtepNodeName switchName = srcId.firstKeyOf(LogicalSwitches.class).getHwvtepNodeName();
        InstanceIdentifier<LogicalSwitches> iid = nodePath.augmentation(HwvtepGlobalAugmentation.class)
                .child(LogicalSwitches.class, new LogicalSwitchesKey(switchName));
        HwvtepLogicalSwitchRef ref = new HwvtepLogicalSwitchRef(iid);
        return ref;
    }

    /**
     * Trnaform locator reference to nodepath passed .
     *
     * @param src {@link HwvtepPhysicalLocatorRef} Logical Switch Ref which needs to be transformed
     * @param nodePath {@link InstanceIdentifier} src needs to be transformed to this path
     * @return physicalLocatorRef {@link HwvtepPhysicalLocatorRef} the transforrmed result
     */
    public static HwvtepPhysicalLocatorRef convertLocatorRef(HwvtepPhysicalLocatorRef src,
                                                             InstanceIdentifier<Node> nodePath) {
        InstanceIdentifier<TerminationPoint> srcTepPath = (InstanceIdentifier<TerminationPoint>)src.getValue();
        TpId tpId = srcTepPath.firstKeyOf(TerminationPoint.class).getTpId();
        InstanceIdentifier<TerminationPoint> tpPath =
                nodePath.child(TerminationPoint.class, new TerminationPointKey(tpId));
        HwvtepPhysicalLocatorRef physicalLocatorRef = new HwvtepPhysicalLocatorRef(tpPath);
        return physicalLocatorRef;
    }

    public static boolean isEmptyList(List list) {
        if (list == null || list.size() == 0) {
            return true;
        }
        return false;
    }

    public static void mergeManagedByNode(Node psNode,
                                          PhysicalSwitchAugmentationBuilder builder,
                                          InstanceIdentifier<Node> haNodePath,
                                          InstanceIdentifier<Node> haPsPath, NodeId haPSNodeId) {
        PhysicalSwitchAugmentation psAugmentation = psNode.getAugmentation(PhysicalSwitchAugmentation.class);
        builder.setManagedBy(new HwvtepGlobalRef(haNodePath));
        builder.setHwvtepNodeName(psAugmentation.getHwvtepNodeName());
        builder.setHwvtepNodeDescription(psAugmentation.getHwvtepNodeDescription());
        builder.setTunnelIps(psAugmentation.getTunnelIps());
        builder.setPhysicalSwitchUuid(getUUid(psAugmentation.getHwvtepNodeName().getValue()));
    }

    public static Node getOriginal(DataObjectModification<Node> mod) {
        Node node = null;
        switch (mod.getModificationType()) {
            case SUBTREE_MODIFIED:
                node = mod.getDataBefore();
                break;
            case WRITE:
                if (mod.getDataBefore() !=  null) {
                    node = mod.getDataBefore();
                }
                break;
            case DELETE:
                node = mod.getDataBefore();
                break;
            default:
                break;
        }
        return node;
    }

    public static Node getUpdated(DataObjectModification<Node> mod) {
        Node node = null;
        switch (mod.getModificationType()) {
            case SUBTREE_MODIFIED:
                node = mod.getDataAfter();
                break;
            case WRITE:
                if (mod.getDataAfter() !=  null) {
                    node = mod.getDataAfter();
                }
                break;
            default:
                break;
        }
        return node;
    }

    public static Node getCreated(DataObjectModification<Node> mod) {
        if ((mod.getModificationType() == DataObjectModification.ModificationType.WRITE)
                && (mod.getDataBefore() == null)) {
            return mod.getDataAfter();
        }
        return null;
    }

    public static Node getRemoved(DataObjectModification<Node> mod) {
        if (mod.getModificationType() == DataObjectModification.ModificationType.DELETE) {
            return mod.getDataBefore();
        }
        return null;
    }

    public static InstanceIdentifier<Node> getGlobalNodePathFromPSNode(Node psNode) {
        if (psNode == null
                || psNode.getAugmentation(PhysicalSwitchAugmentation.class) == null
                || psNode.getAugmentation(PhysicalSwitchAugmentation.class).getManagedBy() == null) {
            return null;
        }
        return (InstanceIdentifier<Node>)psNode
                .getAugmentation(PhysicalSwitchAugmentation.class).getManagedBy().getValue();
    }

    public static InstanceIdentifier<Node> convertPsPath(Node psNode, InstanceIdentifier<Node> nodePath) {
        String psNodeId = psNode.getNodeId().getValue();
        String psName = psNodeId.substring(psNodeId.indexOf(PHYSICALSWITCH) + PHYSICALSWITCH.length());
        String haPsNodeIdVal = nodePath.firstKeyOf(Node.class).getNodeId().getValue() + PHYSICALSWITCH + psName;
        InstanceIdentifier<Node> haPsPath = convertToInstanceIdentifier(haPsNodeIdVal);
        return haPsPath;
    }

    public static NodeBuilder getNodeBuilderForPath(InstanceIdentifier<Node> haPath) {
        NodeBuilder nodeBuilder = new NodeBuilder();
        nodeBuilder.setNodeId(haPath.firstKeyOf(Node.class).getNodeId());
        return nodeBuilder;
    }

    public static String getHAIdFromManagerOtherConfig(Node node) {
        if (node.getAugmentation(HwvtepGlobalAugmentation.class) == null) {
            return null;
        }
        HwvtepGlobalAugmentation globalAugmentation = node.getAugmentation(HwvtepGlobalAugmentation.class);
        if (globalAugmentation != null) {
            List<Managers> managers = globalAugmentation.getManagers();
            if (managers != null && managers.size() > 0 && managers.get(0).getManagerOtherConfigs() != null) {
                for (ManagerOtherConfigs configs : managers.get(0).getManagerOtherConfigs()) {
                    if (configs.getOtherConfigKey().equals(HA_ID)) {
                        return configs.getOtherConfigValue();
                    }
                }
            }
        }
        return null;
    }

    /**
     * Returns ha child node path from ha node of config data tree.
     *
     * @param haGlobalConfigNodeOptional HA global node
     * @return ha Child ids
     */
    public static  List<NodeId> getChildNodeIdsFromManagerOtherConfig(Optional<Node> haGlobalConfigNodeOptional) {
        List<NodeId> childNodeIds = Lists.newArrayList();
        if (!haGlobalConfigNodeOptional.isPresent()) {
            return childNodeIds;
        }
        HwvtepGlobalAugmentation augmentation =
                haGlobalConfigNodeOptional.get().getAugmentation(HwvtepGlobalAugmentation.class);
        if (augmentation != null && augmentation.getManagers() != null
                && augmentation.getManagers().size() > 0) {
            Managers managers = augmentation.getManagers().get(0);
            if (null == managers.getManagerOtherConfigs()) {
                return childNodeIds;
            }
            for (ManagerOtherConfigs otherConfigs : managers.getManagerOtherConfigs()) {
                if (otherConfigs.getOtherConfigKey().equals(HA_CHILDREN)) {
                    String nodeIdsVal = otherConfigs.getOtherConfigValue();
                    if (nodeIdsVal != null) {
                        String[] parts = nodeIdsVal.split(",");
                        for (String part : parts) {
                            childNodeIds.add(new NodeId(part));
                        }
                    }

                }
            }
        }
        return childNodeIds;
    }

    /**
     * Return PS children for passed PS node .
     *
     * @param psNodId PS node path
     * @return child Switches
     */
    public static Set<InstanceIdentifier<Node>> getPSChildrenIdsForHAPSNode(String psNodId) {
        if (psNodId.indexOf(PHYSICALSWITCH) < 0) {
            return Collections.emptySet();
        }
        String nodeId = convertToGlobalNodeId(psNodId);
        InstanceIdentifier<Node> iid = convertToInstanceIdentifier(nodeId);
        if (hwvtepHACache.isHAParentNode(iid)) {
            Set<InstanceIdentifier<Node>> childSwitchIds = new HashSet<>();
            Set<InstanceIdentifier<Node>> childGlobalIds = hwvtepHACache.getChildrenForHANode(iid);
            final String append = psNodId.substring(psNodId.indexOf(PHYSICALSWITCH));
            for (InstanceIdentifier<Node> childId : childGlobalIds) {
                String childIdVal = childId.firstKeyOf(Node.class).getNodeId().getValue();
                childSwitchIds.add(convertToInstanceIdentifier(childIdVal + append));
            }
            return childSwitchIds;
        }
        return Collections.EMPTY_SET;
    }

    public static HwvtepGlobalAugmentation getGlobalAugmentationOfNode(Node node) {
        HwvtepGlobalAugmentation result = null;
        if (node != null) {
            result = node.getAugmentation(HwvtepGlobalAugmentation.class);
        }
        if (result == null) {
            result = new HwvtepGlobalAugmentationBuilder().build();
        }
        return result;
    }

    public static PhysicalSwitchAugmentation getPhysicalSwitchAugmentationOfNode(Node psNode) {
        PhysicalSwitchAugmentation result = null;
        if (psNode != null) {
            result = psNode.getAugmentation(PhysicalSwitchAugmentation.class);
        }
        if (result == null) {
            result = new PhysicalSwitchAugmentationBuilder().build();
        }
        return result;
    }

    /**
     * Transform child managers (Source) to HA managers using HA node path.
     *
     * @param childNode Child Node
     * @param haGlobalCfg HA global config node
     * @return Transformed managers
     */
    public static List<Managers> buildManagersForHANode(Node childNode, Optional<Node> haGlobalCfg) {

        Set<NodeId> nodeIds = Sets.newHashSet(childNode.getNodeId());
        List<NodeId> childNodeIds = getChildNodeIdsFromManagerOtherConfig(haGlobalCfg);
        nodeIds.addAll(childNodeIds);

        ManagersBuilder builder1 = new ManagersBuilder();

        builder1.setKey(new ManagersKey(new Uri(MANAGER_KEY)));
        List<ManagerOtherConfigs> otherConfigses = Lists.newArrayList();
        StringBuffer stringBuffer = new StringBuffer();
        for (NodeId nodeId : nodeIds) {
            stringBuffer.append(nodeId.getValue());
            stringBuffer.append(",");
        }

        String children = stringBuffer.substring(0, stringBuffer.toString().length() - 1);

        otherConfigses.add(getOtherConfigBuilder(HA_CHILDREN, children).build());
        builder1.setManagerOtherConfigs(otherConfigses);
        List<Managers> managers = Lists.newArrayList();
        managers.add(builder1.build());
        return managers;
    }

    /**
     * Transform child switch (Source) to HA swicthes using HA node path.
     *
     * @param childNode  HA child node
     * @param haNodePath  HA node path
     * @param haNode Ha node object
     * @return Transformed switches
     */
    public static List<Switches> buildSwitchesForHANode(Node childNode,
                                              InstanceIdentifier<Node> haNodePath,
                                              Optional<Node> haNode) {
        List<Switches> psList = new ArrayList<>();
        boolean switchesAlreadyPresent = false;
        if (haNode.isPresent()) {
            Node node = haNode.get();
            HwvtepGlobalAugmentation augmentation = node.getAugmentation(HwvtepGlobalAugmentation.class);
            if (augmentation != null) {
                if (augmentation.getSwitches() != null) {
                    if (augmentation.getSwitches().size() > 0) {
                        switchesAlreadyPresent = true;
                    }
                }
            }
        }
        if (!switchesAlreadyPresent) {
            HwvtepGlobalAugmentation augmentation = childNode.getAugmentation(HwvtepGlobalAugmentation.class);
            if (augmentation != null && augmentation.getSwitches() != null) {
                List<Switches> src = augmentation.getSwitches();
                if (src != null && src.size() > 0) {
                    psList.add(new SwitchesCmd().transform(haNodePath, src.get(0)));
                }
            }
        }
        return psList;
    }

    /**
     * Build HA Global node from child nodes in config data tress.
     *
     * @param tx Transaction
     * @param childNode Child Node object
     * @param haNodePath Ha node path
     * @param haGlobalCfg HA global node object
     */
    public static void buildGlobalConfigForHANode(ReadWriteTransaction tx,
                                                  Node childNode,
                                                  InstanceIdentifier<Node> haNodePath,
                                                  Optional<Node> haGlobalCfg) {

        NodeBuilder nodeBuilder = new NodeBuilder();
        HwvtepGlobalAugmentationBuilder hwvtepGlobalBuilder = new HwvtepGlobalAugmentationBuilder();
        hwvtepGlobalBuilder.setSwitches(buildSwitchesForHANode(childNode, haNodePath, haGlobalCfg));
        hwvtepGlobalBuilder.setManagers(buildManagersForHANode(childNode, haGlobalCfg));

        nodeBuilder.setNodeId(haNodePath.firstKeyOf(Node.class).getNodeId());
        nodeBuilder.addAugmentation(HwvtepGlobalAugmentation.class, hwvtepGlobalBuilder.build());
        Node configHANode = nodeBuilder.build();
        tx.merge(CONFIGURATION, haNodePath, configHANode,Boolean.TRUE);
    }

    public static void deleteNodeIfPresent(ReadWriteTransaction tx,
                                           LogicalDatastoreType logicalDatastoreType,
                                           InstanceIdentifier<?> iid) throws ReadFailedException {
        if (tx.read(logicalDatastoreType, iid).checkedGet().isPresent()) {
            LOG.info("Deleting child node {}", getNodeIdVal(iid));
            tx.delete(logicalDatastoreType, iid);
        }
    }

    /**
     * Delete PS data of HA node of Config Data tree.
     *
     * @param key Node object
     * @param haNode Ha Node from which to be deleted
     * @param tx Transaction
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    public static void deletePSNodesOfNode(InstanceIdentifier<Node> key,
                                           Node haNode,
                                           ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {
        //read from switches attribute and clean up them
        HwvtepGlobalAugmentation globalAugmentation = haNode.getAugmentation(HwvtepGlobalAugmentation.class);
        if (globalAugmentation == null) {
            return;
        }
        HashMap<InstanceIdentifier<Node>,Boolean> deleted = new HashMap<>();
        List<Switches> switches = globalAugmentation.getSwitches();
        if (switches != null) {
            for (Switches switche : switches) {
                InstanceIdentifier<Node> psId = (InstanceIdentifier<Node>)switche.getSwitchRef().getValue();
                deleteNodeIfPresent(tx, CONFIGURATION, psId);
                deleted.put(psId, Boolean.TRUE);
            }
        }
        //also read from managed by attribute of switches and cleanup them as a back up if the above cleanup fails
        Optional<Topology> topologyOptional = tx
                .read(CONFIGURATION, (InstanceIdentifier<Topology>)key.firstIdentifierOf(Topology.class)).checkedGet();
        String deletedNodeId = key.firstKeyOf(Node.class).getNodeId().getValue();
        if (topologyOptional.isPresent()) {
            Topology topology = topologyOptional.get();
            if (topology.getNode() != null) {
                for (Node psNode : topology.getNode()) {
                    PhysicalSwitchAugmentation ps = psNode.getAugmentation(PhysicalSwitchAugmentation.class);
                    if (ps != null) {
                        InstanceIdentifier<Node> iid = (InstanceIdentifier<Node>)ps.getManagedBy().getValue();
                        String nodeIdVal = iid.firstKeyOf(Node.class).getNodeId().getValue();
                        if (deletedNodeId.equals(nodeIdVal)) {
                            InstanceIdentifier<Node> psNodeId =
                                    convertToInstanceIdentifier(psNode.getNodeId().getValue());
                            if (deleted.containsKey(psNodeId)) {
                                deleteNodeIfPresent(tx, CONFIGURATION, psNodeId);
                            }
                        }
                    }
                }
            }
        }
    }

    public static void updateL2GwCacheNodeId(Node updatedChildNode, InstanceIdentifier<Node> iid) {
        String haNodeIdVal = getNodeIdVal(iid);
        ConcurrentMap<String, L2GatewayDevice> l2Devices = L2GatewayCacheUtils.getCache();
        if (l2Devices != null) {
            for (String psName : l2Devices.keySet()) {
                L2GatewayDevice l2Device = l2Devices.get(psName);
                if (updatedChildNode.getNodeId().getValue().equals(l2Device.getHwvtepNodeId())) {
                    LOG.info("Replaced the l2gw device cache entry for device {} with val {}",
                            l2Device.getDeviceName(), l2Device.getHwvtepNodeId());
                    l2Device.setHwvtepNodeId(haNodeIdVal);
                    L2GatewayCacheUtils.addL2DeviceToCache(psName, l2Device);
                }
            }
        }
    }

    /**
     * Delete switches from Node in Operational Data Tree .
     *
     * @param haPath HA node path from whih switches will be deleted
     * @param tx  Transaction object
     * @throws ReadFailedException  Exception thrown if read fails
     * @throws ExecutionException  Exception thrown if Execution fail
     * @throws InterruptedException Thread interrupted Exception
     */
    public static void deleteSwitchesManagedByNode(InstanceIdentifier<Node> haPath,
                                                   ReadWriteTransaction tx)
            throws InterruptedException, ExecutionException, ReadFailedException {

        Optional<Node> nodeOptional = tx.read(OPERATIONAL, haPath).checkedGet();
        if (!nodeOptional.isPresent()) {
            return;
        }
        Node node = nodeOptional.get();
        HwvtepGlobalAugmentation globalAugmentation = node.getAugmentation(HwvtepGlobalAugmentation.class);
        if (globalAugmentation == null) {
            return;
        }
        List<Switches> switches = globalAugmentation.getSwitches();
        if (switches != null) {
            for (Switches switche : switches) {
                InstanceIdentifier<Node> id = (InstanceIdentifier<Node>)switche.getSwitchRef().getValue();
                deleteNodeIfPresent(tx, OPERATIONAL, id);
            }
        }
    }

    /**
     * Returns true/false if all the childrens are deleted from Operational Data store.
     *
     * @param children IID for the child node to read from OP data tree
     * @param tx Transaction
     * @return true/false boolean
     * @throws ReadFailedException Exception thrown if read fails
     */
    public static boolean areAllChildDeleted(Set<InstanceIdentifier<Node>> children,
                                             ReadWriteTransaction tx) throws ReadFailedException {
        for (InstanceIdentifier<Node> childId : children) {
            if (tx.read(OPERATIONAL, childId).checkedGet().isPresent()) {
                return false;
            }
        }
        return true;
    }
}
