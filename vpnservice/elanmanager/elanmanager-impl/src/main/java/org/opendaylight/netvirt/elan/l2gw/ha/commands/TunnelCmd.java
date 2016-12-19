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
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepPhysicalLocatorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.PhysicalSwitchAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.Tunnels;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.TunnelsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical._switch.attributes.TunnelsKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TpId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.LoggerFactory;

public class TunnelCmd  extends MergeCommand<Tunnels, PhysicalSwitchAugmentationBuilder, PhysicalSwitchAugmentation> {

    public TunnelCmd() {
        LOG = LoggerFactory.getLogger(TunnelCmd.class);
    }

    @Override
    public List<Tunnels> getData(PhysicalSwitchAugmentation node) {
        if (node != null) {
            return node.getTunnels();
        }
        return null;
    }

    @Override
    public void setData(PhysicalSwitchAugmentationBuilder builder, List<Tunnels> data) {
        builder.setTunnels(data);
    }

    @Override
    protected InstanceIdentifier<Tunnels> generateId(InstanceIdentifier<Node> id, Tunnels src) {
        HwvtepPhysicalLocatorRef hwvtepPhysicalLocatorRef =
                HwvtepHAUtil.convertLocatorRef(src.getLocalLocatorRef(), id);
        HwvtepPhysicalLocatorRef hwvtepPhysicalLocatorRef1 =
                HwvtepHAUtil.convertLocatorRef(src.getRemoteLocatorRef(), id);
        TunnelsKey key = new TunnelsKey(hwvtepPhysicalLocatorRef, hwvtepPhysicalLocatorRef1);
        return id.augmentation(PhysicalSwitchAugmentation.class).child(Tunnels.class, key);
    }

    @Override
    public Tunnels transform(InstanceIdentifier<Node> nodePath, Tunnels src) {
        TunnelsBuilder tunnelsBuilder = new TunnelsBuilder(src);
        tunnelsBuilder.setLocalLocatorRef(HwvtepHAUtil.convertLocatorRef(src.getLocalLocatorRef(), nodePath));
        tunnelsBuilder.setRemoteLocatorRef(HwvtepHAUtil.convertLocatorRef(src.getRemoteLocatorRef(), nodePath));
        tunnelsBuilder.setTunnelUuid(HwvtepHAUtil.getUUid(HwvtepHAUtil.getTepIpVal(src.getRemoteLocatorRef())));
        HwvtepPhysicalLocatorRef hwvtepPhysicalLocatorRef =
                HwvtepHAUtil.convertLocatorRef(src.getLocalLocatorRef(), nodePath);
        HwvtepPhysicalLocatorRef hwvtepPhysicalLocatorRef1 =
                HwvtepHAUtil.convertLocatorRef(src.getRemoteLocatorRef(), nodePath);

        tunnelsBuilder.setKey(new TunnelsKey(hwvtepPhysicalLocatorRef,hwvtepPhysicalLocatorRef1));
        return tunnelsBuilder.build();
    }

    @Override
    public String getKey(Tunnels data) {
        return "tunnel";//TODO return proper data
    }

    @Override
    public String getDescription() {
        return "Tunnels";
    }

    @Override
    public boolean areEqual(Tunnels updated, Tunnels orig) {
        InstanceIdentifier<TerminationPoint> remoteLocatorRefUpdated = (InstanceIdentifier<TerminationPoint>)
                updated.getRemoteLocatorRef().getValue();
        InstanceIdentifier<TerminationPoint> remoteLocatorRefOriginal = (InstanceIdentifier<TerminationPoint>)
                orig.getRemoteLocatorRef().getValue();
        TpId tpId1 = remoteLocatorRefUpdated.firstKeyOf(TerminationPoint.class).getTpId();
        TpId tpId2 = remoteLocatorRefOriginal.firstKeyOf(TerminationPoint.class).getTpId();
        if (tpId1.equals(tpId2)) {
            return true;
        }
        return false;
    }
}
