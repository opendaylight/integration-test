/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.bgpmanager.test;

import java.util.Collection;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataObjectModification;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.binding.api.DataTreeModification;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class MockFibManager extends AbstractMockFibManager<VrfEntry> {

    private int nFibEntries = 0;

    private ListenerRegistration<MockFibManager> listenerRegistration;

    public MockFibManager( final DataBroker db) {
        super() ;
        registerListener(db) ;
    }

    private void registerListener(final DataBroker db) {
        final DataTreeIdentifier<VrfEntry> treeId = new DataTreeIdentifier<>(LogicalDatastoreType.CONFIGURATION, getWildCardPath());
        try {
            listenerRegistration = db.registerDataTreeChangeListener(treeId, MockFibManager.this);
        } catch (final Exception e) {
            throw new IllegalStateException("FibManager registration Listener fail! System needs restart.", e);
        }
    }

    private InstanceIdentifier<VrfEntry> getWildCardPath() {
        return InstanceIdentifier.create(FibEntries.class).child(VrfTables.class).child(VrfEntry.class);
    }

    @Override
    public void onDataTreeChanged(Collection<DataTreeModification<VrfEntry>> changes) {
        for (DataTreeModification<VrfEntry> change : changes) {
            final InstanceIdentifier<VrfEntry> key = change.getRootPath().getRootIdentifier();
            final DataObjectModification<VrfEntry> mod = change.getRootNode();

            switch (mod.getModificationType()) {
                case DELETE:
                    nFibEntries -= 1;
                    break;
                case WRITE:
                    if (mod.getDataBefore() == null) {
                        nFibEntries += 1;
                    } else {
                        // UPDATE COUNT UNCHANGED
                    }
                    break;
                default:
                    throw new IllegalArgumentException("Unhandled modification  type " + mod.getModificationType());
            }
        }
    }

    public int getDataChgCount() {
        return nFibEntries;
    }
}
