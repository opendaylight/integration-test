/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.utils.netvirt.it.utils;

import static org.junit.Assert.assertNotNull;

import com.google.common.collect.Lists;
import org.junit.Assert;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.sal.binding.api.BindingAwareBroker;
import org.opendaylight.netvirt.utils.mdsal.openflow.FlowUtils;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.mdsal.utils.NotifyingDataChangeListener;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.Table;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.Match;
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
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yangtools.yang.binding.Augmentation;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Objects;

/**
 * This class contains various utility methods used in netvirt integration tests (IT).
 */
public class NetvirtItUtils {
    private static final Logger LOG = LoggerFactory.getLogger(NetvirtItUtils.class);
    MdsalUtils mdsalUtils;
    SouthboundUtils southboundUtils;
    DataBroker dataBroker;

    private final static Class[] MATCH_AUGMENTATIONS = {GeneralAugMatchNodesNodeTableFlow.class,
            GeneralAugMatchNotifUpdateFlowStats.class,
            GeneralAugMatchNotifPacketIn.class,
            GeneralAugMatchNotifSwitchFlowRemoved.class,
            GeneralAugMatchRpcAddFlow.class,
            GeneralAugMatchRpcRemoveFlow.class,
            GeneralAugMatchRpcUpdateFlowOriginal.class,
            GeneralAugMatchRpcUpdateFlowUpdated.class};

    private final static Class[] EXT_LIST_AUGMENTATIONS = {NxAugMatchNodesNodeTableFlow.class,
            NxAugMatchNotifUpdateFlowStats.class,
            NxAugMatchNotifPacketIn.class,
            NxAugMatchNotifSwitchFlowRemoved.class,
            NxAugMatchRpcAddFlow.class,
            NxAugMatchRpcRemoveFlow.class,
            NxAugMatchRpcUpdateFlowOriginal.class,
            NxAugMatchRpcUpdateFlowUpdated.class};

    private static Integer DEFAULT_PRIORITY = 32768;

    /**
     * Create a new NetvirtItUtils instance.
     * @param dataBroker  md-sal data broker
     */
    public NetvirtItUtils(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
        mdsalUtils = new MdsalUtils(dataBroker);
        southboundUtils = new SouthboundUtils(mdsalUtils);
    }

    /**
     * Check that the netvirt topology is in the operational mdsal.
     * @return true if the netvirt topology was successfully retrieved
     */
    public Boolean getNetvirtTopology() {
        LOG.info("getNetvirtTopology: looking for {}...", ItConstants.NETVIRT_TOPOLOGY_ID);
        final TopologyId topologyId = new TopologyId(new Uri(ItConstants.NETVIRT_TOPOLOGY_ID));
        InstanceIdentifier<Topology> path =
                InstanceIdentifier.create(NetworkTopology.class).child(Topology.class, new TopologyKey(topologyId));
        NotifyingDataChangeListener waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                path, null);
        waitForIt.registerDataChangeListener(dataBroker);
        try {
            waitForIt.waitForCreation(60 * 1000);
        } catch (InterruptedException e) {
            LOG.info("getNetvirtTopology: InterruptedException while wait(ing)ForCreation");
        }

        boolean found = null != mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, path);

        LOG.info("getNetvirtTopology: found {} == {}", ItConstants.NETVIRT_TOPOLOGY_ID, found);

        return found;
    }

    private static final int FLOW_WAIT = 30 * 1000;

    /**
     * Verify <strong>by flow id</strong> that the given flow was installed in a table. This method will wait 10
     * seconds for the flows to appear in each of the md-sal CONFIGURATION and OPERATIONAL data stores
     * @param datapathId dpid where flow is installed
     * @param flowId The "name" of the flow, e.g., "TunnelFloodOut_100"
     * @param table integer value of table
     * @throws InterruptedException if interrupted while waiting for flow to appear in mdsal
     */
    public void verifyFlow(long datapathId, String flowId, short table) throws Exception {
        org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder nodeBuilder =
                FlowUtils.createNodeBuilder(datapathId);
        FlowBuilder flowBuilder =
                FlowUtils.initFlowBuilder(new FlowBuilder(), flowId, table);

        InstanceIdentifier<Flow> iid = FlowUtils.createFlowPath(flowBuilder, nodeBuilder);

        NotifyingDataChangeListener waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                NotifyingDataChangeListener.BIT_CREATE, iid, null);
        waitForIt.registerDataChangeListener(dataBroker);
        waitForIt.waitForCreation(FLOW_WAIT);

        Flow flow = FlowUtils.getFlow(flowBuilder, nodeBuilder,
                        dataBroker.newReadOnlyTransaction(), LogicalDatastoreType.CONFIGURATION);
        assertNotNull("Could not find flow in config: " + flowBuilder.build() + "--" + nodeBuilder.build(), flow);

        waitForIt.close();
        waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                NotifyingDataChangeListener.BIT_CREATE, iid, null);
        waitForIt.registerDataChangeListener(dataBroker);
        waitForIt.waitForCreation(FLOW_WAIT);

        flow = FlowUtils.getFlow(flowBuilder, nodeBuilder,
                        dataBroker.newReadOnlyTransaction(), LogicalDatastoreType.OPERATIONAL);
        assertNotNull("Could not find flow in operational: " + flowBuilder.build() + "--" + nodeBuilder.build(),
                flow);
        waitForIt.close();
    }

    /*public void verifyFlowByFields(long datapathId, String flowId, short tableId, int waitFor)
            throws Exception {
        verifyFlow(datapathId, flowId, tableId);
    }*/

    /**
     * Verify that a flow in CONFIGURATION exists also in OPERATIONAL. This is done by looking up the flow in
     * CONFIGURATION by flowId and searching the flow's priority and matches in the OPERATIONAL.
     * @param datapathId dpid where flow is installed
     * @param flowId The "name" of the flow, e.g., "TunnelFloodOut_100"
     * @param tableId integer value of table
     * @param waitFor Retry every second for waitFor milliseconds
     * @throws InterruptedException if interrupted while waiting for flow to appear in mdsal
     */
    public void verifyFlowByFields(long datapathId, String flowId, short tableId, int waitFor) throws Exception {
        long start = System.currentTimeMillis();
        do {
            try {
                verifyFlowByFields(datapathId, flowId, tableId);
                return;
            } catch (AssertionError e) {
                if((System.currentTimeMillis() - start) >= waitFor) {
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
    public void verifyFlowByFields(long datapathId, String flowId, short tableId) throws Exception {
        org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder nodeBuilder =
                FlowUtils.createNodeBuilder(datapathId);
        FlowBuilder flowBuilder =
                FlowUtils.initFlowBuilder(new FlowBuilder(), flowId, tableId);

        InstanceIdentifier<Flow> iid = FlowUtils.createFlowPath(flowBuilder, nodeBuilder);

        NotifyingDataChangeListener waitForIt = new NotifyingDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                NotifyingDataChangeListener.BIT_CREATE, iid, null);
        waitForIt.registerDataChangeListener(dataBroker);
        waitForIt.waitForCreation(10000);

        Flow configFlow = FlowUtils.getFlow(flowBuilder, nodeBuilder,
                dataBroker.newReadOnlyTransaction(), LogicalDatastoreType.CONFIGURATION);
        assertNotNull("Could not read flow " + flowId + " from configuration", configFlow);

        LOG.info("verifyFlowByFields: flowId:{} configFlow:{}", flowId, configFlow);
        waitForIt.close();
        Table table = FlowUtils.getTable(nodeBuilder, tableId, dataBroker.newReadOnlyTransaction(),
                                                                                    LogicalDatastoreType.OPERATIONAL);
        assertNotNull("Could not read table " + tableId + " from operational", table);

        List<Flow> flows = table.getFlow();
        LOG.info("verifyFlowByFields: tableId:{} operatioanlFlows:{}", tableId, flows);
        Assert.assertNotNull("No flows found for table", flows);

        for (Flow opFlow : flows) {
            if (checkFlowsEqual(configFlow, opFlow)) {
                return;
            }
        }
        Assert.fail("Could not find matching flow in operational for " + flowId);
    }

    private boolean checkFlowsEqual(Flow configFlow, Flow opFlow) {
        Integer configPrio = configFlow.getPriority();
        Integer opPrio = opFlow.getPriority();
        LOG.info("checkFlowsEqual-Priority: ConfigPriority:{} OperationalPriority:{}", configPrio, opPrio);
        if (!Objects.equals(configPrio == null ? DEFAULT_PRIORITY : configPrio,
                opPrio == null ? DEFAULT_PRIORITY : opPrio)) {
            return false;
        }
        LOG.info("checkFlowsEqual-MatchesEquals: Config:{} operational:{}", configFlow.getMatch(), opFlow.getMatch());
        return areMatchesEqual(configFlow.getMatch(), opFlow.getMatch());
    }

    private boolean areMatchesEqual(Match m1, Match m2) {
        if (m1 == null && m2 == null) {
            return true;
        }

        if (m1 == null || m2 == null) {
            return false;
        }

        if (!Objects.equals(m1.getInPort(), m2.getInPort())) { return false; }
        if (!Objects.equals(m1.getInPhyPort(), m2.getInPhyPort())) { return false; }
        if (!Objects.equals(m1.getMetadata(), m2.getMetadata())) { return false; }
        if (!Objects.equals(m1.getTunnel(), m2.getTunnel())) { return false; }
        if (!Objects.equals(m1.getEthernetMatch(), m2.getEthernetMatch())) { return false; }
        if (!Objects.equals(m1.getVlanMatch(), m2.getVlanMatch())) { return false; }
        if (!Objects.equals(m1.getIpMatch(), m2.getIpMatch())) { return false; }
        if (!Objects.equals(m1.getLayer3Match(), m2.getLayer3Match())) { return false; }
        if (!Objects.equals(m1.getLayer4Match(), m2.getLayer4Match())) { return false; }
        if (!Objects.equals(m1.getIcmpv4Match(), m2.getIcmpv4Match())) { return false; }
        if (!Objects.equals(m1.getIcmpv6Match(), m2.getIcmpv6Match())) { return false; }
        if (!Objects.equals(m1.getProtocolMatchFields(), m2.getProtocolMatchFields())) { return false; }
        if (!Objects.equals(m1.getTcpFlagsMatch(), m2.getTcpFlagsMatch())) { return false; }

        MatchAugmentationIterator it = new MatchAugmentationIterator(m1);
        List<AllMatchesGrouping> side1Matches = Lists.newArrayList();
        AllMatchesGrouping aug;
        while (null != (aug = it.next())) {
            side1Matches.add(aug);
        }

        it = new MatchAugmentationIterator(m2);
        while(null != (aug = it.next())) {
            if (!isMatchInList(aug, side1Matches)) {
                return false;
            }
        }

        return true;
    }

    private boolean isMatchInList(AllMatchesGrouping match, List<AllMatchesGrouping> matchList) {
        for (AllMatchesGrouping match2 : matchList) {
            if (areMatchAugmentationsEqual(match, match2)) {
                return true;
            }
        }

        return false;
    }

    class MatchAugmentationIterator {

        Match myMatch;

        public MatchAugmentationIterator(Match match) {
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

                        while(extListAugmentationIdx < EXT_LIST_AUGMENTATIONS.length) {
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

    private boolean areMatchAugmentationsEqual(AllMatchesGrouping obj1, AllMatchesGrouping obj2) {
        if (obj1 == null && obj2 == null) {
            return true;
        }

        if (obj1 == null || obj2 == null) {
            return false;
        }
        if (!Objects.equals(obj1.getNxmOfEthSrc(), obj2.getNxmOfEthSrc())) { return false; }
        if (!Objects.equals(obj1.getNxmOfArpOp(), obj2.getNxmOfArpOp())) { return false; }
        if (!Objects.equals(obj1.getNxmOfUdpDst(), obj2.getNxmOfUdpDst())) { return false; }
        if (!Objects.equals(obj1.getNxmNxNshc3(), obj2.getNxmNxNshc3())) { return false; }
        if (!Objects.equals(obj1.getNxmNxCtZone(), obj2.getNxmNxCtZone())) { return false; }
        if (!Objects.equals(obj1.getNxmNxArpSha(), obj2.getNxmNxArpSha())) { return false; }
        if (!Objects.equals(obj1.getNxmOfIcmpType(), obj2.getNxmOfIcmpType())) { return false; }
        if (!Objects.equals(obj1.getNxmNxNshc1(), obj2.getNxmNxNshc1())) { return false; }
        if (!Objects.equals(obj1.getNxmOfArpSpa(), obj2.getNxmOfArpSpa())) { return false; }
        if (!Objects.equals(obj1.getNxmNxTunIpv4Dst(), obj2.getNxmNxTunIpv4Dst())) { return false; }
        if (!Objects.equals(obj1.getNxmOfTcpSrc(), obj2.getNxmOfTcpSrc())) { return false; }
        if (!Objects.equals(obj1.getNxmNxNshc4(), obj2.getNxmNxNshc4())) { return false; }
        if (!Objects.equals(obj1.getNxmOfArpTpa(), obj2.getNxmOfArpTpa())) { return false; }
        if (!Objects.equals(obj1.getNxmOfTcpDst(), obj2.getNxmOfTcpDst())) { return false; }
        if (!Objects.equals(obj1.getNxmNxNsi(), obj2.getNxmNxNsi())) { return false; }
        if (!Objects.equals(obj1.getNxmNxNshc2(), obj2.getNxmNxNshc2())) { return false; }
        if (!Objects.equals(obj1.getNxmNxArpTha(), obj2.getNxmNxArpTha())) { return false; }
        if (!Objects.equals(obj1.getNxmNxReg(), obj2.getNxmNxReg())) { return false; }
        if (!Objects.equals(obj1.getNxmOfIpSrc(), obj2.getNxmOfIpSrc())) { return false; }
        if (!Objects.equals(obj1.getNxmOfEthType(), obj2.getNxmOfEthType())) { return false; }
        if (!Objects.equals(obj1.getNxmOfEthDst(), obj2.getNxmOfEthDst())) { return false; }
        if (!Objects.equals(obj1.getNxmOfUdpSrc(), obj2.getNxmOfUdpSrc())) { return false; }
        if (!Objects.equals(obj1.getNxmNxCtState(), obj2.getNxmNxCtState())) { return false; }
        if (!Objects.equals(obj1.getNxmNxTunIpv4Src(), obj2.getNxmNxTunIpv4Src())) { return false; }
        if (!Objects.equals(obj1.getNxmOfIpDst(), obj2.getNxmOfIpDst())) { return false; }
        if (!Objects.equals(obj1.getNxmNxNsp(), obj2.getNxmNxNsp())) { return false; }

        return true;
    }

    /**
     * Log the flows in a given table.
     * @param datapathId dpid
     * @param tableNum table number
     * @param store configuration or operational
     */
    public void logFlows(long datapathId, short tableNum, LogicalDatastoreType store) {
        org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder nodeBuilder =
                FlowUtils.createNodeBuilder(datapathId);
        Table table = FlowUtils.getTable(nodeBuilder, tableNum, dataBroker.newReadOnlyTransaction(), store);
        if (table == null) {
            LOG.info("logFlows: Could not find table {} in {}", tableNum, store);
        }
        //TBD: Log table and store in one line, flows in following lines
        for (Flow flow : table.getFlow()) {
            LOG.info("logFlows: table {} flow {} in {}", tableNum, flow.getFlowName(), store);
        }
    }

    /**
     * Log the flows in a given table.
     * @param datapathId dpid
     * @param table table number
     */
    public void logFlows(long datapathId, short table) {
        logFlows(datapathId, table, LogicalDatastoreType.CONFIGURATION);
    }

    /**
     * Get a DataBroker and assert that it is not null.
     * @param providerContext ProviderContext from which to retrieve the DataBroker
     * @return the Databroker
     */
    public static DataBroker getDatabroker(BindingAwareBroker.ProviderContext providerContext) {
        DataBroker dataBroker = providerContext.getSALService(DataBroker.class);
        assertNotNull("dataBroker should not be null", dataBroker);
        return dataBroker;
    }
}
