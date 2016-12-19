/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.netvirt.dhcpservice.jobs.DhcpInterfaceConfigRemoveJob;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpInterfaceConfigListener
        extends AsyncDataTreeChangeListenerBase<Interface, DhcpInterfaceConfigListener>
        implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpInterfaceConfigListener.class);

    private final DataBroker dataBroker;
    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;
    private DataStoreJobCoordinator dataStoreJobCoordinator;

    public DhcpInterfaceConfigListener(DataBroker dataBroker, DhcpExternalTunnelManager dhcpExternalTunnelManager) {
        super(Interface.class, DhcpInterfaceConfigListener.class);
        this.dataBroker = dataBroker;
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
        dataStoreJobCoordinator = DataStoreJobCoordinator.getInstance();
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.info("DhcpInterfaceConfigListener Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<Interface> identifier, Interface del) {
        DhcpInterfaceConfigRemoveJob job = new DhcpInterfaceConfigRemoveJob(dhcpExternalTunnelManager, dataBroker, del);
        dataStoreJobCoordinator.enqueueJob(DhcpServiceUtils.getJobKey(del.getName()), job, DhcpMConstants.RETRY_COUNT );
    }

    @Override
    protected void update(InstanceIdentifier<Interface> identifier, Interface original, Interface update) {
        // Handled in update () DhcpInterfaceEventListener
    }

    @Override
    protected void add(InstanceIdentifier<Interface> identifier, Interface add) {
    }

    @Override
    protected InstanceIdentifier<Interface> getWildCardPath() {
        return InstanceIdentifier.create(Interfaces.class).child(Interface.class);
    }

    @Override
    protected DhcpInterfaceConfigListener getDataTreeChangeListener() {
        return DhcpInterfaceConfigListener.this;
    }
}
