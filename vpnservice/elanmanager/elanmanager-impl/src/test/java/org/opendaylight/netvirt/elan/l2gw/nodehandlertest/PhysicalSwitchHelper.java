/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.nodehandlertest;

import com.google.common.collect.Lists;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.genius.utils.hwvtep.HwvtepSouthboundConstants;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.l2.types.rev130827.VlanId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalPortAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalPortAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitchesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindings;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindingsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindingsKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TpId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Created by eaksahu on 8/8/2016.
 */
public class PhysicalSwitchHelper {
    static Logger LOG = LoggerFactory.getLogger(PhysicalSwitchHelper.class);

    static InstanceIdentifier<Node> dId;

    public static InstanceIdentifier<Node> getPhysicalSwitchInstanceIdentifier(InstanceIdentifier<Node> iid,
                                                                               String switchName) {
        NodeId id = iid.firstKeyOf(Node.class).getNodeId();
        String nodeString = id.getValue() + "/physicalswitch/" + switchName;
        NodeId nodeId = new NodeId(new Uri(nodeString));
        NodeKey nodeKey = new NodeKey(nodeId);
        TopologyKey topoKey = new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID);
        return InstanceIdentifier.builder(NetworkTopology.class)
                .child(Topology.class, topoKey)
                .child(Node.class, nodeKey)
                .build();
    }

    public static List<TerminationPoint> addPhysicalSwitchTerminationPoints(InstanceIdentifier<Node> switchIid,
                                                                            WriteTransaction transaction,
                                                                            List<String> portNames) {
        List<TerminationPoint> tps = Lists.newArrayList();
        for (String portName : portNames) {
            tps.add(buildTerminationPointForPhysicalSwitch(switchIid, portName, transaction, getVlanBindingData(1)));
        }
        return tps;
    }

    public static TerminationPoint buildTerminationPointForPhysicalSwitch(InstanceIdentifier<Node> switchIid,
                                                                          String portName, WriteTransaction transaction,
                                                                          Map<Long, String> vlanBindingData) {
        TerminationPointKey tpKey = new TerminationPointKey(new TpId(portName));
        TerminationPointBuilder tpBuilder = new TerminationPointBuilder();
        tpBuilder.setKey(tpKey);
        tpBuilder.setTpId(tpKey.getTpId());
        switchIid.firstKeyOf(Node.class);
        InstanceIdentifier<TerminationPoint> tpPath = switchIid.child(TerminationPoint.class,
                new TerminationPointKey(new TpId(portName)));
        HwvtepPhysicalPortAugmentationBuilder tpAugmentationBuilder =
                new HwvtepPhysicalPortAugmentationBuilder();
        buildTerminationPoint(tpAugmentationBuilder, portName, vlanBindingData);
        tpBuilder.addAugmentation(HwvtepPhysicalPortAugmentation.class, tpAugmentationBuilder.build());
        return tpBuilder.build();
    }

    public static void buildTerminationPoint(HwvtepPhysicalPortAugmentationBuilder tpAugmentationBuilder,
                                             String portName, Map<Long, String> vlanBindingData) {
        updatePhysicalPortId(portName, tpAugmentationBuilder);
        updatePort(portName, tpAugmentationBuilder, vlanBindingData);
    }

    public static void updatePhysicalPortId(String portName,
                                            HwvtepPhysicalPortAugmentationBuilder tpAugmentationBuilder) {
        tpAugmentationBuilder.setHwvtepNodeName(new HwvtepNodeName(portName));
        tpAugmentationBuilder.setHwvtepNodeDescription("");
    }

    public static void updatePort(String portName, HwvtepPhysicalPortAugmentationBuilder tpAugmentationBuilder,
                                  Map<Long, String> vlanBindings) {
        updateVlanBindings(vlanBindings, tpAugmentationBuilder);
        tpAugmentationBuilder.setPhysicalPortUuid(new Uuid(UUID.randomUUID().toString()));
    }

    public static void updateVlanBindings(Map<Long, String> vlanBindings,
                                          HwvtepPhysicalPortAugmentationBuilder tpAugmentationBuilder) {
        List<VlanBindings> vlanBindingsList = new ArrayList<>();
        for (Map.Entry<Long, String> vlanBindingEntry : vlanBindings.entrySet()) {
            Long vlanBindingKey = vlanBindingEntry.getKey();
            String logicalSwitch = vlanBindingEntry.getValue();
            if (logicalSwitch != null && vlanBindingKey != null) {
                vlanBindingsList.add(createVlanBinding(vlanBindingKey, logicalSwitch));
            }
        }
        tpAugmentationBuilder.setVlanBindings(vlanBindingsList);
    }

    public static VlanBindings createVlanBinding(Long key, String logicalSwitch) {
        VlanBindingsBuilder vbBuilder = new VlanBindingsBuilder();
        VlanBindingsKey vbKey = new VlanBindingsKey(new VlanId(key.intValue()));
        vbBuilder.setKey(vbKey);
        vbBuilder.setVlanIdKey(vbKey.getVlanIdKey());
        HwvtepLogicalSwitchRef hwvtepLogicalSwitchRef =
                new HwvtepLogicalSwitchRef(createInstanceIdentifier(logicalSwitch));
        vbBuilder.setLogicalSwitchRef(hwvtepLogicalSwitchRef);
        return vbBuilder.build();
    }

    public static InstanceIdentifier<LogicalSwitches> createInstanceIdentifier(String logicalSwitch) {
        NodeId id = dId.firstKeyOf(Node.class).getNodeId();
        NodeKey nodeKey = new NodeKey(id);
        InstanceIdentifier<LogicalSwitches> iid = null;
        iid = InstanceIdentifier.builder(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(HwvtepSouthboundConstants.HWVTEP_TOPOLOGY_ID))
                .child(Node.class, nodeKey).augmentation(HwvtepGlobalAugmentation.class)
                .child(LogicalSwitches.class, new LogicalSwitchesKey(new HwvtepNodeName(logicalSwitch)))
                .build();
        return iid;
    }

    public static Map<Long, String> getVlanBindingData(int mapSize) {
        Map<Long, String> vlanBindings = new HashMap<>();
        for (Integer i = 0; i < mapSize; i++) {
            i = i * 100;
            vlanBindings.put(Long.valueOf(i), "9227c228-6bba-4bbe-bdb8-6942768ff0f1");
        }
        return vlanBindings;
    }

}
