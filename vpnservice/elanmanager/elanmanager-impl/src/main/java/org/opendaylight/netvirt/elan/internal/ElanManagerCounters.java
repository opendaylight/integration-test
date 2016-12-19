/*
 * Copyright (c) 2016 Hewlett-Packard Enterprise and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elan.internal;

import org.opendaylight.infrautils.counters.api.OccurenceCounter;

public enum ElanManagerCounters {
    unknown_smac_pktin_removed_for_retry, //
    unknown_smac_pktin_rcv, //
    unknown_smac_pktin_learned, //
    unknown_smac_pktin_ignored_due_protection, //
    unknown_smac_pktin_removed_for_relearned, //
    unknown_smac_pktin_mac_migration_ignored_due_to_protection; //

    private OccurenceCounter counter;

    ElanManagerCounters() {
        counter = new OccurenceCounter(getClass().getSimpleName(), name(), name());
    }

    public void inc() {
        counter.inc();
    }
}
