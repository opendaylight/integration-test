/*
 * Copyright (c) 2016 Hewlett-Packard Enterprise and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.utilities;

import org.opendaylight.infrautils.counters.api.OccurenceCounter;

public enum VpnManagerCounters {

    garp_add_notification,
    garp_update_notification,
    garp_sent,
    garp_sent_ipv6,
    garp_sent_failed,
	garp_interface_rpc_failed;

    private OccurenceCounter counter;

    private VpnManagerCounters() {
        counter = new OccurenceCounter(getClass().getSimpleName(), name(), name());
    }

    /*
     * increament counter value
     */
    public void inc() {
        counter.inc();
    }

}
