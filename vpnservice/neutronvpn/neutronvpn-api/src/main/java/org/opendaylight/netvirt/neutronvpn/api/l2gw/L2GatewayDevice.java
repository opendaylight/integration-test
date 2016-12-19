/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.api.l2gw;

import com.google.common.base.Function;
import com.google.common.collect.Lists;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.stream.Collectors;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l2gateways.rev150712.l2gateway.attributes.Devices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.global.attributes.LocalUcastMacs;

/**
 * The Class L2GatewayDevice.
 */
public class L2GatewayDevice {

    /** The device name. */
    String deviceName;

    /** The hwvtep node id. */
    String hwvtepNodeId;

    /** The tunnel ips. */
    Set<IpAddress> tunnelIps = new HashSet<>();

    /** The l2 gateway ids. */
    Set<Uuid> l2GatewayIds = new HashSet<>();

    /** The ucast local macs. */
    List<LocalUcastMacs> ucastLocalMacs = Collections.synchronizedList(new ArrayList<>());

    /** the status of this device connectin */
    AtomicBoolean connected = new AtomicBoolean(false);

    /** Connection Id to Devices */
    Map<Uuid,List<Devices>> l2gwConnectionIdToDevices = new HashMap<>();

    /**
     * VTEP device name mentioned with L2 Gateway.
     *
     * @return the device name
     */
    public String getDeviceName() {
        return deviceName;
    }

    /**
     * Sets the device name.
     *
     * @param deviceName
     *            the new device name
     */
    public void setDeviceName(String deviceName) {
        this.deviceName = deviceName;
    }

    /**
     * VTEP Node id for the device mentioned with L2 Gateway.
     *
     * @return the hwvtep node id
     */
    public String getHwvtepNodeId() {
        return hwvtepNodeId;
    }

    /**
     * Sets the hwvtep node id.
     *
     * @param nodeId
     *            the new hwvtep node id
     */
    public void setHwvtepNodeId(String nodeId) {
        this.hwvtepNodeId = nodeId;
    }

    /**
     * Tunnel IP created with in the device mentioned with L2 Gateway.
     *
     * @return the tunnel ips
     */
    public Set<IpAddress> getTunnelIps() {
        return tunnelIps;
    }

    public Map<Uuid, List<Devices>> getL2gwConnectionIdToDevices() {
        return l2gwConnectionIdToDevices;
    }

    public void setL2gwConnectionIdToDevices(Map<Uuid, List<Devices>> l2gwConnectionIdToDevices) {
        this.l2gwConnectionIdToDevices = l2gwConnectionIdToDevices;
    }

    /**
     * Gets the tunnel ip.
     *
     * @return the tunnel ip
     */
    public IpAddress getTunnelIp() {
        if (!tunnelIps.isEmpty()) {
            return tunnelIps.iterator().next();
        }
        return null;
    }

    /**
     * Adds the tunnel ip.
     *
     * @param tunnelIp
     *            the tunnel ip
     */
    public void addTunnelIp(IpAddress tunnelIp) {
        tunnelIps.add(tunnelIp);
    }

    /**
     * UUID representing L2Gateway.
     *
     * @return the l2 gateway ids
     */
    public Set<Uuid> getL2GatewayIds() {
        return l2GatewayIds;
    }

    /**
     * Adds the l2 gateway id.
     *
     * @param l2GatewayId
     *            the l2 gateway id
     */
    public void addL2GatewayId(Uuid l2GatewayId) {
        l2GatewayIds.add(l2GatewayId);
    }

    /**
     * Removes the l2 gateway id.
     *
     * @param l2GatewayId
     *            the l2 gateway id
     */
    public void removeL2GatewayId(Uuid l2GatewayId) {
        l2GatewayIds.remove(l2GatewayId);
    }

    /**
     * Clear hwvtep node data.
     */
    public void clearHwvtepNodeData() {
        tunnelIps.clear();
        hwvtepNodeId = null;
    }

    /**
     * Sets the tunnel ips.
     *
     * @param tunnelIps
     *            the new tunnel ips
     */
    public void setTunnelIps(Set<IpAddress> tunnelIps) {
        this.tunnelIps = tunnelIps;
    }

    /**
     * Gets the ucast local macs.
     *
     * @return the ucast local macs
     */
    public List<LocalUcastMacs> getUcastLocalMacs() {
        return new ArrayList<>(ucastLocalMacs);
    }

    /**
     * Adds the ucast local mac.
     *
     * @param localUcastMacs
     *            the local ucast macs
     */
    public void addUcastLocalMac(LocalUcastMacs localUcastMacs) {
        ucastLocalMacs.add(localUcastMacs);
    }

    /**
     * Removes the ucast local mac.
     *
     * @param localUcastMacs
     *            the local ucast macs
     */
    public void removeUcastLocalMac(LocalUcastMacs localUcastMacs) {
        ucastLocalMacs.remove(localUcastMacs);
    }

    public boolean isConnected() {
        return connected.get();
    }

    public void setConnected(boolean connected) {
        this.connected.set(connected);
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Object#hashCode()
     */
    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((deviceName == null) ? 0 : deviceName.hashCode());
        result = prime * result + ((hwvtepNodeId == null) ? 0 : hwvtepNodeId.hashCode());
        result = prime * result + ((l2GatewayIds == null) ? 0 : l2GatewayIds.hashCode());
        result = prime * result + ((tunnelIps == null) ? 0 : tunnelIps.hashCode());
        result = prime * result + ((ucastLocalMacs == null) ? 0 : ucastLocalMacs.hashCode());
        return result;
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Object#equals(java.lang.Object)
     */
    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        L2GatewayDevice other = (L2GatewayDevice) obj;
        if (deviceName == null) {
            if (other.deviceName != null) {
                return false;
            }
        } else if (!deviceName.equals(other.deviceName)) {
            return false;
        }
        if (hwvtepNodeId == null) {
            if (other.hwvtepNodeId != null) {
                return false;
            }
        } else if (!hwvtepNodeId.equals(other.hwvtepNodeId)) {
            return false;
        }
        if (l2GatewayIds == null) {
            if (other.l2GatewayIds != null) {
                return false;
            }
        } else if (!l2GatewayIds.equals(other.l2GatewayIds)) {
            return false;
        }
        if (tunnelIps == null) {
            if (other.tunnelIps != null) {
                return false;
            }
        } else if (!tunnelIps.equals(other.tunnelIps)) {
            return false;
        }
        if (ucastLocalMacs == null) {
            if (other.ucastLocalMacs != null) {
                return false;
            }
        } else if (!ucastLocalMacs.equals(other.ucastLocalMacs)) {
            return false;
        }
        return true;
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Object#toString()
     */
    @Override
    public String toString() {
        List<String> lstTunnelIps = new ArrayList<>();
        if (this.tunnelIps != null) {
            for (IpAddress ip : this.tunnelIps) {
                lstTunnelIps.add(String.valueOf(ip.getValue()));
            }
        }

        List<String> lstMacs = Lists.transform(this.ucastLocalMacs, new Function<LocalUcastMacs, String>() {
            @Override
            public String apply(LocalUcastMacs localUcastMac) {
                return localUcastMac.getMacEntryKey().getValue();
            }
        });

        StringBuilder builder = new StringBuilder();
        builder.append("L2GatewayDevice [deviceName=").append(deviceName).append(", hwvtepNodeId=").append(hwvtepNodeId)
                .append(", tunnelIps=").append(lstTunnelIps).append(", l2GatewayIds=").append(l2GatewayIds)
                .append(", ucastLocalMacs=").append(lstMacs).append("]");
        return builder.toString();
    }

}
