/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.nodehandlertest;

import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.OPERATIONAL;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.TunnelIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.TunnelIpsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.TunnelIpsKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

/**
 * Created by eaksahu on 10/14/2016.
 */
public class NodeConnectedHandlerUtils {

    void addNode(InstanceIdentifier<Node> path, InstanceIdentifier<Node> psPath, String logicalSwitchData,
                 String localUcasMacData, String localMcastData, String remoteMcastData, String remoteUcasteMacData,
                 String globalTerminationPointIp, WriteTransaction transaction) throws Exception {
        NodeBuilder nodeBuilder = null;
        HwvtepGlobalAugmentationBuilder augmentationBuilder = null;
        nodeBuilder = prepareOperationalNode(path);
        augmentationBuilder = prepareAugmentationBuilder();

        GlobalAugmentationHelper.addLogicalSwitches(augmentationBuilder, getData(logicalSwitchData));

        GlobalAugmentationHelper.addLocalUcastMacs(path, augmentationBuilder, getData(localUcasMacData));

        GlobalAugmentationHelper.addLocalMcastMacs(path, augmentationBuilder, getData(localMcastData));

        GlobalAugmentationHelper.addRemoteMcastMacs(path, augmentationBuilder, getData(remoteMcastData));

        GlobalAugmentationHelper.addRemoteUcastMacs(path, augmentationBuilder, getData(remoteUcasteMacData));

        GlobalAugmentationHelper.addGlobalTerminationPoints(nodeBuilder, path, getData(globalTerminationPointIp));

        GlobalAugmentationHelper.addSwitches(augmentationBuilder, psPath);

        nodeBuilder.addAugmentation(HwvtepGlobalAugmentation.class, augmentationBuilder.build());

        TestUtil.submitNode(OPERATIONAL, path, nodeBuilder.build(), transaction);
    }

    void addPsNode(InstanceIdentifier<Node> path, InstanceIdentifier<Node> parentPath, List<String> portNameList,
                   WriteTransaction transaction) throws Exception {
        NodeBuilder nodeBuilder = null;
        HwvtepGlobalAugmentationBuilder augmentationBuilder = null;

        nodeBuilder = prepareOperationalNode(path);
        PhysicalSwitchAugmentationBuilder physicalSwitchAugmentationBuilder = new PhysicalSwitchAugmentationBuilder();
        physicalSwitchAugmentationBuilder.setManagedBy(new HwvtepGlobalRef(parentPath));
        physicalSwitchAugmentationBuilder.setPhysicalSwitchUuid(getUUid("d1s3"));
        physicalSwitchAugmentationBuilder.setHwvtepNodeName(new HwvtepNodeName("s3"));
        physicalSwitchAugmentationBuilder.setHwvtepNodeDescription("description");


        List<TunnelIps> tunnelIps = new ArrayList<>();
        IpAddress ip = new IpAddress("192.168.122.30".toCharArray());
        tunnelIps.add(new TunnelIpsBuilder().setKey(new TunnelIpsKey(ip)).setTunnelIpsKey(ip).build());
        physicalSwitchAugmentationBuilder.setTunnelIps(tunnelIps);

        nodeBuilder.addAugmentation(PhysicalSwitchAugmentation.class, physicalSwitchAugmentationBuilder.build());
        PhysicalSwitchHelper.dId = parentPath;
        nodeBuilder.setTerminationPoint(PhysicalSwitchHelper
                .addPhysicalSwitchTerminationPoints(path, transaction, portNameList));

        TestUtil.submitNode(OPERATIONAL, path, nodeBuilder.build(), transaction);
    }

    NodeBuilder prepareOperationalNode(InstanceIdentifier<Node> iid) {
        NodeBuilder nodeBuilder = new NodeBuilder();
        nodeBuilder.setNodeId(iid.firstKeyOf(Node.class).getNodeId());
        return nodeBuilder;
    }

    HwvtepGlobalAugmentationBuilder prepareAugmentationBuilder() {
        HwvtepGlobalAugmentationBuilder builder = new HwvtepGlobalAugmentationBuilder();
        builder.setManagers(TestBuilders.buildManagers());
        return builder;
    }

    public List<String> getData(String data) {
        String[] dataArray = data.split(",");
        List<String> logicalSwitch = new ArrayList<>();
        for (int i = 0; i < dataArray.length; i++) {
            logicalSwitch.add(dataArray[i]);
        }
        return logicalSwitch;
    }

    public static Uuid getUUid(String key) {
        return new Uuid(UUID.nameUUIDFromBytes(key.getBytes()).toString());
    }
}
