/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import java.util.Collection;
import java.util.HashMap;
import java.util.Random;
import java.util.UUID;

public class PortInfo {
    public String id;
    public String name;
    private HashMap<String, PortIp> fixedIpList;
    public String mac;
    public long ofPort;
    public String macPfx = "f4:00:00:0f:00:";
    private NeutronPort neutronPort;
    protected int ovsInstance;
    private static Ipv6Utils ipv6Utils;

    PortInfo(int ovsInstance, long ofPort) {
        this.ovsInstance = ovsInstance;
        this.ofPort = ofPort;
        this.mac = macFor(ofPort);
        this.id = UUID.randomUUID().toString();
        this.name = "tap" + id.substring(0, 11);
        this.fixedIpList = new HashMap<String, PortIp>();
        ipv6Utils = new Ipv6Utils();
    }

    public void setNeutronPort(NeutronPort neutronPort) {
        this.neutronPort = neutronPort;
    }

    public NeutronPort getNeutronPort() {
        return neutronPort;
    }

    public PortIp allocateFixedIp(int ipVersion, String ipPfx, String subnetId) {
        PortIp portIp = fixedIpList.get(ipPfx);
        if (portIp == null) {
            portIp = new PortIp(ipVersion, ipPfx, subnetId);
            fixedIpList.put(ipPfx, portIp);
        }

        if (NetvirtITConstants.IPV4 == ipVersion) {
            portIp.setFixedIp(ipFor(ipPfx, ofPort));
        } else {
            portIp.setFixedIp(ipv6Utils.getIpv6AddressUsingEui64(ipPfx, mac));
        }
        return portIp;
    }

    public Collection<PortIp> getPortFixedIps() {
        return fixedIpList.values();
    }

    /**
     * Get the mac address for the n'th port created on this network (starts at 1).
     *
     * @param portNum index of port created
     * @return the mac address
     */
    public String macFor(long portNum) {
        //for router interface use a random number, because we could have multiple interfaces with the same "portNum".
        if (portNum == NetvirtITConstants.GATEWAY_SUFFIX) {
            Random rn = new Random(System.currentTimeMillis());
            portNum = rn.nextInt(10) + 100;
        }
        return macPfx + String.format("%02x", portNum);
    }

    /**
     * Get the ip address for the n'th port created on this network (starts at 1).
     *
     * @param portNum index of port created
     * @return the mac address
     */
    public String ipFor(String ipPfx, long portNum) {
        return ipPfx + portNum;
    }

    @Override
    public String toString() {
        return "PortInfo [name=" + name
                + ", ofPort=" + ofPort
                + ", id=" + id
                + ", mac=" + mac
                + ", fixedIpList=" + fixedIpList
                + "]";
    }

    public class PortIp {
        private int ipVersion;
        private String ipPfx;
        private String ip;
        private String subnetId;

        PortIp(int ipVersion, String ipPfx, String subnetId) {
            this.ipVersion = ipVersion;
            this.ipPfx = ipPfx;
            this.subnetId = subnetId;
        }

        public void setFixedIp(String fixedIp) {
            this.ip = fixedIp;
        }

        public int getIpVersion() {
            return ipVersion;
        }

        public String getIpAddress() {
            return ip;
        }

        public String getIpPrefix() {
            return ipPfx;
        }

        public String getSubnetId() {
            return subnetId;
        }

        @Override
        public String toString() {
            return "PortIp [ipVersion=" + ipVersion
                    + ", ipPfx=" + ipPfx
                    + ", ip=" + ip
                    + ", subnetId=" + subnetId
                    + "]";
        }
    }
}
