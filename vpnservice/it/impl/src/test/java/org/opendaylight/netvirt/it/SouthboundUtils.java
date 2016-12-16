/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import com.google.common.collect.Maps;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchOtherConfigs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchOtherConfigsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchOtherConfigsKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SouthboundUtils {
    private static final Logger LOG = LoggerFactory.getLogger(SouthboundUtils.class);
    private final MdsalUtils mdsalUtils;
    private static final TopologyId OVSDB_TOPOLOGY_ID = new TopologyId(new Uri("ovsdb:1"));

    public SouthboundUtils(MdsalUtils mdsalUtils) {
        this.mdsalUtils = mdsalUtils;
    }

    public boolean addOpenVSwitchOtherConfig(Node ovsdbNode, Map<String, String> otherConfigs) {
        if (ovsdbNode == null) {
            return false;
        }
        if ((otherConfigs == null) || otherConfigs.isEmpty()) {
            return false;
        }

        // Create a single map of both the existing otherConfig and the new otherConfig
        // and then write that to the final otherConfig builder
        Map<String, String> allOtherConfigs = Maps.newHashMap();
        OvsdbNodeAugmentation ovsdbNodeAugmentation = ovsdbNode.getAugmentation(OvsdbNodeAugmentation.class);
        if (ovsdbNodeAugmentation != null && ovsdbNodeAugmentation.getOpenvswitchOtherConfigs() != null) {
            for (OpenvswitchOtherConfigs ovsOtherConfigs : ovsdbNodeAugmentation.getOpenvswitchOtherConfigs()) {
                allOtherConfigs.put(ovsOtherConfigs.getOtherConfigKey(), ovsOtherConfigs.getOtherConfigValue());
            }
        }
        for (Map.Entry<String, String> entry : otherConfigs.entrySet()) {
            allOtherConfigs.put(entry.getKey(), entry.getValue());
        }

        List<OpenvswitchOtherConfigs> otherConfigsList = new ArrayList<>();
        for (Map.Entry<String, String> entry : allOtherConfigs.entrySet()) {
            OpenvswitchOtherConfigsBuilder otherConfigsBuilder = new OpenvswitchOtherConfigsBuilder();
            otherConfigsBuilder.setKey(new OpenvswitchOtherConfigsKey(entry.getKey()));
            otherConfigsBuilder.setOtherConfigKey(entry.getKey());
            otherConfigsBuilder.setOtherConfigValue(entry.getValue());
            otherConfigsList.add(otherConfigsBuilder.build());
        }

        OvsdbNodeAugmentationBuilder ovsdbNodeAugmentationBuilder = new OvsdbNodeAugmentationBuilder();
        ovsdbNodeAugmentationBuilder.setOpenvswitchOtherConfigs(otherConfigsList);

        NodeBuilder nodeBuilder = new NodeBuilder();
        nodeBuilder.setNodeId(ovsdbNode.getNodeId());
        nodeBuilder.addAugmentation(OvsdbNodeAugmentation.class, ovsdbNodeAugmentationBuilder.build());
        InstanceIdentifier<Node> nodeIid = createInstanceIdentifier(ovsdbNode.getNodeId());
        return mdsalUtils.merge(LogicalDatastoreType.CONFIGURATION, nodeIid, nodeBuilder.build());
    }

    public InstanceIdentifier<Node> createInstanceIdentifier(NodeId nodeId) {
        return InstanceIdentifier
                .create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(OVSDB_TOPOLOGY_ID))
                .child(Node.class, new NodeKey(nodeId));
    }
}
