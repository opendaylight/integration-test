/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.aclservice.utils;

import java.math.BigInteger;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import org.opendaylight.ovsdb.utils.config.ConfigProperties;

/**
 * The class to have ACL related constants.
 */
public final class AclConstants {

    public static final short INGRESS_ACL_DEFAULT_FLOW_PRIORITY = 1;
    public static final short EGRESS_ACL_DEFAULT_FLOW_PRIORITY = 11;

    public static final Integer PROTO_IPV6_DROP_PRIORITY = 63020;
    public static final Integer PROTO_IPV6_ALLOWED_PRIORITY = 63010;
    public static final Integer PROTO_DHCP_SERVER_MATCH_PRIORITY = 63010;
    public static final Integer PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY = 63010;
    public static final Integer PROTO_ARP_TRAFFIC_MATCH_PRIORITY = 63010;
    public static final Integer PROTO_MATCH_PRIORITY = 61010;
    public static final Integer PREFIX_MATCH_PRIORITY = 61009;
    public static final Integer PROTO_PREFIX_MATCH_PRIORITY = 61008;
    public static final Integer PROTO_PORT_MATCH_PRIORITY = 61007;
    public static final Integer PROTO_PORT_PREFIX_MATCH_PRIORITY = 61007;
    public static final Integer PROTO_MATCH_SYN_ALLOW_PRIORITY = 61005;
    public static final Integer PROTO_MATCH_SYN_ACK_ALLOW_PRIORITY = 61004;
    public static final Integer PROTO_MATCH_SYN_DROP_PRIORITY = 61003;
    public static final Integer PROTO_VM_IP_MAC_MATCH_PRIORITY = 36001;
    public static final Integer CT_STATE_UNTRACKED_PRIORITY = 62030;
    public static final Integer CT_STATE_TRACKED_EXIST_PRIORITY = 62020;
    public static final Integer CT_STATE_TRACKED_NEW_PRIORITY = 62010;
    public static final Integer CT_STATE_NEW_PRIORITY_DROP = 50;
    public static final short DHCP_CLIENT_PORT_IPV4 = 68;
    public static final short DHCP_SERVER_PORT_IPV4 = 67;
    public static final short DHCP_CLIENT_PORT_IPV6 = 546;
    public static final short DHCP_SERVER_PORT_IPV6 = 547;
    public static final BigInteger COOKIE_ACL_BASE = new BigInteger("6900000", 16);

    public static final int TRACKED_EST_CT_STATE = 0x22;
    public static final int TRACKED_REL_CT_STATE = 0x24;
    public static final int TRACKED_NEW_CT_STATE = 0x21;
    public static final int TRACKED_INV_CT_STATE = 0x30;

    public static final int TRACKED_EST_CT_STATE_MASK = 0x37;
    public static final int TRACKED_REL_CT_STATE_MASK = 0x37;
    public static final int TRACKED_NEW_CT_STATE_MASK = 0x21;
    public static final int TRACKED_INV_CT_STATE_MASK = 0x30;

    public static final String IPV4_ALL_NETWORK = "0.0.0.0/0";
    public static final long TCP_FLAG_SYN = 1 << 1;
    public static final long TCP_FLAG_ACK = 1 << 4;
    public static final long TCP_FLAG_SYN_ACK = TCP_FLAG_SYN + TCP_FLAG_ACK;
    public static final int ALL_LAYER4_PORT = 65535;
    public static final int ALL_LAYER4_PORT_MASK = 0x0000;

    public static final int ICMPV6_TYPE_MLD_QUERY = 130;
    public static final int ICMPV6_TYPE_RS = 133;
    public static final int ICMPV6_TYPE_RA = 134;
    public static final int ICMPV6_TYPE_NS = 135;
    public static final int ICMPV6_TYPE_NA = 136;
    public static final int ICMPV6_TYPE_MLD2_REPORT = 143;

    public static final BigInteger METADATA_MASK_LEARN_FLAG = new BigInteger("FFFFFFFFFFFFFFFE", 16);

    public static final String SECURITY_GROUP_TCP_IDLE_TO_KEY = "security-group-tcp-idle-timeout";
    public static final String SECURITY_GROUP_TCP_HARD_TO_KEY = "security-group-tcp-hard-timeout";
    public static final String SECURITY_GROUP_TCP_FIN_IDLE_TO_KEY = "security-group-tcp-fin-idle-timeout";
    public static final String SECURITY_GROUP_TCP_FIN_HARD_TO_KEY = "security-group-tcp-fin-hard-timeout";
    public static final String SECURITY_GROUP_UDP_IDLE_TO_KEY = "security-group-udp-idle-timeout";
    public static final String SECURITY_GROUP_UDP_HARD_TO_KEY = "security-group-udp-hard-timeout";

    public static final String LEARN_MATCH_REG_VALUE = "1";
    public static final String LEARN_DELETE_LEARNED_FLAG_VALUE = "2";

    public static final String ACL_FLOW_PRIORITY_POOL_NAME = "acl.flow.priorities.pool";
    public static final long ACL_FLOW_PRIORITY_POOL_START = 1000L;
    public static final long ACL_FLOW_PRIORITY_POOL_END = 60000L;

    private AclConstants() {
    }

    private static Map<String, Object> globalConf = Collections.synchronizedMap(new HashMap<>());

    public static String getGlobalConf(String key, String defaultValue) {
        String ret = defaultValue;
        String value = (String)globalConf.get(key);
        if (value == null) {
            String propertyStr = ConfigProperties.getProperty(AclConstants.class, key);
            if (propertyStr != null) {
                ret = propertyStr;
            }
            globalConf.put(key, ret);
        }
        return ret;
    }

}
