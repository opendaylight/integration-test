/*
 * Copyright (c) 2016 Hewlett-Packard Enterprise and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice;

import org.opendaylight.infrautils.counters.api.OccurenceCounter;

public enum DhcpServiceCounters {
    install_dhcp_drop_flow, //
    install_dhcp_flow, //
    install_dhcp_table_miss_flow, //
    install_dhcp_table_miss_flow_for_external_table, //
    remove_dhcp_drop_flow, //
    remove_dhcp_flow;

    private OccurenceCounter counter;

    DhcpServiceCounters() {
        counter = new OccurenceCounter(getClass().getSimpleName(), name(), name());
    }

    public void inc() {
        counter.inc();
    }
}
