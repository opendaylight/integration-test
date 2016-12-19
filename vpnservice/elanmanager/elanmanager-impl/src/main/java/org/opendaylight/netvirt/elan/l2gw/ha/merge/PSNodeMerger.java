/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.merge;

import org.opendaylight.netvirt.elan.l2gw.ha.commands.TerminationPointCmd;

public class PSNodeMerger extends MergeCommandsAggregator {

    public PSNodeMerger() {
        commands.add(new TerminationPointCmd());
    }

    static PSNodeMerger instance = new PSNodeMerger();

    public static PSNodeMerger getInstance() {
        return instance;
    }
}
