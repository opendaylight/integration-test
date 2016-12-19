/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service.utils;

import java.math.BigInteger;

public class Ipv6Constants {

    public static final int IP_V6_ETHTYPE = 34525;
    public static final int ICMP_V6 = 1;

    public static final int ETHTYPE_START = 96;
    public static final int ONE_BYTE  = 8;
    public static final int TWO_BYTES = 16;
    public static final int IP_V6_HDR_START = 112;
    public static final int IP_V6_NEXT_HDR = 48;
    public static final int ICMPV6_HDR_START = 432;

    public static final int ICMPV6_RA_LENGTH_WO_OPTIONS = 16;
    public static final int ICMPV6_OPTION_SOURCE_LLA_LENGTH = 8;
    public static final int ICMPV6_OPTION_PREFIX_LENGTH = 32;

    public static final int IPV6_DEFAULT_HOP_LIMIT = 64;
    public static final int IPV6_ROUTER_LIFETIME = 4500;
    public static final int IPV6_RA_VALID_LIFETIME = 2592000;
    public static final int IPV6_RA_PREFERRED_LIFETIME = 604800;

    public static final int ICMP_V6_TYPE = 58;
    public static final short ICMP_V6_RS_CODE = 133;
    public static final short ICMP_V6_RA_CODE = 134;
    public static final short ICMP_V6_NS_CODE = 135;
    public static final short ICMP_V6_NA_CODE = 136;
    public static final short ICMP_V6_MAX_HOP_LIMIT = 255;
    public static final int ICMPV6_OFFSET = 54;

    public static final String DHCPV6_OFF = "DHCPV6_OFF";
    public static final String IPV6_SLAAC = "IPV6_SLAAC";
    public static final String IPV6_DHCPV6_STATEFUL = "DHCPV6_STATEFUL";
    public static final String IPV6_DHCPV6_STATELESS = "DHCPV6_STATELESS";
    public static final String IPV6_AUTO_ADDRESS_SUBNETS = IPV6_SLAAC + IPV6_DHCPV6_STATELESS;

    public static final String IP_VERSION_V4 = "IPv4";
    public static final String IP_VERSION_V6 = "IPv6";
    public static final String NETWORK_ROUTER_INTERFACE = "network:router_interface";

    public static final BigInteger INVALID_DPID = new BigInteger("-1");
    public static final short DEFAULT_FLOW_PRIORITY = 50;
    public static final String FLOWID_PREFIX = "IPv6.";
    public static final String FLOWID_SEPARATOR = ".";

    public static final int ADD_FLOW = 0;
    public static final int DEL_FLOW = 1;
    public static final int ADD_ENTRY = 0;
    public static final int DEL_ENTRY = 1;
    public static final int FLOWS_CONFIGURED = 1;
    public static final int FLOWS_NOT_CONFIGURED = 0;
    public static final String OPENFLOW_NODE_PREFIX = "openflow:";
    public static final short IPV6_VERSION = 6;
    public static final short ICMP6_NHEADER = 58;
    public static final long DEF_FLOWLABEL = 0;
    public static final String DEF_MCAST_MAC = "33:33:00:00:00:01";
    //default periodic RA transmission interval. timeunit in sec
    public static final long PERIODIC_RA_INTERVAL = 60;

    public enum Ipv6RtrAdvertType {
        UNSOLICITED_ADVERTISEMENT,
        SOLICITED_ADVERTISEMENT,
        CEASE_ADVERTISEMENT;
    }


    private Ipv6Constants() {
    }

}
