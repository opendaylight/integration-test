/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.AlivenessMonitorListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.AlivenessMonitorService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.LivenessState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.alivenessmonitor.rev160411.MonitorEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This class listens for interface creation/removal/update in Configuration DS.
 * This is used to handle interfaces for base of-ports.
 */
public class ArpMonitorEventListener implements AlivenessMonitorListener {
    private static final Logger LOG = LoggerFactory.getLogger(ArpMonitorEventListener.class);
    private AlivenessMonitorService alivenessManager;
    private DataBroker dataBroker;

    public ArpMonitorEventListener(DataBroker dataBroker, AlivenessMonitorService alivenessManager) {
        this.alivenessManager = alivenessManager;
        this.dataBroker = dataBroker;
    }

    @Override
    public void onMonitorEvent(MonitorEvent notification) {
        Long monitorId = notification.getEventData().getMonitorId();
        MacEntry macEntry = AlivenessMonitorUtils.getMacEntryFromMonitorId(monitorId);
        if(macEntry == null) {
            LOG.debug("No MacEntry found associated with the monitor Id {}", monitorId);
            return;
        }
        LivenessState livenessState = notification.getEventData().getMonitorState();
        if(livenessState.equals(LivenessState.Down)) {
            DataStoreJobCoordinator coordinator = DataStoreJobCoordinator.getInstance();
            coordinator.enqueueJob(ArpMonitoringHandler.buildJobKey(macEntry.getIpAddress().getHostAddress(),
                    macEntry.getVpnName()),
                    new ArpMonitorStopTask(macEntry, dataBroker, alivenessManager));
        }
    }

}