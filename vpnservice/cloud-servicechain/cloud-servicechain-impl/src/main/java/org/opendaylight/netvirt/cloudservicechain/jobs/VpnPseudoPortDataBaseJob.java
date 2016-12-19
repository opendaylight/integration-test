/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.jobs;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.List;
import java.util.concurrent.Callable;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;

/**
 * Modifies VpnPseudoPort stateful data. Objects of this class are intended to
 * be used with DataStoreJobCoordinator
 */
public abstract class VpnPseudoPortDataBaseJob implements Callable<List<ListenableFuture<Void>>> {

    protected final DataBroker dataBroker;
    protected final String vpnRd;

    public VpnPseudoPortDataBaseJob(DataBroker dataBroker, String vpnRd) {
        this.dataBroker = dataBroker;
        this.vpnRd = vpnRd;
    }

    public String getDsJobCoordinatorKey() {
        return "VpnPseudoPortDataUpdater." + this.vpnRd;
    }

}
