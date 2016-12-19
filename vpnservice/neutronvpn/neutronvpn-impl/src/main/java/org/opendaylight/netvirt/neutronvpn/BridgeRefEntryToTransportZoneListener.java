/*
 * Copyright (c) 2015 - 2016 HPE and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import org.opendaylight.controller.md.sal.binding.api.ClusteredDataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.BridgeRefInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntry;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BridgeRefEntryToTransportZoneListener extends AsyncDataTreeChangeListenerBase<BridgeRefEntry,
    BridgeRefEntryToTransportZoneListener> implements ClusteredDataTreeChangeListener<BridgeRefEntry>, AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(BridgeRefEntryToTransportZoneListener.class);
    private TransportZoneNotificationUtil ism;
    private DataBroker dbx;

    public BridgeRefEntryToTransportZoneListener(DataBroker dbx, NeutronvpnManager nvManager) {
        super(BridgeRefEntry.class, BridgeRefEntryToTransportZoneListener.class);
        this.dbx = dbx;
        ism = new TransportZoneNotificationUtil(dbx, nvManager);
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        if (ism.isAutoTunnelConfigEnabled()) {
            registerListener(LogicalDatastoreType.OPERATIONAL, dbx);
        }
    }

    @Override
    protected InstanceIdentifier<BridgeRefEntry> getWildCardPath() {
        InstanceIdentifier.InstanceIdentifierBuilder<BridgeRefEntry> bridgeRefEntryInstanceIdentifierBuilder =
                InstanceIdentifier.builder(BridgeRefInfo.class)
                        .child(BridgeRefEntry.class);
        return bridgeRefEntryInstanceIdentifierBuilder.build();
    }


    @Override
    protected void remove(InstanceIdentifier<BridgeRefEntry> identifier, BridgeRefEntry del) {
        // once the TZ is declared it will stay forever
    }

    @Override
    protected void update(InstanceIdentifier<BridgeRefEntry> identifier, BridgeRefEntry original,
            BridgeRefEntry update) {
        LOG.debug("handle BridgeRefEntry update notification {}", update);
        ism.updateTrasportZone(update);
    }

    @Override
    protected void add(InstanceIdentifier<BridgeRefEntry> identifier, BridgeRefEntry add) {
        LOG.debug("handle BridgeRefEntry add notification {}", add);
        ism.updateTrasportZone(add);
    }

    @Override
    protected BridgeRefEntryToTransportZoneListener getDataTreeChangeListener() {
        return BridgeRefEntryToTransportZoneListener.this;
    }

}
