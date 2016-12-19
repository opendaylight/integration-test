/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.natservice.internal;

import java.math.BigInteger;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.FlowAdded;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.FlowRemoved;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.FlowUpdated;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.NodeErrorNotification;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.NodeExperimenterErrorNotification;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.SalFlowListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.SwitchFlowRemoved;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.TcpMatchFields;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.UdpMatchFields;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.Layer3Match;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.Layer4Match;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.layer._3.match.Ipv4Match;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.layer._4.match.TcpMatch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.layer._4.match.UdpMatch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.ip.port.map.IpPortExternal;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NaptFlowRemovedEventHandler implements SalFlowListener{
    private static final Logger LOG = LoggerFactory.getLogger(NaptFlowRemovedEventHandler.class);
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private final EventDispatcher naptEventdispatcher;
    private final NaptPacketInHandler naptPacketInHandler;
    private final NaptManager naptManager;

    public NaptFlowRemovedEventHandler(final DataBroker dataBroker,
                                       final IMdsalApiManager mdsalManager,
                                       final EventDispatcher eventDispatcher,
                                       final NaptPacketInHandler handler,
                                       final NaptManager naptManager) {
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.naptEventdispatcher = eventDispatcher;
        this.naptPacketInHandler = handler;
        this.naptManager = naptManager;
    }

    @Override
    public void onSwitchFlowRemoved(SwitchFlowRemoved flowRemoved) {

    }

    private BigInteger getDpnId(String node) {
        //openflow:1]
        String temp[] = node.split(":");
        BigInteger dpnId = new BigInteger(temp[1]);
        return dpnId;

    }

    @Override
    public void onFlowAdded(FlowAdded arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onFlowRemoved(FlowRemoved flowRemoved) {
        /*
        If the removed flow is from the OUTBOUND NAPT table :
        1) Get the ActionInfo of the flow.
        2) From the ActionInfo of the flow get the internal IP address, port and the protocol.
        3) Get the Metadata matching info of the flow.
        4) From the Metadata matching info of the flow get router ID.
        5) Querry the container intext-ip-port-map using the router ID
           and the internal IP address, port to get the external IP address, port
        6) Instantiate an NaptEntry event and populate the external IP address, port and the router ID.
        7) Place the NaptEntry event to the queue.
*/

        short tableId = flowRemoved.getTableId();

        if (tableId == NwConstants.OUTBOUND_NAPT_TABLE) {
            LOG.info("NaptFlowRemovedEventHandler : onSwitchFlowRemoved() entry");

            //Get the internal internal IP address and the port number from the IPv4 match.
            Ipv4Prefix internalIpv4Address = null;
            Layer3Match layer3Match = flowRemoved.getMatch().getLayer3Match();
            if (layer3Match instanceof Ipv4Match) {
                Ipv4Match internalIpv4Match = (Ipv4Match) layer3Match;
                internalIpv4Address = internalIpv4Match.getIpv4Source();
            }
            if(internalIpv4Address == null){
                LOG.error("NaptFlowRemovedEventHandler : Matching internal IP is null while retrieving the value from the Outbound NAPT flow");
                return;
            }
            //Get the internal IP as a string
            String internalIpv4AddressAsString = internalIpv4Address.getValue();
            String[] internalIpv4AddressParts = internalIpv4AddressAsString.split("/");
            String internalIpv4HostAddress = null;
            if(internalIpv4AddressParts.length >= 1){
                internalIpv4HostAddress = internalIpv4AddressParts[0];
            }

            //Get the protocol from the layer4 match
            NAPTEntryEvent.Protocol protocol = null;
            Integer internalPortNumber = null;
            Layer4Match layer4Match = flowRemoved.getMatch().getLayer4Match();
            if (layer4Match instanceof TcpMatch) {
                TcpMatchFields tcpMatchFields = (TcpMatchFields)layer4Match;
                internalPortNumber = tcpMatchFields.getTcpSourcePort().getValue();
                protocol = NAPTEntryEvent.Protocol.TCP;
            }else if (layer4Match instanceof UdpMatch){
                UdpMatchFields udpMatchFields = (UdpMatchFields)layer4Match;
                internalPortNumber = udpMatchFields.getUdpSourcePort().getValue();
                protocol = NAPTEntryEvent.Protocol.UDP;
            }
            if(protocol == null){
                LOG.error("NaptFlowRemovedEventHandler : Matching protocol is null while retrieving the value from the Outbound NAPT flow");
                return;
            }

            //Get the router ID from the metadata.
            Long routerId;
            BigInteger metadata = flowRemoved.getMatch().getMetadata().getMetadata();
            if (MetaDataUtil.getNatRouterIdFromMetadata(metadata) != 0) {
                routerId = MetaDataUtil.getNatRouterIdFromMetadata(metadata);
            } else {
                LOG.error("NaptFlowRemovedEventHandler : Null exception while retrieving routerId");
                return;
            }

            //Get the external IP address and the port from the model
            IpPortExternal ipPortExternal = NatUtil.getExternalIpPortMap(dataBroker, routerId, internalIpv4HostAddress, internalPortNumber.toString(), protocol);
            if (ipPortExternal == null) {
                LOG.error("NaptFlowRemovedEventHandler : IpPortExternal not found, BGP vpn might be associated with router");
                //router must be associated with BGP vpn ID
                long bgpVpnId = routerId;
                LOG.debug("NaptFlowRemovedEventHandler : BGP VPN ID {}", bgpVpnId);
                String vpnName = NatUtil.getRouterName(dataBroker, bgpVpnId);
                String routerName = NatUtil.getRouterIdfromVpnInstance(dataBroker, vpnName);
                if (routerName == null) {
                    LOG.error("NAT Service: Unable to find router for VpnName {}", vpnName);
                    return;
                }
                routerId = NatUtil.getVpnId(dataBroker, routerName);
                LOG.debug("NaptFlowRemovedEventHandler : Router ID {}", routerId);
                ipPortExternal = NatUtil.getExternalIpPortMap(dataBroker, routerId, internalIpv4HostAddress, internalPortNumber.toString(), protocol);
                if(ipPortExternal == null) {
                    LOG.error("NaptFlowRemovedEventHandler : IpPortExternal is null while queried from the model for routerId {}",routerId);
                    return;
                }
            }
            String externalIpAddress = ipPortExternal.getIpAddress();
            int externalPortNumber = ipPortExternal.getPortNum();

            //Create an NAPT event and place it in the queue.
            NAPTEntryEvent naptEntryEvent =  new NAPTEntryEvent(externalIpAddress, externalPortNumber, routerId, NAPTEntryEvent.Operation.DELETE, protocol, null, false);
            naptEventdispatcher.addNaptEvent(naptEntryEvent);

            //Get the DPN ID from the Node
            InstanceIdentifier<Node> nodeRef = flowRemoved.getNode().getValue().firstIdentifierOf(Node.class);
            String dpn = nodeRef.firstKeyOf(Node.class).getId().getValue();
            BigInteger dpnId = getDpnId(dpn);
            String switchFlowRef = NatUtil.getNaptFlowRef(dpnId, tableId, String.valueOf(routerId), internalIpv4HostAddress, internalPortNumber);

            //Inform the MDSAL manager to inform about the flow removal.
            LOG.debug("NaptFlowRemovedEventHandler : DPN ID {}, Metadata {}, SwitchFlowRef {}, internalIpv4HostAddress{}", dpnId, routerId, switchFlowRef, internalIpv4AddressAsString);
            FlowEntity snatFlowEntity = NatUtil.buildFlowEntity(dpnId, tableId, switchFlowRef);
            mdsalManager.removeFlow(snatFlowEntity);

            LOG.debug("Received flow removed notification due to idleTimeout of flow from switch for flowref {}",switchFlowRef);
            //Remove the SourceIP:Port key from the Napt packet handler map.
            String internalIpPortKey = internalIpv4HostAddress + ":" + internalPortNumber;
            naptPacketInHandler.removeIncomingPacketMap(internalIpPortKey);

            //Remove the mapping of internal fixed ip/port to external ip/port from the datastore.
            SessionAddress internalSessionAddress = new SessionAddress(internalIpv4HostAddress, internalPortNumber);
            naptManager.releaseIpExtPortMapping(routerId, internalSessionAddress, protocol);
            LOG.info("NaptFlowRemovedEventHandler : onSwitchFlowRemoved() exit");
        }else {
            LOG.debug("Received flow removed notification due to flowdelete from switch for flowref");
        }

    }

    @Override
    public void onFlowUpdated(FlowUpdated arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onNodeErrorNotification(NodeErrorNotification arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onNodeExperimenterErrorNotification(NodeExperimenterErrorNotification arg0) {
        // TODO Auto-generated method stub

    }

}
