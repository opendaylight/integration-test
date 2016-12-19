/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.natservice.internal;
import java.math.BigInteger;

import org.opendaylight.genius.mdsalutil.packet.Ethernet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketReceived;


public class NAPTEntryEvent {
    private String ipAddress;
    private int portNumber;
    private Long routerId;
    private Operation op;
    private Protocol protocol;
    private PacketReceived packetReceived;
    private boolean pktProcessed;

    public PacketReceived getPacketReceived() {
        return packetReceived;
    }

    public boolean isPktProcessed() {
        return pktProcessed;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public int getPortNumber() {
        return portNumber;
    }

    public Long getRouterId() {
        return routerId;
    }

    public Operation getOperation() {
        return op;
    }

    public Protocol getProtocol() {
        return protocol;
    }

    NAPTEntryEvent(String ipAddress, int portNumber, Long routerId, Operation op, Protocol protocol, PacketReceived packetReceived, boolean pktProcessed){
        this.ipAddress = ipAddress;
        this.portNumber = portNumber;
        this.routerId = routerId;
        this.op = op;
        this.protocol = protocol;
        this.packetReceived = packetReceived;
        this.pktProcessed = pktProcessed;
    }

    public enum Operation{
        ADD, DELETE
    }

    public enum Protocol{
        TCP, UDP
    }
}
