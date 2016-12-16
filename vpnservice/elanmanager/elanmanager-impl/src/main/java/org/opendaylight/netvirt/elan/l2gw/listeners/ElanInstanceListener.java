/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.listeners;

import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.netvirt.elan.l2gw.utils.L2GatewayConnectionUtils;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.connections.attributes.l2gatewayconnections.L2gatewayConnection;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Created by eaksahu on 11/2/2016.
 */
public class ElanInstanceListener extends AsyncDataTreeChangeListenerBase<ElanInstance,
        ElanInstanceListener> implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(ElanInstanceListener.class);

    private final DataBroker broker;
    private final L2GatewayConnectionUtils l2GatewayConnectionUtils;

    public ElanInstanceListener(final DataBroker db, ElanUtils elanUtils) {
        super(ElanInstance.class, ElanInstanceListener.class);
        broker = db;
        this.l2GatewayConnectionUtils = elanUtils.getL2GatewayConnectionUtils();
        registerListener(LogicalDatastoreType.CONFIGURATION, db);
    }

    @Override
    protected void remove(InstanceIdentifier<ElanInstance> identifier, ElanInstance del) {
        LOG.info("Elan instance {} deleted from Operational tree ", del);
        List<L2gatewayConnection> l2gatewayConnections = L2GatewayConnectionUtils.getL2GwConnectionsByElanName(this
                .broker, del.getElanInstanceName());
        if (l2gatewayConnections != null) {
            LOG.info("L2Gatewconnection {} to be deleted as part of Elan Instance deletion {} ", l2gatewayConnections,
                    del);
            for (L2gatewayConnection l2gatewayConnection : l2gatewayConnections) {
                l2GatewayConnectionUtils.deleteL2GatewayConnection(l2gatewayConnection);
            }
            LOG.info("L2Gatewconnection {} delet task submitted Successfully", l2gatewayConnections);
        }

    }

    @Override
    protected void update(InstanceIdentifier<ElanInstance> identifier, ElanInstance original, ElanInstance update) {

    }

    @Override
    protected void add(InstanceIdentifier<ElanInstance> identifier, ElanInstance add) {

    }

    @Override
    protected ElanInstanceListener getDataTreeChangeListener() {
        return ElanInstanceListener.this;
    }

    @Override
    protected InstanceIdentifier<ElanInstance> getWildCardPath() {
        return InstanceIdentifier.create(ElanInstances.class).child(ElanInstance.class);
    }

}
