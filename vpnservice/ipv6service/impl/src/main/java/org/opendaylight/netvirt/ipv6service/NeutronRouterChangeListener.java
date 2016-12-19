/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.ipv6service;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.AbstractDataChangeListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.Router;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronRouterChangeListener extends AbstractDataChangeListener<Router> implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronRouterChangeListener.class);
    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker dataBroker;
    private final IfMgr ifMgr;

    public NeutronRouterChangeListener(final DataBroker dataBroker) {
        super(Router.class);
        this.dataBroker = dataBroker;
        this.ifMgr = IfMgr.getIfMgrInstance();
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        listenerRegistration = dataBroker.registerDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                getWildCardPath(), this, DataChangeScope.SUBTREE);
    }

    private InstanceIdentifier<Router> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(Routers.class).child(Router.class);
    }

    @Override
    protected void add(InstanceIdentifier<Router> identifier, Router input) {
        LOG.debug("Add Router notification handler is invoked...");
        ifMgr.addRouter(input.getUuid(), input.getName(), input.getTenantId(), input.isAdminStateUp());
    }

    @Override
    protected void remove(InstanceIdentifier<Router> identifier, Router input) {
        LOG.debug("Remove Router notification handler is invoked...");
        ifMgr.removeRouter(input.getUuid());
    }

    @Override
    protected void update(InstanceIdentifier<Router> identifier, Router original, Router update) {
        LOG.debug("Update Router notification handler is invoked...");
    }

    @Override
    public void close() throws Exception {
        if (listenerRegistration != null) {
            listenerRegistration.close();
            listenerRegistration = null;
        }
        LOG.info("{} close", getClass().getSimpleName());
    }
}
