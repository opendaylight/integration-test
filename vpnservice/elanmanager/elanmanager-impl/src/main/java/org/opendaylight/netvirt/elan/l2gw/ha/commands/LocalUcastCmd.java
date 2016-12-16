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
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepLogicalSwitchRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.LoggerFactory;



public class LocalUcastCmd
        extends MergeCommand<LocalUcastMacs, HwvtepGlobalAugmentationBuilder, HwvtepGlobalAugmentation> {

    public LocalUcastCmd() {
        LOG = LoggerFactory.getLogger(LocalUcastCmd.class);
    }

    @Override
    public List<LocalUcastMacs> getData(HwvtepGlobalAugmentation node) {
        if (node != null) {
            return node.getLocalUcastMacs();
        }
        return null;
    }

    @Override
    public void setData(HwvtepGlobalAugmentationBuilder builder, List<LocalUcastMacs> data) {
        builder.setLocalUcastMacs(data);
    }

    @Override
    protected InstanceIdentifier<LocalUcastMacs> generateId(InstanceIdentifier<Node> id, LocalUcastMacs node) {
        HwvtepLogicalSwitchRef lsRef = HwvtepHAUtil.convertLogicalSwitchRef(node.getKey().getLogicalSwitchRef(), id);
        LocalUcastMacsKey key = new LocalUcastMacsKey(lsRef, node.getMacEntryKey());

        return id.augmentation(HwvtepGlobalAugmentation.class).child(LocalUcastMacs.class, key);
    }

    @Override
    public LocalUcastMacs transform(InstanceIdentifier<Node> nodePath, LocalUcastMacs src) {
        LocalUcastMacsBuilder ucmlBuilder = new LocalUcastMacsBuilder(src);
        ucmlBuilder.setLocatorRef(HwvtepHAUtil.convertLocatorRef(src.getLocatorRef(), nodePath));
        ucmlBuilder.setLogicalSwitchRef(
                HwvtepHAUtil.convertLogicalSwitchRef(src.getLogicalSwitchRef(), nodePath));
        ucmlBuilder.setMacEntryUuid(HwvtepHAUtil.getUUid(src.getMacEntryKey().getValue()));
        LocalUcastMacsKey key = new LocalUcastMacsKey(ucmlBuilder.getLogicalSwitchRef(), ucmlBuilder.getMacEntryKey());
        ucmlBuilder.setKey(key);
        return ucmlBuilder.build();
    }

    @Override
    public String getKey(LocalUcastMacs data) {
        return data.getKey().toString();
    }

    @Override
    public String getDescription() {
        return "LocalUcastMacs";
    }

    @Override
    public boolean areEqual(LocalUcastMacs updated, LocalUcastMacs orig) {
        InstanceIdentifier<?> updatedMacRefIdentifier = updated.getLogicalSwitchRef().getValue();
        HwvtepNodeName updatedMacNodeName = updatedMacRefIdentifier
                .firstKeyOf(LogicalSwitches.class).getHwvtepNodeName();
        InstanceIdentifier<?> origMacRefIdentifier = orig.getLogicalSwitchRef().getValue();
        HwvtepNodeName origMacNodeName = origMacRefIdentifier.firstKeyOf(LogicalSwitches.class).getHwvtepNodeName();
        if (updated.getMacEntryKey().equals(orig.getMacEntryKey())
                && updatedMacNodeName.equals(origMacNodeName)) {
            return true;
        }
        return false;

    }
}
