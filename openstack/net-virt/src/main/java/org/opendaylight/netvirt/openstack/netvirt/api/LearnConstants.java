/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.api;

import java.math.BigInteger;
import java.util.HashMap;

public class LearnConstants {
    public static final String LEARN_MATCH_REG_VALUE = "1";
    public static final int ETHTYPE_IPV4 = 0X0800;
    public static final int ETHTYPE_IPV6 = 0x86dd;
    public static final int IP_PROT_ICMP = 1;
    public static final int IP_PROT_TCP = 6;
    public static final int IP_PROT_UDP = 17;
    public static final String LEARN_PRIORITY = "61010";
    public static final String DELETE_LEARNED_FLAG_VALUE = "2";
    public static final HashMap<Integer, String> ICMP_TYPE_MAP = new HashMap<Integer, String>();
    static
    {
        ICMP_TYPE_MAP.put(8, "0");
        ICMP_TYPE_MAP.put(13, "14");
        ICMP_TYPE_MAP.put(15, "16");
        ICMP_TYPE_MAP.put(17, "18");
    }
    public enum NxmOfFieldType {
        NXM_OF_IN_PORT(0x0000, 0, 2, 16),
        NXM_OF_ETH_DST(0x0000, 1, 6, 48),
        NXM_OF_ETH_SRC(0x0000, 2, 6, 48),
        NXM_NX_TUN_ID(0x001, 16, 8, 64),
        NXM_OF_ETH_TYPE(0x0000, 3, 2, 16),
        NXM_OF_VLAN_TCI(0x0000, 4, 2, 12),
        NXM_OF_IP_TOS(0x0000, 5, 1, 8),
        NXM_OF_IP_PROTO(0x0000, 6, 1, 8),
        NXM_OF_IP_SRC(0x0000, 7, 4, 32),
        NXM_OF_IP_DST(0x0000, 8, 4, 32),
        NXM_OF_TCP_SRC(0x0000, 9, 2, 16),
        NXM_OF_TCP_DST(0x0000, 10, 2, 16),
        NXM_OF_UDP_SRC(0x0000, 11, 2, 16),
        NXM_OF_UDP_DST(0x0000, 12, 2, 16),
        NXM_OF_ICMP_TYPE(0x0000, 13, 1, 8),
        NXM_OF_ICMP_CODE(0x0000, 14, 1, 8),
        NXM_OF_ARP_OP(0x0000, 15, 2, 16),
        NXM_OF_ARP_SPA(0x0000, 16, 4, 16),
        NXM_OF_ARP_TPA(0x0000, 17, 4, 16),
        NXM_NX_REG0(0x0001, 0, 4, -1),
        NXM_NX_REG1(0x0001, 1, 4, -1),
        NXM_NX_REG2(0x0001, 2, 4, -1),
        NXM_NX_REG3(0x0001, 3, 4, -1),
        NXM_NX_REG4(0x0001, 4, 4, -1),
        NXM_NX_REG5(0x0001, 5, 4, -1),
        NXM_NX_REG6(0x0001, 6, 4, -1),
        NXM_NX_REG7(0x0001, 7, 4, -1);

        long hexType;
        long flowModHeaderLen;

        NxmOfFieldType(long vendor, long field, long length, long flowModHeaderLen) {
            hexType = nxmHeader(vendor, field, length);
            this.flowModHeaderLen = flowModHeaderLen;
        }

        private static long nxmHeader(long vendor, long field, long length) {
            return ((vendor) << 16) | ((field) << 9) | (length);
        }

        public String getHexType() {
            return String.valueOf(hexType);
        }

        public String getFlowModHeaderLen() {
            return String.valueOf(flowModHeaderLen);
        }
    }

    public enum LearnFlowModsType {
        MATCH_FROM_FIELD, MATCH_FROM_VALUE, COPY_FROM_FIELD, COPY_FROM_VALUE, OUTPUT_TO_PORT;
    }
}
