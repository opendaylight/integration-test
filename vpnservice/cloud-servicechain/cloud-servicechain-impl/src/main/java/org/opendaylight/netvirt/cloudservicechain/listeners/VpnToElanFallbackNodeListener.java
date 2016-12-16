/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.listeners;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.cloudservicechain.CloudServiceChainConstants;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.FlowId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NodeId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;

import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

// Rationale: for vpn-servicechain and elan-servicechain to coexist in the same deployment, it is necessary a flow
// in LPortDispatcher that sets SI to ELAN in case that VPN does not apply
/**
 * Listens for Node Up/Down events in order to install the L2 to L3 default
 * fallback flow. This flow, with minimum priority, consists on matching on
 * SI=2 and sets SI=3.
 *
 */
public class VpnToElanFallbackNodeListener extends AsyncDataTreeChangeListenerBase<Node, VpnToElanFallbackNodeListener>
                                           implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(VpnToElanFallbackNodeListener.class);
    private static final String L3_TO_L2_DEFAULT_FLOW_REF = "L3VPN_to_Elan_Fallback_Default_Rule";

    private final DataBroker broker;
    private final IMdsalApiManager mdsalMgr;

    // TODO: Remove when included in ovsdb's SouthboundUtils
    public static final TopologyId FLOW_TOPOLOGY_ID = new TopologyId(new Uri("flow:1"));

    public VpnToElanFallbackNodeListener(final DataBroker db, final IMdsalApiManager mdsalManager) {
        super(Node.class, VpnToElanFallbackNodeListener.class);
        this.broker = db;
        this.mdsalMgr = mdsalManager;
    }

    @Override
    public void init() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }


    @Override
    protected InstanceIdentifier<Node> getWildCardPath() {
        return InstanceIdentifier.create(NetworkTopology.class)
                                 .child(Topology.class, new TopologyKey(FLOW_TOPOLOGY_ID))
                                 .child(Node.class);
    }

    @Override
    protected VpnToElanFallbackNodeListener getDataTreeChangeListener() {
        return VpnToElanFallbackNodeListener.this;
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node del) {
        BigInteger dpnId = getDpnIdFromNodeId(del.getNodeId());
        if ( dpnId == null ) {
            return;
        }

        LOG.debug("Removing L3VPN to ELAN default Fallback flow in LPortDispatcher table from Dpn {}",
                  del.getNodeId());

        Flow flowToRemove = new FlowBuilder().setFlowName(L3_TO_L2_DEFAULT_FLOW_REF)
                .setId(new FlowId(L3_TO_L2_DEFAULT_FLOW_REF))
                .setTableId(NwConstants.LPORT_DISPATCHER_TABLE).build();
        mdsalMgr.removeFlow(dpnId, flowToRemove);
    }

    @Override
    protected void update(InstanceIdentifier<Node> identifier, Node original, Node update) {
    }

    @Override
    protected void add(InstanceIdentifier<Node> identifier, Node add) {
        BigInteger dpnId = getDpnIdFromNodeId(add.getNodeId());
        if ( dpnId == null ) {
            return;
        }

        LOG.debug("Installing L3VPN to ELAN default Fallback flow in LPortDispatcher table on Dpn {}",
                  add.getNodeId());
        BigInteger[] metadataToMatch = new BigInteger[] {
            MetaDataUtil.getServiceIndexMetaData(ServiceIndex.getIndex(NwConstants.L3VPN_SERVICE_NAME,
                                                                       NwConstants.L3VPN_SERVICE_INDEX)),
            MetaDataUtil.METADATA_MASK_SERVICE_INDEX
        };
        List<MatchInfo> matches = Arrays.asList(new MatchInfo(MatchFieldType.metadata, metadataToMatch));

        BigInteger metadataToWrite =
            MetaDataUtil.getServiceIndexMetaData(ServiceIndex.getIndex(NwConstants.ELAN_SERVICE_NAME,
                                                                       NwConstants.ELAN_SERVICE_INDEX));
        int instructionKey = 0;
        List<Instruction> instructions =
                Arrays.asList(MDSALUtil.buildAndGetWriteMetadaInstruction(metadataToWrite,
                        MetaDataUtil.METADATA_MASK_SERVICE_INDEX,
                        ++instructionKey),
                        MDSALUtil.buildAndGetGotoTableInstruction(NwConstants.L3_INTERFACE_TABLE, ++instructionKey));

        Flow flow = MDSALUtil.buildFlowNew(NwConstants.LPORT_DISPATCHER_TABLE, L3_TO_L2_DEFAULT_FLOW_REF,
                NwConstants.TABLE_MISS_PRIORITY, L3_TO_L2_DEFAULT_FLOW_REF,
                0, 0, CloudServiceChainConstants.COOKIE_L3_BASE,
                matches, instructions);
        mdsalMgr.installFlow(dpnId, flow);
    }


    private BigInteger getDpnIdFromNodeId(NodeId nodeId) {
        String[] node =  nodeId.getValue().split(":");
        if (node.length < 2) {
            LOG.warn("Unexpected nodeId {}", nodeId.getValue());
            return null;
        }
        return new BigInteger(node[1]);
    }
}
