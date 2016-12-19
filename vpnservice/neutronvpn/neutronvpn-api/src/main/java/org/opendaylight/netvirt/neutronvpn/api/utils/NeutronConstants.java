/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn.api.utils;

public class NeutronConstants {

    public static final String DEVICE_OWNER_GATEWAY_INF = "network:router_gateway";
    public static final String DEVICE_OWNER_ROUTER_INF = "network:router_interface";
    public static final String DEVICE_OWNER_FLOATING_IP = "network:floatingip";
    public static final String VNIC_TYPE_NORMAL = "normal";
    public static final String VIF_TYPE_VHOSTUSER = "vhostuser";
    public static final String VIF_TYPE_UNBOUND = "unbound";
    public static final String VIF_TYPE_BINDING_FAILED = "binding_failed";
    public static final String VIF_TYPE_DISTRIBUTED = "distributed";
    public static final String VIF_TYPE_OVS = "ovs";
    public static final String VIF_TYPE_BRIDGE = "bridge";
    public static final String VIF_TYPE_OTHER = "other";
    public static final String VIF_TYPE_MACVTAP = "macvtap";
    public static final String PREFIX_TAP = "tap";
    public static final String PREFIX_VHOSTUSER = "vhu";
    public static final String RD_IDPOOL_NAME = "RouteDistinguisherPool";
    public static final long RD_IDPOOL_START = 1L;
    public static final String RD_IDPOOL_SIZE = "65535";// 16 bit AS specific part of RD
    public static final String RD_PROPERTY_KEY = "vpnservice.admin.rdvalue";//stored in etc/custom.properties

}
