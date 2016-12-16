/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.commands;

import java.util.List;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.Switches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.SwitchesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.SwitchesKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SwitchesCmd extends MergeCommand<Switches, HwvtepGlobalAugmentationBuilder, HwvtepGlobalAugmentation> {

    static Logger LOG = LoggerFactory.getLogger(SwitchesCmd.class);

    public SwitchesCmd() {
        LOG = LoggerFactory.getLogger(SwitchesCmd.class);
    }


    @Override
    public List<Switches> getData(HwvtepGlobalAugmentation node) {
        if (node != null) {
            return node.getSwitches();
        }
        return null;
    }

    @Override
    public void setData(HwvtepGlobalAugmentationBuilder builder, List<Switches> data) {
        builder.setSwitches(data);
    }

    @Override
    protected InstanceIdentifier<Switches> generateId(InstanceIdentifier<Node> id, Switches node) {
        return id.augmentation(HwvtepGlobalAugmentation.class).child(Switches.class, node.getKey());
    }

    @Override
    public Switches transform(InstanceIdentifier<Node> nodePath, Switches src) {
        SwitchesBuilder builder = new SwitchesBuilder(src);
        InstanceIdentifier<Node> psNodeIid = (InstanceIdentifier<Node>) src.getSwitchRef().getValue();
        String psNodeId = psNodeIid.firstKeyOf(Node.class).getNodeId().getValue();
        String nodeId = nodePath.firstKeyOf(Node.class).getNodeId().getValue();
        int idx = nodeId.indexOf("/physicalswitch/");
        if (idx > 0) {
            nodeId = nodeId.substring(0, idx);
        }
        idx = psNodeId.indexOf("/physicalswitch/") + "/physicalswitch/".length();
        String switchName = psNodeId.substring(idx);
        String dstNodeId = nodeId + "/physicalswitch/" + switchName;

        InstanceIdentifier<Node> id2 = HwvtepHAUtil.convertToInstanceIdentifier(dstNodeId);

        builder.setSwitchRef(new HwvtepPhysicalSwitchRef(id2));
        builder.setKey(new SwitchesKey(new HwvtepPhysicalSwitchRef(id2)));
        return builder.build();
    }

    @Override
    public String getKey(Switches data) {
        InstanceIdentifier<?> id = data.getSwitchRef().getValue();
        return id.firstKeyOf(Node.class).getNodeId().getValue();
    }

    @Override
    public String getDescription() {
        return "Switches";
    }

    @Override
    public boolean areEqual(Switches switchA, Switches switchB) {
        return true;
    }
}
