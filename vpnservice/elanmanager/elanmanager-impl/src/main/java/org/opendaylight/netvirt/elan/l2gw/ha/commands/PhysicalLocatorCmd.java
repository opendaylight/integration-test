/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.commands;

import java.util.List;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.LoggerFactory;

public class PhysicalLocatorCmd extends MergeCommand<TerminationPoint, NodeBuilder, Node> {

    public PhysicalLocatorCmd() {
        LOG = LoggerFactory.getLogger(PhysicalLocatorCmd.class);
    }

    @Override
    public List<TerminationPoint> getData(Node node) {
        if (node != null) {
            return node.getTerminationPoint();
        }
        return null;
    }

    @Override
    public void setData(NodeBuilder builder, List<TerminationPoint> data) {
        builder.setTerminationPoint(data);
    }

    @Override
    protected InstanceIdentifier<TerminationPoint> generateId(InstanceIdentifier<Node> id, TerminationPoint node) {
        return id.child(TerminationPoint.class, node.getKey());
    }

    @Override
    public TerminationPoint transform(InstanceIdentifier<Node> nodePath, TerminationPoint src) {
        return src;
    }

    @Override
    public String getKey(TerminationPoint data) {
        return data.getTpId().getValue();
    }

    @Override
    public String getDescription() {
        return "PhysicalLocator";
    }

    @Override
    public boolean areEqual(TerminationPoint updated, TerminationPoint orig) {
        HwvtepPhysicalLocatorAugmentation updatedPhysicalLocator =
                updated.getAugmentation(HwvtepPhysicalLocatorAugmentation.class);
        HwvtepPhysicalLocatorAugmentation origPhysicalLocator =
                orig.getAugmentation(HwvtepPhysicalLocatorAugmentation.class);
        if (updatedPhysicalLocator.getDstIp().equals(origPhysicalLocator.getDstIp())
                && (updatedPhysicalLocator.getEncapsulationType() == origPhysicalLocator.getEncapsulationType())) {
            return true;
        }
        return false;
    }
}
