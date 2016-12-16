/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.nodehandlertest;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.OPERATIONAL;

import com.google.common.base.Optional;
import java.util.Arrays;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.ReadFailedException;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.HwvtepGlobalAugmentation;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Created by eaksahu on 8/12/2016.
 */
public class TestUtil {
    static Logger LOG = LoggerFactory.getLogger(TestUtil.class);

    public static void deleteNode(ReadWriteTransaction tx, InstanceIdentifier<Node> id) throws Exception {
        tx.delete(OPERATIONAL, id);
        tx.submit().checkedGet();
    }

    public static void verifyHAOpNode(Node d1GlobalOpNode, Node haGlobalOpNode, Node d1PsOpNode, Node haPsOpNode,
                                      InstanceIdentifier<Node> haId, InstanceIdentifier<Node> d1PsId,
                                      InstanceIdentifier<Node> haPsId, NodeId haNodeId, DataBroker dataBroker)
            throws ReadFailedException {
        ReadWriteTransaction transaction = dataBroker.newReadWriteTransaction();
        TestComparators.compareLogicalSwitches(d1GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareRemoteUcastMacs(d1GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareRemoteMcastMacs(d1GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareLocalUcastMacs(d1GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareLocalMcastMacs(d1GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.verifySwitches(haGlobalOpNode, haPsOpNode);
        TestComparators.verifySwitches(d1GlobalOpNode, d1PsOpNode);
        TestComparators.comparePhysicalSwitches(d1PsOpNode, haPsOpNode, d1PsId, haPsId, transaction, "s3",
                d1GlobalOpNode, haGlobalOpNode);
    }

    public static void verifyHAOpNode(Node d1GlobalOpNode, Node d2GlobalOpNode, Node haGlobalOpNode,
                                      Node d1PsOpNode, Node d2PsOpNode, Node haPsOpNode,
                                      InstanceIdentifier<Node> haId, InstanceIdentifier<Node> d1PsId,
                                      InstanceIdentifier<Node> d2PsId, InstanceIdentifier<Node> haPsId,
                                      NodeId haNodeId, DataBroker dataBroker) throws ReadFailedException {
        ReadWriteTransaction transaction = dataBroker.newReadWriteTransaction();
        TestComparators.compareLogicalSwitches(d1GlobalOpNode, d2GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareRemoteUcastMacs(d1GlobalOpNode, d2GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareRemoteMcastMacs(d1GlobalOpNode, d2GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareLocalUcastMacs(d1GlobalOpNode, d2GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.compareLocalMcastMacs(d1GlobalOpNode, d2GlobalOpNode, haGlobalOpNode, haId);
        TestComparators.verifySwitches(haGlobalOpNode, haPsOpNode);
        TestComparators.verifySwitches(d1GlobalOpNode, d1PsOpNode);
        TestComparators.verifySwitches(d2GlobalOpNode, d2PsOpNode);
        TestComparators.comparePhysicalSwitches(d1PsOpNode, d2PsOpNode, haPsOpNode, d1PsId, d2PsId, haPsId,
                transaction, "s3", d1GlobalOpNode, d2GlobalOpNode, haGlobalOpNode);
    }

    public static Node readNode(LogicalDatastoreType datastoreType, InstanceIdentifier<Node> id, DataBroker dataBroker)
            throws Exception {
        if (dataBroker.newReadWriteTransaction().read(datastoreType, id).checkedGet().isPresent()) {
            return dataBroker.newReadWriteTransaction().read(datastoreType, id).checkedGet().get();
        }
        return null;
    }

    public static Optional<Node> readNode(LogicalDatastoreType datastoreType, InstanceIdentifier<Node> id,
                                          ReadOnlyTransaction tx) throws Exception {
        return tx.read(datastoreType, id).checkedGet();
    }

    static void updateNode(LogicalDatastoreType datastoreType, InstanceIdentifier<Node> id, Node node,
                           DataBroker dataBroker) throws Exception {
        WriteTransaction transaction = dataBroker.newWriteOnlyTransaction();
        transaction.merge(datastoreType, id, node, WriteTransaction.CREATE_MISSING_PARENTS);
        transaction.submit();
    }


    static void submitNode(LogicalDatastoreType datastoreType, InstanceIdentifier<Node> id, Node node,
                           WriteTransaction transaction) throws Exception {
        transaction.put(datastoreType, id, node, WriteTransaction.CREATE_MISSING_PARENTS);
        transaction.submit();
    }

    static Optional<Node> readNodeOptional(LogicalDatastoreType datastoreType, InstanceIdentifier<Node> id,
                                           DataBroker dataBroker) throws Exception {
        return dataBroker.newReadWriteTransaction().read(datastoreType, id).checkedGet();
    }

    public static void verifyHaAfterDelete(InstanceIdentifier<Node> nodeId, LogicalDatastoreType datastoreType,
                                           String message, DataBroker dataBroker) throws Exception {
        Optional<Node> nodeOptional = TestUtil.readNodeOptional(datastoreType, nodeId, dataBroker);
        if (!message.contains("D2")) {
            assertTrue(message, nodeOptional.isPresent());
        } else {
            assertFalse(message, nodeOptional.isPresent());
        }
        if (nodeOptional.isPresent()) {
            LOG.info("Node data{}", nodeOptional.get());
        }
    }

    public static void verifyHAconfigNode(InstanceIdentifier<Node> nodeId, DataBroker dataBroker, String message)
            throws Exception {
        Optional<Node> nodeOptional = TestUtil.readNodeOptional(LogicalDatastoreType.CONFIGURATION, nodeId, dataBroker);
        assertTrue(message, nodeOptional.isPresent());
        if (nodeOptional.isPresent()) {
            nodeOptional.get().getAugmentation(HwvtepGlobalAugmentation.class).getManagers();
        }
    }

    public static void verifyHAconfigNode(Node haConfig, Node d1Node) throws Exception {
        String haid = haConfig.getAugmentation(HwvtepGlobalAugmentation.class).getManagers()
                .get(0).getManagerOtherConfigs().get(0).getOtherConfigValue();
        String d1id = d1Node.getNodeId().getValue();
        assertEquals("Other config should contain D1 as child manager", haid, d1id);
    }

    public static void verifyHAconfigNode(Node haConfig, Node d1Node, Node d2Node) throws Exception {
        String haid = haConfig.getAugmentation(HwvtepGlobalAugmentation.class).getManagers()
                .get(0).getManagerOtherConfigs().get(0).getOtherConfigValue();
        String[] haids = haid.split(",");
        List<String> haidSlist = Arrays.asList(haids);
        assertEquals("Ha Other config size should be 2 after creationg of D2 Node", 2, haids.length);
        String d1id = d1Node.getNodeId().getValue();
        String d2id = d2Node.getNodeId().getValue();
        assertTrue("ha should contain d1/d2 id as other config", haidSlist.contains(d1id));
        assertTrue("ha should contain d1/d2 id as other config", haidSlist.contains(d2id));
    }

}
