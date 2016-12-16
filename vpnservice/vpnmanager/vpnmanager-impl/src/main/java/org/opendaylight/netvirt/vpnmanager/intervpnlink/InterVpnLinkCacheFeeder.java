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
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Clustered listener whose only purpose is to keep global (well, per cluster)
 * caches updated.
 */
public class InterVpnLinkCacheFeeder extends AsyncClusteredDataChangeListenerBase<InterVpnLink, InterVpnLinkCacheFeeder>
                                     implements AutoCloseable {

    private ListenerRegistration<DataChangeListener> listenerRegistration;

    private static final Logger logger = LoggerFactory.getLogger(InterVpnLinkCacheFeeder.class);

    public InterVpnLinkCacheFeeder(final DataBroker broker) {
        super(InterVpnLink.class, InterVpnLinkCacheFeeder.class);
        registerListener(broker);
    }

    private void registerListener(final DataBroker db) {
        logger.debug("Registering InterVpnLinkListener");
        try {
            listenerRegistration = db.registerDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                                                                 getWildCardPath(), InterVpnLinkCacheFeeder.this,
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
                logger.error("Error when cleaning up InterVpnLinkListener.", e);
            }
            listenerRegistration = null;
        }
        logger.debug("InterVpnLinkListener Listener Closed");
    }

    @Override
    protected void remove(InstanceIdentifier<InterVpnLink> identifier, InterVpnLink del) {
        InterVpnLinkCache.removeInterVpnLinkFromCache(del);
    }

    @Override
    protected void update(InstanceIdentifier<InterVpnLink> identifier, InterVpnLink original, InterVpnLink update) {
        // TODO Auto-generated method stub
    }

    @Override
    protected void add(InstanceIdentifier<InterVpnLink> identifier, InterVpnLink add) {
        logger.debug("Added interVpnLink {}  with vpn1={} and vpn2={}", add.getName(),
                     add.getFirstEndpoint().getVpnUuid(), add.getSecondEndpoint().getVpnUuid());
        InterVpnLinkCache.addInterVpnLinkToCaches(add);
    }

    @Override
    protected InstanceIdentifier<InterVpnLink> getWildCardPath() {
        return InstanceIdentifier.create(InterVpnLinks.class).child(InterVpnLink.class);
    }

    @Override
    protected ClusteredDataChangeListener getDataChangeListener() {
        return InterVpnLinkCacheFeeder.this;
    }

    @Override
    protected DataChangeScope getDataChangeScope() {
        return AsyncDataBroker.DataChangeScope.BASE;
    }

}
