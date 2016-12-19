/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.oam;


public class BgpConstants {

    public static final String BGP_SPEAKER_HOST_NAME = "vpnservice.bgpspeaker.host.name";
    public static final String BGP_SPEAKER_THRIFT_PORT = "vpnservice.bgpspeaker.thrift.port";
    public static final String DEFAULT_BGP_HOST_NAME = "localhost";
    public static final int DEFAULT_BGP_THRIFT_PORT = 7644;
    public static final int BGP_NOTIFY_CEASE_CODE = 6;
    public static final String QBGP_VTY_PASSWORD = "sdncbgpc";
    public static final String BGP_COUNTER_NBR_PKTS_RX = "BgpNeighborPacketsReceived";
    public static final String BGP_COUNTER_NBR_PKTS_TX = "BgpNeighborPacketsSent";
    public static final String BGP_COUNTER_RD_ROUTE_COUNT = "BgpRdRouteCount";
    public static final String BGP_COUNTER_TOTAL_PFX = "BgpTotalPrefixes";
    public static final String BGP_DEF_LOG_LEVEL = "errors";
    public static final String BGP_DEF_LOG_FILE = "/var/log/bgp_debug.log";
    public static final long DEFAULT_ETH_TAG = 0L;
}
