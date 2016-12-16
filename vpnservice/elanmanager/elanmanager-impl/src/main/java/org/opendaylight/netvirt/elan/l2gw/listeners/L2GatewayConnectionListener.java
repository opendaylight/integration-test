/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.listeners;

import org.opendaylight.controller.md.sal.binding.api.ClusteredDataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataChangeListenerBase;
import org.opendaylight.netvirt.elan.l2gw.utils.L2GatewayConnectionUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.L2gatewayConnections;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.l2gatewayconnections.L2gatewayConnection;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class L2GatewayConnectionListener extends AsyncClusteredDataChangeListenerBase<L2gatewayConnection,
        L2GatewayConnectionListener> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(L2GatewayConnectionListener.class);

    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker broker;
    private final L2GatewayConnectionUtils l2GatewayConnectionUtils;

    public L2GatewayConnectionListener(final DataBroker db,
                                       ElanUtils elanUtils) {
        super(L2gatewayConnection.class, L2GatewayConnectionListener.class);
        broker = db;
        this.l2GatewayConnectionUtils = elanUtils.getL2GatewayConnectionUtils();
        registerListener(db);
    }

    @Override
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void close() throws Exception {
        // TODO use https://git.opendaylight.org/gerrit/#/c/44145/ when merged, and remove @SuppressWarnings
        if (listenerRegistration != null) {
            try {
                listenerRegistration.close();
            } catch (final Exception e) {
                LOG.error("Error when cleaning up DataChangeListener.", e);
            }
            listenerRegistration = null;
        }
        LOG.info("L2 Gateway Connection listener Closed");
    }

    private void registerListener(final DataBroker db) {
        listenerRegistration = db.registerDataChangeListener(
                LogicalDatastoreType.CONFIGURATION, InstanceIdentifier.create(Neutron.class)
                        .child(L2gatewayConnections.class).child(L2gatewayConnection.class),
                L2GatewayConnectionListener.this, DataChangeScope.SUBTREE);
    }

    @Override
    protected void add(final InstanceIdentifier<L2gatewayConnection> identifier, final L2gatewayConnection input) {
        LOG.trace("Adding L2gatewayConnection: {}", input);

        // Get associated L2GwId from 'input'
        // Create logical switch in each of the L2GwDevices part of L2Gw
        // Logical switch name is network UUID
        // Add L2GwDevices to ELAN
        l2GatewayConnectionUtils.addL2GatewayConnection(input);
    }

    @Override
    protected void remove(InstanceIdentifier<L2gatewayConnection> identifier, L2gatewayConnection input) {
        LOG.trace("Removing L2gatewayConnection: {}", input);

        l2GatewayConnectionUtils.deleteL2GatewayConnection(input);
    }

    @Override
    protected void update(InstanceIdentifier<L2gatewayConnection> identifier, L2gatewayConnection original,
            L2gatewayConnection update) {
        LOG.trace("Updating L2gatewayConnection : original value={}, updated value={}", original, update);
    }

    @Override
    protected InstanceIdentifier<L2gatewayConnection> getWildCardPath() {
        return InstanceIdentifier.create(L2gatewayConnection.class);
    }

    @Override
    protected ClusteredDataChangeListener getDataChangeListener() {
        return L2GatewayConnectionListener.this;
    }

    @Override
    protected DataChangeScope getDataChangeScope() {
        return DataChangeScope.BASE;
    }
}
