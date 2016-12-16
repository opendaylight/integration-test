/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.AbstractDataChangeListener;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.NxMatchInfo;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.elan.utils.ElanConstants;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.config.rev150710.ElanConfig;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ElanNodeListener extends AbstractDataChangeListener<Node> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(ElanNodeListener.class);
    private static final String LEARN_MATCH_REG4_VALUE = "1";

    private final DataBroker broker;
    private final IMdsalApiManager mdsalManager;
    private final int tempSmacLearnTimeout;

    private ListenerRegistration<DataChangeListener> listenerRegistration;

    public ElanNodeListener(DataBroker dataBroker, IMdsalApiManager mdsalManager, ElanConfig elanConfig) {
        super(Node.class);
        this.broker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.tempSmacLearnTimeout = elanConfig.getTempSmacLearnTimeout();
    }

    public void init() {
        registerListener(broker);
    }

    private void registerListener(final DataBroker db) {
        listenerRegistration = db.registerDataChangeListener(LogicalDatastoreType.OPERATIONAL,
            getWildCardPath(), ElanNodeListener.this, AsyncDataBroker.DataChangeScope.SUBTREE);
    }

    private InstanceIdentifier<Node> getWildCardPath() {
        return InstanceIdentifier.create(Nodes.class).child(Node.class);
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node del) {
    }

    @Override
    protected void update(InstanceIdentifier<Node> identifier, Node original, Node update) {
    }

    @Override
    protected void add(InstanceIdentifier<Node> identifier, Node add) {
        NodeId nodeId = add.getId();
        String[] node =  nodeId.getValue().split(":");
        if (node.length < 2) {
            LOG.warn("Unexpected nodeId {}", nodeId.getValue());
            return;
        }
        BigInteger dpId = new BigInteger(node[1]);
        createTableMissEntry(dpId);
    }

    public void createTableMissEntry(BigInteger dpnId) {
        setupTableMissSmacFlow(dpnId);
        setupTableMissDmacFlow(dpnId);
    }

    private void setupTableMissSmacFlow(BigInteger dpId) {
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller, new String[] {}));

        String[][] learnActionMatches = new String[2][];
        learnActionMatches[0] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_SRC.getFlowModHeaderLen() };
        learnActionMatches[1] = new String[] {
                NwConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), LEARN_MATCH_REG4_VALUE,
                NwConstants.NxmOfFieldType.NXM_NX_REG4.getHexType(), "8" };

        String[] header = new String[] {
            String.valueOf(0),
            String.valueOf(tempSmacLearnTimeout),
            BigInteger.ZERO.toString(),
            ElanConstants.COOKIE_ELAN_LEARNED_SMAC.toString(),
            "0",
            Short.toString(NwConstants.ELAN_SMAC_LEARNED_TABLE),
            String.valueOf(0),
            String.valueOf(0)
        };
        actionsInfos.add(new ActionInfo(ActionType.learn, header, learnActionMatches));

        List<InstructionInfo> mkInstructions = new ArrayList<>();
        mkInstructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        mkInstructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.ELAN_DMAC_TABLE }));

        List<MatchInfo> mkMatches = new ArrayList<>();
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.ELAN_SMAC_TABLE,
                getTableMissFlowRef(NwConstants.ELAN_SMAC_TABLE), 0, "ELAN sMac Table Miss Flow", 0, 0,
                ElanConstants.COOKIE_ELAN_KNOWN_SMAC, mkMatches, mkInstructions);
        mdsalManager.installFlow(flowEntity);

        addSmacBaseTableFlow(dpId);
        addSmacLearnedTableFlow(dpId);
    }

    private void addSmacBaseTableFlow(BigInteger dpId) {
        //T48 - resubmit to T49 & T50
        List<ActionInfo> actionsInfo = new ArrayList<>();
        actionsInfo.add(new ActionInfo(ActionType.nx_resubmit,
                new String[] {Short.toString(NwConstants.ELAN_SMAC_LEARNED_TABLE) }));
        actionsInfo.add(new ActionInfo(ActionType.nx_resubmit,
                new String[] {Short.toString(NwConstants.ELAN_SMAC_TABLE) }));
        List<InstructionInfo> mkInstruct = new ArrayList<>();
        mkInstruct.add(new InstructionInfo(InstructionType.apply_actions, actionsInfo));
        List<MatchInfo> mkMatch = new ArrayList<>();
        FlowEntity doubleResubmitTable = MDSALUtil.buildFlowEntity(dpId, NwConstants.ELAN_BASE_TABLE,
                getTableMissFlowRef(NwConstants.ELAN_BASE_TABLE),
                0, "Elan sMac resubmit table", 0, 0,
                ElanConstants.COOKIE_ELAN_BASE_SMAC, mkMatch, mkInstruct);
        mdsalManager.installFlow(doubleResubmitTable);
    }

    private void addSmacLearnedTableFlow(BigInteger dpId) {
        //T50 - match on Reg4 and goto T51
        List<MatchInfoBase> mkMatches = new ArrayList<>();
        mkMatches.add(new NxMatchInfo(NxMatchFieldType.nxm_reg_4, new long[] {
                Long.valueOf(LEARN_MATCH_REG4_VALUE).longValue() }));
        List<InstructionInfo> mkInstructions = new ArrayList<>();
        mkInstructions.add(new InstructionInfo(InstructionType.goto_table,
                new long[] { NwConstants.ELAN_DMAC_TABLE }));
        String flowRef = new StringBuffer().append(NwConstants.ELAN_SMAC_TABLE).append(NwConstants.FLOWID_SEPARATOR)
                .append(LEARN_MATCH_REG4_VALUE).toString();
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.ELAN_SMAC_TABLE, flowRef,
                10, "ELAN sMac Table Reg4 Flow", 0, 0,
                ElanConstants.COOKIE_ELAN_KNOWN_SMAC.add(new BigInteger(LEARN_MATCH_REG4_VALUE)),
                mkMatches, mkInstructions);
        mdsalManager.installFlow(flowEntity);
    }

    private void setupTableMissDmacFlow(BigInteger dpId) {
        List<MatchInfo> mkMatches = new ArrayList<>();

        List<InstructionInfo> mkInstructions = new ArrayList<>();
        mkInstructions.add(
                new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.ELAN_UNKNOWN_DMAC_TABLE }));

        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.ELAN_DMAC_TABLE,
                getTableMissFlowRef(NwConstants.ELAN_DMAC_TABLE), 0, "ELAN dMac Table Miss Flow", 0, 0,
                ElanConstants.COOKIE_ELAN_KNOWN_DMAC, mkMatches, mkInstructions);
        mdsalManager.installFlow(flowEntity);
    }

    private String getTableMissFlowRef(long tableId) {
        return new StringBuffer().append(tableId).toString();
    }

    @Override
    public void close() throws Exception {
        if (listenerRegistration != null) {
            listenerRegistration.close();
        }
    }
}
