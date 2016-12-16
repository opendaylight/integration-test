/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw;

import static org.junit.Assert.assertEquals;

import java.util.ArrayList;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.mockito.Mockito;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.binding.test.AbstractDataBrokerTest;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.LogicalSwitchesCmd;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepNodeName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitchesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LogicalSwitchesKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class LogicalSwitchesCmdTest  extends AbstractDataBrokerTest {

    DataBroker dataBroker;
    ReadWriteTransaction tx;
    LogicalSwitchesCmd cmd = new LogicalSwitchesCmd();

    HwvtepGlobalAugmentationBuilder dstBuilder = new HwvtepGlobalAugmentationBuilder();

    HwvtepGlobalAugmentation existingData = null;//nodata
    HwvtepGlobalAugmentation srcData = null;

    HwvtepGlobalAugmentation updatedData = null;
    HwvtepGlobalAugmentation originalData = null;

    InstanceIdentifier<Node> haNodePath = HwvtepHAUtil.convertToInstanceIdentifier("ha");
    InstanceIdentifier<Node> d1NodePath = HwvtepHAUtil.convertToInstanceIdentifier("d1");
    InstanceIdentifier<Node> d2NodePath = HwvtepHAUtil.convertToInstanceIdentifier("d2");

    LogicalSwitches[] logicalSwitches = new LogicalSwitches[4];
    InstanceIdentifier<LogicalSwitches>[] ids = new InstanceIdentifier[4];

    String[][] data = new String[][] {
            {"ls1", "100"},
            {"ls2", "200"},
            {"ls3", "300"},
            {"ls4", "400"}
    };

    @Before
    public void setupForHANode() {
        dataBroker = getDataBroker();
        tx = Mockito.spy(dataBroker.newReadWriteTransaction());
        for (int i = 0 ; i < 4; i++) {
            logicalSwitches[i] = buildData(data[i][0], data[i][1]);
            ids[i] = haNodePath.augmentation(HwvtepGlobalAugmentation.class).child(LogicalSwitches.class,
                    new LogicalSwitchesKey(new HwvtepNodeName(data[i][0])));
        }
    }

    @After
    public void teardown() {
    }


    @Test
    public void testD1Connect() throws Exception {
        srcData = getData(new LogicalSwitches[] {logicalSwitches[0], logicalSwitches[1]} );
        cmd.mergeOperationalData(dstBuilder, existingData, srcData, haNodePath);
        assertEquals("should copy the logical switches ", 2, dstBuilder.getLogicalSwitches().size());
    }

    @Test
    public void testD2Connect() throws Exception {
        existingData = getData(new LogicalSwitches[] {logicalSwitches[0], logicalSwitches[1]} );
        srcData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1],
                logicalSwitches[2], logicalSwitches[3]});
        cmd.mergeOperationalData(dstBuilder, existingData, srcData, haNodePath);
        assertEquals("should copy the logical switches ", 2, dstBuilder.getLogicalSwitches().size());
    }

    @Test
    public void testOneLogicalSwitchAddedUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        updatedData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1], logicalSwitches[2]});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verify(tx).put(LogicalDatastoreType.OPERATIONAL, ids[2], logicalSwitches[2], true);
    }

    @Test
    public void testTwoLogicalSwitchesAddedUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        updatedData = getData(new LogicalSwitches[]{logicalSwitches[0],
                logicalSwitches[1], logicalSwitches[2], logicalSwitches[3]});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verify(tx).put(LogicalDatastoreType.OPERATIONAL, ids[2], logicalSwitches[2], true);
        Mockito.verify(tx).put(LogicalDatastoreType.OPERATIONAL, ids[3], logicalSwitches[3], true);
    }

    @Test
    public void testLogicalSwitchDeletedUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1], logicalSwitches[2]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1], logicalSwitches[2]});
        updatedData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[2]);
    }


    @Test
    public void testTwoLogicalSwitchesDeletedUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1],
                logicalSwitches[2], logicalSwitches[3]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1],
                logicalSwitches[2], logicalSwitches[3]});
        updatedData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[2]);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[3]);
    }

    @Test
    public void testTwoAddTwoDeletedLogicalSwitchesUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        updatedData = getData(new LogicalSwitches[]{logicalSwitches[2], logicalSwitches[3]});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verify(tx).put(LogicalDatastoreType.OPERATIONAL, ids[2], logicalSwitches[2], true);
        Mockito.verify(tx).put(LogicalDatastoreType.OPERATIONAL, ids[3], logicalSwitches[3], true);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[0]);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[1]);
    }

    @Test
    public void testAllDeleteUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        updatedData = getData(new LogicalSwitches[]{});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[0]);
        Mockito.verify(tx).delete(LogicalDatastoreType.OPERATIONAL, ids[1]);
    }

    @Test
    public void testNoUpdate() throws Exception {
        existingData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        originalData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        updatedData = getData(new LogicalSwitches[]{logicalSwitches[0], logicalSwitches[1]});
        cmd.mergeOpUpdate(existingData, updatedData, originalData, haNodePath, tx);
        Mockito.verifyNoMoreInteractions(tx);
    }

    LogicalSwitches buildData(String name, String tunnelKey) {
        LogicalSwitchesBuilder logicalSwitchesBuilder = new LogicalSwitchesBuilder();
        logicalSwitchesBuilder.setKey(new LogicalSwitchesKey(new HwvtepNodeName(name)));
        logicalSwitchesBuilder.setTunnelKey(tunnelKey);
        logicalSwitchesBuilder.setHwvtepNodeName(new HwvtepNodeName(name));
        return logicalSwitchesBuilder.build();
    }

    HwvtepGlobalAugmentation getData(LogicalSwitches[] elements) {
        HwvtepGlobalAugmentationBuilder newDataBuilder = new HwvtepGlobalAugmentationBuilder();
        List<LogicalSwitches> ls = new ArrayList<>();
        for (LogicalSwitches ele : elements) {
            ls.add(ele);
        }
        newDataBuilder.setLogicalSwitches(ls);
        return newDataBuilder.build();
    }
}
