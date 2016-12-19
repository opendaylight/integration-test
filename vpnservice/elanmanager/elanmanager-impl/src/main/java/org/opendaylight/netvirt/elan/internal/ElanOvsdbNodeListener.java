/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.AbstractDataChangeListener;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.config.rev150710.ElanConfig;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Listen for new OVSDB nodes and then make sure they have the necessary bridges configured.
 */
public class ElanOvsdbNodeListener extends AbstractDataChangeListener<Node> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(ElanOvsdbNodeListener.class);
    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker dataBroker;
    private final ElanBridgeManager bridgeMgr;
    private final IElanService elanProvider;
    private boolean generateIntBridgeMac;

    /**
     * Constructor.
     * @param dataBroker the DataBroker
     * @param elanConfig the elan configuration
     * @param bridgeMgr bridge manager
     * @param elanProvider elan provider
     */
    public ElanOvsdbNodeListener(final DataBroker dataBroker, ElanConfig elanConfig,
                                 final ElanBridgeManager bridgeMgr,
                                 final IElanService elanProvider) {
        super(Node.class);
        this.dataBroker = dataBroker;
        this.generateIntBridgeMac = elanConfig.isIntBridgeGenMac();
        this.bridgeMgr = bridgeMgr;
        this.elanProvider = elanProvider;
    }

    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        listenerRegistration = dataBroker.registerDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                getWildCardPath(), this, AsyncDataBroker.DataChangeScope.SUBTREE);
    }

    private InstanceIdentifier<Node> getWildCardPath() {
        return InstanceIdentifier
                .create(NetworkTopology.class)
                .child(Topology.class, new TopologyKey(SouthboundUtils.OVSDB_TOPOLOGY_ID))
                .child(Node.class);
    }

    @Override
    public void close() throws Exception {
        if (listenerRegistration != null) {
            listenerRegistration.close();
            listenerRegistration = null;
        }
        LOG.info("{} close", getClass().getSimpleName());
    }

    @Override
    protected void remove(InstanceIdentifier<Node> identifier, Node node) {
        elanProvider.deleteExternalElanNetworks(node);
    }

    @Override
    protected void update(InstanceIdentifier<Node> identifier, Node original, Node update) {
        LOG.debug("ElanOvsdbNodeListener.update, updated node detected. original: {} new: {}", original, update);
        // ignore updates where the bridge was deleted
        if (!(bridgeMgr.isBridgeOnOvsdbNode(original, bridgeMgr.getIntegrationBridgeName())
                && !bridgeMgr.isBridgeOnOvsdbNode(update, bridgeMgr.getIntegrationBridgeName()))) {
            doNodeUpdate(update);
        }
        elanProvider.updateExternalElanNetworks(original, update);
    }

    @Override
    protected void add(InstanceIdentifier<Node> identifier, Node node) {
        LOG.debug("ElanOvsdbNodeListener.add, new node detected {}", node);
        doNodeUpdate(node);
        elanProvider.createExternalElanNetworks(node);
    }

    private void doNodeUpdate(Node node) {
        bridgeMgr.processNodePrep(node, generateIntBridgeMac);
    }
}
