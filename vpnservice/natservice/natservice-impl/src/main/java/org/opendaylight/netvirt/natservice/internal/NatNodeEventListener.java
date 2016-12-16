/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.natservice.internal;

import java.math.BigInteger;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;

public class NatNodeEventListener extends AsyncDataTreeChangeListenerBase<Node, NatNodeEventListener> implements
        AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NatNodeEventListener.class);
    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker dataBroker;

    public NatNodeEventListener(final DataBroker dataBroker) {
        super(Node.class, NatNodeEventListener.class);
        this.dataBroker = dataBroker;
    }

    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Node> getWildCardPath() {
        return InstanceIdentifier.create(Nodes.class).child(Node.class);
    }

    @Override
    protected NatNodeEventListener getDataTreeChangeListener() {
        return NatNodeEventListener.this;
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node del) {
        LOG.debug("NAT Service : NatNodeEventListener: Node removed received");
        NodeId nodeId = del.getId();
        String[] node =  nodeId.getValue().split(":");
        if(node.length < 2) {
            LOG.warn("NAT Service : Unexpected nodeId {}", nodeId.getValue());
            return;
        }
        BigInteger dpnId = new BigInteger(node[1]);
        LOG.debug("NAT Service : NodeId removed is {}",dpnId);
    }

    @Override
    protected void update(InstanceIdentifier<Node> identifier, Node original, Node update) {
    }

    @Override
    protected void add(InstanceIdentifier<Node> identifier, Node add) {
        LOG.debug("NAT Service : NatNodeEventListener: Node added received");
        NodeId nodeId = add.getId();
        String[] node =  nodeId.getValue().split(":");
        if(node.length < 2) {
            LOG.warn("NAT Service : Unexpected nodeId {}", nodeId.getValue());
            return;
        }
        BigInteger dpnId = new BigInteger(node[1]);
        LOG.debug("NAT Service : NodeId added is {}",dpnId);
    }
}
