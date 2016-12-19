/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import java.io.IOException;
import java.util.List;
import java.util.regex.Pattern;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.DockerOvs;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DockerNetOvsImpl extends AbstractNetOvs {
    private static final Logger LOG = LoggerFactory.getLogger(DockerNetOvsImpl.class);

    DockerNetOvsImpl(final DockerOvs dockerOvs, final Boolean isUserSpace, final MdsalUtils mdsalUtils,
                     final SouthboundUtils southboundUtils) {
        super(dockerOvs, isUserSpace, mdsalUtils, southboundUtils);
    }

    @Override
    public String createPort(int ovsInstance, Node bridgeNode, String networkName ,List<Uuid> securityGroupList)
            throws InterruptedException, IOException {
        PortInfo portInfo = buildPortInfo(ovsInstance, networkName);

        // userspace requires adding vm port as a special tap port
        // kernel mode uses the port as created by ovs
        if (isUserSpace) {
            dockerOvs.runInContainer(DEFAULT_WAIT, ovsInstance, "ip", "tuntap", "add", portInfo.name, "mode", "tap");
        }

        NeutronPort neutronPort = new NeutronPort(mdsalUtils, getNetworkId(networkName));

        neutronPort.createPort(portInfo, "compute:None", null, true ,securityGroupList);
        // Not sure if tap really matters. ovs 2.4.0 fails anyways because group chaining
        // is only supported in 2.5.0
        if (isUserSpace) {
            addTerminationPoint(portInfo, bridgeNode, "tap");
        } else {
            addTerminationPoint(portInfo, bridgeNode, "internal");
        }
        dockerOvs.runInContainer(DEFAULT_WAIT, ovsInstance,
                "ip", "link", "set", "dev", portInfo.name, "address", portInfo.mac);
        portInfo.setNeutronPort(neutronPort);
        portInfoByName.put(portInfo.name, portInfo);

        return portInfo.name;
    }

    @Override
    public void preparePortForPing(String portName) throws InterruptedException, IOException {
        String nsName = "ns-" + portName;
        PortInfo portInfo = portInfoByName.get(portName);
        dockerOvs.runInContainer(DEFAULT_WAIT, portInfo.ovsInstance, "ip", "netns", "add", nsName);
        dockerOvs.runInContainer(DEFAULT_WAIT, portInfo.ovsInstance, "ip", "link", "set", portName, "netns", nsName);
        dockerOvs.runInContainer(DEFAULT_WAIT, portInfo.ovsInstance, "ip", "netns", "exec", nsName, "ip", "link",
                "set", "dev", portName, "up");

        for (PortInfo.PortIp portIp: portInfo.getPortFixedIps()) {
            if (NetvirtITConstants.IPV4 == portIp.getIpVersion()) {
                dockerOvs.runInContainer(DEFAULT_WAIT, portInfo.ovsInstance, "ip", "netns", "exec", nsName,
                        "ip", "addr", "add", "dev", portName, portIp.getIpAddress() + "/24");
                dockerOvs.runInContainer(DEFAULT_WAIT, portInfo.ovsInstance, "ip", "netns", "exec", nsName, "ip",
                        "route", "add", "default", "via", portIp.getIpPrefix() + NetvirtITConstants.GATEWAY_SUFFIX);
            } else {
                // IPv6 Default route is auto-discovered from the Router Advt.
                dockerOvs.runInContainer(DEFAULT_WAIT, portInfo.ovsInstance, "ip", "netns", "exec",
                        nsName, "ip", "-6", "addr", "add", "dev", portName,
                        portIp.getIpAddress() + NetvirtITConstants.IPV6_SLAAC_SUBNET_PREFIX);
            }
        }
    }

    /**
     * Ping from one port to the other.
     *
     * @param fromPort name of the port to ping from. This is the name you used for createPort.
     * @param toPort   name of the port to ping to. This is the name you used for createPort.
     * @throws IOException          if an IO error occurs with one of the spawned procs
     * @throws InterruptedException because we sleep
     */
    public int ping(String fromPort, String toPort) throws InterruptedException, IOException {
        PortInfo portInfo = portInfoByName.get(toPort);
        for (PortInfo.PortIp portIp: portInfo.getPortFixedIps()) {
            if (NetvirtITConstants.IPV4 == portIp.getIpVersion()) {
                return pingIp(fromPort, portIp.getIpAddress(), NetvirtITConstants.IPV4);
            }
        }
        return -1;
    }

    /**
     * Ping from one port to the other.
     *
     * @param fromPort name of the port to ping from. This is the name you used for createPort.
     * @param toPort   name of the port to ping to. This is the name you used for createPort.
     * @throws IOException          if an IO error occurs with one of the spawned procs
     * @throws InterruptedException because we sleep
     */
    public int ping6(String fromPort, String toPort) throws InterruptedException, IOException {
        PortInfo portInfo = portInfoByName.get(toPort);
        for (PortInfo.PortIp portIp: portInfo.getPortFixedIps()) {
            if (NetvirtITConstants.IPV6 == portIp.getIpVersion()) {
                return pingIp(fromPort, portIp.getIpAddress(), NetvirtITConstants.IPV6);
            }
        }
        return -1;
    }

    /**
     * Ping from one port to an IP address.
     *
     * @param fromPort name of the port to ping from. This is the name you used for createPort.
     * @param ip       The IP address to ping
     * @throws IOException          if an IO error occurs with one of the spawned procs
     * @throws InterruptedException because we sleep
     */
    public int pingIp(String fromPort, String ip, int ipVersion) throws IOException, InterruptedException {
        String fromNs = "ns-" + fromPort;
        int ret;
        PortInfo portInfo = portInfoByName.get(fromPort);
        if (ipVersion == NetvirtITConstants.IPV4) {
            ret = dockerOvs.runInContainer(0, DEFAULT_WAIT, portInfo.ovsInstance,
                    "ip", "netns", "exec", fromNs, "ping", "-c", "4", ip);
        } else {
            ret = dockerOvs.runInContainer(0, DEFAULT_WAIT, portInfo.ovsInstance,
                    "ip", "netns", "exec", fromNs, "ping6", "-c", "4", ip);
        }
        return ret;
    }

    @Override
    public void logState(int dockerInstance, String logText) throws IOException, InterruptedException {
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "link");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "addr");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "route");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "netns", "list");
        PortInfo portInfo = getPortInfoByOvsInstance(dockerInstance);
        if (portInfo != null) {
            String ns = "ns-" + portInfo.name;
            dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "netns", "exec", ns, "ip", "link");
            dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "netns", "exec", ns, "ip", "addr");
            dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "netns", "exec", ns, "ip", "route");
            dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ip", "netns", "exec", ns, "ip", "-6", "route");
        }
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-vsctl", "show");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-vsctl", "list", "Open_vSwitch");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-ofctl", "-OOpenFlow13", "show", "br-int");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-ofctl", "-OOpenFlow13", "dump-flows", "br-int");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-ofctl", "-OOpenFlow13", "dump-groups", "br-int");
        dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-ofctl", "-OOpenFlow13", "dump-group-stats",
                "br-int");
        //dockerOvs.tryInContainer(logText, 5000, dockerInstance, "ovs-appctl", "fdb/show", "br-int");
        //ovs-appctl -t /var/run/openvswitch/ovs-vswitchd.12.ctl fdb/show br-int
    }

    @Override
    public String getInstanceIp(int ovsInstance) throws InterruptedException, IOException {
        StringBuilder capturedStdout = new StringBuilder();
        dockerOvs.runInContainer(0, 5000, capturedStdout, ovsInstance, "ip", "-o", "addr");

        String ip = "";
        for (String line : capturedStdout.toString().split("\\n")) {
            if (line.contains("eth0")) {
                String[] split = line.split("\\s+");
                String[] ipnet = split[3].split(Pattern.quote("/"));
                ip = ipnet[0];
                LOG.info("ovs: {}, split: {}, ipnet: {}, ip: {}", ovsInstance, split, ipnet, ip);
                break;
            }
        }
        return ip;
    }
}
