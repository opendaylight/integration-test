/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.l2gw;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.TransportZones;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZone;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The listener class for ITM transport zone updates.
 */
public class L2GwTransportZoneListener
        extends AsyncDataTreeChangeListenerBase<TransportZone, L2GwTransportZoneListener>
        implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(L2GwTransportZoneListener.class);
    private final DataBroker dataBroker;
    private final ItmRpcService itmRpcService;

    /**
     * Instantiates a new l2 gw transport zone listener.
     *
     * @param dataBroker the data broker
     * @param itmRpcService the itm rpc service
     */
    public L2GwTransportZoneListener(DataBroker dataBroker, ItmRpcService itmRpcService) {
        super(TransportZone.class, L2GwTransportZoneListener.class);
        this.dataBroker = dataBroker;
        this.itmRpcService = itmRpcService;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.opendaylight.vpnservice.datastoreutils.
     * AsyncDataTreeChangeListenerBase#getWildCardPath()
     */
    @Override
    protected InstanceIdentifier<TransportZone> getWildCardPath() {
        return InstanceIdentifier.create(TransportZones.class).child(TransportZone.class);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.opendaylight.vpnservice.datastoreutils.
     * AsyncDataTreeChangeListenerBase#remove(org.opendaylight.yangtools.yang.
     * binding.InstanceIdentifier,
     * org.opendaylight.yangtools.yang.binding.DataObject)
     */
    @Override
    protected void remove(InstanceIdentifier<TransportZone> key, TransportZone dataObjectModification) {
        // do nothing
    }

    /*
     * (non-Javadoc)
     *
     * @see org.opendaylight.vpnservice.datastoreutils.
     * AsyncDataTreeChangeListenerBase#update(org.opendaylight.yangtools.yang.
     * binding.InstanceIdentifier,
     * org.opendaylight.yangtools.yang.binding.DataObject,
     * org.opendaylight.yangtools.yang.binding.DataObject)
     */
    @Override
    protected void update(InstanceIdentifier<TransportZone> key, TransportZone dataObjectModificationBefore,
                          TransportZone dataObjectModificationAfter) {
        // do nothing
    }

    /*
     * (non-Javadoc)
     *
     * @see org.opendaylight.vpnservice.datastoreutils.
     * AsyncDataTreeChangeListenerBase#add(org.opendaylight.yangtools.yang.
     * binding.InstanceIdentifier,
     * org.opendaylight.yangtools.yang.binding.DataObject)
     */
    @Override
    protected void add(InstanceIdentifier<TransportZone> key, TransportZone tzNew) {
        LOG.trace("Received Transport Zone Add Event: {}", tzNew);
        if (tzNew.getTunnelType().equals(TunnelTypeVxlan.class)) {
            DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
            AddL2GwDevicesToTransportZoneJob job =
                    new AddL2GwDevicesToTransportZoneJob(dataBroker, itmRpcService, tzNew);
            coordinator.enqueueJob(job.getJobKey(), job);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.opendaylight.vpnservice.datastoreutils.
     * AsyncDataTreeChangeListenerBase#getDataTreeChangeListener()
     */
    @Override
    protected L2GwTransportZoneListener getDataTreeChangeListener() {
        return this;
    }
}
