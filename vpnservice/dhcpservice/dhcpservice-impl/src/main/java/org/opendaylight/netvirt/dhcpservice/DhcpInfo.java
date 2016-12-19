/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice;

import java.util.ArrayList;
import java.util.List;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnet.attributes.HostRoutes;

public class DhcpInfo  {
    private String clientIp;
    private String serverIp;
    private String gatewayIp;
    private String cidr;
    private List<String> dnsServers;
    private List<HostRoutes> hostRoutes;

    public DhcpInfo() {
        //Empty constructor
    }

    protected DhcpInfo setClientIp(String clientIp) {
        this.clientIp = clientIp;
        return this;
    }

    protected DhcpInfo setCidr(String cidr) {
        this.cidr = cidr;
        return this;
    }

    protected DhcpInfo setServerIp(String serverIp) {
        this.serverIp = serverIp;
        return this;
    }

    protected DhcpInfo setGatewayIp(String gwIp) {
        gatewayIp = gwIp;
        return this;
    }

    protected DhcpInfo setHostRoutes(List<HostRoutes> hostRoutes) {
        this.hostRoutes = hostRoutes;
        return this;
    }

    protected DhcpInfo setDnsServers(List<String> dnsServers) {
        this.dnsServers = dnsServers;
        return this;
    }

    protected DhcpInfo setDnsServersIpAddrs(List<IpAddress> dnsServers) {
        for (IpAddress ipAddr: dnsServers) {
            addDnsServer(ipAddr.getIpv4Address().getValue());
        }
        return this;
    }

    protected DhcpInfo addDnsServer(String dnsServerIp) {
        if (dnsServers == null) {
            dnsServers = new ArrayList<>();
        }
        dnsServers.add(dnsServerIp);
        return this;
    }


    protected String getClientIp() {
        return clientIp;
    }

    protected String getCidr() {
        return cidr;
    }

    protected String getServerIp() {
        return serverIp;
    }

    protected String getGatewayIp() {
        return gatewayIp;
    }

    protected List<String> getDnsServers() {
        return dnsServers;
    }

    protected List<HostRoutes> getHostRoutes() {
        return hostRoutes;
    }

}
