/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager.intervpnlink;

import org.opendaylight.controller.md.sal.binding.api.ClusteredDataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataChangeListenerBase;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkCache;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinkStates;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Clustered listener whose only purpose is to keep global (well, per cluster)
 * caches updated. Same as InterVpnLinkCacheFeeder but this listens on
 * InterVpnLinkState changes.
 */
public class InterVpnLinkStateCacheFeeder
                extends AsyncClusteredDataChangeListenerBase<InterVpnLinkState, InterVpnLinkStateCacheFeeder>
                implements AutoCloseable {

    private static final Logger logger = LoggerFactory.getLogger(InterVpnLinkStateCacheFeeder.class);

    private ListenerRegistration<DataChangeListener> listenerRegistration;

    public InterVpnLinkStateCacheFeeder(final DataBroker broker) {
        super(InterVpnLinkState.class, InterVpnLinkStateCacheFeeder.class);
        registerListener(broker);
    }

    private void registerListener(final DataBroker db) {
        logger.debug("Registering InterVpnLinkStateListener");
        try {
            listenerRegistration = db.registerDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                                                                 getWildCardPath(), InterVpnLinkStateCacheFeeder.this,
                                                                 AsyncDataBroker.DataChangeScope.SUBTREE);
        } catch (final Exception e) {
            logger.error("NodeListener: DataChange listener registration fail!", e);
            throw new IllegalStateException("NodeListener: registration Listener failed.", e);
        }
    }

    @Override
    public void close() throws Exception {
        if (listenerRegistration != null) {
            try {
                listenerRegistration.close();
            } catch (final Exception e) {
                logger.error("Error when cleaning up InterVpnLinkStateListener.", e);
            }
            listenerRegistration = null;
        }
        logger.debug("InterVpnLinkStateListener Listener Closed");
    }


    @Override
    protected void remove(InstanceIdentifier<InterVpnLinkState> identifier, InterVpnLinkState del) {
        logger.debug("InterVpnLinkState {} has been removed", del.getInterVpnLinkName());
        InterVpnLinkCache.removeInterVpnLinkStateFromCache(del);
    }

    @Override
    protected void update(InstanceIdentifier<InterVpnLinkState> identifier, InterVpnLinkState original,
                          InterVpnLinkState update) {
        logger.debug("InterVpnLinkState {} has been updated", update.getInterVpnLinkName());
        InterVpnLinkCache.addInterVpnLinkStateToCaches(update);
    }

    @Override
    protected void add(InstanceIdentifier<InterVpnLinkState> identifier, InterVpnLinkState add) {
        logger.debug("InterVpnLinkState {} has been added", add.getInterVpnLinkName());
        InterVpnLinkCache.addInterVpnLinkStateToCaches(add);
    }

    @Override
    protected InstanceIdentifier<InterVpnLinkState> getWildCardPath() {
        return InstanceIdentifier.create(InterVpnLinkStates.class).child(InterVpnLinkState.class);
    }

    @Override
    protected ClusteredDataChangeListener getDataChangeListener() {
        return this;
    }

    @Override
    protected DataChangeScope getDataChangeScope() {
        return AsyncDataBroker.DataChangeScope.BASE;
    }

}
