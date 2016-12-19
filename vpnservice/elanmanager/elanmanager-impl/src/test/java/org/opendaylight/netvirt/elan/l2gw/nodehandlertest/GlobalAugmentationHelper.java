/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.nodehandlertest;

import com.google.common.collect.Lists;
import java.util.List;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Switches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.SwitchesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.SwitchesKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

/**
 * Created by eaksahu on 8/9/2016.
 */
public class GlobalAugmentationHelper {
    public static void addLogicalSwitches(HwvtepGlobalAugmentationBuilder augmentationBuilder,
                                          List<String> logicalSwitchData) {
        List<LogicalSwitches> logicalSwitches = Lists.newArrayList();
        for (int i = 0; i < logicalSwitchData.size(); i += 2) {
            logicalSwitches.add(TestBuilders.buildLogicalSwitch(logicalSwitchData.get(i),
                    logicalSwitchData.get(i + 1)));
        }
        augmentationBuilder.setLogicalSwitches(logicalSwitches);
    }

    public static Node updateLogicalSwitches(Node node, List<String> logicalSwitchData) {
        HwvtepGlobalAugmentationBuilder hwvtepGlobalAugmentationBuilder = new HwvtepGlobalAugmentationBuilder();
        List<LogicalSwitches> logicalSwitches = Lists.newArrayList();
        for (int i = 0; i < logicalSwitchData.size(); i += 2) {
            logicalSwitches.add(TestBuilders.buildLogicalSwitch(logicalSwitchData.get(i),
                    logicalSwitchData.get(i + 1)));
        }
        hwvtepGlobalAugmentationBuilder.setLogicalSwitches(logicalSwitches);
        NodeBuilder nodeBuilder = new NodeBuilder();
        nodeBuilder.setNodeId(node.getNodeId());
        nodeBuilder.addAugmentation(HwvtepGlobalAugmentation.class, hwvtepGlobalAugmentationBuilder.build());
        return nodeBuilder.build();
    }

    public static void addLocalMcastMacs(InstanceIdentifier<Node> iid,
                                         HwvtepGlobalAugmentationBuilder augmentationBuilder,
                                         List<String> localMcastData) {
        List<LocalMcastMacs> localMcastMacses = Lists.newArrayList();
        for (int i = 0; i < localMcastData.size(); i += 3) {
            localMcastMacses.add(TestBuilders.buildLocalMcastMacs(iid, localMcastData.get(i), localMcastData.get(i + 1),
                    localMcastData.get(i + 2)));
        }
        augmentationBuilder.setLocalMcastMacs(localMcastMacses);
    }

    public static void addRemoteMcastMacs(InstanceIdentifier<Node> iid,
                                          HwvtepGlobalAugmentationBuilder augmentationBuilder,
                                          List<String> remoteMcastData) {
        List<RemoteMcastMacs> remoteMcastMacses = Lists.newArrayList();
        for (int i = 0; i < remoteMcastData.size(); i += 4) {
            remoteMcastMacses.add(TestBuilders.buildRemoteMcastMacs(iid, remoteMcastData.get(i),
                    remoteMcastData.get(i + 1), new String[]{remoteMcastData.get(i + 2),
                            remoteMcastData.get(i + 3)}));
        }
        augmentationBuilder.setRemoteMcastMacs(remoteMcastMacses);
    }

    public static void addLocalUcastMacs(InstanceIdentifier<Node> iid,
                                         HwvtepGlobalAugmentationBuilder augmentationBuilder,
                                         List<String> localUcastData) {
        List<LocalUcastMacs> localUcastMacses = Lists.newArrayList();
        for (int i = 0; i < localUcastData.size(); i += 4) {
            localUcastMacses.add(TestBuilders.buildLocalUcastMacs(iid, localUcastData.get(i),
                    localUcastData.get(i + 1), localUcastData.get(i + 2), localUcastData.get(i + 3)));
        }
        augmentationBuilder.setLocalUcastMacs(localUcastMacses);
    }

    public static void addRemoteUcastMacs(InstanceIdentifier<Node> iid,
                                          HwvtepGlobalAugmentationBuilder augmentationBuilder,
                                          List<String> remoteUcastMacdata) {
        List<RemoteUcastMacs> remoteUcastMacses = Lists.newArrayList();
        for (int i = 0; i < remoteUcastMacdata.size(); i += 4) {
            remoteUcastMacses.add(TestBuilders.buildRemoteUcastMacs(iid, remoteUcastMacdata.get(i),
                    remoteUcastMacdata.get(i + 1),
                    remoteUcastMacdata.get(i + 2), remoteUcastMacdata.get(i + 3)));
        }
        augmentationBuilder.setRemoteUcastMacs(remoteUcastMacses);
    }

    //physicallocators
    public static void addGlobalTerminationPoints(NodeBuilder nodeBuilder, InstanceIdentifier<Node> nodeIid,
                                                  List<String> globalTerminationPointIp) {
        List<TerminationPoint> terminationPoints = Lists.newArrayList();
        for (int i = 0; i < globalTerminationPointIp.size(); i++) {
            terminationPoints.add(TestBuilders.buildTerminationPoint(nodeIid, globalTerminationPointIp.get(i)));
        }
        nodeBuilder.setTerminationPoint(terminationPoints);
    }

    public static void addSwitches(HwvtepGlobalAugmentationBuilder augmentationBuilder, InstanceIdentifier<Node> psId) {
        List<Switches> switches = Lists.newArrayList();

        SwitchesBuilder switchesBuilder = new SwitchesBuilder();
        switchesBuilder.setKey(new SwitchesKey(new HwvtepPhysicalSwitchRef(psId)));
        switchesBuilder.setSwitchRef(new HwvtepPhysicalSwitchRef(psId));
        switches.add(switchesBuilder.build());

        augmentationBuilder.setSwitches(switches);
    }
}
