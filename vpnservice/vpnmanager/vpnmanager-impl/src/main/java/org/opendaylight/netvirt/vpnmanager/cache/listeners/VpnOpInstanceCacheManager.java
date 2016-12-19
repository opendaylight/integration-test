/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.cache.listeners;

import org.opendaylight.controller.md.sal.binding.api.ClusteredDataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.vpnmanager.VpnConstants;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataChangeListenerBase;
import org.opendaylight.genius.utils.cache.DataStoreCache;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Listens to changes in the Vpn instance Operational data so that this data can be updated if needed
 *
 */
public class VpnOpInstanceCacheManager
    extends AsyncClusteredDataChangeListenerBase<VpnInstanceOpDataEntry, VpnOpInstanceCacheManager>
    implements AutoCloseable {

    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker dataBroker;

    private static final Logger log = LoggerFactory.getLogger(VpnOpInstanceCacheManager.class);

    public VpnOpInstanceCacheManager(final DataBroker broker) {
        super(VpnInstanceOpDataEntry.class, VpnOpInstanceCacheManager.class);
        this.dataBroker = broker;
    }

    public void start() {
        log.info("{} start", getClass().getSimpleName());
        DataStoreCache.create(VpnConstants.VPN_OP_INSTANCE_CACHE_NAME);
        try {
            listenerRegistration = dataBroker.registerDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                    getWildCardPath(), this,
                    AsyncDataBroker.DataChangeScope.SUBTREE);
        } catch (final Exception e) {
            log.error("VpnOpInstance CacheManager registration failed", e);
        }
    }

    @Override
    public void close() {
        if (listenerRegistration != null) {
            try {
                listenerRegistration.close();
            } catch (final Exception e) {
                log.error("Error when cleaning up VpnOpInstance CacheManager.", e);
            }
            listenerRegistration = null;
        }
        log.trace("VpnOpInstance CacheManager Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<VpnInstanceOpDataEntry> identifier, VpnInstanceOpDataEntry del) {
        DataStoreCache.remove(VpnConstants.VPN_OP_INSTANCE_CACHE_NAME, del.getVrfId());
    }

    @Override
    protected void update(InstanceIdentifier<VpnInstanceOpDataEntry> identifier, VpnInstanceOpDataEntry original,
                          VpnInstanceOpDataEntry update) {
        DataStoreCache.add(VpnConstants.VPN_OP_INSTANCE_CACHE_NAME, update.getVrfId(), update);
    }

    @Override
    protected void add(InstanceIdentifier<VpnInstanceOpDataEntry> identifier, VpnInstanceOpDataEntry add) {
        DataStoreCache.add(VpnConstants.VPN_OP_INSTANCE_CACHE_NAME, add.getVrfId(), add);
    }

    @Override
    protected InstanceIdentifier<VpnInstanceOpDataEntry> getWildCardPath() {
        return InstanceIdentifier.builder(VpnInstanceOpData.class)
                .child(VpnInstanceOpDataEntry.class).build();
    }

    @Override
    protected ClusteredDataChangeListener getDataChangeListener() {
        return this;
    }

    @Override
    protected AsyncDataBroker.DataChangeScope getDataChangeScope() {
        return AsyncDataBroker.DataChangeScope.SUBTREE;
    }



}
