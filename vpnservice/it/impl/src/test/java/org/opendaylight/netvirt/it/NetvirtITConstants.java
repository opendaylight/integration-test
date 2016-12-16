/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.EthertypeV4;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.EthertypeV6;
/**
 * Constants for NetvirtIT.
 */

public final class NetvirtITConstants {
    private NetvirtITConstants() {
    }

    public static final String ORG_OPS4J_PAX_LOGGING_CFG = "etc/org.ops4j.pax.logging.cfg";
    public static final String CUSTOM_PROPERTIES = "etc/custom.properties";
    public static final String SERVER_IPADDRESS = "ovsdbserver.ipaddress";
    public static final String SERVER_PORT = "ovsdbserver.port";
    public static final String CONTROLLER_IPADDRESS = "ovsdb.controller.address";
    public static final String USERSPACE_ENABLED = "ovsdb.userspace.enabled";
    public static final String SERVER_EXTRAS = "ovsdbserver.extras";
    public static final String CONNECTION_TYPE = "ovsdbserver.connection";
    public static final String CONNECTION_TYPE_ACTIVE = "active";
    public static final String CONNECTION_TYPE_PASSIVE = "passive";
    public static final int CONNECTION_INIT_TIMEOUT = 10000;
    public static final String DEFAULT_SERVER_IPADDRESS = "127.0.0.1";
    public static final String DEFAULT_SERVER_PORT = "6640";
    public static final String DEFAULT_OPENFLOW_PORT = "6653";
    public static final String DEFAULT_SERVER_EXTRAS = "false";
    public static final String BRIDGE_NAME = "brtest";
    public static final String PORT_NAME = "porttest";
    public static final String INTEGRATION_BRIDGE_NAME = "br-int";
    public static final String OPENFLOW_CONNECTION_PROTOCOL = "tcp";
    public static final int GATEWAY_SUFFIX = 254;
    public static final int IPV6_GATEWAY_SUFFIX = 1;

    public static final String IPV6_SLAAC_SUBNET_PREFIX = "/64";
    public static final Class<EthertypeV4> ETHER_TYPE_V4 = EthertypeV4.class;
    public static final Class<EthertypeV6> ETHER_TYPE_V6 = EthertypeV6.class;
    public static final String PROTOCOL_ICMP = "icmp";
    public static final String PROTOCOL_TCP = "tcp";
    public static final String PROTOCOL_UDP = "udp";
    public static final String PROTOCOL_ICMPV6 = "icmpv6";
    public static final String PREFIX_ALL_NETWORK = "0.0.0.0/0";
    public static final String PREFIX_ALL_IPV6_NETWORK = "::/0";

    public static final int IPV4 = 4;
    public static final int IPV6 = 6;

    public enum DefaultFlow {
        DHCP_EXTERNAL_TUNNEL("DHCPTableMissFlowForExternalTunnel", NwConstants.DHCP_TABLE_EXTERNAL_TUNNEL),
        DHCP("DHCPTableMissFlow", NwConstants.DHCP_TABLE),
        IPV6("IPv6TableMissFlow", NwConstants.IPV6_TABLE);

        String flowId;
        short tableId;

        DefaultFlow(String flowId, short tableId) {
            this.flowId = flowId;
            this.tableId = tableId;
        }

        public String getFlowId() {
            return flowId;
        }

        public short getTableId() {
            return tableId;
        }
    }


}
