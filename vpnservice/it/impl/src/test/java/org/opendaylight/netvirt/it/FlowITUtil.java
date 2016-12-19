/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import static org.junit.Assert.assertNotNull;

import com.google.common.base.Optional;
import com.google.common.collect.Lists;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.ExecutionException;
import org.junit.Assert;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.ovsdb.utils.mdsal.utils.NotifyingDataChangeListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowCapableNode;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.Table;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.TableKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.Match;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchNodesNodeTableFlow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchNotifPacketIn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchNotifSwitchFlowRemoved;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchNotifUpdateFlowStats;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchRpcAddFlow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchRpcRemoveFlow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchRpcUpdateFlowOriginal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralAugMatchRpcUpdateFlowUpdated;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.GeneralExtensionListGrouping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.general.rev140714.general.extension.list.grouping.ExtensionList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.AllMatchesGrouping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchNodesNodeTableFlow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchNotifPacketIn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchNotifSwitchFlowRemoved;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchNotifUpdateFlowStats;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchRpcAddFlow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchRpcRemoveFlow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchRpcUpdateFlowOriginal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.match.rev140714.NxAugMatchRpcUpdateFlowUpdated;
import org.opendaylight.yangtools.yang.binding.Augmentation;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FlowITUtil {
    private static final Logger LOG = LoggerFactory.getLogger(FlowITUtil.class);
    private static final String OPENFLOW = "openflow";
    private DataBroker dataBroker;

    public FlowITUtil(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    private static final Class[] MATCH_AUGMENTATIONS = {
        GeneralAugMatchNodesNodeTableFlow.class,
        GeneralAugMatchNotifUpdateFlowStats.class,
        GeneralAugMatchNotifPacketIn.class,
        GeneralAugMatchNotifSwitchFlowRemoved.class,
        GeneralAugMatchRpcAddFlow.class,
        GeneralAugMatchRpcRemoveFlow.class,
        GeneralAugMatchRpcUpdateFlowOriginal.class,
        GeneralAugMatchRpcUpdateFlowUpdated.class};

    private static final Class[] EXT_LIST_AUGMENTATIONS = {
        NxAugMatchNodesNodeTableFlow.class,
        NxAugMatchNotifUpdateFlowStats.class,
        NxAugMatchNotifPacketIn.class,
        NxAugMatchNotifSwitchFlowRemoved.class,
        NxAugMatchRpcAddFlow.class,
        NxAugMatchRpcRemoveFlow.class,
        NxAugMatchRpcUpdateFlowOriginal.class,
        NxAugMatchRpcUpdateFlowUpdated.class};

    private static Integer DEFAULT_PRIORITY = new Integer(32768);

    private String getNodeName(long dpidLong) {
        return OPENFLOW + ":" + dpidLong;
    }

    private NodeBuilder createNodeBuilder(String nodeId) {
        NodeBuilder builder = new NodeBuilder();
        builder.setId(new NodeId(nodeId));
        builder.setKey(new NodeKey(builder.getId()));
        return builder;
    }

    private NodeBuilder createNodeBuilder(long dpidLong) {
        return createNodeBuilder(getNodeName(dpidLong));
    }

    private InstanceIdentifier<Flow> createFlowPath(FlowBuilder flowBuilder, NodeBuilder nodeBuilder) {
        return InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, nodeBuilder.getKey())
                .augmentation(FlowCapableNode.class)
                .child(Table.class, new TableKey(flowBuilder.getTableId()))
                .child(Flow.class, flowBuilder.getKey()).build();
    }

    private InstanceIdentifier<Table> createTablePath(NodeBuilder nodeBuilder, short table) {
        return InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, nodeBuilder.getKey())
                .augmentation(FlowCapableNode.class)
                .child(Table.class, new TableKey(table)).build();
    }

    private Flow getFlow(FlowBuilder flowBuilder, NodeBuilder nodeBuilder,
                               ReadOnlyTransaction readTx, final LogicalDatastoreType store) {
        try {
            Optional<Flow> data = readTx.read(store, createFlowPath(flowBuilder, nodeBuilder)).get();
            if (data.isPresent()) {
                return data.get();
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to get flow {}", flowBuilder.getFlowName(), e);
        }

        LOG.info("Cannot find data for Flow {} in {}", flowBuilder.getFlowName(), store);
        return null;
    }


    /**
     * Sets up common defaults for the given flow builder: a flow identifier and key based on the given flow name,
     * strict, no barrier, the given table identifier, no hard timeout and no idle timeout.
     *
     * @param flowBuilder The flow builder.
     * @param flowName The flow name.
     * @param table The table.
     * @return The flow builder.
     */
    private FlowBuilder initFlowBuilder(FlowBuilder flowBuilder, String flowName, short table) {
        final FlowId flowId = new FlowId(flowName);
        flowBuilder
                .setId(flowId)
                .setStrict(true)
                .setBarrier(false)
                .setTableId(table)
                .setKey(new FlowKey(flowId))
                .setFlowName(flowName)
                .setHardTimeout(0)
                .setIdleTimeout(0);
        return flowBuilder;
    }

    private Table getTable(NodeBuilder nodeBuilder, short table,
                           ReadOnlyTransaction readTx, final LogicalDatastoreType store) {
        try {
            Optional<Table> data = readTx.read(store, this.createTablePath(nodeBuilder, table)).get();
            if (data.isPresent()) {
                return data.get();
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to get table {}", table, e);
        }

        LOG.info("Cannot find data for table {} in {}", table, store);
        return null;
    }

    /**
     * Verify <strong>by flow id</strong> that the given flow was installed in a table. This method will wait 10
     * seconds for the flows to appear in each of the md-sal CONFIGURATION and OPERATIONAL data stores
     * @param datapathId dpid where flow is installed
     * @param flowId The "name" of the flow, e.g., "TunnelFloodOut_100"
     * @param table integer value of table
     * @throws InterruptedException if interrupted while waiting for flow to appear in mdsal
     */
    public void verifyFlowById(long datapathId, String flowId, short table) throws Exception {
        org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder nodeBuilder =
                this.createNodeBuilder(datapathId);
        FlowBuilder flowBuilder =
                this.initFlowBuilder(new FlowBuilder(), flowId, table);

        InstanceIdentifier<Flow> iid = this.createFlowPath(flowBuilder, nodeBuilder);

        NotifyingDataChangeListener waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                NotifyingDataChangeListener.BIT_CREATE, iid, null);
        waitForIt.registerDataChangeListener(dataBroker);
        waitForIt.waitForCreation(10000);

        Flow flow = this.getFlow(flowBuilder, nodeBuilder,
                dataBroker.newReadOnlyTransaction(), LogicalDatastoreType.CONFIGURATION);
        assertNotNull("Could not find flow in config: " + flowBuilder.build() + "--" + nodeBuilder.build(), flow);

        waitForIt.close();
        waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                NotifyingDataChangeListener.BIT_CREATE, iid, null);
        waitForIt.registerDataChangeListener(dataBroker);
        waitForIt.waitForCreation(10000);

        flow = this.getFlow(flowBuilder, nodeBuilder,
                dataBroker.newReadOnlyTransaction(), LogicalDatastoreType.OPERATIONAL);
        assertNotNull("Could not find flow in operational: " + flowBuilder.build() + "--" + nodeBuilder.build(),
                flow);
        waitForIt.close();
    }

    /**
     * Verify that a flow in CONFIGURATION exists also in OPERATIONAL. This is done by looking up the flow in
     * CONFIGURATION by flowId and searching the flow's priority and matches in the OPERATIONAL.
     * @param datapathId dpid where flow is installed
     * @param flowId The "name" of the flow, e.g., "TunnelFloodOut_100"
     * @param tableId integer value of table
     * @param waitFor Retry every second for waitFor milliseconds
     * @throws InterruptedException if interrupted while waiting for flow to appear in mdsal
     */
    public void verifyFlowByFields(long datapathId, String flowId, short tableId, int waitFor)
            throws InterruptedException {
        long start = System.currentTimeMillis();
        int cnt = 0;
        do {
            try {
                cnt++;
                LOG.info("verifyFlowByFields(try {}) datapathId: {}, flowId: {}, tableId: {}",
                        cnt, datapathId, flowId, tableId);
                verifyFlowByFields(datapathId, flowId, tableId);
                return;
            } catch (AssertionError e) {
                if ((System.currentTimeMillis() - start) >= waitFor) {
                    throw e;
                }
                Thread.sleep(1000);
            }
        } while (true);
    }

    /**
     * Verify that a flow in CONFIGURATION exists also in OPERATIONAL. This is done by looking up the flow in
     * CONFIGURATION by flowId and searching the flow's priority and matches in the OPERATIONAL.
     * @param datapathId dpid where flow is installed
     * @param flowId The "name" of the flow, e.g., "TunnelFloodOut_100"
     * @param tableId integer value of table
     * @throws InterruptedException if interrupted while waiting for flow to appear in mdsal
     */
    public void verifyFlowByFields(long datapathId, String flowId, short tableId) throws InterruptedException {
        org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder nodeBuilder =
                this.createNodeBuilder(datapathId);
        FlowBuilder flowBuilder =
                this.initFlowBuilder(new FlowBuilder(), flowId, tableId);

        InstanceIdentifier<Flow> iid = this.createFlowPath(flowBuilder, nodeBuilder);

        NotifyingDataChangeListener waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                iid, null);
        waitForIt.registerDataChangeListener(dataBroker);
        waitForIt.waitForCreation(10000);

        Flow configFlow = this.getFlow(flowBuilder, nodeBuilder,
                dataBroker.newReadOnlyTransaction(), LogicalDatastoreType.CONFIGURATION);
        assertNotNull("Could not read flow " + flowId + " from configuration", configFlow);

        Table table = this.getTable(nodeBuilder, tableId, dataBroker.newReadOnlyTransaction(),
                LogicalDatastoreType.OPERATIONAL);
        assertNotNull("Could not read table " + tableId + " from operational", table);

        List<Flow> flows = table.getFlow();
        Assert.assertNotNull("No flows found for table", flows);

        for (Flow opFlow : flows) {
            if (checkFlowsEqual(configFlow, opFlow)) {
                LOG.info("verifyFlowByFields datapathId: {}, flowId: {}, tableId: {}",
                        datapathId, flowId, tableId);
                return;
            }
        }
        Assert.fail("Could not find matching flow in operational for " + flowId);
    }

    private boolean isMatchInList(AllMatchesGrouping match, List<AllMatchesGrouping> matchList) {
        for (AllMatchesGrouping match2 : matchList) {
            if (areMatchAugmentationsEqual(match, match2)) {
                return true;
            }
        }

        return false;
    }

    private boolean checkFlowsEqual(Flow configFlow, Flow opFlow) {
        Integer configPrio = configFlow.getPriority();
        Integer opPrio = opFlow.getPriority();
        if (!Objects.equals(configPrio == null ? DEFAULT_PRIORITY : configPrio,
                opPrio == null ? DEFAULT_PRIORITY : opPrio)) {
            return false;
        }
        return areMatchesEqual(configFlow.getMatch(), opFlow.getMatch());
    }

    private boolean areMatchesEqual(Match m1, Match m2) {
        if (m1 == null && m2 == null) {
            return true;
        }

        if (m1 == null || m2 == null) {
            return false;
        }

        if (!Objects.equals(m1.getInPort(), m2.getInPort())
                || !Objects.equals(m1.getInPhyPort(), m2.getInPhyPort())
                || !Objects.equals(m1.getMetadata(), m2.getMetadata())
                || !Objects.equals(m1.getTunnel(), m2.getTunnel())
                || !Objects.equals(m1.getEthernetMatch(), m2.getEthernetMatch())
                || !Objects.equals(m1.getVlanMatch(), m2.getVlanMatch())
                || !Objects.equals(m1.getIpMatch(), m2.getIpMatch())
                || !Objects.equals(m1.getLayer3Match(), m2.getLayer3Match())
                || !Objects.equals(m1.getLayer4Match(), m2.getLayer4Match())
                || !Objects.equals(m1.getIcmpv4Match(), m2.getIcmpv4Match())
                || !Objects.equals(m1.getIcmpv6Match(), m2.getIcmpv6Match())
                || !Objects.equals(m1.getProtocolMatchFields(), m2.getProtocolMatchFields())
                || !Objects.equals(m1.getTcpFlagsMatch(), m2.getTcpFlagsMatch())) {
            return false;
        }

        MatchAugmentationIterator it = new MatchAugmentationIterator(m1);
        List<AllMatchesGrouping> side1Matches = Lists.newArrayList();
        AllMatchesGrouping aug;
        while (null != (aug = it.next())) {
            side1Matches.add(aug);
        }

        it = new MatchAugmentationIterator(m2);
        while (null != (aug = it.next())) {
            if (!isMatchInList(aug, side1Matches)) {
                return false;
            }
        }

        return true;
    }

    private boolean areMatchAugmentationsEqual(AllMatchesGrouping obj1, AllMatchesGrouping obj2) {
        if (obj1 == null && obj2 == null) {
            return true;
        }

        if (obj1 == null || obj2 == null) {
            return false;
        }

        if (!Objects.equals(obj1.getNxmOfEthSrc(), obj2.getNxmOfEthSrc())
                || !Objects.equals(obj1.getNxmOfArpOp(), obj2.getNxmOfArpOp())
                || !Objects.equals(obj1.getNxmOfUdpDst(), obj2.getNxmOfUdpDst())
                || !Objects.equals(obj1.getNxmNxNshc3(), obj2.getNxmNxNshc3())
                || !Objects.equals(obj1.getNxmNxCtZone(), obj2.getNxmNxCtZone())
                || !Objects.equals(obj1.getNxmNxArpSha(), obj2.getNxmNxArpSha())
                || !Objects.equals(obj1.getNxmOfIcmpType(), obj2.getNxmOfIcmpType())
                || !Objects.equals(obj1.getNxmNxNshc1(), obj2.getNxmNxNshc1())
                || !Objects.equals(obj1.getNxmOfArpSpa(), obj2.getNxmOfArpSpa())
                || !Objects.equals(obj1.getNxmNxTunIpv4Dst(), obj2.getNxmNxTunIpv4Dst())
                || !Objects.equals(obj1.getNxmOfTcpSrc(), obj2.getNxmOfTcpSrc())
                || !Objects.equals(obj1.getNxmNxNshc4(), obj2.getNxmNxNshc4())
                || !Objects.equals(obj1.getNxmOfArpTpa(), obj2.getNxmOfArpTpa())
                || !Objects.equals(obj1.getNxmOfTcpDst(), obj2.getNxmOfTcpDst())
                || !Objects.equals(obj1.getNxmNxNsi(), obj2.getNxmNxNsi())
                || !Objects.equals(obj1.getNxmNxNshc2(), obj2.getNxmNxNshc2())
                || !Objects.equals(obj1.getNxmNxArpTha(), obj2.getNxmNxArpTha())
                || !Objects.equals(obj1.getNxmNxReg(), obj2.getNxmNxReg())
                || !Objects.equals(obj1.getNxmOfIpSrc(), obj2.getNxmOfIpSrc())
                || !Objects.equals(obj1.getNxmOfEthType(), obj2.getNxmOfEthType())
                || !Objects.equals(obj1.getNxmOfEthDst(), obj2.getNxmOfEthDst())
                || !Objects.equals(obj1.getNxmOfUdpSrc(), obj2.getNxmOfUdpSrc())
                || !Objects.equals(obj1.getNxmNxCtState(), obj2.getNxmNxCtState())
                || !Objects.equals(obj1.getNxmNxTunIpv4Src(), obj2.getNxmNxTunIpv4Src())
                || !Objects.equals(obj1.getNxmOfIpDst(), obj2.getNxmOfIpDst())
                || !Objects.equals(obj1.getNxmNxNsp(), obj2.getNxmNxNsp())) {
            return false;
        }

        return true;
    }

    class MatchAugmentationIterator {

        Match myMatch;

        MatchAugmentationIterator(Match match) {
            this.myMatch = match;
        }

        private int matchAugmentationIdx = 0;
        private int extListListIdx = 0;
        private int extListAugmentationIdx = 0;

        public AllMatchesGrouping next() {

            while (matchAugmentationIdx < MATCH_AUGMENTATIONS.length) {
                GeneralExtensionListGrouping extensionListGrouping = (GeneralExtensionListGrouping)
                        myMatch.getAugmentation(MATCH_AUGMENTATIONS[matchAugmentationIdx]);

                if (null != extensionListGrouping) {
                    List<ExtensionList> extListList = extensionListGrouping.getExtensionList();

                    while (extListListIdx < extListList.size()) {

                        ExtensionList extList = extListList.get(extListListIdx);

                        while (extListAugmentationIdx < EXT_LIST_AUGMENTATIONS.length) {
                            Augmentation res = extList.getExtension().getAugmentation(
                                    EXT_LIST_AUGMENTATIONS[extListAugmentationIdx]);
                            ++extListAugmentationIdx;
                            if (res != null) {
                                return (AllMatchesGrouping) res;
                            }
                        }
                        extListAugmentationIdx = 0;
                        ++extListListIdx;
                    }
                    extListListIdx = 0;
                }
                ++matchAugmentationIdx;

            }

            return null;
        }

    }
}
