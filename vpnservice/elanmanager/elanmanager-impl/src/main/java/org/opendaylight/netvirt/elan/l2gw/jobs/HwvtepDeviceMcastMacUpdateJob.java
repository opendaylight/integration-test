/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.jobs;

import com.google.common.collect.Lists;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.netvirt.elan.l2gw.utils.ElanL2GatewayMulticastUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HwvtepDeviceMcastMacUpdateJob implements Callable<List<ListenableFuture<Void>>> {
    private static final Logger LOG = LoggerFactory.getLogger(HwvtepDeviceMcastMacUpdateJob.class);

    private final ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils;
    private final String elanName;
    private final L2GatewayDevice l2GatewayDevice;

    public HwvtepDeviceMcastMacUpdateJob(ElanL2GatewayMulticastUtils elanL2GatewayMulticastUtils, String elanName,
                                         L2GatewayDevice l2GatewayDevice) {
        this.elanL2GatewayMulticastUtils = elanL2GatewayMulticastUtils;
        this.l2GatewayDevice = l2GatewayDevice;
        this.elanName = elanName;
    }

    public String getJobKey() {
        return elanName;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        LOG.info("running update mcast mac entry job for {} {}",
                elanName, l2GatewayDevice.getHwvtepNodeId());
        return Lists.newArrayList(
                elanL2GatewayMulticastUtils.updateRemoteMcastMacOnElanL2GwDevice(elanName, l2GatewayDevice));
    }

}
