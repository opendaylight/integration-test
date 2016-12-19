/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.utils.netvirt.it.utils;

import org.junit.Assert;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronSecurityGroup;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.DockerOvs;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;

import java.io.IOException;

/**
 * This class adds the ability to issue pings from one port to another to its base class, NeutronNetItUtil.
 * Please see NetvirtIT#testNeutronNet for an example of how this class is used
 * N.B. At this point this class only supports DockerOvs runs where the docker-compose file runs a single
 * docker container with OVS. A little work will need to be invested to extend this functionality to support
 * configuring "ping-ability" on multiple docker containers.
 */
public class PingableNeutronNetItUtil extends NeutronNetItUtil {

    private static final int DEFAULT_WAIT = 30 * 1000;
    private DockerOvs dockerOvs;
    private final Boolean isUserSpace;

    public PingableNeutronNetItUtil(DockerOvs dockerOvs, SouthboundUtils southboundUtils, String tenantId,
                                    Boolean isUserSpace) {
        super(southboundUtils, tenantId);
        this.dockerOvs = dockerOvs;
        this.isUserSpace = isUserSpace;
    }

    public PingableNeutronNetItUtil(DockerOvs dockerOvs, SouthboundUtils southboundUtils, String tenantId,
                                    String segId, String macPfx, String ipPfx, String cidr, Boolean isUserSpace) {
        super(southboundUtils, tenantId, segId, macPfx, ipPfx, cidr);
        this.dockerOvs = dockerOvs;
        this.isUserSpace = isUserSpace;
    }

    /**
     * Create a port on the network. The deviceOwner will be set to "compute:None".
     * @param bridge bridge where the port will be created on OVS
     * @param portName name for this port
     * @param owner deviceOwner, e.g., "network:dhcp"
     * @param secGroups Optional NeutronSecurityGroup objects see NeutronUtils.createNeutronSecurityGroup()
     * @throws InterruptedException if we're interrupted while waiting for objects to be created
     */
    public void createPort(Node bridge, String portName, String owner, NeutronSecurityGroup... secGroups)
            throws InterruptedException, IOException {
        if (dockerOvs.usingExternalDocker()) {
            super.createPort(bridge, portName, owner, secGroups);
            return;
        }

        PortInfo portInfo = buildPortInfo(portName);

        if (isUserSpace) {
            dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "tuntap", "add", portInfo.name, "mode", "tap");
            dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "link", "set", "dev",
                    portInfo.name, "address", portInfo.mac);

            doCreatePort(bridge, portInfo, owner, "tap", secGroups);
        } else {
            doCreatePort(bridge, portInfo, owner, "internal", secGroups);
            dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "link", "set", "dev",
                    portInfo.name, "address", portInfo.mac);
        }
    }

    /**
     * This method must be run on a port before calling ping() or pingIp()
     * @param portName The name of the port used when it was created using createPort()
     * @throws IOException if an IO error occurs with one of the spawned procs
     * @throws InterruptedException because we sleep
     */
    public void preparePortForPing(String portName) throws IOException, InterruptedException {
        if (dockerOvs.usingExternalDocker()) {
            return;
        }

        String nsName = "ns-" + portName;

        PortInfo portInfo = portInfoByName.get(portName);
        Assert.assertNotNull(portInfo);
        dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "netns", "add", nsName);
        dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "link", "set", portName, "netns", nsName);
        dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "netns", "exec", nsName, "ip", "addr",
                "add", "dev", portName, portInfo.ip + "/24");
        dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "netns", "exec", nsName, "ip", "link",
                "set", "dev", "lo", "up");
        dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "netns", "exec", nsName, "ip", "link",
                "set", "dev", portName, "up");
        dockerOvs.runInContainer(DEFAULT_WAIT, 0, "ip", "netns", "exec", nsName, "ip", "route",
                "add", "default", "via", portInfo.ip);
    }

    /**
     * Ping from one port to the other
     * @param fromPort name of the port to ping from. This is the name you used for createPort.
     * @param toPort name of the port to ping to. This is the name you used for createPort.
     * @throws IOException if an IO error occurs with one of the spawned procs
     * @throws InterruptedException because we sleep
     */
    public void ping(String fromPort, String toPort) throws IOException, InterruptedException {
        if (dockerOvs.usingExternalDocker()) {
            return;
        }

        PortInfo portInfo = portInfoByName.get(toPort);
        Assert.assertNotNull(portInfo);
        pingIp(fromPort, portInfo.ip);
    }

    /**
     * Ping from one port to an IP address
     * @param fromPort name of the port to ping from. This is the name you used for createPort.
     * @param ip The IP address to ping
     * @throws IOException if an IO error occurs with one of the spawned procs
     * @throws InterruptedException because we sleep
     */
    public void pingIp(String fromPort, String ip) throws IOException, InterruptedException {
        if (dockerOvs.usingExternalDocker()) {
            return;
        }

        String fromNs = "ns-" + fromPort;
        dockerOvs.runInContainer(0, DEFAULT_WAIT, 0, "ip", "netns", "exec", fromNs, "ping", "-c", "4", ip);
    }
}
