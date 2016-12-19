/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.populator.input;


import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;

import java.math.BigInteger;


public class L3vpnInput {
    private String rd;
    private Adjacency nextHop;
    private String nextHopIp;
    private String gatewayMac;
    private Long l3vni;
    private String interfaceName;
    private String vpnName;
    private BigInteger dpnId;

    public String getRd() {
        return rd;
    }

    public Adjacency getNextHop() {
        return nextHop;
    }

    public String getNextHopIp() {
        return nextHopIp;
    }

    public String getGatewayMac() {
        return gatewayMac;
    }

    public Long getL3vni() {
        return l3vni;
    }

    public String getInterfaceName() {
        return interfaceName;
    }

    public String getVpnName() {
        return vpnName;
    }

    public BigInteger getDpnId() {
        return dpnId;
    }

    public L3vpnInput setRd(String rd) {
        this.rd = rd;
        return this;
    }

    public L3vpnInput setNextHop(Adjacency nextHop) {
        this.nextHop = nextHop;
        return this;
    }

    public L3vpnInput setNextHopIp(String nextHopIp) {
        this.nextHopIp = nextHopIp;
        return this;
    }

    public L3vpnInput setGatewayMac(String gatewayMac) {
        this.gatewayMac = gatewayMac;
        return this;
    }

    public L3vpnInput setL3vni(Long l3vni) {
        this.l3vni = l3vni;
        return this;
    }

    public L3vpnInput setInterfaceName(String interfaceName) {
        this.interfaceName = interfaceName;
        return this;
    }

    public L3vpnInput setVpnName(String vpnName) {
        this.vpnName = vpnName;
        return this;
    }

    public L3vpnInput setDpnId(BigInteger dpnId) {
        this.dpnId = dpnId;
        return this;
    }
}
