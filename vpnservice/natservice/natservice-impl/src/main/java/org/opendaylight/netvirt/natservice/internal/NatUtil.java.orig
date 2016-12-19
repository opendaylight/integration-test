/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.natservice.internal;

import java.math.BigInteger;

import com.google.common.collect.Lists;
import com.google.common.collect.Sets;

import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnInstanceToVpnId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.action.OutputActionCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.action.PushVlanActionCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.action.SetFieldCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExtRouters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalIpsCounter;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalNetworks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.FloatingIpPortInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ProviderTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.FloatingIpInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.IntextIpMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.IntextIpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.NaptSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ProtocolTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.RouterIdName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.RouterToVpnMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.SnatintIpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.RoutersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.ExternalCounters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.ExternalCountersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.external.counters.ExternalIpCounter;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.ports.InternalToExternalPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.ports.InternalToExternalPortMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.port.info.FloatingIpIdToPortMappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.IntextIpProtocolType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.IntextIpProtocolTypeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.ip.port.map.IpPortExternal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.id.name.RouterIds;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.id.name.RouterIdsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.to.vpn.mapping.Routermapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.to.vpn.mapping.RoutermappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.IntipPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.IntipPortMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.IpPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.IpPortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.ip.port.IntIpProtoType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.ip.port.IntIpProtoTypeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.NeutronRouterDpns;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.VpnIdToVpnInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NetworkMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronVpnPortipPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.VpnMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.networkmaps.NetworkMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.neutron.vpn.portip.port.data.VpnPortipToPortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.SubnetKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.add.group.input.buckets.bucket.action.action.NxActionResubmitRpcAddGroupCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nodes.node.table.flow.instructions.instruction.instruction.apply.actions._case.apply.actions.action.action.NxActionRegLoadNodesNodeTableFlowApplyActionsCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.reg.load.grouping.NxRegLoad;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import com.google.common.base.Optional;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.NetworksKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.RouterPorts;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.RouterPortsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.PortsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitchKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIds;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.id.to.vpn.instance.VpnIdsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.DpnEndpoints;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.DPNTEPsInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.DPNTEPsInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.dpn.teps.info.TunnelEndPoints;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMappingKey;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.DpnRoutersList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.DpnRoutersListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.dpn.routers.list.RoutersList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfacesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.DpnRoutersListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.dpn.routers.list.RoutersListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.dpn.routers.list.RoutersListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.DpnRouters;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;

public class NatUtil {

    private static String OF_URI_SEPARATOR = ":";
    private static final Logger LOG = LoggerFactory.getLogger(NatUtil.class);

    /*
        getCookieSnatFlow() computes and returns a unique cookie value for the NAT flows using the router ID as the reference value.
     */
    public static BigInteger getCookieSnatFlow(long routerId) {
        return NatConstants.COOKIE_NAPT_BASE.add(new BigInteger("0110000", 16)).add(
                BigInteger.valueOf(routerId));
    }

    /*
        getCookieNaptFlow() computes and returns a unique cookie value for the NAPT flows using the router ID as the reference value.
    */
    public static BigInteger getCookieNaptFlow(long routerId) {
        return NatConstants.COOKIE_NAPT_BASE.add(new BigInteger("0111000", 16)).add(
                BigInteger.valueOf(routerId));
    }

    /*
        getVpnId() returns the VPN ID from the VPN name
     */
    public static long getVpnId(DataBroker broker, String vpnName) {
        if(vpnName == null) {
            return NatConstants.INVALID_ID;
        }

        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> id
                = getVpnInstanceToVpnIdIdentifier(vpnName);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> vpnInstance
                = read(broker, LogicalDatastoreType.CONFIGURATION, id);


        long vpnId = NatConstants.INVALID_ID;
        if(vpnInstance.isPresent()) {
            Long vpnIdAsLong = vpnInstance.get().getVpnId();
            if(vpnIdAsLong != null){
                vpnId = vpnIdAsLong;
            }
        }
        return vpnId;
    }

    public static Long getVpnId(DataBroker broker, long routerId){
        //Get the external network ID from the ExternalRouter model
        Uuid networkId = NatUtil.getNetworkIdFromRouterId(broker, routerId);
        if(networkId == null ){
            LOG.error("NAT Service : networkId is null");
            return null;
        }

        //Get the VPN ID from the ExternalNetworks model
        Uuid vpnUuid = NatUtil.getVpnIdfromNetworkId(broker, networkId);
        if(vpnUuid == null ){
            LOG.error("NAT Service : vpnUuid is null");
            return null;
        }
        Long vpnId = NatUtil.getVpnId(broker, vpnUuid.getValue());
        return vpnId;
    }

    static InstanceIdentifier<RouterPorts> getRouterPortsId(String routerId) {
        return InstanceIdentifier.builder(FloatingIpInfo.class).child(RouterPorts.class, new RouterPortsKey(routerId)).build();
    }

    static InstanceIdentifier<Routermapping> getRouterVpnMappingId(String routerId) {
        return InstanceIdentifier.builder(RouterToVpnMapping.class).child(Routermapping.class, new RoutermappingKey(routerId)).build();
    }

    static InstanceIdentifier<Ports> getPortsIdentifier(String routerId, String portName) {
        return InstanceIdentifier.builder(FloatingIpInfo.class).child(RouterPorts.class, new RouterPortsKey(routerId))
                .child(Ports.class, new PortsKey(portName)).build();
    }

    static InstanceIdentifier<InternalToExternalPortMap> getIntExtPortMapIdentifier(String routerId, String portName,
                                                                                    String internalIp) {
        return InstanceIdentifier.builder(FloatingIpInfo.class).child(RouterPorts.class, new RouterPortsKey(routerId))
                .child(Ports.class, new PortsKey(portName))
                .child(InternalToExternalPortMap.class, new InternalToExternalPortMapKey(internalIp)).build();
    }

    static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance>
    getVpnInstanceToVpnIdIdentifier(String vpnName) {
        return InstanceIdentifier.builder(VpnInstanceToVpnId.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance.class,
                        new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstanceKey(vpnName)).build();
    }

    static String getVpnInstanceFromVpnIdentifier(DataBroker broker, long vpnId) {
        InstanceIdentifier<VpnIds> id = InstanceIdentifier.builder(VpnIdToVpnInstance.class)
                .child(VpnIds.class, new VpnIdsKey(Long.valueOf(vpnId))).build();
        Optional<VpnIds> vpnInstance = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        return vpnInstance.isPresent() ? vpnInstance.get().getVpnInstanceName() : null;
    }

    /*
       getFlowRef() returns a string identfier for the SNAT flows using the router ID as the reference.
    */
    public static String getFlowRef(BigInteger dpnId, short tableId, long routerID, String ip) {
        return new StringBuffer().append(NatConstants.NAPT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
                append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID)
                .append(NatConstants.FLOWID_SEPARATOR).append(ip).toString();
    }

    public static String getNaptFlowRef(BigInteger dpnId, short tableId, String routerID, String ip, int port) {
        return new StringBuffer().append(NatConstants.NAPT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
                append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID).append(NatConstants.FLOWID_SEPARATOR).append(ip).
                append(NatConstants.FLOWID_SEPARATOR).append(port).toString();
    }

    /*
        getNetworkIdFromRouterId() returns the network-id from the below model using the router-id as the key
               container ext-routers {
                   list routers {
                       key router-name;
                       leaf router-name { type string; }
                       leaf network-id { type yang:uuid; }
                       leaf enable-snat { type boolean; }
                       leaf-list external-ips {
                            type string; //format - ipaddress\prefixlength
                       }
                       leaf-list subnet-ids { type yang:uuid; }
                   }
               }

    */
    static Uuid getNetworkIdFromRouterId(DataBroker broker, long routerId) {
        String routerName = getRouterName(broker, routerId);
        InstanceIdentifier id = buildRouterIdentifier(routerName);
        Optional<Routers> routerData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerData.isPresent()) {
            return routerData.get().getNetworkId();
        }
        return null;
    }

    static InstanceIdentifier<Routers> buildRouterIdentifier(String routerId) {
        InstanceIdentifier<Routers> routerInstanceIndentifier = InstanceIdentifier.builder(ExtRouters.class).child
                (Routers.class, new RoutersKey(routerId)).build();
        return routerInstanceIndentifier;
    }

    /*
     * getEnableSnatFromRouterId() returns IsSnatEnabled true is routerID is present in external n/w otherwise returns false
     */
    static boolean isSnatEnabledForRouterId(DataBroker broker, String routerId){
        InstanceIdentifier id = buildRouterIdentifier(routerId);
        Optional<Routers> routerData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerData.isPresent()) {
            return routerData.get().isEnableSnat();
        }
        return false;
    }
    /*
        getVpnIdfromNetworkId() returns the vpnid from the below model using the network ID as the key.
            container external-networks {
                list networks  {
                    key id;
                    leaf id {
                        type yang:uuid;
                    }
                    leaf vpnid { type yang:uuid; }
                    leaf-list router-ids { type yang:uuid; }
                    leaf-list subnet-ids{ type yang:uuid; }
                }
            }
    */
    public static Uuid getVpnIdfromNetworkId(DataBroker broker, Uuid networkId) {
        InstanceIdentifier<Networks> id = buildNetworkIdentifier(networkId);
        Optional<Networks> networkData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (networkData.isPresent()) {
            return networkData.get().getVpnid();
        }
        return null;
    }

    public static ProviderTypes getProviderTypefromNetworkId(DataBroker broker, Uuid networkId) {
        InstanceIdentifier<Networks> id = buildNetworkIdentifier(networkId);
        Optional<Networks> networkData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if ((networkData.isPresent()) && (networkData.get() != null)) {
            return networkData.get().getProviderNetworkType();
        }
        return null;
    }

    public static List<Uuid> getRouterIdsfromNetworkId(DataBroker broker, Uuid networkId) {
        InstanceIdentifier<Networks> id = buildNetworkIdentifier(networkId);
        Optional<Networks> networkData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        return networkData.isPresent() ? networkData.get().getRouterIds() : Collections.emptyList();
    }

    static String getAssociatedExternalNetwork(DataBroker dataBroker, String routerId) {
        InstanceIdentifier<Routers> id = NatUtil.buildRouterIdentifier(routerId);
        Optional<Routers> routerData = NatUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerData.isPresent()) {
            Uuid networkId = routerData.get().getNetworkId();
            if(networkId != null) {
                return networkId.getValue();
            }
        }
        return null;
    }

    private static InstanceIdentifier<Networks> buildNetworkIdentifier(Uuid networkId) {
        InstanceIdentifier<Networks> network = InstanceIdentifier.builder(ExternalNetworks.class).child
                (Networks.class, new NetworksKey(networkId)).build();
        return network;
    }




    /*
        getNaptSwitchesDpnIdsfromRouterId() returns the primary-switch-id and the secondary-switch-id in a array using the router-id; as the key.
            container napt-switches {
                list router-to-napt-switch {
                    key router-id;
                    leaf router-id { type uint32; }
                    leaf primary-switch-id { type uint64; }
                    leaf secondary-switch-id { type uint64; }
                }
            }
    */
    public static BigInteger getPrimaryNaptfromRouterId(DataBroker broker, Long routerId) {
        // convert routerId to Name
        String routerName = getRouterName(broker, routerId);
        InstanceIdentifier id = buildNaptSwitchIdentifier(routerName);
        Optional<RouterToNaptSwitch> routerToNaptSwitchData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerToNaptSwitchData.isPresent()) {
            RouterToNaptSwitch routerToNaptSwitchInstance = routerToNaptSwitchData.get();
            return routerToNaptSwitchInstance.getPrimarySwitchId();
        }
        return null;
    }

    private static InstanceIdentifier<RouterToNaptSwitch> buildNaptSwitchIdentifier(String routerId) {
        InstanceIdentifier<RouterToNaptSwitch> rtrNaptSw = InstanceIdentifier.builder(NaptSwitches.class).child
                (RouterToNaptSwitch.class, new RouterToNaptSwitchKey(routerId)).build();
        return rtrNaptSw;
    }

    public static String getRouterName(DataBroker broker, Long routerId) {
        InstanceIdentifier id = buildRouterIdentifier(routerId);
        Optional<RouterIds> routerIdsData = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        if (routerIdsData.isPresent()) {
            RouterIds routerIdsInstance = routerIdsData.get();
            return routerIdsInstance.getRouterName();
        }
        return null;
    }

    private static InstanceIdentifier<RouterIds> buildRouterIdentifier(Long routerId) {
        InstanceIdentifier<RouterIds> routerIds = InstanceIdentifier.builder(RouterIdName.class).child
                (RouterIds.class, new RouterIdsKey(routerId)).build();
        return routerIds;
    }

    public static <T extends DataObject> Optional<T> read(DataBroker broker, LogicalDatastoreType datastoreType,
                                                          InstanceIdentifier<T> path) {

        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return result;
    }

    static InstanceIdentifier<VpnInstanceOpDataEntry> getVpnInstanceOpDataIdentifier(String vrfId) {
        return InstanceIdentifier.builder(VpnInstanceOpData.class)
                .child(VpnInstanceOpDataEntry.class, new VpnInstanceOpDataEntryKey(vrfId)).build();
    }

    public static long readVpnId(DataBroker broker, String vpnName) {

        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> id
                = getVpnInstanceToVpnIdIdentifier(vpnName);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> vpnInstance
                = read(broker, LogicalDatastoreType.CONFIGURATION, id);

        long vpnId = NatConstants.INVALID_ID;
        if(vpnInstance.isPresent()) {
            vpnId = vpnInstance.get().getVpnId();
        }
        return vpnId;
    }

    public static FlowEntity buildFlowEntity(BigInteger dpnId, short tableId, BigInteger cookie) {
        FlowEntity flowEntity = new FlowEntity(dpnId);
        flowEntity.setTableId(tableId);
        flowEntity.setCookie(cookie);
        return flowEntity;
    }

    public static long getIpAddress(byte[] rawIpAddress) {
        return (((rawIpAddress[0] & 0xFF) << (3 * 8)) + ((rawIpAddress[1] & 0xFF) << (2 * 8))
                + ((rawIpAddress[2] & 0xFF) << (1 * 8)) + (rawIpAddress[3] & 0xFF)) & 0xffffffffL;
    }

    public static String getFlowRef(BigInteger dpnId, short tableId, InetAddress destPrefix) {
        return new StringBuilder(64).append(NatConstants.FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR)
                .append(destPrefix.getHostAddress()).toString();
    }

    public static String getEndpointIpAddressForDPN(DataBroker broker, BigInteger dpnId) {
        String nextHopIp = null;
        InstanceIdentifier<DPNTEPsInfo> tunnelInfoId =
                InstanceIdentifier.builder(DpnEndpoints.class).child(DPNTEPsInfo.class, new DPNTEPsInfoKey(dpnId)).build();
        Optional<DPNTEPsInfo> tunnelInfo = read(broker, LogicalDatastoreType.CONFIGURATION, tunnelInfoId);
        if (tunnelInfo.isPresent()) {
            List<TunnelEndPoints> nexthopIpList = tunnelInfo.get().getTunnelEndPoints();
            if (nexthopIpList != null && !nexthopIpList.isEmpty()) {
                nextHopIp = nexthopIpList.get(0).getIpAddress().getIpv4Address().getValue();
            }
        }
        return nextHopIp;
    }

    /*
        getVpnRd returns the rd (route distinguisher) which is the VRF ID from the below model using the vpnName
            list vpn-instance {
                key "vpn-instance-name"
                leaf vpn-instance-name {
                    type string;
                }
                leaf vpn-id {
                    type uint32;
                }
                leaf vrf-id {
                    type string;
                }
            }
    */
    public static String getVpnRd(DataBroker broker, String vpnName) {

        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> id
                = getVpnInstanceToVpnIdIdentifier(vpnName);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.to.vpn.id.VpnInstance> vpnInstance
                = read(broker, LogicalDatastoreType.CONFIGURATION, id);

        String rd = null;
        if(vpnInstance.isPresent()) {
            rd = vpnInstance.get().getVrfId();
        }
        return rd;
    }

    /*  getExternalIPPortMap() returns the internal IP and the port for the querried router ID, external IP and the port.
        container intext-ip-port-map {
        config true;
        list ip-port-mapping {
            key router-id;
            leaf router-id { type uint32; }
            list intext-ip-protocol-type {
                key protocol;
                leaf protocol { type protocol-types; }
                list ip-port-map {
                    key ip-port-internal;
                    description "internal to external ip-port mapping";
                    leaf ip-port-internal { type string; }
                    container ip-port-external {
                       uses ip-port-entity;
                    }
                }
            }
         }
       }
    */
    public static IpPortExternal getExternalIpPortMap(DataBroker broker, Long routerId, String internalIpAddress, String internalPort, NAPTEntryEvent.Protocol protocol) {
        ProtocolTypes protocolType = NatUtil.getProtocolType(protocol);
        InstanceIdentifier ipPortMapId = buildIpToPortMapIdentifier(routerId, internalIpAddress, internalPort, protocolType);
        Optional<IpPortMap> ipPortMapData = read(broker, LogicalDatastoreType.CONFIGURATION, ipPortMapId);
        if (ipPortMapData.isPresent()) {
            IpPortMap ipPortMapInstance = ipPortMapData.get();
            return ipPortMapInstance.getIpPortExternal();
        }
        return null;
    }

    private static InstanceIdentifier<IpPortMap> buildIpToPortMapIdentifier(Long routerId, String internalIpAddress, String internalPort , ProtocolTypes protocolType) {
        InstanceIdentifier<IpPortMap> ipPortMapId = InstanceIdentifier.builder(IntextIpPortMap.class).child
                (IpPortMapping.class, new IpPortMappingKey(routerId)).child(IntextIpProtocolType.class, new IntextIpProtocolTypeKey(protocolType))
                .child(IpPortMap.class, new IpPortMapKey(internalIpAddress + ":" + internalPort)).build();
        return ipPortMapId;
    }

    public static FlowEntity buildFlowEntity(BigInteger dpnId, short tableId, String flowId, int priority, String flowName,
                                             BigInteger cookie, List<MatchInfo> listMatchInfo) {

        FlowEntity flowEntity = new FlowEntity(dpnId);
        flowEntity.setTableId(tableId);
        flowEntity.setFlowId(flowId);
        flowEntity.setPriority(priority);
        flowEntity.setFlowName(flowName);
        flowEntity.setCookie(cookie);
        flowEntity.setMatchInfoList(listMatchInfo);
        return flowEntity;
    }

    static boolean isVpnInterfaceConfigured(DataBroker broker, String interfaceName)
    {
        InstanceIdentifier<VpnInterface> interfaceId = getVpnInterfaceIdentifier(interfaceName);
        Optional<VpnInterface> configuredVpnInterface = read(broker, LogicalDatastoreType.CONFIGURATION, interfaceId);

        if (configuredVpnInterface.isPresent()) {
            return true;
        }
        return false;
    }

    static InstanceIdentifier<VpnInterface> getVpnInterfaceIdentifier(String vpnInterfaceName) {
        return InstanceIdentifier.builder(VpnInterfaces.class)
                .child(VpnInterface.class, new VpnInterfaceKey(vpnInterfaceName)).build();
    }

    static VpnInterface getConfiguredVpnInterface(DataBroker broker, String interfaceName) {
        InstanceIdentifier<VpnInterface> interfaceId = getVpnInterfaceIdentifier(interfaceName);
        Optional<VpnInterface> configuredVpnInterface = read(broker, LogicalDatastoreType.CONFIGURATION, interfaceId);

        if (configuredVpnInterface.isPresent()) {
            return configuredVpnInterface.get();
        }
        return null;
    }

    public static String getDpnFromNodeConnectorId(NodeConnectorId portId) {
        /*
         * NodeConnectorId is of form 'openflow:dpnid:portnum'
         */
        String[] split = portId.getValue().split(OF_URI_SEPARATOR);
        if (split == null || split.length != 3) {
            return null;
        }
        return split[1];
    }

    public static BigInteger getDpIdFromInterface(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface ifState) {
        String lowerLayerIf = ifState.getLowerLayerIf().get(0);
        NodeConnectorId nodeConnectorId = new NodeConnectorId(lowerLayerIf);
        return new BigInteger(getDpnFromNodeConnectorId(nodeConnectorId));
    }

    /*
    container vpnMaps {
        list vpnMap {
            key vpn-id;
            leaf vpn-id {
                type    yang:uuid;
                description "vpn-id";
            }
            leaf name {
                type  string;
                description "vpn name";
            }
            leaf tenant-id {
                type    yang:uuid;
                description "The UUID of the tenant that will own the subnet.";
            }

            leaf router-id {
              type    yang:uuid;
              description "UUID of router ";
            }
            leaf-list network_ids {
              type    yang:uuid;
              description "UUID representing the network ";
            }
        }
    }
    Method returns router Id associated to a VPN
     */

    public static String getRouterIdfromVpnInstance(DataBroker broker,String vpnName){
        InstanceIdentifier<VpnMap> vpnMapIdentifier = InstanceIdentifier.builder(VpnMaps.class)
                .child(VpnMap.class, new VpnMapKey(new Uuid(vpnName))).build();
        Optional<VpnMap> optionalVpnMap = read(broker, LogicalDatastoreType.CONFIGURATION,
                vpnMapIdentifier);
        if (optionalVpnMap.isPresent()) {
            Uuid routerId = optionalVpnMap.get().getRouterId();
            if (routerId != null) {
                return routerId.getValue();
            }
        }
        return null;
    }

    static Uuid getVpnForRouter(DataBroker broker, String routerId) {
        InstanceIdentifier<VpnMaps> vpnMapsIdentifier = InstanceIdentifier.builder(VpnMaps.class).build();
        Optional<VpnMaps> optionalVpnMaps = read(broker, LogicalDatastoreType.CONFIGURATION,
                vpnMapsIdentifier);
        if (optionalVpnMaps.isPresent() && optionalVpnMaps.get().getVpnMap() != null) {
            List<VpnMap> allMaps = optionalVpnMaps.get().getVpnMap();
            if (routerId != null) {
                for (VpnMap vpnMap : allMaps) {
                    if (vpnMap.getRouterId() != null &&
                            routerId.equals(vpnMap.getRouterId().getValue()) &&
                            !routerId.equals(vpnMap.getVpnId().getValue())) {
                        return vpnMap.getVpnId();
                    }
                }
            }
        }
        return null;
    }

    static long getAssociatedVpn(DataBroker broker, String routerName) {
        InstanceIdentifier<Routermapping> routerMappingId = NatUtil.getRouterVpnMappingId(routerName);
        Optional<Routermapping> optRouterMapping = NatUtil.read(broker, LogicalDatastoreType.OPERATIONAL, routerMappingId);
        if(optRouterMapping.isPresent()) {
            Routermapping routerMapping = optRouterMapping.get();
            return routerMapping.getVpnId();
        }
        return NatConstants.INVALID_ID;
    }

    public static String getAssociatedVPN(DataBroker dataBroker, Uuid networkId, Logger log) {
        Uuid vpnUuid = NatUtil.getVpnIdfromNetworkId(dataBroker, networkId);
        if(vpnUuid == null ){
            log.error("No VPN instance associated with ext network {}", networkId);
            return null;
        }
        return vpnUuid.getValue();
    }

    public static void addPrefixToBGP(DataBroker broker,
                                      IBgpManager bgpManager,
                                      IFibManager fibManager,
                                      String rd,
                                      String prefix,
                                      String nextHopIp,
                                      long label,
                                      Logger log,
                                      RouteOrigin origin) {
        try {
            LOG.info("ADD: Adding Fib entry rd {} prefix {} nextHop {} label {}", rd, prefix, nextHopIp, label);
            if (nextHopIp == null)
            {
                log.error("addPrefix failed since nextHopIp cannot be null.");
                return;
            }
            fibManager.addOrUpdateFibEntry(broker, rd, null /*macAddress*/, prefix, Arrays.asList(nextHopIp),
                    VrfEntry.EncapType.Mplsgre, (int)label, 0 /*l3vni*/, null /*gatewayMacAddress*/, origin, null /*writeTxn*/);
<<<<<<< HEAD
            bgpManager.advertisePrefix(rd, prefix, Arrays.asList(nextHopIp), (int)label);
=======
            bgpManager.advertisePrefix(rd, null /*macAddress*/, prefix, Arrays.asList(nextHopIp),
                    VrfEntry.EncapType.Mplsgre, (int)label, 0 /*l3vni*/, null /*gatewayMac*/);
>>>>>>> 501b5dd9525a54e133e562f05841257a3ee678d2
            LOG.info("ADD: Added Fib entry rd {} prefix {} nextHop {} label {}", rd, prefix, nextHopIp, label);
        } catch(Exception e) {
            log.error("Add prefix failed", e);
        }
    }

    static InstanceIdentifier<Ports> buildPortToIpMapIdentifier(String routerId, String portName) {
        InstanceIdentifier<Ports> ipPortMapId = InstanceIdentifier.builder(FloatingIpInfo.class).child
                (RouterPorts.class, new RouterPortsKey(routerId)).child(Ports.class, new PortsKey(portName)).build();
        return ipPortMapId;
    }

    static InstanceIdentifier<RouterPorts> buildRouterPortsIdentifier(String routerId) {
        InstanceIdentifier<RouterPorts> routerInstanceIndentifier = InstanceIdentifier.builder(FloatingIpInfo.class).child
                (RouterPorts.class, new RouterPortsKey(routerId)).build();
        return routerInstanceIndentifier;
    }

    /* container snatint-ip-port-map {
        list intip-port-map {
            key router-id;
            leaf router-id { type uint32; }
            list ip-port {
                key internal-ip;
                leaf internal-ip { type string; }
                list int-ip-proto-type {
                    key protocol;
                    leaf protocol { type protocol-types; }
                    leaf-list ports { type uint16; }
                }
            }
        }
    }
    Method returns InternalIp port List
    */

    public static List<Integer> getInternalIpPortListInfo(DataBroker dataBroker,Long routerId, String internalIpAddress, ProtocolTypes protocolType){
        Optional<IntIpProtoType> optionalIpProtoType = read(dataBroker, LogicalDatastoreType.CONFIGURATION, buildSnatIntIpPortIdentifier(routerId, internalIpAddress, protocolType));
        if (optionalIpProtoType.isPresent()) {
            return optionalIpProtoType.get().getPorts();
        }
        return null;
    }

    public static InstanceIdentifier<IntIpProtoType> buildSnatIntIpPortIdentifier(Long routerId, String internalIpAddress, ProtocolTypes protocolType) {
        InstanceIdentifier<IntIpProtoType> intIpProtocolTypeId = InstanceIdentifier.builder(SnatintIpPortMap.class).child
                (IntipPortMap.class, new IntipPortMapKey(routerId)).child(IpPort.class, new IpPortKey(internalIpAddress)).child
                (IntIpProtoType.class, new IntIpProtoTypeKey(protocolType)).build();
        return intIpProtocolTypeId;
    }

    public static ProtocolTypes getProtocolType(NAPTEntryEvent.Protocol protocol) {
        ProtocolTypes protocolType = ProtocolTypes.TCP.toString().equals(protocol.toString()) ? ProtocolTypes.TCP : ProtocolTypes.UDP;
        return protocolType;
    }

    public static InstanceIdentifier<NaptSwitches> getNaptSwitchesIdentifier() {
        return InstanceIdentifier.create(NaptSwitches.class);
    }

    public static InstanceIdentifier<RouterToNaptSwitch> buildNaptSwitchRouterIdentifier(String routerId) {
        return InstanceIdentifier.create(NaptSwitches.class).child(RouterToNaptSwitch.class, new RouterToNaptSwitchKey(routerId));
    }

    public static String toStringIpAddress(byte[] ipAddress, Logger log)
    {
        String ip = "";
        if (ipAddress == null) {
            return ip;
        }

        try {
            ip = InetAddress.getByAddress(ipAddress).getHostAddress();
        } catch(UnknownHostException e) {
            log.error("NAT Service : Caught exception during toStringIpAddress()");
        }

        return ip;
    }

    public static String getGroupIdKey(String routerName){
        String groupIdKey = new String("snatmiss." + routerName);
        return groupIdKey;
    }

    public static long createGroupId(String groupIdKey,IdManagerService idManager) {
        AllocateIdInput getIdInput = new AllocateIdInputBuilder()
                .setPoolName(NatConstants.SNAT_IDPOOL_NAME).setIdKey(groupIdKey)
                .build();
        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            return rpcResult.getResult().getIdValue();
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.trace("", e);
        }
        return 0;
    }

    public static void removePrefixFromBGP(DataBroker broker , IBgpManager bgpManager, IFibManager fibManager, String rd, String prefix, Logger log) {
        try {
            LOG.info("REMOVE: Removing Fib entry rd {} prefix {}", rd, prefix);
            fibManager.removeFibEntry(broker, rd, prefix, null);
            bgpManager.withdrawPrefix(rd, prefix);
            LOG.info("REMOVE: Removed Fib entry rd {} prefix {}", rd, prefix);
        } catch(Exception e) {
            log.error("Delete prefix failed", e);
        }
    }

    public static FlowEntity buildFlowEntity(BigInteger dpnId, short tableId, BigInteger cookie, String flowId) {
        FlowEntity flowEntity = new FlowEntity(dpnId);
        flowEntity.setTableId(tableId);
        flowEntity.setCookie(cookie);
        flowEntity.setFlowId(flowId);
        return flowEntity;
    }

    public static FlowEntity buildFlowEntity(BigInteger dpnId, short tableId, String flowId) {
        FlowEntity flowEntity = new FlowEntity(dpnId);
        flowEntity.setTableId(tableId);
        flowEntity.setFlowId(flowId);
        return flowEntity;
    }

    public static IpPortMapping getIportMapping(DataBroker broker, long routerId) {
        Optional<IpPortMapping> getIportMappingData = read(broker, LogicalDatastoreType.CONFIGURATION, getIportMappingIdentifier(routerId));
        if(getIportMappingData.isPresent()) {
            return getIportMappingData.get();
        }
        return null;
    }

    public static InstanceIdentifier<IpPortMapping> getIportMappingIdentifier(long routerId) {
        return InstanceIdentifier.builder(IntextIpPortMap.class).child(IpPortMapping.class, new IpPortMappingKey(routerId)).build();
    }

    public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMapping> getIpMappingBuilder(Long routerId) {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMapping> idBuilder = InstanceIdentifier.builder(IntextIpMap.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMapping.class, new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMappingKey(routerId)).build();
        return idBuilder;
    }

    public static List<String> getExternalIpsForRouter(DataBroker dataBroker,Long routerId) {
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMapping> ipMappingOptional = read(dataBroker,
                LogicalDatastoreType.OPERATIONAL, getIpMappingBuilder(routerId));
        List<String> externalIps = new ArrayList<>();
        if (ipMappingOptional.isPresent()) {
            List<IpMap> ipMaps = ipMappingOptional.get().getIpMap();
            for (IpMap ipMap : ipMaps) {
                externalIps.add(ipMap.getExternalIp());
            }
            //remove duplicates
            Set<String> uniqueExternalIps = Sets.newHashSet(externalIps);
            externalIps = Lists.newArrayList(uniqueExternalIps);
            return externalIps;
        }
        return null;
    }

    public static HashMap<String,Long> getExternalIpsLabelForRouter(DataBroker dataBroker,Long routerId) {
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMapping> ipMappingOptional = read(dataBroker,
                LogicalDatastoreType.OPERATIONAL, getIpMappingBuilder(routerId));
        HashMap<String,Long> externalIpsLabel = new HashMap<>();
        if (ipMappingOptional.isPresent()) {
            List<IpMap> ipMaps = ipMappingOptional.get().getIpMap();
            for (IpMap ipMap : ipMaps) {
                externalIpsLabel.put(ipMap.getExternalIp(), ipMap.getLabel());
            }
            return externalIpsLabel;
        }
        return null;
    }
    /*
    container external-ips-counter {
        config false;
        list external-counters{
            key segment-id;
            leaf segment-id { type uint32; }
            list external-ip-counter {
                key external-ip;
                leaf external-ip { type string; }
                leaf counter { type uint8; }
            }
        }
    }
    */

    public static String getLeastLoadedExternalIp(DataBroker dataBroker, long segmentId){
        String leastLoadedExternalIp =  null;
        InstanceIdentifier<ExternalCounters> id = InstanceIdentifier.builder(ExternalIpsCounter.class).child(ExternalCounters.class, new ExternalCountersKey(segmentId)).build();
        Optional <ExternalCounters> externalCountersData = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        if (externalCountersData.isPresent()) {
            ExternalCounters externalCounter = externalCountersData.get();
            List<ExternalIpCounter> externalIpCounterList = externalCounter.getExternalIpCounter();
            short countOfLstLoadExtIp = 32767;
            for(ExternalIpCounter externalIpCounter : externalIpCounterList){
                String curExternalIp = externalIpCounter.getExternalIp();
                short countOfCurExtIp  = externalIpCounter.getCounter();
                if( countOfCurExtIp < countOfLstLoadExtIp ){
                    countOfLstLoadExtIp = countOfCurExtIp;
                    leastLoadedExternalIp = curExternalIp;
                }
            }
        }
        return leastLoadedExternalIp;
    }

    public static String[] getSubnetIpAndPrefix(DataBroker dataBroker, Uuid subnetId){
        String subnetIP = getSubnetIp(dataBroker, subnetId);
        if(subnetId != null){
            return getSubnetIpAndPrefix(subnetIP);
        }
        return null;
    }

    public static String getSubnetIp(DataBroker dataBroker, Uuid subnetId){
        InstanceIdentifier<Subnetmap> subnetmapId = InstanceIdentifier
                .builder(Subnetmaps.class)
                .child(Subnetmap.class, new SubnetmapKey(subnetId))
                .build();
        Optional<Subnetmap> removedSubnet = read(dataBroker, LogicalDatastoreType.CONFIGURATION, subnetmapId);
        if(removedSubnet.isPresent()) {
            Subnetmap subnetMapEntry = removedSubnet.get();
            return subnetMapEntry.getSubnetIp();
        }
        return null;

    }
    public static String[] getSubnetIpAndPrefix(String subnetString){
        String[] subnetSplit = subnetString.split("/");
        String subnetIp = subnetSplit[0];
        String subnetPrefix = "0";
        if (subnetSplit.length == 2) {
            subnetPrefix = subnetSplit[1];
        }
        return new String[] {subnetIp, subnetPrefix};
    }

    public static String[] getExternalIpAndPrefix(String leastLoadedExtIpAddr){
        String[] leastLoadedExtIpAddrSplit = leastLoadedExtIpAddr.split("/");
        String leastLoadedExtIp = leastLoadedExtIpAddrSplit[0];
        String leastLoadedExtIpPrefix = String.valueOf(NatConstants.DEFAULT_PREFIX);
        if (leastLoadedExtIpAddrSplit.length == 2) {
            leastLoadedExtIpPrefix = leastLoadedExtIpAddrSplit[1];
        }
        return new String[] {leastLoadedExtIp, leastLoadedExtIpPrefix};
    }

    public static List<BigInteger> getDpnsForRouter(DataBroker dataBroker, String routerUuid){
        InstanceIdentifier id = InstanceIdentifier.builder(NeutronRouterDpns.class).child(RouterDpnList.class, new RouterDpnListKey(routerUuid)).build();
        Optional<RouterDpnList> routerDpnListData = read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        List<BigInteger> dpns = new ArrayList<>();
        if (routerDpnListData.isPresent()) {
            List<DpnVpninterfacesList> dpnVpninterfacesList = routerDpnListData.get().getDpnVpninterfacesList();
            for (DpnVpninterfacesList dpnVpnInterface : dpnVpninterfacesList) {
                dpns.add(dpnVpnInterface.getDpnId());
            }
            return dpns;
        }
        return null;
    }

    public static long getBgpVpnId(DataBroker dataBroker, String routerName){
        long bgpVpnId = NatConstants.INVALID_ID;
        Uuid bgpVpnUuid = NatUtil.getVpnForRouter(dataBroker, routerName);
        if(bgpVpnUuid != null){
            bgpVpnId = NatUtil.getVpnId(dataBroker, bgpVpnUuid.getValue());
        }
        return bgpVpnId;
    }

    static org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface
    getConfiguredRouterInterface(DataBroker broker, String interfaceName) {
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface> optRouterInterface =
                read(broker, LogicalDatastoreType.CONFIGURATION, NatUtil
                .getRouterInterfaceId(interfaceName));
        if(optRouterInterface.isPresent()) {
            return optRouterInterface.get();
        }
        return null;
    }

    static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface>
    getRouterInterfaceId(String interfaceName) {
        return InstanceIdentifier.builder(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.RouterInterfaces.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterface.class,
                        new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.router.interfaces.RouterInterfaceKey(interfaceName)).build();
    }

    static void addToNeutronRouterDpnsMap(DataBroker broker, String routerName, String interfaceName,
                                     OdlInterfaceRpcService ifaceMgrRpcService, WriteTransaction writeOperTxn) {
        BigInteger dpId = getDpnForInterface(ifaceMgrRpcService, interfaceName);
        if(dpId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : Could not retrieve dp id for interface {} to handle router {} association model", interfaceName, routerName);
            return;
        }

        LOG.debug("NAT Service : Adding the Router {} and DPN {} for the Interface {} in the ODL-L3VPN : NeutronRouterDpn map",
                routerName, dpId, interfaceName);
        InstanceIdentifier<DpnVpninterfacesList> dpnVpnInterfacesListIdentifier = getRouterDpnId(routerName, dpId);

        Optional<DpnVpninterfacesList> optionalDpnVpninterfacesList = read(broker, LogicalDatastoreType
                .OPERATIONAL, dpnVpnInterfacesListIdentifier);
        org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces routerInterface =
                new RouterInterfacesBuilder().setKey(new RouterInterfacesKey(interfaceName)).setInterface(interfaceName).build();
        if (optionalDpnVpninterfacesList.isPresent()) {
            LOG.debug("NAT Service : RouterDpnList already present for the Router {} and DPN {} for the Interface {} in the " +
                    "ODL-L3VPN : NeutronRouterDpn map", routerName, dpId, interfaceName);
            writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL, dpnVpnInterfacesListIdentifier.child(
                    org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces.class, new RouterInterfacesKey(interfaceName)), routerInterface, true);
        } else {
            LOG.debug("NAT Service : Building new RouterDpnList for the Router {} and DPN {} for the Interface {} in the " +
                    "ODL-L3VPN : NeutronRouterDpn map", routerName, dpId, interfaceName);
            RouterDpnListBuilder routerDpnListBuilder = new RouterDpnListBuilder();
            routerDpnListBuilder.setRouterId(routerName);
            DpnVpninterfacesListBuilder dpnVpnList = new DpnVpninterfacesListBuilder().setDpnId(dpId);
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces> routerInterfaces =  new ArrayList<>();
            routerInterfaces.add(routerInterface);
            dpnVpnList.setRouterInterfaces(routerInterfaces);
            routerDpnListBuilder.setDpnVpninterfacesList(Arrays.asList(dpnVpnList.build()));
            writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL,
                    getRouterId(routerName),
                    routerDpnListBuilder.build(), true);
        }
    }

    static void addToDpnRoutersMap(DataBroker broker, String routerName, String interfaceName,
                                          OdlInterfaceRpcService ifaceMgrRpcService, WriteTransaction writeOperTxn) {
        BigInteger dpId = getDpnForInterface(ifaceMgrRpcService, interfaceName);
        if(dpId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : Could not retrieve dp id for interface {} to handle router {} association model", interfaceName, routerName);
            return;
        }

        LOG.debug("NAT Service : Adding the DPN {} and router {} for the Interface {} in the ODL-L3VPN : " +
                        "DPNRouters map",
                dpId, routerName, interfaceName);
        InstanceIdentifier<DpnRoutersList> dpnRoutersListIdentifier = getDpnRoutersId(dpId);

        Optional<DpnRoutersList> optionalDpnRoutersList = read(broker, LogicalDatastoreType.OPERATIONAL, dpnRoutersListIdentifier);

        if (optionalDpnRoutersList.isPresent()) {
            RoutersList routersList = new RoutersListBuilder().setKey(new RoutersListKey(routerName)).setRouter(routerName)
                    .build();
            List<RoutersList> routersListFromDs = optionalDpnRoutersList.get().getRoutersList();
            if(!routersListFromDs.contains(routersList)) {
                LOG.debug("NAT Service : Router {} not present for the DPN {}" +
                        " in the ODL-L3VPN : DPNRouters map", routerName, dpId);
                writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL, dpnRoutersListIdentifier.child(RoutersList.class, new
                        RoutersListKey(routerName)), routersList, true);
            }else{
                LOG.debug("NAT Service : Router {} already mapped to the DPN {} in the ODL-L3VPN : DPNRouters map",
                        routerName, dpId);
            }
        } else {
            LOG.debug("NAT Service : Building new DPNRoutersList for the Router {} present in the DPN {} " +
                    "ODL-L3VPN : DPNRouters map", routerName, dpId);
            DpnRoutersListBuilder dpnRoutersListBuilder = new DpnRoutersListBuilder();
            dpnRoutersListBuilder.setDpnId(dpId);
            RoutersListBuilder routersListBuilder = new RoutersListBuilder();
            routersListBuilder.setRouter(routerName);
            dpnRoutersListBuilder.setRoutersList(Arrays.asList(routersListBuilder.build()));
            writeOperTxn.merge(LogicalDatastoreType.OPERATIONAL,
                    getDpnRoutersId(dpId),
                    dpnRoutersListBuilder.build(), true);
        }
    }

    static void removeFromNeutronRouterDpnsMap(DataBroker broker, String routerName, String interfaceName,
                                                  BigInteger dpId, WriteTransaction writeOperTxn) {
        if(dpId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : Could not retrieve dp id for interface {} to handle router {} dissociation model", interfaceName, routerName);
            return;
        }
        InstanceIdentifier<DpnVpninterfacesList> routerDpnListIdentifier = getRouterDpnId(routerName, dpId);
        Optional<DpnVpninterfacesList> optionalRouterDpnList = NatUtil.read(broker, LogicalDatastoreType
                .OPERATIONAL, routerDpnListIdentifier);
        if (optionalRouterDpnList.isPresent()) {
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces> routerInterfaces = optionalRouterDpnList.get().getRouterInterfaces();
            org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces routerInterface = new RouterInterfacesBuilder().setKey(new RouterInterfacesKey(interfaceName)).setInterface(interfaceName).build();
            if (routerInterfaces != null && routerInterfaces.remove(routerInterface)) {
                if (routerInterfaces.isEmpty()) {
                    writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier);
                } else {
                    writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier.child(
                            org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces.class,
                            new RouterInterfacesKey(interfaceName)));
                }
            }
        }
    }

    static void removeFromNeutronRouterDpnsMap(DataBroker broker, String routerName,
                                               BigInteger dpId, WriteTransaction writeOperTxn) {
        if(dpId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : DPN ID is invalid for the router {} ", routerName);
            return;
        }

        InstanceIdentifier<DpnVpninterfacesList> routerDpnListIdentifier = getRouterDpnId(routerName, dpId);
        Optional<DpnVpninterfacesList> optionalRouterDpnList = NatUtil.read(broker, LogicalDatastoreType
                .OPERATIONAL, routerDpnListIdentifier);
        if (optionalRouterDpnList.isPresent()) {
            LOG.debug("NAT Service : Removing the dpn-vpninterfaces-list from the odl-l3vpn:neutron-router-dpns model " +
                            "for the router {}", routerName);
            writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier);
        }else{
            LOG.debug("NAT Service : dpn-vpninterfaces-list does not exist in the odl-l3vpn:neutron-router-dpns model " +
                    "for the router {}", routerName);
        }
    }

    static void removeFromNeutronRouterDpnsMap(DataBroker broker, String routerName, String vpnInterfaceName,
                                                  OdlInterfaceRpcService ifaceMgrRpcService, WriteTransaction writeOperTxn) {
        BigInteger dpId = getDpnForInterface(ifaceMgrRpcService, vpnInterfaceName);
        if(dpId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : Could not retrieve dp id for interface {} to handle router {} dissociation model", vpnInterfaceName, routerName);
            return;
        }
        InstanceIdentifier<DpnVpninterfacesList> routerDpnListIdentifier = getRouterDpnId(routerName, dpId);
        Optional<DpnVpninterfacesList> optionalRouterDpnList = read(broker, LogicalDatastoreType
                .OPERATIONAL, routerDpnListIdentifier);
        if (optionalRouterDpnList.isPresent()) {
            List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces> routerInterfaces = optionalRouterDpnList.get().getRouterInterfaces();
            org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces routerInterface = new RouterInterfacesBuilder().setKey(new RouterInterfacesKey(vpnInterfaceName)).setInterface(vpnInterfaceName).build();

            if (routerInterfaces != null && routerInterfaces.remove(routerInterface)) {
                if (routerInterfaces.isEmpty()) {
                    if (writeOperTxn != null) {
                        writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier);
                    } else {
                        MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier);
                    }
                } else {
                    if (writeOperTxn != null) {
                        writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier.child(
                                org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces.class,
                                new RouterInterfacesKey(vpnInterfaceName)));
                    } else {
                        MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, routerDpnListIdentifier.child(
                                org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.dpn.vpninterfaces.list.RouterInterfaces.class,
                                new RouterInterfacesKey(vpnInterfaceName)));
                    }
                }
            }
        }
    }

    static void removeFromDpnRoutersMap(DataBroker broker, String routerName, String vpnInterfaceName,
                                        OdlInterfaceRpcService ifaceMgrRpcService, WriteTransaction writeOperTxn) {
        BigInteger dpId = getDpnForInterface(ifaceMgrRpcService, vpnInterfaceName);
        if (dpId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : removeFromDpnRoutersMap() : Could not retrieve DPN ID for interface {} to handle router {} dissociation model",
                    vpnInterfaceName, routerName);
            return;
        }
        removeFromDpnRoutersMap(broker, routerName, vpnInterfaceName, dpId, ifaceMgrRpcService, writeOperTxn);
    }

    static void removeFromDpnRoutersMap(DataBroker broker, String routerName, String vpnInterfaceName, BigInteger curDpnId,
                                           OdlInterfaceRpcService ifaceMgrRpcService, WriteTransaction writeOperTxn) {
        /*
            1) Get the DpnRoutersList for the DPN.
            2) Get the RoutersList identifier for the DPN and router.
            3) Get the VPN interfaces for the router (routerList) through which it is connected to the DPN.
            4) If the removed VPN interface is the only interface through which the router is connected to the DPN,
             then remove RouterList.
         */

        LOG.debug("NAT Service : removeFromDpnRoutersMap() : Removing the DPN {} and router {} for the Interface {}" +
                " in the ODL-L3VPN : DPNRouters map", curDpnId, routerName, vpnInterfaceName);

        //Get the dpn-routers-list instance for the current DPN.
        InstanceIdentifier<DpnRoutersList> dpnRoutersListIdentifier = getDpnRoutersId(curDpnId);
        Optional<DpnRoutersList> dpnRoutersListData = read(broker, LogicalDatastoreType.OPERATIONAL,
                dpnRoutersListIdentifier);

        if (dpnRoutersListData == null || !dpnRoutersListData.isPresent()) {
            LOG.debug("NAT Service : dpn-routers-list is not present for DPN {} in the ODL-L3VPN:dpn-routers model",
                    curDpnId);
            return;
        }

        //Get the routers-list instance for the router on the current DPN only
        InstanceIdentifier<RoutersList> routersListIdentifier = getRoutersList(curDpnId, routerName);
        Optional<RoutersList> routersListData = read(broker, LogicalDatastoreType.OPERATIONAL, routersListIdentifier);

        if (routersListData == null || !routersListData.isPresent()) {
            LOG.debug("NAT Service : routers-list is not present for the DPN {} in the ODL-L3VPN:dpn-routers model",
                    curDpnId);
            return;
        }

        LOG.debug("NAT Service : Get the interfaces for the router {} from the NeutronVPN - router-interfaces-map",
                routerName);
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.
                interfaces.map.RouterInterfaces> routerInterfacesId = getRoutersInterfacesIdentifier(routerName);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.
                RouterInterfaces> routerInterfacesData = read(broker, LogicalDatastoreType.CONFIGURATION,
                routerInterfacesId);

        if (routerInterfacesData == null || !routerInterfacesData.isPresent()) {
            LOG.debug("NAT Service : Unable to get the routers list for the DPN {}. Possibly all subnets removed" +
                    " from router {} OR Router {} has been deleted. Hence DPN router model WILL be cleared ", curDpnId,
                    routerName, routerName);
            writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routersListIdentifier);
            return;
        }

        //Get the VM interfaces for the router on the current DPN only.
        List<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.Interfaces> vmInterfaces =
                routerInterfacesData.get().getInterfaces();
        if (vmInterfaces == null) {
            LOG.debug("NAT Service : VM interfaces are not present for the router {} in the NeutronVPN - router-interfaces-map", routerName);
            return;
        }

        //If the removed VPN interface is the only interface through which the router is connected to the DPN, then remove RouterList.
        for (org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.router.interfaces.Interfaces vmInterface :
                vmInterfaces) {
            String vmInterfaceName = vmInterface.getInterfaceId();
            BigInteger vmDpnId = getDpnForInterface(ifaceMgrRpcService, vmInterfaceName);
            if (vmDpnId.equals(BigInteger.ZERO) || !vmDpnId.equals(curDpnId)) {
                LOG.debug("NAT Service : DPN ID {} for the removed interface {} is not the same as that of the DPN ID for the checked interface {} ",
                        curDpnId, vpnInterfaceName, vmDpnId, vmInterfaceName);
                continue;
            }
            if(!vmInterfaceName.equalsIgnoreCase(vpnInterfaceName)) {
                LOG.debug("NAT Service : Router {} is present in the DPN {} through the other interface {} " +
                        "Hence DPN router model WOULD NOT be cleared", routerName, curDpnId, vmInterfaceName);
                return;
            }
        }
        LOG.debug("NAT Service : Router {} is present in the DPN {} only through the interface {} " +
                "Hence DPN router model WILL be cleared. Possibly last VM for the router " +
                "deleted in the DPN", routerName, curDpnId);
        writeOperTxn.delete(LogicalDatastoreType.OPERATIONAL, routersListIdentifier);

    }

    private static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfaces>
        getRoutersInterfacesIdentifier(String routerName){
        return InstanceIdentifier.builder(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.RouterInterfacesMap.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfaces.class,
                        new org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.router.interfaces.map.RouterInterfacesKey(new Uuid(routerName)))
                .build();
    }

    private static InstanceIdentifier<RoutersList> getRoutersList(BigInteger dpnId, String routerName) {
        return InstanceIdentifier.builder(DpnRouters.class)
                .child(DpnRoutersList.class, new DpnRoutersListKey(dpnId))
                .child(RoutersList.class, new RoutersListKey(routerName)).build();
    }

    public static BigInteger getDpnForInterface(OdlInterfaceRpcService interfaceManagerRpcService, String ifName) {
        BigInteger nodeId = BigInteger.ZERO;
        try {
            GetDpidFromInterfaceInput
                    dpIdInput =
                    new GetDpidFromInterfaceInputBuilder().setIntfName(ifName).build();
            Future<RpcResult<GetDpidFromInterfaceOutput>>
                    dpIdOutput =
                    interfaceManagerRpcService.getDpidFromInterface(dpIdInput);
            RpcResult<GetDpidFromInterfaceOutput> dpIdResult = dpIdOutput.get();
            if (dpIdResult.isSuccessful()) {
                nodeId = dpIdResult.getResult().getDpid();
            } else {
                LOG.error("NAT Service : Could not retrieve DPN Id for interface {}", ifName);
            }
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.error("NAT Service : Exception when getting dpn for interface {}", ifName,  e);
        }
        return nodeId;
    }

    public static List<ActionInfo> getEgressActionsForInterface(OdlInterfaceRpcService interfaceManager, String ifName,
            Long tunnelKey) {
        return getEgressActionsForInterface(interfaceManager, ifName, tunnelKey, 0);
    }

    public static List<ActionInfo> getEgressActionsForInterface(OdlInterfaceRpcService interfaceManager, String ifName,
            Long tunnelKey, int pos) {
        LOG.debug("NAT Service : getEgressActionsForInterface called for interface {}", ifName);
        GetEgressActionsForInterfaceInputBuilder egressActionsBuilder = new GetEgressActionsForInterfaceInputBuilder()
                .setIntfName(ifName);
        if (tunnelKey != null) {
            egressActionsBuilder.setTunnelKey(tunnelKey);
        }

        List<ActionInfo> listActionInfo = new ArrayList<>();
        try {
            Future<RpcResult<GetEgressActionsForInterfaceOutput>> result = interfaceManager
                    .getEgressActionsForInterface(egressActionsBuilder.build());
            RpcResult<GetEgressActionsForInterfaceOutput> rpcResult = result.get();
            if (!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to Get egress actions for interface {} returned with Errors {}", ifName,
                        rpcResult.getErrors());
            } else {
                List<Action> actions = rpcResult.getResult().getAction();
                for (Action action : actions) {
                    org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.Action actionClass = action
                            .getAction();
                    if (actionClass instanceof OutputActionCase) {
                        listActionInfo
                                .add(new ActionInfo(ActionType.output, new String[] { ((OutputActionCase) actionClass)
                                        .getOutputAction().getOutputNodeConnector().getValue() }, pos++));
                    } else if (actionClass instanceof PushVlanActionCase) {
                        listActionInfo.add(new ActionInfo(ActionType.push_vlan, new String[] {}, pos++));
                    } else if (actionClass instanceof SetFieldCase) {
                        if (((SetFieldCase) actionClass).getSetField().getVlanMatch() != null) {
                            int vlanVid = ((SetFieldCase) actionClass).getSetField().getVlanMatch().getVlanId()
                                    .getVlanId().getValue();
                            listActionInfo.add(new ActionInfo(ActionType.set_field_vlan_vid,
                                    new String[] { Long.toString(vlanVid) }, pos++));
                        }
                    } else if (actionClass instanceof NxActionResubmitRpcAddGroupCase) {
                        Short tableId = ((NxActionResubmitRpcAddGroupCase)actionClass).getNxResubmit().getTable();
                        listActionInfo.add(new ActionInfo(ActionType.nx_resubmit,
                            new String[] { tableId.toString() }, pos++));
                    } else if (actionClass instanceof NxActionRegLoadNodesNodeTableFlowApplyActionsCase) {
                        NxRegLoad nxRegLoad =
                            ((NxActionRegLoadNodesNodeTableFlowApplyActionsCase)actionClass).getNxRegLoad();
                        listActionInfo.add(new ActionInfo(ActionType.nx_load_reg_6,
                            new String[] { nxRegLoad.getDst().getStart().toString(),
                                nxRegLoad.getDst().getEnd().toString(),
                                nxRegLoad.getValue().toString(10)}, pos++));
                    }
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when egress actions for interface {}", ifName, e);
        }
        return listActionInfo;
    }

    public static Port getNeutronPortForRouterGetewayIp(DataBroker broker, IpAddress targetIP) {
        return getNeutronPortForIp(broker, targetIP, NeutronConstants.DEVICE_OWNER_GATEWAY_INF);
    }

    public static List<Port> getNeutronPorts(DataBroker broker) {
        InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports>
        portsIdentifier = InstanceIdentifier
                .create(Neutron.class)
                .child(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports.class);
        Optional<org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports> portsOptional = read(
                broker, LogicalDatastoreType.CONFIGURATION, portsIdentifier);

        if (!portsOptional.isPresent() || portsOptional.get().getPort() == null) {
            LOG.trace("No neutron ports found");
            return Collections.EMPTY_LIST;
        }

        return portsOptional.get().getPort();

    }

    public static Port getNeutronPortForIp(DataBroker broker,
        IpAddress targetIP, String deviceType) {
        List<Port> ports = getNeutronPorts(
                broker);

        for (Port port : ports) {
            if (deviceType.equals(port.getDeviceOwner()) && port.getFixedIps() != null) {
                for (FixedIps ip : port.getFixedIps()) {
                    if (Objects.equals(ip.getIpAddress(), targetIP)) {
                        return port;
                    }
                }
            }
        }

        return null;
    }

    public static Uuid getSubnetIdForFloatingIp(Port port, IpAddress targetIP) {
        if (port == null) {
            return null;
        }
        for (FixedIps ip : port.getFixedIps()) {
            if (Objects.equals(ip.getIpAddress(), targetIP)) {
                return ip.getSubnetId();
            }
        }

        return null;
    }

    public static Subnetmap getSubnetMap(DataBroker broker, Uuid subnetId) {
        InstanceIdentifier<Subnetmap> subnetmapId = InstanceIdentifier.builder(Subnetmaps.class)
                .child(Subnetmap.class, new SubnetmapKey(subnetId)).build();
        Optional<Subnetmap> subnetOpt = read(broker, LogicalDatastoreType.CONFIGURATION, subnetmapId);
        return subnetOpt.isPresent() ? subnetOpt.get() : null;
    }

    public static List<Uuid> getSubnetIdsFromNetworkId(DataBroker broker, Uuid networkId) {
        InstanceIdentifier<NetworkMap> id = InstanceIdentifier.builder(NetworkMaps.class)
                .child(NetworkMap.class, new NetworkMapKey(networkId)).build();
        Optional<NetworkMap> optionalNetworkMap = read(broker, LogicalDatastoreType.CONFIGURATION, id);
        return optionalNetworkMap.isPresent() ? optionalNetworkMap.get().getSubnetIdList() : null;
    }

    public static String getSubnetGwMac(DataBroker broker, Uuid subnetId, String vpnName) {
        if (subnetId == null) {
            return null;
        }

        InstanceIdentifier<Subnet> subnetInst = InstanceIdentifier.create(Neutron.class).child(Subnets.class)
                .child(Subnet.class, new SubnetKey(subnetId));
        Optional<Subnet> subnetOpt = read(broker, LogicalDatastoreType.CONFIGURATION, subnetInst);
        if (!subnetOpt.isPresent()) {
            return null;
        }

        IpAddress gatewayIp = subnetOpt.get().getGatewayIp();
        if (gatewayIp == null) {
            LOG.trace("No GW ip found for subnet {}", subnetId.getValue());
            return null;
        }

        InstanceIdentifier<VpnPortipToPort> portIpInst = InstanceIdentifier.builder(NeutronVpnPortipPortData.class)
                .child(VpnPortipToPort.class, new VpnPortipToPortKey(gatewayIp.getIpv4Address().getValue(), vpnName))
                .build();
        Optional<VpnPortipToPort> portIpToPortOpt = read(broker, LogicalDatastoreType.OPERATIONAL, portIpInst);
        if (!portIpToPortOpt.isPresent()) {
            LOG.trace("No resolution was found to GW ip {} in subnet {}", gatewayIp, subnetId.getValue());
            return null;
        }

        return portIpToPortOpt.get().getMacAddress();
    }

    public static boolean isIPv6Subnet(String prefix) {
        IpPrefix ipPrefix = new IpPrefix(prefix.toCharArray());
        if (ipPrefix.getIpv6Prefix() != null) {
            return true;
        }
        return false;
    }

    static InstanceIdentifier<DpnRoutersList> getDpnRoutersId(BigInteger dpnId) {
        return InstanceIdentifier.builder(DpnRouters.class)
                .child(DpnRoutersList.class, new DpnRoutersListKey(dpnId)).build();
    }

    static InstanceIdentifier<DpnVpninterfacesList> getRouterDpnId(String routerName, BigInteger dpnId) {
        return InstanceIdentifier.builder(NeutronRouterDpns.class)
                .child(RouterDpnList.class, new RouterDpnListKey(routerName))
                .child(DpnVpninterfacesList.class, new DpnVpninterfacesListKey(dpnId)).build();
    }

    static org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface getInterface(DataBroker broker, String interfaceName) {
        Optional<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> optInterface =
                read(broker, LogicalDatastoreType.CONFIGURATION, getInterfaceIdentifier(interfaceName));
        if(optInterface.isPresent()) {
            return optInterface.get();
        }
        return null;
    }

    static InstanceIdentifier<RouterDpnList> getRouterId(String routerName) {
        return InstanceIdentifier.builder(NeutronRouterDpns.class)
                .child(RouterDpnList.class, new RouterDpnListKey(routerName)).build();
    }

    protected static String getFloatingIpPortMacFromFloatingIpId(DataBroker broker, Uuid floatingIpId) {
        InstanceIdentifier id = buildfloatingIpIdToPortMappingIdentifier(floatingIpId);
        Optional<FloatingIpIdToPortMapping> optFloatingIpIdToPortMapping = read(broker, LogicalDatastoreType
                        .CONFIGURATION, id);
        if (optFloatingIpIdToPortMapping.isPresent()) {
            return optFloatingIpIdToPortMapping.get().getFloatingIpPortMacAddress();
        }
        return null;
    }

    protected static Uuid getFloatingIpPortSubnetIdFromFloatingIpId(DataBroker broker, Uuid floatingIpId) {
        InstanceIdentifier id = buildfloatingIpIdToPortMappingIdentifier(floatingIpId);
        Optional<FloatingIpIdToPortMapping> optFloatingIpIdToPortMapping = read(broker, LogicalDatastoreType
                .CONFIGURATION, id);
        if (optFloatingIpIdToPortMapping.isPresent()) {
            return optFloatingIpIdToPortMapping.get().getFloatingIpPortSubnetId();
        }
        return null;
    }

    static InstanceIdentifier<FloatingIpIdToPortMapping> buildfloatingIpIdToPortMappingIdentifier (Uuid floatingIpId) {
        return InstanceIdentifier.builder(FloatingIpPortInfo.class).child(FloatingIpIdToPortMapping.class, new
                FloatingIpIdToPortMappingKey(floatingIpId)).build();
    }

    static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> getInterfaceIdentifier(String interfaceName) {
        return InstanceIdentifier.builder(Interfaces.class)
                .child(
                        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface.class, new InterfaceKey(interfaceName)).build();
    }
    static final FutureCallback<Void> DEFAULT_CALLBACK =
            new FutureCallback<Void>() {
                @Override
                public void onSuccess(Void result) {
                    LOG.debug("NAT Service : Success in Datastore operation");
                }

                @Override
                public void onFailure(Throwable error) {
                    LOG.error("NAT Service : Error in Datastore operation", error);
                }

                ;
            };

    static <T extends DataObject> void delete(DataBroker broker, LogicalDatastoreType datastoreType,
                                                     InstanceIdentifier<T> path) {
        delete(broker, datastoreType, path, DEFAULT_CALLBACK);
    }

   static <T extends DataObject> void delete(DataBroker broker, LogicalDatastoreType datastoreType,
                                                     InstanceIdentifier<T> path, FutureCallback<Void> callback) {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.delete(datastoreType, path);
        Futures.addCallback(tx.submit(), callback);
    }
    static Interface getInterfaceStateFromOperDS(DataBroker dataBroker, String interfaceName) {
        InstanceIdentifier<Interface> ifStateId =
                buildStateInterfaceId(interfaceName);
        Optional<Interface> ifStateOptional = read(dataBroker, LogicalDatastoreType.OPERATIONAL, ifStateId);
        if (ifStateOptional.isPresent()) {
            return ifStateOptional.get();
        }

        return null;
    }

    static InstanceIdentifier<Interface>
    buildStateInterfaceId(String interfaceName) {
        InstanceIdentifier.InstanceIdentifierBuilder<Interface> idBuilder =
                InstanceIdentifier.builder(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState.class)
                        .child(Interface.class,
                                new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.InterfaceKey(interfaceName));
        InstanceIdentifier<Interface> id = idBuilder.build();
        return id;
    }
}
