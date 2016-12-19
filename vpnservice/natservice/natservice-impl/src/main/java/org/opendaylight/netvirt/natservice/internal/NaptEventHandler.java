/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.natservice.internal;

import java.math.BigInteger;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.opendaylight.controller.liblldp.NetUtils;
import org.opendaylight.controller.liblldp.PacketException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.mdsalutil.packet.Ethernet;
import org.opendaylight.genius.mdsalutil.packet.IPProtocols;
import org.opendaylight.genius.mdsalutil.packet.IPv4;
import org.opendaylight.genius.mdsalutil.packet.TCP;
import org.opendaylight.genius.mdsalutil.packet.UDP;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.IfL2vlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.TransmitPacketInput;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NaptEventHandler {
    private static final Logger LOG = LoggerFactory.getLogger(NaptEventHandler.class);
    private final DataBroker dataBroker;
    private static IMdsalApiManager mdsalManager;
    private final PacketProcessingService pktService;
    private final OdlInterfaceRpcService interfaceManagerRpc;
    private final NaptManager naptManager;
    private IInterfaceManager interfaceManager;

    public NaptEventHandler(final DataBroker dataBroker, final IMdsalApiManager mdsalManager,
                            final NaptManager naptManager,
                            final PacketProcessingService pktService,
                            final OdlInterfaceRpcService interfaceManagerRpc,
                            final IInterfaceManager interfaceManager) {
        this.dataBroker = dataBroker;
        NaptEventHandler.mdsalManager = mdsalManager;
        this.naptManager = naptManager;
        this.pktService = pktService;
        this.interfaceManagerRpc = interfaceManagerRpc;
        this.interfaceManager = interfaceManager;
    }

    public void handleEvent(NAPTEntryEvent naptEntryEvent){
    /*
            Flow programming logic of the OUTBOUND NAPT TABLE :
            1) Get the internal IP address, port number, router ID from the event.
            2) Use the NAPT service getExternalAddressMapping() to get the External IP and the port.
            3) Build the flow for replacing the Internal IP and port with the External IP and port.
              a) Write the matching criteria.
              b) Match the router ID in the metadata.
              d) Write the VPN ID to the metadata.
              e) Write the other data.
              f) Set the apply actions instruction with the action setfield.
            4) Write the flow to the OUTBOUND NAPT Table and forward to FIB table for routing the traffic.

            Flow programming logic of the INBOUND NAPT TABLE :
            Same as Outbound table logic except that :
            1) Build the flow for replacing the External IP and port with the Internal IP and port.
            2) Match the VPN ID in the metadata.
            3) Write the router ID to the metadata.
            5) Write the flow to the INBOUND NAPT Table and forward to FIB table for routing the traffic.
    */
        try {
        Long routerId = naptEntryEvent.getRouterId();
        LOG.info("NAT Service : handleEvent() entry for IP {}, port {}, routerID {}", naptEntryEvent.getIpAddress(), naptEntryEvent.getPortNumber(), routerId);

        //Get the DPN ID
        BigInteger dpnId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
        long bgpVpnId = NatConstants.INVALID_ID;
        if(dpnId == null ){
            LOG.warn("NAT Service : dpnId is null. Assuming the router ID {} as the BGP VPN ID and proceeding....", routerId);
            bgpVpnId = routerId;
            LOG.debug("NAT Service : BGP VPN ID {}", bgpVpnId);
            String vpnName = NatUtil.getRouterName(dataBroker, bgpVpnId);
            String routerName = NatUtil.getRouterIdfromVpnInstance(dataBroker, vpnName);
            if (routerName == null) {
                LOG.error("NAT Service: Unable to find router for VpnName {}", vpnName);
                return;
            }
            routerId = NatUtil.getVpnId(dataBroker, routerName);
            LOG.debug("NAT Service : Router ID {}", routerId);
            dpnId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
            if(dpnId == null){
                LOG.error("NAT Service : dpnId is null for the router {}", routerId);
                return;
            }
        }
        if(naptEntryEvent.getOperation() == NAPTEntryEvent.Operation.ADD) {
            LOG.debug("NAT Service : Inside Add operation of NaptEventHandler");

            //Get the external network ID from the ExternalRouter model
            Uuid networkId = NatUtil.getNetworkIdFromRouterId(dataBroker, routerId);
            if(networkId == null ){
                LOG.error("NAT Service : networkId is null");
                return;
            }

            //Get the VPN ID from the ExternalNetworks model
            Uuid vpnUuid = NatUtil.getVpnIdfromNetworkId(dataBroker, networkId);
            if(vpnUuid == null ){
                LOG.error("NAT Service : vpnUuid is null");
                return;
            }
            Long vpnId = NatUtil.getVpnId(dataBroker, vpnUuid.getValue());

            //Get the internal IpAddress, internal port number from the event
            String internalIpAddress = naptEntryEvent.getIpAddress();
            int internalPort = naptEntryEvent.getPortNumber();
            SessionAddress internalAddress = new SessionAddress(internalIpAddress, internalPort);
            NAPTEntryEvent.Protocol protocol = naptEntryEvent.getProtocol();

            //Get the external IP address for the corresponding internal IP address
            SessionAddress externalAddress = naptManager.getExternalAddressMapping(routerId, internalAddress, naptEntryEvent.getProtocol());
            if(externalAddress == null ){
                if(externalAddress == null){
                    LOG.error("NAT Service : externalAddress is null");
                    return;
                }
            }
            //Build and install the NAPT translation flows in the Outbound and Inbound NAPT tables
            if(!naptEntryEvent.isPktProcessed()) {
                buildAndInstallNatFlows(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, vpnId, routerId, bgpVpnId, internalAddress, externalAddress, protocol);
                buildAndInstallNatFlows(dpnId, NwConstants.INBOUND_NAPT_TABLE, vpnId, routerId, bgpVpnId, externalAddress, internalAddress, protocol);
            }

            //Send Packetout - tcp or udp packets which got punted to controller.
            BigInteger metadata = naptEntryEvent.getPacketReceived().getMatch().getMetadata().getMetadata();
            byte[] inPayload = naptEntryEvent.getPacketReceived().getPayload();
            Ethernet ethPkt = new Ethernet();
            if (inPayload != null) {
                try {
                    ethPkt.deserialize(inPayload, 0, inPayload.length * NetUtils.NumBitsInAByte);
                } catch (Exception e) {
                    LOG.warn("Failed to decode Packet", e);
                    return;
                }
            }


            long portTag = MetaDataUtil.getLportFromMetadata(metadata).intValue();
            LOG.debug("NAT Service : portTag from incoming packet is {}", portTag);
            String interfaceName = getInterfaceNameFromTag(portTag);
            LOG.debug("NAT Service : interfaceName fetched from portTag is {}", interfaceName);
            org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface iface = null;
            long vlanId =0;
            iface = interfaceManager.getInterfaceInfoFromConfigDataStore(interfaceName);
            if(iface == null) {
                LOG.error("NAT Service : Unable to read interface {} from config DataStore", interfaceName);
                return;
            }
            IfL2vlan ifL2vlan = iface.getAugmentation(IfL2vlan.class);
            if(ifL2vlan != null && ifL2vlan.getVlanId() !=null){
                vlanId = ifL2vlan.getVlanId().getValue() == null ? 0 : ifL2vlan.getVlanId().getValue();
            }
            InterfaceInfo infInfo = interfaceManager.getInterfaceInfoFromOperationalDataStore(interfaceName);
            if(infInfo !=null) {
                LOG.debug("NAT Service : portName fetched from interfaceManager is {}", infInfo.getPortName());
            }

            byte[] pktOut = buildNaptPacketOut(ethPkt);

            List<ActionInfo> actionInfos  = new ArrayList<ActionInfo>();
            if (ethPkt.getPayload() instanceof IPv4) {
                IPv4 ipPkt = (IPv4) ethPkt.getPayload();
                if ((ipPkt.getPayload() instanceof TCP) || (ipPkt.getPayload() instanceof UDP) ) {
                    if (ethPkt.getEtherType() != (short)NwConstants.ETHTYPE_802_1Q) {
                        // VLAN Access port
                        if(infInfo != null) {
                            LOG.debug("NAT Service : vlanId is {}", vlanId);
                            if(vlanId != 0) {
                                // Push vlan
                                actionInfos.add(new ActionInfo(ActionType.push_vlan, new String[] {}, 0));
                                actionInfos.add(new ActionInfo(ActionType.set_field_vlan_vid,
                                           new String[] { Long.toString(vlanId) }, 1));
                            } else {
                                LOG.debug("NAT Service : No vlanId {}, may be untagged", vlanId);
                            }
                        } else {
                            LOG.error("NAT Service : error in getting interfaceInfo");
                            return;
                        }
                    } else {
                        // VLAN Trunk Port
                        LOG.debug("NAT Service : This is VLAN Trunk port case - need not do VLAN tagging again");
                    }
                }
            }
            if(pktOut != null) {
                sendNaptPacketOut(pktOut, infInfo, actionInfos, routerId);
            } else {
                LOG.warn("NAT Service : Unable to send Packet Out");
            }

        }else{
            LOG.debug("NAT Service : Inside delete Operation of NaptEventHandler");
            removeNatFlows(dpnId, NwConstants.INBOUND_NAPT_TABLE, routerId, naptEntryEvent.getIpAddress(), naptEntryEvent.getPortNumber());
        }

        LOG.info("NAT Service : handleNaptEvent() exited for IP, port, routerID : {}", naptEntryEvent.getIpAddress(), naptEntryEvent.getPortNumber(), routerId);
        } catch (Exception e){
            LOG.error("NAT Service :Exception in NaptEventHandler.handleEvent() payload {}", naptEntryEvent,e);
        }
    }

    public static void buildAndInstallNatFlows(BigInteger dpnId, short tableId, long vpnId, long routerId, long bgpVpnId, SessionAddress actualSourceAddress,
                                         SessionAddress translatedSourceAddress, NAPTEntryEvent.Protocol protocol){
        LOG.debug("NAT Service : Build and install NAPT flows in InBound and OutBound tables for dpnId {} and routerId {}", dpnId, routerId);
        //Build the flow for replacing the actual IP and port with the translated IP and port.
        String actualIp = actualSourceAddress.getIpAddress();
        int actualPort = actualSourceAddress.getPortNumber();
        String translatedIp = translatedSourceAddress.getIpAddress();
        String translatedPort = String.valueOf(translatedSourceAddress.getPortNumber());
        int idleTimeout=0;
        if(tableId == NwConstants.OUTBOUND_NAPT_TABLE) {
            idleTimeout = NatConstants.DEFAULT_NAPT_IDLE_TIMEOUT;
        }
        long metaDataValue = routerId;
        String switchFlowRef = NatUtil.getNaptFlowRef(dpnId, tableId, String.valueOf(metaDataValue), actualIp, actualPort);

        long intranetVpnId;
        if(bgpVpnId != NatConstants.INVALID_ID){
            intranetVpnId = bgpVpnId;
        }else{
            intranetVpnId = routerId;
        }
        LOG.debug("NAT Service : Intranet VPN ID {}", intranetVpnId);
        LOG.debug("NAT Service : Router ID {}", routerId);
        FlowEntity snatFlowEntity = MDSALUtil.buildFlowEntity(dpnId, tableId, switchFlowRef, NatConstants.DEFAULT_NAPT_FLOW_PRIORITY, NatConstants.NAPT_FLOW_NAME,
                idleTimeout, 0, NatUtil.getCookieNaptFlow(metaDataValue), buildAndGetMatchInfo(actualIp, actualPort, tableId, protocol, intranetVpnId, vpnId),
                buildAndGetSetActionInstructionInfo(translatedIp, translatedPort, intranetVpnId, vpnId, tableId, protocol));

        snatFlowEntity.setSendFlowRemFlag(true);

        LOG.debug("NAT Service : Installing the NAPT flow in the table {} for the switch with the DPN ID {} ", tableId, dpnId);
        mdsalManager.syncInstallFlow(snatFlowEntity, 1);
        LOG.trace("NAT Service : Exited buildAndInstallNatflows");
    }

    private static List<MatchInfo> buildAndGetMatchInfo(String ip, int port, short tableId, NAPTEntryEvent.Protocol protocol, long segmentId, long vpnId){
        MatchInfo ipMatchInfo = null;
        MatchInfo portMatchInfo = null;
        MatchInfo protocolMatchInfo = null;
        InetAddress ipAddress = null;
        String ipAddressAsString = null;
        try {
            ipAddress = InetAddress.getByName(ip);
            ipAddressAsString = ipAddress.getHostAddress();

        } catch (UnknownHostException e) {
            LOG.error("NAT Service : UnknowHostException in buildAndGetMatchInfo. Failed  to build NAPT Flow for  ip {}", ipAddress);
            return null;
        }

        MatchInfo metaDataMatchInfo = null;
        if(tableId == NwConstants.OUTBOUND_NAPT_TABLE){
            ipMatchInfo = new MatchInfo(MatchFieldType.ipv4_source, new String[] {ipAddressAsString, "32" });
            if(protocol == NAPTEntryEvent.Protocol.TCP) {
                protocolMatchInfo = new MatchInfo(MatchFieldType.ip_proto, new long[] {IPProtocols.TCP.intValue()});
                portMatchInfo = new MatchInfo(MatchFieldType.tcp_src, new long[]{port});
            } else if(protocol == NAPTEntryEvent.Protocol.UDP) {
                protocolMatchInfo = new MatchInfo(MatchFieldType.ip_proto, new long[] {IPProtocols.UDP.intValue()});
                portMatchInfo = new MatchInfo(MatchFieldType.udp_src, new long[]{port});
            }
            metaDataMatchInfo = new MatchInfo(MatchFieldType.metadata,
                    new BigInteger[] { MetaDataUtil.getVpnIdMetadata(segmentId), MetaDataUtil.METADATA_MASK_VRFID });
        }else{
            ipMatchInfo = new MatchInfo(MatchFieldType.ipv4_destination, new String[] {ipAddressAsString, "32" });
            if(protocol == NAPTEntryEvent.Protocol.TCP) {
                protocolMatchInfo = new MatchInfo(MatchFieldType.ip_proto, new long[] {IPProtocols.TCP.intValue()});
                portMatchInfo = new MatchInfo(MatchFieldType.tcp_dst, new long[]{port});
            } else if(protocol == NAPTEntryEvent.Protocol.UDP) {
                protocolMatchInfo = new MatchInfo(MatchFieldType.ip_proto, new long[] {IPProtocols.UDP.intValue()});
                portMatchInfo = new MatchInfo(MatchFieldType.udp_dst, new long[]{port});
            }
            //metaDataMatchInfo = new MatchInfo(MatchFieldType.metadata, new BigInteger[]{BigInteger.valueOf(vpnId), MetaDataUtil.METADATA_MASK_VRFID});
        }
        ArrayList<MatchInfo> matchInfo = new ArrayList<>();
        matchInfo.add(new MatchInfo(MatchFieldType.eth_type, new long[] { 0x0800L }));
        matchInfo.add(ipMatchInfo);
        matchInfo.add(protocolMatchInfo);
        matchInfo.add(portMatchInfo);
        if(tableId == NwConstants.OUTBOUND_NAPT_TABLE){
            matchInfo.add(metaDataMatchInfo);
        }
        return matchInfo;
    }

    private static List<InstructionInfo> buildAndGetSetActionInstructionInfo(String ipAddress, String port, long segmentId, long vpnId, short tableId, NAPTEntryEvent.Protocol protocol) {
        ActionInfo ipActionInfo = null;
        ActionInfo portActionInfo = null;
        ArrayList<ActionInfo> listActionInfo = new ArrayList<>();
        ArrayList<InstructionInfo> instructionInfo = new ArrayList<>();

        if(tableId == NwConstants.OUTBOUND_NAPT_TABLE){
            ipActionInfo = new ActionInfo(ActionType.set_source_ip, new String[] {ipAddress});
            if(protocol == NAPTEntryEvent.Protocol.TCP) {
               portActionInfo = new ActionInfo( ActionType.set_tcp_source_port, new String[] {port});
            } else if(protocol == NAPTEntryEvent.Protocol.UDP) {
               portActionInfo = new ActionInfo( ActionType.set_udp_source_port, new String[] {port});
            }
            // reset the split-horizon bit to allow traffic from tunnel to be
            // sent back to the provider port
            instructionInfo.add(new InstructionInfo(InstructionType.write_metadata,
                    new BigInteger[] { MetaDataUtil.getVpnIdMetadata(vpnId),
                            MetaDataUtil.METADATA_MASK_VRFID.or(MetaDataUtil.METADATA_MASK_SH_FLAG) }));
        }else{
            ipActionInfo = new ActionInfo(ActionType.set_destination_ip, new String[] {ipAddress});
            if(protocol == NAPTEntryEvent.Protocol.TCP) {
               portActionInfo = new ActionInfo( ActionType.set_tcp_destination_port, new String[] {port});
            } else if(protocol == NAPTEntryEvent.Protocol.UDP) {
               portActionInfo = new ActionInfo( ActionType.set_udp_destination_port, new String[] {port});
            }
            instructionInfo.add(new InstructionInfo(InstructionType.write_metadata,
                    new BigInteger[] { MetaDataUtil.getVpnIdMetadata(segmentId), MetaDataUtil.METADATA_MASK_VRFID }));
        }

        listActionInfo.add(ipActionInfo);
        listActionInfo.add(portActionInfo);

        instructionInfo.add(new InstructionInfo(InstructionType.apply_actions, listActionInfo));
        instructionInfo.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.NAPT_PFIB_TABLE
        }));

        return instructionInfo;
    }

    void removeNatFlows(BigInteger dpnId, short tableId ,long segmentId, String ip, int port){
        if(dpnId == null || dpnId.equals(BigInteger.ZERO)){
            LOG.error("NAT Service : DPN ID {} is invalid" , dpnId);
        }
        LOG.debug("NAT Service : Remove NAPT flows for dpnId {}, segmentId {}, ip {} and port {} ", dpnId, segmentId, ip, port);

        //Build the flow with the port IP and port as the match info.
        String switchFlowRef = NatUtil.getNaptFlowRef(dpnId, tableId, String.valueOf(segmentId), ip, port);
        FlowEntity snatFlowEntity = NatUtil.buildFlowEntity(dpnId, tableId, switchFlowRef);
        LOG.debug("NAT Service : Remove the flow in the table {} for the switch with the DPN ID {}", NwConstants.INBOUND_NAPT_TABLE, dpnId);
        mdsalManager.removeFlow(snatFlowEntity);

    }

    protected byte[] buildNaptPacketOut(Ethernet etherPkt) {

        LOG.debug("NAT Service : About to build Napt Packet Out");
        if (etherPkt.getPayload() instanceof IPv4) {
            byte[] rawPkt;
            IPv4 ipPkt = (IPv4) etherPkt.getPayload();
            if ((ipPkt.getPayload() instanceof TCP) || (ipPkt.getPayload() instanceof UDP) ) {
                try {
                    rawPkt = etherPkt.serialize();
                    return rawPkt;
                } catch (PacketException e2) {
                    // TODO Auto-generated catch block
                    e2.printStackTrace();
                    return null;
                }
             } else {
                 LOG.error("NAT Service : Unable to build NaptPacketOut since its neither TCP nor UDP");
                 return null;
             }
        }
        LOG.error("NAT Service : Unable to build NaptPacketOut since its not IPv4 packet");
        return null;

    }

    private void sendNaptPacketOut(byte[] pktOut, InterfaceInfo infInfo, List<ActionInfo> actionInfos, Long routerId) {
        LOG.trace("NAT Service: Sending packet out DpId {}, interfaceInfo {}", infInfo.getDpId(), infInfo);
        // set in_port, and action as OFPP_TABLE so that it starts from table 0 (lowest table as per spec)
        actionInfos.add(new ActionInfo(ActionType.set_field_tunnel_id, new BigInteger[] {
                  BigInteger.valueOf(routerId)}, 2));
        actionInfos.add(new ActionInfo(ActionType.output, new String[] { "0xfffffff9" }, 3));
        NodeConnectorRef in_port = MDSALUtil.getNodeConnRef(infInfo.getDpId(), String.valueOf(infInfo.getPortNo()));
        LOG.debug("NAT Service : in_port for packetout is being set to {}", String.valueOf(infInfo.getPortNo()));
        TransmitPacketInput output = MDSALUtil.getPacketOut(actionInfos, pktOut, infInfo.getDpId().longValue(), in_port);
        LOG.trace("NAT Service: Transmitting packet: {}",output);
        this.pktService.transmitPacket(output);
    }

    private String getInterfaceNameFromTag(long portTag) {
        String interfaceName = null;
        GetInterfaceFromIfIndexInput input = new GetInterfaceFromIfIndexInputBuilder().setIfIndex(new Integer((int)portTag)).build();
        Future<RpcResult<GetInterfaceFromIfIndexOutput>> futureOutput = interfaceManagerRpc.getInterfaceFromIfIndex(input);
        try {
            GetInterfaceFromIfIndexOutput output = futureOutput.get().getResult();
            interfaceName = output.getInterfaceName();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("NAT Service : Error while retrieving the interfaceName from tag using getInterfaceFromIfIndex RPC");
        }
        LOG.trace("NAT Service : Returning interfaceName {} for tag {} form getInterfaceNameFromTag", interfaceName, portTag);
        return interfaceName;
    }

}
