/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.cloudservicechain;

import java.math.BigInteger;


public class CloudServiceChainConstants {
    public static final BigInteger COOKIE_SCF_BASE = new BigInteger("7000000", 16);
    public static final BigInteger COOKIE_LPORT_DISPATCHER_BASE = new BigInteger("6000000", 16);
    public static final BigInteger METADATA_MASK_SCF_WRITE = new BigInteger("000000FF00000000", 16);
    public static final BigInteger COOKIE_L3_BASE = new BigInteger("8000000", 16);
    public static final int DEFAULT_LPORT_DISPATCHER_FLOW_PRIORITY = 1;
    public static final int DEFAULT_SCF_FLOW_PRIORITY = 20;
    public static final String FLOWID_PREFIX_SCF = "SCF.";
    public static final String FLOWID_PREFIX_L3 = "L3.";

    public static final short SCF_SERVICE_INDEX = 1;
    public static final short ELAN_SERVICE_INDEX = 3;
    public static final short LPORT_DISPATCHER_TABLE = 17;
    public static final short ELAN_SMAC_TABLE = 50;
    public static final short FIB_TABLE = 21;
    public static final short SCF_UP_SUB_FILTER_TCP_BASED_TABLE = 70;
    public static final short SCF_DOWN_SUB_FILTER_TCP_BASED_TABLE = 72;
    public static final short SCF_CHAIN_FWD_TABLE = 75;
    public static final String FLOWID_PREFIX = "L3.";
    public static final String L2_FLOWID_PREFIX = "L2.";
    public static final String VPN_PSEUDO_PORT_FLOWID_PREFIX = "VpnPseudoPort.";
    public static final String VPN_PSEUDO_VPN2SCF_FLOWID_PREFIX = "VpnPseudoPort.Vpn2Scf";
    public static final String VPN_PSEUDO_VPN2VPN_FLOWID_PREFIX = "VpnPseudoPort.Vpn2Vpn";
    public static final String VPN_PSEUDO_SCF2VPN_FLOWID_PREFIX = "VpnPseudoPort.Scf2Vpn";
    public static final String ELAN_TO_SCF_L2_FLOWID_PREFIX = "ElanPseudoPort.Elan2Scf";
    public static final String SCF_TO_ELAN_L2_FLOWID_PREFIX = "ElanPseudoPort.Scf2Elan";
    public static final long INVALID_VPN_TAG = -1;

}
