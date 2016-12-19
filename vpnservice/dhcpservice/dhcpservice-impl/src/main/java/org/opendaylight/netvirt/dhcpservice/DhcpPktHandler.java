/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.dhcpservice;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigInteger;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.apache.commons.net.util.SubnetUtils;
import org.apache.commons.net.util.SubnetUtils.SubnetInfo;
import org.opendaylight.controller.liblldp.EtherTypes;
import org.opendaylight.controller.liblldp.NetUtils;
import org.opendaylight.controller.liblldp.PacketException;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.packet.Ethernet;
import org.opendaylight.genius.mdsalutil.packet.IEEE8021Q;
import org.opendaylight.genius.mdsalutil.packet.IPProtocols;
import org.opendaylight.genius.mdsalutil.packet.IPv4;
import org.opendaylight.genius.mdsalutil.packet.UDP;
import org.opendaylight.netvirt.dhcpservice.api.DHCP;
import org.opendaylight.netvirt.dhcpservice.api.DHCPConstants;
import org.opendaylight.netvirt.dhcpservice.api.DHCPUtils;
import org.opendaylight.netvirt.dhcpservice.api.DhcpMConstants;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnet.attributes.HostRoutes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketInReason;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketReceived;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.SendToController;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.TransmitPacketInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.dhcpservice.config.rev150710.DhcpserviceConfig;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class DhcpPktHandler implements PacketProcessingListener {

    private static final Logger LOG = LoggerFactory.getLogger(DhcpPktHandler.class);

    private final DhcpManager dhcpMgr;
    private final OdlInterfaceRpcService interfaceManagerRpc;
    private final PacketProcessingService pktService;
    private final DhcpExternalTunnelManager dhcpExternalTunnelManager;
    private final IInterfaceManager interfaceManager;
    private final DhcpserviceConfig config;

    public DhcpPktHandler(final DhcpManager dhcpManager,
                          final DhcpExternalTunnelManager dhcpExternalTunnelManager,
                          final OdlInterfaceRpcService interfaceManagerRpc,
                          final PacketProcessingService pktService,
                          final IInterfaceManager interfaceManager,
                          final DhcpserviceConfig config) {
        this.interfaceManagerRpc = interfaceManagerRpc;
        this.pktService = pktService;
        this.dhcpExternalTunnelManager = dhcpExternalTunnelManager;
        this.dhcpMgr = dhcpManager;
        this.interfaceManager = interfaceManager;
        this.config = config;
    }

    //TODO: Handle this in a separate thread
    @Override
    public void onPacketReceived(PacketReceived packet) {
        if (!config.isControllerDhcpEnabled()) {
            return;
        }
        Class<? extends PacketInReason> pktInReason = packet.getPacketInReason();
        short tableId = packet.getTableId().getValue();
        if ((tableId == NwConstants.DHCP_TABLE || tableId == NwConstants.DHCP_TABLE_EXTERNAL_TUNNEL)
                && isPktInReasonSendtoCtrl(pktInReason)) {
            byte[] inPayload = packet.getPayload();
            Ethernet ethPkt = new Ethernet();
            try {
                ethPkt.deserialize(inPayload, 0, inPayload.length * NetUtils.NumBitsInAByte);
            } catch (PacketException e) {
                LOG.warn("Failed to decode DHCP Packet.", e);
                LOG.trace("Received packet {}", packet);
                return;
            }
            DHCP pktIn;
            pktIn = getDhcpPktIn(ethPkt);
            if (pktIn != null) {
                LOG.trace("DHCPPkt received: {}", pktIn);
                LOG.trace("Received Packet: {}", packet);
                BigInteger metadata = packet.getMatch().getMetadata().getMetadata();
                long portTag = MetaDataUtil.getLportFromMetadata(metadata).intValue();
                String macAddress = DHCPUtils.byteArrayToString(ethPkt.getSourceMACAddress());
                BigInteger tunnelId =
                        packet.getMatch().getTunnel() == null ? null : packet.getMatch().getTunnel().getTunnelId();
                String interfaceName = getInterfaceNameFromTag(portTag);
                InterfaceInfo interfaceInfo =
                        interfaceManager.getInterfaceInfoFromOperationalDataStore(interfaceName);
                if (interfaceInfo == null) {
                    LOG.error("Failed to get interface info for interface name {}", interfaceName);
                    return;
                }
                DHCP replyPkt = handleDhcpPacket(pktIn, interfaceName, macAddress, tunnelId);
                byte[] pktOut = getDhcpPacketOut(replyPkt, ethPkt, interfaceInfo.getMacAddress());
                sendPacketOut(pktOut, interfaceInfo.getDpId(), interfaceName, tunnelId);
            }
        }
    }

    private void sendPacketOut(byte[] pktOut, BigInteger dpnId, String interfaceName, BigInteger tunnelId) {
        List<Action> action = getEgressAction(interfaceName, tunnelId);
        TransmitPacketInput output = MDSALUtil.getPacketOut(action, pktOut, dpnId);
        LOG.trace("Transmitting packet: {}", output);
        this.pktService.transmitPacket(output);
    }

    private DHCP handleDhcpPacket(DHCP dhcpPkt, String interfaceName, String macAddress, BigInteger tunnelId) {
        LOG.trace("DHCP pkt rcvd {}", dhcpPkt);
        byte msgType = dhcpPkt.getMsgType();
        if (msgType == DHCPConstants.MSG_DECLINE) {
            LOG.trace("DHCPDECLINE received");
            return null;
        } else if (msgType == DHCPConstants.MSG_RELEASE) {
            LOG.trace("DHCPRELEASE received");
            return null;
        }
        Port port;
        if (tunnelId != null) {
            port = dhcpExternalTunnelManager.readVniMacToPortCache(tunnelId, macAddress);
        } else {
            port = getNeutronPort(interfaceName);
        }
        Subnet subnet = getNeutronSubnet(port);
        DhcpInfo dhcpInfo = getDhcpInfo(port, subnet);
        LOG.trace("NeutronPort: {} \n NeutronSubnet: {}, dhcpInfo{}", port, subnet, dhcpInfo);
        DHCP reply = null;
        if (dhcpInfo != null) {
            if (msgType == DHCPConstants.MSG_DISCOVER) {
                reply = getReplyToDiscover(dhcpPkt, dhcpInfo);
            } else if (msgType == DHCPConstants.MSG_REQUEST) {
                reply = getReplyToRequest(dhcpPkt, dhcpInfo);
            }
        }

        return reply;
    }

    private DhcpInfo getDhcpInfo(Port port, Subnet subnet) {
        DhcpInfo dhcpInfo = null;
        if (port != null && subnet != null) {
            String clientIp = getIpv4Address(port);
            String serverIp = null;
            if (isIpv4Address(subnet.getGatewayIp())) {
                serverIp = subnet.getGatewayIp().getIpv4Address().getValue();
            }
            if (clientIp != null && serverIp != null) {
                List<IpAddress> dnsServers = subnet.getDnsNameservers();
                dhcpInfo = new DhcpInfo();
                dhcpInfo.setClientIp(clientIp).setServerIp(serverIp)
                        .setCidr(String.valueOf(subnet.getCidr().getValue())).setHostRoutes(subnet.getHostRoutes())
                        .setDnsServersIpAddrs(dnsServers).setGatewayIp(serverIp);
            }
        }
        return dhcpInfo;
    }

    /* TODO:
     * getIpv4Address and isIpv4Address
     * Many other modules use/need similar methods. Should
     * be refactored to a common NeutronUtils module.     *
     */
    private String getIpv4Address(Port port) {

        for (FixedIps fixedIp : port.getFixedIps()) {
            if (isIpv4Address(fixedIp.getIpAddress())) {
                return fixedIp.getIpAddress().getIpv4Address().getValue();
            }
        }
        return null;
    }

    private boolean isIpv4Address(IpAddress ip) {
        return ip.getIpv4Address() != null;
    }

    private Subnet getNeutronSubnet(Port port) {
        return dhcpMgr.getNeutronSubnet(port);
    }

    private Port getNeutronPort(String interfaceName) {
        return dhcpMgr.getNeutronPort(interfaceName);
    }

    private DHCP getDhcpPktIn(Ethernet actualEthernetPacket) {
        Ethernet ethPkt = actualEthernetPacket;
        if (ethPkt.getEtherType() == (short)NwConstants.ETHTYPE_802_1Q) {
            ethPkt = (Ethernet)ethPkt.getPayload();
        }
        // Currently only IPv4 is supported
        if (ethPkt.getPayload() instanceof IPv4) {
            IPv4 ipPkt = (IPv4) ethPkt.getPayload();
            if (ipPkt.getPayload() instanceof UDP) {
                UDP udpPkt = (UDP) ipPkt.getPayload();
                if (udpPkt.getSourcePort() == DhcpMConstants.DHCP_CLIENT_PORT
                        && udpPkt.getDestinationPort() == DhcpMConstants.DHCP_SERVER_PORT) {
                    LOG.trace("Matched DHCP_CLIENT_PORT and DHCP_SERVER_PORT");
                    byte[] rawDhcpPayload = udpPkt.getRawPayload();
                    DHCP reply = new DHCP();
                    try {
                        reply.deserialize(rawDhcpPayload, 0, rawDhcpPayload.length);
                    } catch (PacketException e) {
                        LOG.warn("Failed to deserialize DHCP pkt");
                        LOG.trace("Reason for failure", e);
                        return null;
                    }
                    return reply;
                }
            }
        }
        return null;
    }

    DHCP getReplyToDiscover(DHCP dhcpPkt, DhcpInfo dhcpInfo) {
        DHCP reply = new DHCP();
        reply.setOp(DHCPConstants.BOOTREPLY);
        reply.setHtype(dhcpPkt.getHtype());
        reply.setHlen(dhcpPkt.getHlen());
        reply.setHops((byte) 0);
        reply.setXid(dhcpPkt.getXid());
        reply.setSecs((short) 0);

        reply.setYiaddr(dhcpInfo.getClientIp());
        reply.setSiaddr(dhcpInfo.getServerIp());

        reply.setFlags(dhcpPkt.getFlags());
        reply.setGiaddr(dhcpPkt.getGiaddr());
        reply.setChaddr(dhcpPkt.getChaddr());

        reply.setMsgType(DHCPConstants.MSG_OFFER);
        if (dhcpPkt.containsOption(DHCPConstants.OPT_PARAMETER_REQUEST_LIST)) {
            setParameterListOptions(dhcpPkt, reply, dhcpInfo);
        }
        setCommonOptions(reply, dhcpInfo);
        return reply;
    }

    DHCP getReplyToRequest(DHCP dhcpPkt, DhcpInfo dhcpInfo) {
        boolean sendAck = false;
        byte[] requestedIp = null;
        DHCP reply = new DHCP();
        reply.setOp(DHCPConstants.BOOTREPLY);
        reply.setHtype(dhcpPkt.getHtype());
        reply.setHlen(dhcpPkt.getHlen());
        reply.setHops((byte) 0);
        reply.setXid(dhcpPkt.getXid());
        reply.setSecs((short) 0);

        reply.setFlags(dhcpPkt.getFlags());
        reply.setGiaddr(dhcpPkt.getGiaddr());
        reply.setChaddr(dhcpPkt.getChaddr());
        byte[] allocatedIp = DHCPUtils.strAddrToByteArray(dhcpInfo.getClientIp());
        if (Arrays.equals(allocatedIp, dhcpPkt.getCiaddr())) {
            //This means a renew request
            sendAck = true;
        } else {
            requestedIp = dhcpPkt.getOptionBytes(DHCPConstants.OPT_REQUESTED_ADDRESS);
            sendAck = Arrays.equals(allocatedIp, requestedIp);
        }

        if (sendAck) {
            reply.setCiaddr(dhcpPkt.getCiaddr());
            reply.setYiaddr(dhcpInfo.getClientIp());
            reply.setSiaddr(dhcpInfo.getServerIp());
            reply.setMsgType(DHCPConstants.MSG_ACK);
            if (dhcpPkt.containsOption(DHCPConstants.OPT_PARAMETER_REQUEST_LIST)) {
                setParameterListOptions(dhcpPkt, reply, dhcpInfo);
            }
            setCommonOptions(reply, dhcpInfo);
        } else {
            reply.setMsgType(DHCPConstants.MSG_NAK);
        }
        return reply;
    }

    protected byte[] getDhcpPacketOut(DHCP reply, Ethernet etherPkt, String phyAddrees) {
        if (reply == null) {
            /*
             * DECLINE or RELEASE don't result in reply packet
             */
            return null;
        }
        LOG.trace("Sending DHCP Pkt {}", reply);
        // create UDP pkt
        UDP udpPkt = new UDP();
        byte[] rawPkt;
        try {
            rawPkt = reply.serialize();
        } catch (PacketException e) {
            LOG.warn("Failed to serialize packet", e);
            return null;
        }
        udpPkt.setRawPayload(rawPkt);
        udpPkt.setDestinationPort(DhcpMConstants.DHCP_CLIENT_PORT);
        udpPkt.setSourcePort(DhcpMConstants.DHCP_SERVER_PORT);
        udpPkt.setLength((short) (rawPkt.length + 8));
        //Create IP Pkt
        try {
            rawPkt = udpPkt.serialize();
        } catch (PacketException e) {
            LOG.warn("Failed to serialize packet", e);
            return null;
        }
        short checkSum = 0;
        boolean computeUdpChecksum = true;
        if (computeUdpChecksum) {
            checkSum = computeChecksum(rawPkt, reply.getSiaddr(), NetUtils.intToByteArray4(DhcpMConstants.BCAST_IP));
        }
        udpPkt.setChecksum(checkSum);
        IPv4 ip4Reply = new IPv4();
        ip4Reply.setPayload(udpPkt);
        ip4Reply.setProtocol(IPProtocols.UDP.byteValue());
        ip4Reply.setSourceAddress(reply.getSiaddrAsInetAddr());
        ip4Reply.setDestinationAddress(DhcpMConstants.BCAST_IP);
        ip4Reply.setTotalLength((short) (rawPkt.length + 20));
        ip4Reply.setTtl((byte) 32);
        // create Ethernet Frame
        Ethernet ether = new Ethernet();
        if (etherPkt.getEtherType() == (short)NwConstants.ETHTYPE_802_1Q) {
            IEEE8021Q vlanPacket = (IEEE8021Q) etherPkt.getPayload();
            IEEE8021Q vlanTagged = new IEEE8021Q();
            vlanTagged.setCFI(vlanPacket.getCfi());
            vlanTagged.setPriority(vlanPacket.getPriority());
            vlanTagged.setVlanId(vlanPacket.getVlanId());
            vlanTagged.setPayload(ip4Reply);
            vlanTagged.setEtherType(EtherTypes.IPv4.shortValue());
            ether.setPayload(vlanTagged);
            ether.setEtherType((short) NwConstants.ETHTYPE_802_1Q);
        } else {
            ether.setEtherType(EtherTypes.IPv4.shortValue());
            ether.setPayload(ip4Reply);
        }
        ether.setSourceMACAddress(getServerMacAddress(phyAddrees));
        ether.setDestinationMACAddress(etherPkt.getSourceMACAddress());

        try {
            rawPkt = ether.serialize();
        } catch (PacketException e) {
            LOG.warn("Failed to serialize ethernet reply",e);
            return null;
        }
        return rawPkt;
    }

    private byte[] getServerMacAddress(String phyAddress) {
        // Should we return ControllerMac instead?
        return DHCPUtils.strMacAddrtoByteArray(phyAddress);
    }

    public short computeChecksum(byte[] inData, byte[] srcAddr, byte[] destAddr) {
        int sum = 0;
        int carry = 0;
        int wordData;
        int index;

        for (index = 0; index < inData.length - 1; index = index + 2) {
            // Skip, if the current bytes are checkSum bytes
            wordData = (inData[index] << 8 & 0xFF00) + (inData[index + 1] & 0xFF);
            sum = sum + wordData;
        }

        if (index < inData.length) {
            wordData = (inData[index] << 8 & 0xFF00) + (0 & 0xFF);
            sum = sum + wordData;
        }

        for (index = 0; index < 4; index = index + 2) {
            wordData = (srcAddr[index] << 8 & 0xFF00) + (srcAddr[index + 1] & 0xFF);
            sum = sum + wordData;
        }

        for (index = 0; index < 4; index = index + 2) {
            wordData = (destAddr[index] << 8 & 0xFF00) + (destAddr[index + 1] & 0xFF);
            sum = sum + wordData;
        }
        sum = sum + 17 + inData.length;

        while (sum >> 16 != 0) {
            carry = sum >> 16;
            sum = (sum & 0xFFFF) + carry;
        }
        short checkSum = (short) ~((short) sum & 0xFFFF);
        if (checkSum == 0) {
            checkSum = (short)0xffff;
        }
        return checkSum;
    }

    private void setCommonOptions(DHCP pkt, DhcpInfo dhcpInfo) {
        pkt.setOptionInt(DHCPConstants.OPT_LEASE_TIME, dhcpMgr.getDhcpLeaseTime());
        if (dhcpMgr.getDhcpDefDomain() != null) {
            pkt.setOptionString(DHCPConstants.OPT_DOMAIN_NAME, dhcpMgr.getDhcpDefDomain());
        }
        if (dhcpMgr.getDhcpLeaseTime() > 0) {
            pkt.setOptionInt(DHCPConstants.OPT_REBINDING_TIME, dhcpMgr.getDhcpRebindingTime());
            pkt.setOptionInt(DHCPConstants.OPT_RENEWAL_TIME, dhcpMgr.getDhcpRenewalTime());
        }
        SubnetUtils util = null;
        SubnetInfo info = null;
        util = new SubnetUtils(dhcpInfo.getCidr());
        info = util.getInfo();
        String gwIp = dhcpInfo.getGatewayIp();
        List<String> dnServers = dhcpInfo.getDnsServers();
        try {
            /*
             * setParameterListOptions may have initialized some of these
             * options to maintain order. If we can't fill them, unset to avoid
             * sending wrong information in reply.
             */
            if (gwIp != null) {
                pkt.setOptionInetAddr(DHCPConstants.OPT_SERVER_IDENTIFIER, gwIp);
                pkt.setOptionInetAddr(DHCPConstants.OPT_ROUTERS, gwIp);
            } else {
                pkt.unsetOption(DHCPConstants.OPT_SERVER_IDENTIFIER);
                pkt.unsetOption(DHCPConstants.OPT_ROUTERS);
            }
            if (info != null) {
                pkt.setOptionInetAddr(DHCPConstants.OPT_SUBNET_MASK, info.getNetmask());
                pkt.setOptionInetAddr(DHCPConstants.OPT_BROADCAST_ADDRESS, info.getBroadcastAddress());
            } else {
                pkt.unsetOption(DHCPConstants.OPT_SUBNET_MASK);
                pkt.unsetOption(DHCPConstants.OPT_BROADCAST_ADDRESS);
            }
            if (dnServers != null && dnServers.size() > 0) {
                pkt.setOptionStrAddrs(DHCPConstants.OPT_DOMAIN_NAME_SERVERS, dnServers);
            } else {
                pkt.unsetOption(DHCPConstants.OPT_DOMAIN_NAME_SERVERS);
            }
        } catch (UnknownHostException e) {
            // TODO Auto-generated catch block
            LOG.warn("Failed to set option", e);
        }
    }

    private void setParameterListOptions(DHCP req, DHCP reply, DhcpInfo dhcpInfo) {
        byte[] paramList = req.getOptionBytes(DHCPConstants.OPT_PARAMETER_REQUEST_LIST);
        for (byte element : paramList) {
            switch (element) {
                case DHCPConstants.OPT_SUBNET_MASK:
                case DHCPConstants.OPT_ROUTERS:
                case DHCPConstants.OPT_SERVER_IDENTIFIER:
                case DHCPConstants.OPT_DOMAIN_NAME_SERVERS:
                case DHCPConstants.OPT_BROADCAST_ADDRESS:
                case DHCPConstants.OPT_LEASE_TIME:
                case DHCPConstants.OPT_RENEWAL_TIME:
                case DHCPConstants.OPT_REBINDING_TIME:
                    /* These values will be filled in setCommonOptions
                     * Setting these just to preserve order as
                     * specified in PARAMETER_REQUEST_LIST.
                     */
                    reply.setOptionInt(element, 0);
                    break;
                case DHCPConstants.OPT_DOMAIN_NAME:
                    reply.setOptionString(element, " ");
                    break;
                case DHCPConstants.OPT_CLASSLESS_ROUTE:
                    setOptionClasslessRoute(reply, dhcpInfo);
                    break;
                default:
                    LOG.trace("DHCP Option code {} not supported yet", element);
                    break;
            }
        }
    }

    private void setOptionClasslessRoute(DHCP reply, DhcpInfo dhcpInfo) {
        List<HostRoutes> hostRoutes = dhcpInfo.getHostRoutes();
        if (hostRoutes == null) {
            //we can't set this option, so return
            return;
        }
        ByteArrayOutputStream result = new ByteArrayOutputStream();
        Iterator<HostRoutes> iter = hostRoutes.iterator();
        while (iter.hasNext()) {
            HostRoutes hostRoute = iter.next();
            if (hostRoute.getNexthop().getIpv4Address() == null
                    || hostRoute.getDestination().getIpv4Prefix() == null ) {
                // we only deal with IPv4 addresses
                return;
            }
            String router = hostRoute.getNexthop().getIpv4Address().getValue();
            String dest = hostRoute.getDestination().getIpv4Prefix().getValue();
            try {
                result.write(convertToClasslessRouteOption(dest, router));
            } catch (IOException | NullPointerException e) {
                LOG.trace("Exception {}", e.getMessage());
            }
        }
        if (result.size() > 0) {
            reply.setOptionBytes(DHCPConstants.OPT_CLASSLESS_ROUTE , result.toByteArray());
        }
    }

    protected byte[] convertToClasslessRouteOption(String dest, String router) {
        ByteArrayOutputStream byteArray = new ByteArrayOutputStream();
        if (dest == null || router == null) {
            return null;
        }

        //get prefix
        Short prefix = null;
        String[] parts = dest.split("/");
        if (parts.length < 2) {
            prefix = (short) 0;
        } else {
            prefix = Short.valueOf(parts[1]);
        }

        byteArray.write(prefix.byteValue());
        SubnetUtils util = new SubnetUtils(dest);
        SubnetInfo info = util.getInfo();
        String strNetAddr = info.getNetworkAddress();
        try {
            byte[] netAddr = InetAddress.getByName(strNetAddr).getAddress();
          //Strip any trailing 0s from netAddr
            for (int i = 0; i < netAddr.length;i++) {
                if (netAddr[i] != 0) {
                    byteArray.write(netAddr,i,1);
                }
            }
            byteArray.write(InetAddress.getByName(router).getAddress());
        } catch (IOException e) {
            return null;
        }
        return byteArray.toByteArray();
    }

    private boolean isPktInReasonSendtoCtrl(Class<? extends PacketInReason> pktInReason) {
        return pktInReason == SendToController.class;
    }

    private String getInterfaceNameFromTag(long portTag) {
        String interfaceName = null;
        GetInterfaceFromIfIndexInput input =
                new GetInterfaceFromIfIndexInputBuilder().setIfIndex(new Integer((int)portTag)).build();
        Future<RpcResult<GetInterfaceFromIfIndexOutput>> futureOutput =
                interfaceManagerRpc.getInterfaceFromIfIndex(input);
        try {
            GetInterfaceFromIfIndexOutput output = futureOutput.get().getResult();
            interfaceName = output.getInterfaceName();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error while retrieving the interfaceName from tag using getInterfaceFromIfIndex RPC");
        }
        LOG.trace("Returning interfaceName {} for tag {} form getInterfaceNameFromTag", interfaceName, portTag);
        return interfaceName;
    }

    private List<Action> getEgressAction(String interfaceName, BigInteger tunnelId) {
        List<Action> actions = null;
        try {
            GetEgressActionsForInterfaceInputBuilder egressAction =
                    new GetEgressActionsForInterfaceInputBuilder().setIntfName(interfaceName);
            if (tunnelId != null) {
                egressAction.setTunnelKey(tunnelId.longValue());
            }
            Future<RpcResult<GetEgressActionsForInterfaceOutput>> result =
                    interfaceManagerRpc.getEgressActionsForInterface(egressAction.build());
            RpcResult<GetEgressActionsForInterfaceOutput> rpcResult = result.get();
            if (!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to Get egress actions for interface {} returned with Errors {}",
                        interfaceName, rpcResult.getErrors());
            } else {
                actions = rpcResult.getResult().getAction();
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when egress actions for interface {}", interfaceName, e);
        }
        return actions;
    }
}
