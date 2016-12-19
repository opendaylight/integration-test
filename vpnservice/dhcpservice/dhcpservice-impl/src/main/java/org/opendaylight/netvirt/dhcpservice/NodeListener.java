/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice;

import java.math.BigInteger;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NodeListener extends AsyncDataTreeChangeListenerBase<Node, NodeListener> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(NodeListener.class);

    private final DataBroker broker;
    private final DhcpManager dhcpManager;
    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;

    public NodeListener(final DataBroker db, final DhcpManager dhcpMgr,
            final DhcpExternalTunnelManager dhcpExternalTunnelManager) {
        super(Node.class, NodeListener.class);
        this.broker = db;
        this.dhcpManager = dhcpMgr;
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
    }

    public void init() {
        registerListener(LogicalDatastoreType.OPERATIONAL, broker);
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node del) {
        NodeId nodeId = del.getId();
        BigInteger dpnId = MDSALUtil.getDpnIdFromNodeName(nodeId);
        List<BigInteger> listOfDpns = DhcpServiceUtils.getListOfDpns(broker);
        dhcpExternalTunnelManager.handleDesignatedDpnDown(dpnId, listOfDpns);
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
        dhcpManager.setupTableMissForDhcpTable(dpId);
        dhcpExternalTunnelManager.installDhcpDropActionOnDpn(dpId);
        List<BigInteger> listOfDpns = DhcpServiceUtils.getListOfDpns(broker);
        dhcpExternalTunnelManager.handleDesignatedDpnDown(DhcpMConstants.INVALID_DPID, listOfDpns);
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.debug("Node Listener Closed");
    }

    @Override
    protected InstanceIdentifier<Node> getWildCardPath() {
        return InstanceIdentifier.create(Nodes.class).child(Node.class);
    }

    @Override
    protected NodeListener getDataTreeChangeListener() {
        return NodeListener.this;
    }
}