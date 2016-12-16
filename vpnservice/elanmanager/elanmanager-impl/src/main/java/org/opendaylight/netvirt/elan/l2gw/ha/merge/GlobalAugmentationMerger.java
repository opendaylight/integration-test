/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.merge;


import org.opendaylight.netvirt.elan.l2gw.ha.commands.LocalMcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.LocalUcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.LogicalSwitchesCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.RemoteMcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.RemoteUcastCmd;
import org.opendaylight.netvirt.elan.l2gw.ha.commands.SwitchesCmd;

public class GlobalAugmentationMerger
        extends MergeCommandsAggregator {

    private GlobalAugmentationMerger() {
        commands.add(new RemoteMcastCmd());
        commands.add(new RemoteUcastCmd());
        commands.add(new LocalUcastCmd());
        commands.add(new LocalMcastCmd());
        commands.add(new LogicalSwitchesCmd());
        commands.add(new SwitchesCmd());
    }

    static GlobalAugmentationMerger instance = new GlobalAugmentationMerger();

    public static GlobalAugmentationMerger getInstance() {
        return instance;
    }
}
