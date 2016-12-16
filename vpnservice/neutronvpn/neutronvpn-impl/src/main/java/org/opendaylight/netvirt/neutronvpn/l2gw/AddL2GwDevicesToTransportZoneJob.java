/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.l2gw;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentMap;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZone;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * The Class AddL2GwDevicesToTransportZoneJob.
 */
public class AddL2GwDevicesToTransportZoneJob implements Callable<List<ListenableFuture<Void>>> {

    /** The Constant LOG. */
    private static final Logger LOG = LoggerFactory.getLogger(AddL2GwDevicesToTransportZoneJob.class);

    /** The data broker. */
    private DataBroker dataBroker;

    /** The itm rpc service. */
    private ItmRpcService itmRpcService;

    /** The transport zone. */
    private TransportZone transportZone;

    /**
     * Instantiates a new adds the l2 gw devices to transport zone job.
     *
     * @param dataBroker the data broker
     * @param itmRpcService the itm rpc service
     * @param transportZone the transport zone
     */
    public AddL2GwDevicesToTransportZoneJob(DataBroker dataBroker, ItmRpcService itmRpcService,
                                            TransportZone transportZone) {
        this.dataBroker = dataBroker;
        this.itmRpcService = itmRpcService;
        this.transportZone = transportZone;
        LOG.debug("created AddL2GwDevicesToTransportZone Job for tZone {}", transportZone.getZoneName());
    }

    /**
     * Gets the job key.
     *
     * @return the job key
     */
    public String getJobKey() {
        return "L2GW" + this.transportZone.getZoneName();
    }

    /*
     * (non-Javadoc)
     *
     * @see java.util.concurrent.Callable#call()
     */
    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        LOG.debug("Running AddL2GwDevicesToTransportZone job for {}", this.transportZone.getZoneName());
        try {
            // When vxlan transport zone is added, add all l2gw devices to that
            // transport zone. Doesn't matter if tz already has data or not.
            ConcurrentMap<String, L2GatewayDevice> l2GwDevices = L2GatewayCacheUtils.getCache();
            for (L2GatewayDevice l2gwDevice : l2GwDevices.values()) {
                if (!l2gwDevice.getL2GatewayIds().isEmpty()) {
                    LOG.debug("Adding l2gw device [{}] to transport zone [{}]", l2gwDevice.getDeviceName(),
                            this.transportZone.getZoneName());
                    L2GatewayUtils.createItmTunnels(itmRpcService, l2gwDevice.getHwvtepNodeId(),
                            l2gwDevice.getDeviceName(), l2gwDevice.getTunnelIp());
                }
            }
        } catch (Exception e) {
            LOG.error("Failed during AddL2GwDevicesToTransportZone job ", e);
        }
        return Collections.emptyList();
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Object#toString()
     */
    @Override
    public String toString() {
        return "AddL2GwDevicesToTransportZoneJob [transportZone=" + transportZone.getZoneName() + "]";
    }
}
