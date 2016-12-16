/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.nodehandlertest;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import com.google.common.collect.Sets;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.LocalMcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.LocalUcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.LogicalSwitchesCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.RemoteMcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.RemoteUcastCmd;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalPortAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteMcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.RemoteUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Switches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.port.attributes.VlanBindings;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TpId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPointKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Created by ekvsver on 8/6/2016.
 */
public class TestComparators {
    static Logger LOG = LoggerFactory.getLogger(TestComparators.class);

    public static void verifySwitches(Node globalOpNode, Node psOpNode) {
        for (Switches switches : globalOpNode.getAugmentation(HwvtepGlobalAugmentation.class).getSwitches()) {
            String switchValue = switches.getSwitchRef().getValue().firstKeyOf(Node.class).getNodeId().getValue();
            assertEquals("Switch Name should be equal", switchValue, psOpNode.getNodeId().getValue());
        }
    }

    public static void compareLogicalSwitches(Node src, Node dst, InstanceIdentifier<Node> nodePath) {
        LogicalSwitchesCmd cmd = new LogicalSwitchesCmd();
        HwvtepGlobalAugmentation d1Aug = src.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = dst.getAugmentation(HwvtepGlobalAugmentation.class);

        List<LogicalSwitches> d1Values =
                d1Aug.getLogicalSwitches() != null ? d1Aug.getLogicalSwitches() : new ArrayList<LogicalSwitches>();
        List<LogicalSwitches> result1 = cmd.transform(nodePath, d1Values);
        List<LogicalSwitches> result2 = cmd.transform(nodePath, haAug.getLogicalSwitches());

        Set<LogicalSwitches> set1 = Sets.newHashSet(result1);
        Set<LogicalSwitches> set2 = Sets.newHashSet(result2);
        assertEquals("should have equal logical switches", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void compareLogicalSwitches(Node d1, Node d2, Node ha, InstanceIdentifier<Node> nodePath) {
        LogicalSwitchesCmd cmd = new LogicalSwitchesCmd();
        HwvtepGlobalAugmentation d1Aug = d1.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation d2Aug = d2.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = ha.getAugmentation(HwvtepGlobalAugmentation.class);

        List<LogicalSwitches> d1Values =
                d1Aug.getLogicalSwitches() != null ? d1Aug.getLogicalSwitches() : new ArrayList<LogicalSwitches>();
        List<LogicalSwitches> result1 = cmd.transform(nodePath, d1Values);
        List<LogicalSwitches> d2Values =
                d2Aug.getLogicalSwitches() != null ? d2Aug.getLogicalSwitches() : new ArrayList<LogicalSwitches>();
        List<LogicalSwitches> result2 = cmd.transform(nodePath, d2Values);
        //Merge data of both d1 and d2 logical switch info should be same as ha
        Set<LogicalSwitches> set1 = new HashSet<>();
        set1.addAll(result1);
        set1.addAll(result2);
        List<LogicalSwitches> result = cmd.transform(nodePath, haAug.getLogicalSwitches());
        Set<LogicalSwitches> set2 = Sets.newHashSet(result);
        assertEquals("should have equal logical switches", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void compareRemoteUcastMacs(Node src, Node dst, InstanceIdentifier<Node> nodePath) {
        RemoteUcastCmd cmd = new RemoteUcastCmd();
        HwvtepGlobalAugmentation d1Aug = src.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = dst.getAugmentation(HwvtepGlobalAugmentation.class);
        List<RemoteUcastMacs> d1Values =
                d1Aug.getRemoteUcastMacs() != null ? d1Aug.getRemoteUcastMacs() : new ArrayList<RemoteUcastMacs>();
        List<RemoteUcastMacs> result1 = cmd.transform(nodePath, d1Values);
        List<RemoteUcastMacs> result2 = cmd.transform(nodePath, haAug.getRemoteUcastMacs());

        RemoteUcastMacs mac1 = result1.get(0);
        RemoteUcastMacs mac2 = result2.get(0);
        LOG.info("Mac1{} ", mac1);
        LOG.info("Mac2{}", mac2);
        Set<RemoteUcastMacs> set1 = Sets.newHashSet(result1);
        Set<RemoteUcastMacs> set2 = Sets.newHashSet(result2);
        assertEquals("should have equal remote ucast macs ", 0, Sets.symmetricDifference(set1, set2).size());
    }

    public static void compareRemoteUcastMacs(Node d1, Node d2, Node ha, InstanceIdentifier<Node> nodePath) {
        RemoteUcastCmd cmd = new RemoteUcastCmd();
        HwvtepGlobalAugmentation d1Aug = d1.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation d2Aug = d2.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = ha.getAugmentation(HwvtepGlobalAugmentation.class);

        List<RemoteUcastMacs> d1Values =
                d1Aug.getRemoteUcastMacs() != null ? d1Aug.getRemoteUcastMacs() : new ArrayList<RemoteUcastMacs>();
        List<RemoteUcastMacs> result1 = cmd.transform(nodePath, d1Values);

        List<RemoteUcastMacs> d2Values =
                d2Aug.getRemoteUcastMacs() != null ? d2Aug.getRemoteUcastMacs() : new ArrayList<RemoteUcastMacs>();
        List<RemoteUcastMacs> result2 = cmd.transform(nodePath, d2Values);
        List<RemoteUcastMacs> ruMacList = new ArrayList<RemoteUcastMacs>();
        ruMacList.addAll(result1);
        ruMacList.addAll(result2);
        List<RemoteUcastMacs> result = cmd.transform(nodePath, haAug.getRemoteUcastMacs());

        Set<RemoteUcastMacs> set1 = Sets.newHashSet(ruMacList);
        Set<RemoteUcastMacs> set2 = Sets.newHashSet(result);
        assertEquals("should have equal remote ucast macs ", 0, Sets.difference(set1, set2).size());

    }

    public static void compareRemoteMcastMacs(Node src, Node dst, InstanceIdentifier<Node> nodePath) {
        RemoteMcastCmd cmd = new RemoteMcastCmd();
        HwvtepGlobalAugmentation d1Aug = src.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = dst.getAugmentation(HwvtepGlobalAugmentation.class);
        List<RemoteMcastMacs> d1Values =
                d1Aug.getRemoteMcastMacs() != null ? d1Aug.getRemoteMcastMacs() : new ArrayList<RemoteMcastMacs>();
        List<RemoteMcastMacs> result1 = cmd.transform(nodePath, d1Values);
        List<RemoteMcastMacs> result2 = cmd.transform(nodePath, haAug.getRemoteMcastMacs());

        Set<RemoteMcastMacs> set1 = Sets.newHashSet(result1);
        Set<RemoteMcastMacs> set2 = Sets.newHashSet(result2);
        assertEquals("should have equal remote ucast macs ", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void compareRemoteMcastMacs(Node d1, Node d2, Node ha, InstanceIdentifier<Node> nodePath) {
        RemoteMcastCmd cmd = new RemoteMcastCmd();
        HwvtepGlobalAugmentation d1Aug = d1.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation d2Aug = d2.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = ha.getAugmentation(HwvtepGlobalAugmentation.class);

        List<RemoteMcastMacs> d1Values =
                d1Aug.getRemoteMcastMacs() != null ? d1Aug.getRemoteMcastMacs() : new ArrayList<RemoteMcastMacs>();
        List<RemoteMcastMacs> result1 = cmd.transform(nodePath, d1Values);

        List<RemoteMcastMacs> d2Values =
                d2Aug.getRemoteMcastMacs() != null ? d2Aug.getRemoteMcastMacs() : new ArrayList<RemoteMcastMacs>();
        List<RemoteMcastMacs> result2 = cmd.transform(nodePath, d2Values);
        List<RemoteMcastMacs> rmMacList = new ArrayList<RemoteMcastMacs>();
        rmMacList.addAll(result1);
        rmMacList.addAll(result2);

        List<RemoteMcastMacs> result = cmd.transform(nodePath, haAug.getRemoteMcastMacs());

        Set<RemoteMcastMacs> set1 = Sets.newHashSet(rmMacList);
        Set<RemoteMcastMacs> set2 = Sets.newHashSet(result);
        assertEquals("should have equal remote Mcast macs ", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void compareLocalUcastMacs(Node src, Node dst, InstanceIdentifier<Node> nodePath) {
        LocalUcastCmd cmd = new LocalUcastCmd();
        HwvtepGlobalAugmentation d1Aug = src.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = dst.getAugmentation(HwvtepGlobalAugmentation.class);
        List<LocalUcastMacs> d1Values =
                d1Aug.getLocalUcastMacs() != null ? d1Aug.getLocalUcastMacs() : new ArrayList<LocalUcastMacs>();
        List<LocalUcastMacs> result1 = cmd.transform(nodePath, d1Values);
        List<LocalUcastMacs> result2 = cmd.transform(nodePath, haAug.getLocalUcastMacs());

        Set<LocalUcastMacs> set1 = Sets.newHashSet(result1);
        Set<LocalUcastMacs> set2 = Sets.newHashSet(result2);
        assertEquals("should have equal remote ucast macs ", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void compareLocalUcastMacs(Node d1, Node d2, Node ha, InstanceIdentifier<Node> nodePath) {
        LocalUcastCmd cmd = new LocalUcastCmd();
        HwvtepGlobalAugmentation d1Aug = d1.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation d2Aug = d2.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = ha.getAugmentation(HwvtepGlobalAugmentation.class);

        List<LocalUcastMacs> d1Values =
                d1Aug.getLocalUcastMacs() != null ? d1Aug.getLocalUcastMacs() : new ArrayList<LocalUcastMacs>();
        List<LocalUcastMacs> result1 = cmd.transform(nodePath, d1Values);
        List<LocalUcastMacs> d2Values =
                d2Aug.getLocalUcastMacs() != null ? d2Aug.getLocalUcastMacs() : new ArrayList<LocalUcastMacs>();
        List<LocalUcastMacs> result2 = cmd.transform(nodePath, d2Values);

        List<LocalUcastMacs> result = cmd.transform(nodePath, haAug.getLocalUcastMacs());

        List<LocalUcastMacs> luMacList = new ArrayList<LocalUcastMacs>();
        luMacList.addAll(result1);
        luMacList.addAll(result2);

        Set<LocalUcastMacs> set1 = Sets.newHashSet(luMacList);
        Set<LocalUcastMacs> set2 = Sets.newHashSet(result);
        assertEquals("should have equal Local ucast macs ", 0, Sets.symmetricDifference(set1, set2).size());
    }

    public static void compareLocalMcastMacs(Node src, Node dst, InstanceIdentifier<Node> nodePath) {
        LocalMcastCmd cmd = new LocalMcastCmd();
        HwvtepGlobalAugmentation d1Aug = src.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = dst.getAugmentation(HwvtepGlobalAugmentation.class);
        List<LocalMcastMacs> d1Values =
                d1Aug.getLocalUcastMacs() != null ? d1Aug.getLocalMcastMacs() : new ArrayList<LocalMcastMacs>();
        List<LocalMcastMacs> result1 = cmd.transform(nodePath, d1Values);
        List<LocalMcastMacs> result2 = cmd.transform(nodePath, haAug.getLocalMcastMacs());

        Set<LocalMcastMacs> set1 = Sets.newHashSet(result1);
        Set<LocalMcastMacs> set2 = Sets.newHashSet(result2);
        assertEquals("should have equal remote ucast macs ", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void compareLocalMcastMacs(Node d1, Node d2, Node ha, InstanceIdentifier<Node> nodePath) {
        LocalMcastCmd cmd = new LocalMcastCmd();
        HwvtepGlobalAugmentation d1Aug = d1.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation d2Aug = d2.getAugmentation(HwvtepGlobalAugmentation.class);
        HwvtepGlobalAugmentation haAug = ha.getAugmentation(HwvtepGlobalAugmentation.class);
        List<LocalMcastMacs> d1Values =
                d1Aug.getLocalUcastMacs() != null ? d1Aug.getLocalMcastMacs() : new ArrayList<LocalMcastMacs>();
        List<LocalMcastMacs> result1 = cmd.transform(nodePath, d1Values);
        List<LocalMcastMacs> d2Values =
                d2Aug.getLocalUcastMacs() != null ? d2Aug.getLocalMcastMacs() : new ArrayList<LocalMcastMacs>();
        List<LocalMcastMacs> result2 = cmd.transform(nodePath, d2Values);

        List<LocalMcastMacs> result = cmd.transform(nodePath, haAug.getLocalMcastMacs());

        List<LocalMcastMacs> lmMacList = new ArrayList<LocalMcastMacs>();
        lmMacList.addAll(result1);
        lmMacList.addAll(result2);

        Set<LocalMcastMacs> set1 = Sets.newHashSet(lmMacList);
        Set<LocalMcastMacs> set2 = Sets.newHashSet(result);
        assertEquals("should have equal Local Mcast macs ", 0, Sets.symmetricDifference(set1, set2).size());

    }

    public static void comparePhysicalSwitches(Node d1ps, Node d2ps, Node haps, InstanceIdentifier<Node> d1psnodePath,
                                               InstanceIdentifier<Node> d2psnodePath,
                                               InstanceIdentifier<Node> haPsnodePath,
                                               ReadWriteTransaction readWriteTransaction, String switchName,
                                               Node d1, Node d2, Node ha) throws ReadFailedException {
        PhysicalSwitchAugmentation d1PsAug = d1ps.getAugmentation(PhysicalSwitchAugmentation.class);
        PhysicalSwitchAugmentation d2PsAug = d2ps.getAugmentation(PhysicalSwitchAugmentation.class);
        PhysicalSwitchAugmentation haPsAug = haps.getAugmentation(PhysicalSwitchAugmentation.class);

        HwvtepGlobalRef managerd1Ps = d1PsAug.getManagedBy();
        assertEquals("Hwvtep node name should be same", d1PsAug.getHwvtepNodeName().getValue(),
                haPsAug.getHwvtepNodeName().getValue());
        assertEquals("Managers should be equal  for d1 ", d1ps.getNodeId().getValue(),
                managerd1Ps.getValue().firstKeyOf(Node.class).getNodeId().getValue() + "/physicalswitch/" + switchName);
        HwvtepGlobalRef managerd2Ps = d2PsAug.getManagedBy();
        assertEquals("Hwvtep node name should be same", d2PsAug.getHwvtepNodeName().getValue(),
                haPsAug.getHwvtepNodeName().getValue());
        assertEquals("Managers should be equal  for d2 ", d2ps.getNodeId().getValue(),
                managerd2Ps.getValue().firstKeyOf(Node.class).getNodeId().getValue() + "/physicalswitch/" + switchName);
        HwvtepGlobalRef managerhaPs = haPsAug.getManagedBy();
        assertEquals("Managers should be equal for ha ", haps.getNodeId().getValue(),
                managerhaPs.getValue().firstKeyOf(Node.class).getNodeId().getValue() + "/physicalswitch/" + switchName);

        assertEquals("Should have equal number TunnelIps",
                d1PsAug.getTunnelIps().size(), haPsAug.getTunnelIps().size());
        assertEquals("Should have equal number TunnelIps",
                d2PsAug.getTunnelIps().size(), haPsAug.getTunnelIps().size());
        if (d1PsAug.getTunnelIps().size() == haPsAug.getTunnelIps().size()
                && d2PsAug.getTunnelIps().size() == haPsAug.getTunnelIps().size()) {
            assertTrue(d1PsAug.getTunnelIps().containsAll(haPsAug.getTunnelIps()));
            assertTrue(d2PsAug.getTunnelIps().containsAll(haPsAug.getTunnelIps()));
        }

        //Compare Termination point
        assertTerminationPoint(DataProvider.getPortNameListD1(),
                d1psnodePath, haPsnodePath, readWriteTransaction, d1, ha);
        assertTerminationPoint(DataProvider.getPortNameListD2(),
                d2psnodePath, haPsnodePath, readWriteTransaction, d2, ha);
    }

    public static void comparePhysicalSwitches(Node d1ps, Node haps, InstanceIdentifier<Node> d1psnodePath,
                                               InstanceIdentifier<Node> haPsnodePath,
                                               ReadWriteTransaction readWriteTransaction,
                                               String switchName, Node d1, Node ha) throws ReadFailedException {
        //Compare Physical Augmentation data
        PhysicalSwitchAugmentation d1PsAug = d1ps.getAugmentation(PhysicalSwitchAugmentation.class);
        PhysicalSwitchAugmentation haPsAug = haps.getAugmentation(PhysicalSwitchAugmentation.class);

        HwvtepGlobalRef managerd1Ps = d1PsAug.getManagedBy();
        assertEquals("Hwvtep node name should be same", d1PsAug.getHwvtepNodeName().getValue(),
                haPsAug.getHwvtepNodeName().getValue());
        assertEquals("Managers should be equal  for d1 ", d1ps.getNodeId().getValue(),
                managerd1Ps.getValue().firstKeyOf(Node.class).getNodeId().getValue() + "/physicalswitch/" + switchName);
        HwvtepGlobalRef managerhaPs = haPsAug.getManagedBy();
        assertEquals("Managers should be equal for ha ", haps.getNodeId().getValue(),
                managerhaPs.getValue().firstKeyOf(Node.class).getNodeId().getValue() + "/physicalswitch/" + switchName);

        assertEquals("Should have equal number TunnelIps", d1PsAug.getTunnelIps().size(),
                haPsAug.getTunnelIps().size());
        if (d1PsAug.getTunnelIps().size() == haPsAug.getTunnelIps().size()) {
            assertTrue(d1PsAug.getTunnelIps().containsAll(haPsAug.getTunnelIps()));
        }

        //Compare Termination point
        assertTerminationPoint(DataProvider.getPortNameListD1(), d1psnodePath, haPsnodePath,
                readWriteTransaction, d1, ha);
    }

    public static void assertTerminationPoint(List<String> terminationPointNames, InstanceIdentifier<Node> d1ps,
                                              InstanceIdentifier<Node> haPsa, ReadWriteTransaction readWriteTransaction,
                                              Node nodeD, Node nodeHa) throws ReadFailedException {
        for (String portName : terminationPointNames) {
            InstanceIdentifier<TerminationPoint> tpPathd = d1ps.child(TerminationPoint.class,
                    new TerminationPointKey(new TpId(portName)));
            TerminationPoint tpNoded = readWriteTransaction.read(LogicalDatastoreType.OPERATIONAL, tpPathd)
                    .checkedGet().get();
            HwvtepPhysicalPortAugmentation hwvtepPhysicalPortAugmentationD =
                    tpNoded.getAugmentation(HwvtepPhysicalPortAugmentation.class);

            InstanceIdentifier<TerminationPoint> tpPathha = haPsa.child(TerminationPoint.class,
                    new TerminationPointKey(new TpId(portName)));
            TerminationPoint tpNodeha = readWriteTransaction.read(LogicalDatastoreType.OPERATIONAL, tpPathha)
                    .checkedGet().get();
            HwvtepPhysicalPortAugmentation hwvtepPhysicalPortAugmentationHa =
                    tpNodeha.getAugmentation(HwvtepPhysicalPortAugmentation.class);
            assertEquals("Termination point hwvtep-node-name should be same",
                    hwvtepPhysicalPortAugmentationD.getHwvtepNodeName(),
                    hwvtepPhysicalPortAugmentationHa.getHwvtepNodeName());

            List<VlanBindings> vlanBindingsesD = hwvtepPhysicalPortAugmentationD.getVlanBindings();
            List<VlanBindings> vlanBindingsesHa = hwvtepPhysicalPortAugmentationHa.getVlanBindings();
            assertEquals("Size of VlanBindings should be same", vlanBindingsesD.size(), vlanBindingsesHa.size());

            List<Integer> vlanKeysD = new ArrayList<>();
            List<Integer> vlanKeysHa = new ArrayList<>();
            String logicalSwitchRefD = new String();
            String logicalSwitchRefHa = new String();
            List<String> logicalSwitchNameD = new ArrayList<>();
            List<String> logicalSwitchNameHa = new ArrayList<>();
            if (vlanBindingsesD.size() == vlanBindingsesHa.size()) {
                for (int i = 0; i < vlanBindingsesD.size(); i++) {
                    vlanKeysD.add(vlanBindingsesD.get(i).getVlanIdKey().getValue());
                    logicalSwitchRefD = vlanBindingsesD.get(i).getLogicalSwitchRef().getValue()
                            .firstKeyOf(Node.class).getNodeId().getValue();
                    logicalSwitchNameD.add(vlanBindingsesD.get(i).getLogicalSwitchRef().getValue()
                            .firstKeyOf(LogicalSwitches.class).getHwvtepNodeName().getValue());

                    vlanKeysHa.add(vlanBindingsesHa.get(i).getVlanIdKey().getValue());
                    logicalSwitchRefHa = vlanBindingsesHa.get(i).getLogicalSwitchRef().getValue()
                            .firstKeyOf(Node.class).getNodeId().getValue();
                    logicalSwitchNameHa.add(vlanBindingsesHa.get(i).getLogicalSwitchRef().getValue()
                            .firstKeyOf(LogicalSwitches.class).getHwvtepNodeName().getValue());
                }
                assertTrue(vlanKeysD.containsAll(vlanKeysHa));
                assertTrue(logicalSwitchRefD.equals(nodeD.getNodeId().getValue()));
                assertTrue(logicalSwitchRefHa.equals(nodeHa.getNodeId().getValue()));
                assertTrue(logicalSwitchNameD.containsAll(logicalSwitchNameHa));
            }
        }
    }

}
