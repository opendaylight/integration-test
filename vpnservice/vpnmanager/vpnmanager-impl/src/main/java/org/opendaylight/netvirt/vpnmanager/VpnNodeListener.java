/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.vpnmanager.arp.responder.ArpResponderConstant;
import org.opendaylight.netvirt.vpnmanager.arp.responder.ArpResponderUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VpnNodeListener extends AsyncClusteredDataTreeChangeListenerBase<Node, VpnNodeListener> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(VpnNodeListener.class);
    private static final String FLOWID_PREFIX = "L3.";
    private static final String FLOWID_PREFIX_FOR_ARP = "L3.GW_MAC_TABLE.ARP.";

    private final DataBroker broker;
    private final IMdsalApiManager mdsalManager;
    private final IdManagerService idManagerService;

    public VpnNodeListener(DataBroker dataBroker, IMdsalApiManager mdsalManager, final IdManagerService idManagerService) {
        super(Node.class, VpnNodeListener.class);
        this.broker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.idManagerService = idManagerService;
    }

    public void start() {
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }

    @Override
    public void close() throws Exception {
        super.close();
    }

    @Override
    protected InstanceIdentifier<Node> getWildCardPath() {
        return InstanceIdentifier.create(Nodes.class).child(Node.class);
    }

    @Override
    protected VpnNodeListener getDataTreeChangeListener() {
        return VpnNodeListener.this;
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
        processNodeAdd(dpId);
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node del) {
    }

    @Override
    protected void update(InstanceIdentifier<Node> identifier, Node original, Node update) {
    }

    private void processNodeAdd(BigInteger dpId) {
        LOG.debug("Received notification to install TableMiss entries for dpn {} ", dpId);
        WriteTransaction writeFlowTx = broker.newWriteOnlyTransaction();
        makeTableMissFlow(writeFlowTx, dpId, NwConstants.ADD_FLOW);
        makeL3IntfTblMissFlow(writeFlowTx, dpId, NwConstants.ADD_FLOW);
        makeSubnetRouteTableMissFlow(writeFlowTx, dpId, NwConstants.ADD_FLOW);
        programTableMissForVpnVniDemuxTable(writeFlowTx, dpId, NwConstants.ADD_FLOW);
        createTableMissForVpnGwFlow(writeFlowTx, dpId);
        createArpRequestMatchFlowForGwMacTable(writeFlowTx, dpId);
        createArpResponseMatchFlowForGwMacTable(writeFlowTx, dpId);
        writeFlowTx.submit();
    }

    private void makeTableMissFlow(WriteTransaction writeFlowTx, BigInteger dpnId, int addOrRemove) {
        final BigInteger COOKIE_TABLE_MISS = new BigInteger("1030000", 16);
        // Instruction to goto L3 InterfaceTable
        List<InstructionInfo> instructions = Collections.singletonList(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.L3_INTERFACE_TABLE }));
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        FlowEntity flowEntityLfib = MDSALUtil.buildFlowEntity(dpnId, NwConstants.L3_LFIB_TABLE,
                getTableMissFlowRef(dpnId, NwConstants.L3_LFIB_TABLE, NwConstants.TABLE_MISS_FLOW),
                NwConstants.TABLE_MISS_PRIORITY, "Table Miss", 0, 0, COOKIE_TABLE_MISS, matches, instructions);

        if (addOrRemove == NwConstants.ADD_FLOW) {
            LOG.debug("Invoking MDSAL to install Table Miss Entry");
            mdsalManager.addFlowToTx(flowEntityLfib, writeFlowTx);
        } else {
            mdsalManager.removeFlowToTx(flowEntityLfib, writeFlowTx);
        }
    }

    private void makeL3IntfTblMissFlow(WriteTransaction writeFlowTx, BigInteger dpnId, int addOrRemove) {
        List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        final BigInteger COOKIE_TABLE_MISS = new BigInteger("1030000", 16);
        // Instruction to goto L3 InterfaceTable

        List <ActionInfo> actionsInfos = new ArrayList <ActionInfo> ();
        actionsInfos.add(new ActionInfo(ActionType.nx_resubmit, new String[]{
                Short.toString(NwConstants.LPORT_DISPATCHER_TABLE)}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        //instructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.LPORT_DISPATCHER_TABLE }));

        FlowEntity flowEntityL3Intf = MDSALUtil.buildFlowEntity(dpnId, NwConstants.L3_INTERFACE_TABLE,
                getTableMissFlowRef(dpnId, NwConstants.L3_INTERFACE_TABLE, NwConstants.TABLE_MISS_FLOW),
                NwConstants.TABLE_MISS_PRIORITY, "L3 Interface Table Miss", 0, 0, COOKIE_TABLE_MISS,
                matches, instructions);
        if (addOrRemove == NwConstants.ADD_FLOW) {
            LOG.debug("Invoking MDSAL to install L3 interface Table Miss Entries");
            mdsalManager.addFlowToTx(flowEntityL3Intf, writeFlowTx);
        } else {
            mdsalManager.removeFlowToTx(flowEntityL3Intf, writeFlowTx);
        }
    }

    private void makeSubnetRouteTableMissFlow(WriteTransaction writeFlowTx, BigInteger dpnId, int addOrRemove) {
        final BigInteger COOKIE_TABLE_MISS = new BigInteger("8000004", 16);
        List<ActionInfo> actionsInfos = new ArrayList<ActionInfo>();
        List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller, new String[]{}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        String flowRef = getTableMissFlowRef(dpnId, NwConstants.L3_SUBNET_ROUTE_TABLE, NwConstants.TABLE_MISS_FLOW);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpnId, NwConstants.L3_SUBNET_ROUTE_TABLE, flowRef,
                NwConstants.TABLE_MISS_PRIORITY, "Subnet Route Table Miss", 0, 0, COOKIE_TABLE_MISS, matches, instructions);

        if (addOrRemove == NwConstants.ADD_FLOW) {
            mdsalManager.addFlowToTx(flowEntity, writeFlowTx);
        } else {
            mdsalManager.removeFlowToTx(flowEntity, writeFlowTx);
        }
    }

    private void programTableMissForVpnVniDemuxTable(WriteTransaction writeFlowTx, BigInteger dpnId, int addOrRemove) {
        final BigInteger COOKIE_TABLE_MISS = new BigInteger("1080000", 16);
        List<ActionInfo> actionsInfos = new ArrayList<ActionInfo>();
        List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
        actionsInfos.add(new ActionInfo(ActionType.nx_resubmit, new String[]{Short.toString(NwConstants.LPORT_DISPATCHER_TABLE)}));
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        String flowRef = getTableMissFlowRef(dpnId, (short)1850, NwConstants.TABLE_MISS_FLOW);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpnId, (short)1850, flowRef,
                NwConstants.TABLE_MISS_PRIORITY, "VPN-VNI Demux Table Miss", 0, 0, COOKIE_TABLE_MISS, matches, instructions);

        if (addOrRemove == NwConstants.ADD_FLOW) {
            mdsalManager.addFlowToTx(flowEntity, writeFlowTx);
        } else {
            mdsalManager.removeFlowToTx(flowEntity, writeFlowTx);
        }
    }

    private void createTableMissForVpnGwFlow(WriteTransaction writeFlowTx, BigInteger dpId) {
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        List<ActionInfo> actionsInfos = Collections.singletonList(new ActionInfo(ActionType.nx_resubmit, new String[] { Integer.toString(NwConstants.LPORT_DISPATCHER_TABLE) }));
        List<InstructionInfo> instructions = Collections.singletonList(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        FlowEntity flowEntityMissforGw = MDSALUtil.buildFlowEntity(dpId, NwConstants.L3_GW_MAC_TABLE,
                getTableMissFlowRef(dpId, NwConstants.L3_GW_MAC_TABLE, NwConstants.TABLE_MISS_FLOW),
                NwConstants.TABLE_MISS_PRIORITY, "L3 Gw Mac Table Miss", 0, 0, new BigInteger("1080000", 16), matches, instructions);
        LOG.trace("Invoking MDSAL to install L3 Gw Mac Table Miss Entry");
        mdsalManager.addFlowToTx(flowEntityMissforGw, writeFlowTx);
        mdsalManager.addFlowToTx(ArpResponderUtil.getArpResponderTableMissFlow(dpId), writeFlowTx);
   }

    private void createArpRequestMatchFlowForGwMacTable(WriteTransaction writeFlowTx, BigInteger dpId) {
        final List<BucketInfo> buckets = ArpResponderUtil.getDefaultBucketInfos(
                NwConstants.LPORT_DISPATCHER_TABLE,
                NwConstants.ARP_RESPONDER_TABLE);
        ArpResponderUtil.installGroup(mdsalManager, dpId,
                ArpResponderUtil.retrieveStandardArpResponderGroupId(idManagerService),
                ArpResponderConstant.GROUP_FLOW_NAME.value(), buckets);

        final List<MatchInfo> matches = new ArrayList<MatchInfo>();
        matches.add(new MatchInfo(MatchFieldType.eth_type, new long[] { NwConstants.ETHTYPE_ARP }));
        matches.add(new MatchInfo(MatchFieldType.arp_op, new long[] {NwConstants.ARP_REQUEST}));
        final List<ActionInfo> actionInfos = Collections.singletonList(new ActionInfo(ActionType.group, new String[] { String.valueOf(ArpResponderUtil.retrieveStandardArpResponderGroupId(idManagerService))}));
        final List<InstructionInfo> instructions = Collections.singletonList(new InstructionInfo(InstructionType.apply_actions, actionInfos));
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.L3_GW_MAC_TABLE,
                getFlowRefForArpFlows(dpId, NwConstants.L3_GW_MAC_TABLE, NwConstants.ARP_REQUEST),
                NwConstants.DEFAULT_ARP_FLOW_PRIORITY, "L3GwMac Arp Rquest", 0, 0, new BigInteger("1080000", 16), matches, instructions);
        LOG.trace("Invoking MDSAL to install L3 Gw Mac Arp Rquest Match Flow");
        mdsalManager.addFlowToTx(flowEntity, writeFlowTx);
   }

    private void createArpResponseMatchFlowForGwMacTable(WriteTransaction writeFlowTx, BigInteger dpId) {
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        matches.add(new MatchInfo(MatchFieldType.eth_type, new long[] { NwConstants.ETHTYPE_ARP }));
        matches.add(new MatchInfo(MatchFieldType.arp_op, new long[] {NwConstants.ARP_REPLY}));
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller, new String[] {}));
        actionsInfos.add(new ActionInfo(ActionType.nx_resubmit, new String[] { Integer.toString(NwConstants.LPORT_DISPATCHER_TABLE) }));
        List<InstructionInfo> instructions = Collections.singletonList(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.L3_GW_MAC_TABLE,
                getFlowRefForArpFlows(dpId, NwConstants.L3_GW_MAC_TABLE, NwConstants.ARP_REPLY),
                NwConstants.DEFAULT_ARP_FLOW_PRIORITY, "L3GwMac Arp Reply", 0, 0, new BigInteger("1080000", 16), matches, instructions);
        LOG.trace("Invoking MDSAL to install L3 Gw Mac Arp Reply Match Flow");
        mdsalManager.addFlowToTx(flowEntity, writeFlowTx);
   }

    private String getFlowRefForArpFlows(BigInteger dpnId, short tableId, int arpRequestOrReply) {
        return new StringBuffer().append(FLOWID_PREFIX_FOR_ARP).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR).append(arpRequestOrReply)
                .append(FLOWID_PREFIX).toString();
    }

    private String getTableMissFlowRef(BigInteger dpnId, short tableId, int tableMiss) {
        return new StringBuffer().append(FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR).append(tableMiss)
                .append(FLOWID_PREFIX).toString();
    }
}