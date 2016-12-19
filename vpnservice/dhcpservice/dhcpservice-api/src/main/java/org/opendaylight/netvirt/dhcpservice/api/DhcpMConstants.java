/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice.api;

import java.math.BigInteger;

public final class DhcpMConstants {

    public static final long DHCP_TABLE_MAX_ENTRY = 10000;

    public static final int DEFAULT_DHCP_FLOW_PRIORITY = 50;
    public static final int ARP_FLOW_PRIORITY = 50;
    public static final short DEFAULT_FLOW_PRIORITY = 100;

    public static final BigInteger COOKIE_DHCP_BASE = new BigInteger("6800000", 16);
    public static final BigInteger METADATA_ALL_CLEAR_MASK = new BigInteger("0000000000000000", 16);
    public static final BigInteger METADATA_ALL_SET_MASK = new BigInteger("FFFFFFFFFFFFFFFF", 16);

    public static final String FLOWID_PREFIX = "DHCP.";
    public static final String VMFLOWID_PREFIX = "DHCP.INTERFACE.";
    public static final String BCAST_DEST_IP = "255.255.255.255";
    public static final int BCAST_IP = 0xffffffff;

    public static final short DHCP_CLIENT_PORT = 68;
    public static final short DHCP_SERVER_PORT = 67;

    public static final int DEFAULT_LEASE_TIME = 86400;
    public static final String DEFAULT_DOMAIN_NAME = "openstacklocal";

    public static final BigInteger COOKIE_VM_INGRESS_TABLE = new BigInteger("6800001", 16);
    public static final BigInteger INVALID_DPID = new BigInteger("-1");
    public static final String DHCP_JOB_KEY_PREFIX = "DHCP_";
    public static final int RETRY_COUNT = 6;
}
