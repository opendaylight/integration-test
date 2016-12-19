/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.listeners;

import org.opendaylight.controller.md.sal.binding.api.ClusteredDataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncClusteredDataChangeListenerBase;
import org.opendaylight.netvirt.cloudservicechain.utils.VpnPseudoPortCache;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.VpnToPseudoPortList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.vpn.to.pseudo.port.list.VpnToPseudoPortData;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Listens to changes in the Vpn to VpnPseudoPort relationship with the only
 * purpose of updating the VpnPseudoPorts caches in all blades.
 *
 */
public class VpnPseudoPortListener
    extends AsyncClusteredDataChangeListenerBase<VpnToPseudoPortData, VpnPseudoPortListener>
    implements AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(VpnPseudoPortListener.class);
    private final DataBroker dataBroker;

    public VpnPseudoPortListener(final DataBroker dataBroker) {
        super(VpnToPseudoPortData.class, VpnPseudoPortListener.class);
        this.dataBroker = dataBroker;
    }

    public void init() {
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected void remove(InstanceIdentifier<VpnToPseudoPortData> identifier, VpnToPseudoPortData del) {
        LOG.trace("Reacting to VpnToPseudoPortData removal: iid={}", identifier);
        VpnPseudoPortCache.removeVpnPseudoPortFromCache(del.getVrfId());
    }

    @Override
    protected void update(InstanceIdentifier<VpnToPseudoPortData> identifier, VpnToPseudoPortData original,
                          VpnToPseudoPortData update) {
        VpnPseudoPortCache.addVpnPseudoPortToCache(update.getVrfId(), update.getVpnLportTag());
    }

    @Override
    protected void add(InstanceIdentifier<VpnToPseudoPortData> identifier, VpnToPseudoPortData add) {
        LOG.trace("Reacting to VpnToPseudoPortData creation:  vrf={}  vpnPseudoLportTag={}  scfTag={}  scfTable={}.",
                  add.getVrfId(), add.getVpnLportTag(), add.getScfTag(), add.getScfTableId());
        VpnPseudoPortCache.addVpnPseudoPortToCache(add.getVrfId(), add.getVpnLportTag());
    }

    @Override
    protected InstanceIdentifier<VpnToPseudoPortData> getWildCardPath() {
        return InstanceIdentifier.builder(VpnToPseudoPortList.class).child(VpnToPseudoPortData.class).build();
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
