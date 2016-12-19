/*
 * Copyright (c) 2015 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service;

import io.netty.util.Timeout;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6Constants;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6PeriodicTimer;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6ServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class VirtualPort  {

    private Uuid      intfUUID;
    private Uuid      networkID;
    private String    macAddress;
    private Boolean   routerIntfFlag;
    private String    dpId;
    private String    deviceOwner;
    private Long      ofPort;
    private Boolean   serviceBindingStatus;
    private HashMap<Uuid, SubnetInfo> snetInfo;
    private Ipv6PeriodicTimer periodicTimer;
    private Timeout periodicTimeout;

    // associated router if any
    private VirtualRouter router = null;

    // TODO:: Need Openflow port

    /**
     * Logger instance.
     */
    static final Logger LOG = LoggerFactory.getLogger(VirtualPort.class);

    public VirtualPort() {
        snetInfo = new HashMap<Uuid, SubnetInfo>();
        serviceBindingStatus = Boolean.FALSE;
    }

    public Uuid getIntfUUID() {
        return intfUUID;
    }

    public VirtualPort setIntfUUID(Uuid intfUUID) {
        this.intfUUID = intfUUID;
        return this;
    }

    public Uuid getNetworkID() {
        return networkID;
    }

    public VirtualPort setNetworkID(Uuid networkID) {
        this.networkID = networkID;
        return this;
    }

    public VirtualPort setSubnetInfo(Uuid snetID, IpAddress fixedIp) {
        SubnetInfo subnetInfo = snetInfo.get(snetID);
        if (subnetInfo == null) {
            subnetInfo = new SubnetInfo(snetID, fixedIp);
            snetInfo.put(snetID, subnetInfo);
        } else {
            subnetInfo.setIpAddr(fixedIp);
        }
        return this;
    }

    public void clearSubnetInfo() {
        snetInfo.clear();
    }

    public void removeSubnetInfo(Uuid snetID) {
        this.snetInfo.remove(snetID);
    }

    public void setSubnet(Uuid snetID, VirtualSubnet subnet) {
        SubnetInfo subnetInfo = snetInfo.get(snetID);
        if (subnetInfo == null) {
            LOG.info("Subnet {} not associated with the virtual port {}",
                snetID, intfUUID);
            return;
        }
        subnetInfo.setSubnet(subnet);
    }

    public List<VirtualSubnet> getSubnets() {
        List<VirtualSubnet> subnetList = new ArrayList<>();
        for (SubnetInfo subnetInfo : snetInfo.values()) {
            if (subnetInfo.getSubnet() != null) {
                subnetList.add(subnetInfo.getSubnet());
            }
        }
        return subnetList;
    }

    public List<IpAddress> getIpAddresses() {
        List<IpAddress> ipAddrList = new ArrayList<>();
        for (SubnetInfo subnetInfo : snetInfo.values()) {
            ipAddrList.add(subnetInfo.getIpAddr());
        }
        return ipAddrList;
    }

    public List<Ipv6Address> getIpv6Addresses() {
        List<Ipv6Address> ipv6AddrList = new ArrayList<>();
        for (SubnetInfo subnetInfo : snetInfo.values()) {
            if (subnetInfo.getIpAddr().getIpv6Address() instanceof Ipv6Address) {
                ipv6AddrList.add(subnetInfo.getIpAddr().getIpv6Address());
            }
        }
        if (deviceOwner.equalsIgnoreCase(Ipv6Constants.NETWORK_ROUTER_INTERFACE)) {
            Ipv6ServiceUtils ipv6Utils = Ipv6ServiceUtils.getInstance();
            Ipv6Address llAddr = ipv6Utils.getIpv6LinkLocalAddressFromMac(new MacAddress(macAddress));
            ipv6AddrList.add(llAddr);
        }
        return ipv6AddrList;
    }

    public List<Ipv6Address> getIpv6AddressesWithoutLLA() {
        List<Ipv6Address> ipv6AddrList = new ArrayList<>();
        for (SubnetInfo subnetInfo : snetInfo.values()) {
            if (subnetInfo.getIpAddr().getIpv6Address() instanceof Ipv6Address) {
                ipv6AddrList.add(subnetInfo.getIpAddr().getIpv6Address());
            }
        }
        return ipv6AddrList;
    }

    public String getMacAddress() {
        return macAddress;
    }

    public VirtualPort setMacAddress(String macAddress) {
        this.macAddress = macAddress;
        return this;
    }

    public Boolean getRouterIntfFlag() {
        return routerIntfFlag;
    }

    public VirtualPort setRouterIntfFlag(Boolean routerIntfFlag) {
        this.routerIntfFlag = routerIntfFlag;
        return this;
    }

    public void setRouter(VirtualRouter rtr) {
        this.router = rtr;
    }

    public VirtualRouter getRouter() {
        return router;
    }

    public VirtualPort setDeviceOwner(String deviceOwner) {
        this.deviceOwner = deviceOwner;
        return this;
    }

    public String getDeviceOwner() {
        return deviceOwner;
    }

    public VirtualPort setDpId(String dpId) {
        this.dpId = dpId;
        return this;
    }

    public String getDpId() {
        return dpId;
    }

    public void setOfPort(Long ofPort) {
        this.ofPort = ofPort;
    }

    public Long getOfPort() {
        return ofPort;
    }

    public void setServiceBindingStatus(Boolean status) {
        this.serviceBindingStatus = status;
    }

    public Boolean getServiceBindingStatus() {
        return serviceBindingStatus;
    }

    public void removeSelf() {
        if (routerIntfFlag == true) {
            if (router != null) {
                router.removeInterface(this);
            }
        }

        for (SubnetInfo subnetInfo: snetInfo.values()) {
            if (subnetInfo.getSubnet() != null) {
                subnetInfo.getSubnet().removeInterface(this);
            }
        }
    }

    @Override
    public String toString() {
        return "VirtualPort[IntfUUid=" + intfUUID + " subnetInfo="
                + snetInfo + " NetworkId=" + networkID + " mac=" + macAddress + " ofPort="
                + ofPort + " routerFlag=" + routerIntfFlag + " dpId=" + dpId + "]";
    }

    public void setPeriodicTimer() {
        periodicTimer = new Ipv6PeriodicTimer(intfUUID);
    }

    public Ipv6PeriodicTimer getPeriodicTimer() {
        return periodicTimer;
    }

    public void setPeriodicTimeout(Timeout timeout) {
        periodicTimeout = timeout;
    }

    public void resetPeriodicTimeout() {
        periodicTimeout = null;
    }

    public Timeout getPeriodicTimeout() {
        return periodicTimeout;
    }

    private class SubnetInfo {
        private Uuid      subnetID;
        private IpAddress ipAddr;
        // associated subnet
        private VirtualSubnet subnet = null;

        SubnetInfo(Uuid subnetId, IpAddress ipAddr) {
            this.subnetID = subnetId;
            this.ipAddr = ipAddr;
        }

        public Uuid getSubnetID() {
            return subnetID;
        }

        public IpAddress getIpAddr() {
            return ipAddr;
        }

        public void setIpAddr(IpAddress ipAddr) {
            this.ipAddr = ipAddr;
        }

        public VirtualSubnet getSubnet() {
            return subnet;
        }

        public void setSubnet(VirtualSubnet subnet) {
            this.subnet = subnet;
        }

        @Override
        public String toString() {
            return "subnetInfot[subnetId=" + subnetID + " ipAddr=" + ipAddr + " ]";
        }
    }
}
