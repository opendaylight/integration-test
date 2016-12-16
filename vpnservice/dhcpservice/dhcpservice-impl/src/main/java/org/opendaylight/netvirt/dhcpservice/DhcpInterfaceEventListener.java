/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
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
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.netvirt.dhcpservice.jobs.DhcpInterfaceAddJob;
import org.opendaylight.netvirt.dhcpservice.jobs.DhcpInterfaceRemoveJob;
import org.opendaylight.netvirt.dhcpservice.jobs.DhcpInterfaceUpdateJob;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface.OperStatus;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpInterfaceEventListener
        extends AsyncDataTreeChangeListenerBase<Interface, DhcpInterfaceEventListener>
        implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpInterfaceEventListener.class);

    private final DataBroker dataBroker;
    private final DhcpManager dhcpManager;
    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;
    private DataStoreJobCoordinator dataStoreJobCoordinator;
    private final IInterfaceManager interfaceManager;

    public DhcpInterfaceEventListener(DhcpManager dhcpManager, DataBroker dataBroker,
                                      DhcpExternalTunnelManager dhcpExternalTunnelManager,
                                      IInterfaceManager interfaceManager) {
        super(Interface.class, DhcpInterfaceEventListener.class);
        this.dhcpManager = dhcpManager;
        this.dataBroker = dataBroker;
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        this.interfaceManager = interfaceManager;
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
        dataStoreJobCoordinator = DataStoreJobCoordinator.getInstance();
    }

    @Override
    public void close() throws Exception {
        super.close();
        LOG.info("Interface Manager Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<Interface> identifier, Interface del) {
        List<String> ofportIds = del.getLowerLayerIf();
        if (ofportIds == null || ofportIds.isEmpty()) {
            return;
        }
        String interfaceName = del.getName();
        NodeConnectorId nodeConnectorId = new NodeConnectorId(ofportIds.get(0));
        BigInteger dpnId = BigInteger.valueOf(MDSALUtil.getDpnIdFromPortName(nodeConnectorId));
        DhcpInterfaceRemoveJob job = new DhcpInterfaceRemoveJob(dhcpManager, dhcpExternalTunnelManager,
                dataBroker, interfaceName, dpnId, interfaceManager);
        dataStoreJobCoordinator.enqueueJob(DhcpServiceUtils.getJobKey(interfaceName), job, DhcpMConstants.RETRY_COUNT);
    }

    @Override
    protected void update(InstanceIdentifier<Interface> identifier,
            Interface original, Interface update) {
        if (update.getType() == null) {
            LOG.trace("Interface type for interface {} is null", update);
            return;
        }
        if ((original.getOperStatus().getIntValue() ^ update.getOperStatus().getIntValue()) == 0) {
            LOG.trace("Interface operstatus {} is same", update.getOperStatus());
            return;
        }

        if (original.getOperStatus().equals(OperStatus.Unknown) || update.getOperStatus().equals(OperStatus.Unknown)) {
            LOG.trace("New/old interface state is unknown not handling");
            return;
        }

        List<String> ofportIds = update.getLowerLayerIf();
        if (ofportIds == null || ofportIds.isEmpty()) {
            return;
        }
        NodeConnectorId nodeConnectorId = new NodeConnectorId(ofportIds.get(0));
        BigInteger dpnId = BigInteger.valueOf(MDSALUtil.getDpnIdFromPortName(nodeConnectorId));
        String interfaceName = update.getName();
        DhcpInterfaceUpdateJob job = new DhcpInterfaceUpdateJob(dhcpManager, dhcpExternalTunnelManager, dataBroker,
                interfaceName, dpnId, update.getOperStatus(), interfaceManager);
        dataStoreJobCoordinator.enqueueJob(DhcpServiceUtils.getJobKey(interfaceName), job, DhcpMConstants.RETRY_COUNT);
    }

    @Override
    protected void add(InstanceIdentifier<Interface> identifier, Interface add) {
        String interfaceName = add.getName();
        List<String> ofportIds = add.getLowerLayerIf();
        if (ofportIds == null || ofportIds.isEmpty()) {
            return;
        }
        NodeConnectorId nodeConnectorId = new NodeConnectorId(ofportIds.get(0));
        BigInteger dpnId = BigInteger.valueOf(MDSALUtil.getDpnIdFromPortName(nodeConnectorId));
        DhcpInterfaceAddJob job = new DhcpInterfaceAddJob(dhcpManager, dhcpExternalTunnelManager, dataBroker,
                interfaceName, dpnId, interfaceManager);
        dataStoreJobCoordinator.enqueueJob(DhcpServiceUtils.getJobKey(interfaceName), job, DhcpMConstants.RETRY_COUNT);
    }

    @Override
    protected InstanceIdentifier<Interface> getWildCardPath() {
        return InstanceIdentifier.create(InterfacesState.class).child(Interface.class);
    }

    @Override
    protected DhcpInterfaceEventListener getDataTreeChangeListener() {
        return DhcpInterfaceEventListener.this;
    }
}