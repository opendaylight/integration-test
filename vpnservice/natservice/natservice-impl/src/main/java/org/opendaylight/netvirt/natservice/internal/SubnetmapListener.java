/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.natservice.internal;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class SubnetmapListener extends AsyncDataTreeChangeListenerBase<Subnetmap, SubnetmapListener> {
    private static final Logger LOG = LoggerFactory.getLogger(SubnetmapListener.class);
    private final DataBroker dataBroker;
    private final ExternalNetworkGroupInstaller externalNetworkGroupInstaller;

    public SubnetmapListener(final DataBroker dataBroker, final ExternalNetworkGroupInstaller externalNetworkGroupInstaller) {
        super(Subnetmap.class, SubnetmapListener.class);
        this.dataBroker = dataBroker;
        this.externalNetworkGroupInstaller = externalNetworkGroupInstaller;
    }

    public void init() {
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Subnetmap> getWildCardPath() {
        return InstanceIdentifier.create(Subnetmaps.class).child(Subnetmap.class);
    }

    @Override
    protected void remove(InstanceIdentifier<Subnetmap> identifier, Subnetmap subnetmap) {
        LOG.trace("SubnetmapListener remove subnetmap method - key: " + identifier + ", value" + subnetmap);
        NatServiceCounters.subnetmap_remove.inc();
        externalNetworkGroupInstaller.removeExtNetGroupEntries(subnetmap);
    }

    @Override
    protected void update(InstanceIdentifier<Subnetmap> identifier, Subnetmap subnetmapBefore, Subnetmap subnetmapAfter) {
        LOG.trace("SubnetmapListener update subnetmap method - key: " + identifier + ", original=" + subnetmapBefore + ", update=" + subnetmapAfter);
        NatServiceCounters.subnetmap_update.inc();
        externalNetworkGroupInstaller.installExtNetGroupEntries(subnetmapAfter);
    }

    @Override
    protected void add(InstanceIdentifier<Subnetmap> identifier, Subnetmap subnetmap) {
        LOG.trace("SubnetmapListener add subnetmap method - key: " + identifier + ", value=" + subnetmap);
        NatServiceCounters.subnetmap_add.inc();
        externalNetworkGroupInstaller.installExtNetGroupEntries(subnetmap);
    }

    @Override
    protected SubnetmapListener getDataTreeChangeListener() {
        return this;
    }
}
