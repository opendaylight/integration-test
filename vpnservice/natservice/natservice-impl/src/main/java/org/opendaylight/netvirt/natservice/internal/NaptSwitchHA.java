/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.natservice.internal;

import com.google.common.base.Optional;
import com.google.common.collect.Sets;

import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.GroupEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.FibRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetTunnelInterfaceNameInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetTunnelInterfaceNameOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalNetworks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ProtocolTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.networks.NetworksKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.IntextIpProtocolType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.ip.port.map.IpPortExternal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitchKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.VpnRpcService;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.HashMap;

public class NaptSwitchHA {
    private static final Logger LOG = LoggerFactory.getLogger(NaptSwitchHA.class);
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private final ItmRpcService itmManager;
    private final OdlInterfaceRpcService interfaceManager;
    private final IdManagerService idManager;
    private final NAPTSwitchSelector naptSwitchSelector;
    private final ExternalRoutersListener externalRouterListener;
    private final IBgpManager bgpManager;
    private final VpnRpcService vpnService;
    private final FibRpcService fibService;
    private final IFibManager fibManager;
    private List<String> externalIpsCache;
    private HashMap<String,Long> externalIpsLabel;

    public NaptSwitchHA(final DataBroker dataBroker, final IMdsalApiManager mdsalManager,
                        final ExternalRoutersListener externalRouterListener,
                        final ItmRpcService itmManager,
                        final OdlInterfaceRpcService interfaceManager,
                        final IdManagerService idManager,
                        final NAPTSwitchSelector naptSwitchSelector,
                        final IBgpManager bgpManager,
                        final VpnRpcService vpnService,
                        final FibRpcService fibService,
                        final IFibManager fibManager) {
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.externalRouterListener = externalRouterListener;
        this.itmManager = itmManager;
        this.interfaceManager = interfaceManager;
        this.idManager = idManager;
        this.naptSwitchSelector = naptSwitchSelector;
        this.bgpManager = bgpManager;
        this.vpnService = vpnService;
        this.fibService =fibService;
        this.fibManager = fibManager;
    }

    /* This method checks the switch that gone down is a NaptSwitch for a router.
       If it is a NaptSwitch
          1) selects new NAPT switch
          2) installs nat flows in new NAPT switch
          table 21(FIB)->26(PSNAT)->group(resubmit/napttunnel)->36(Terminating)->46(outbound)->47(resubmit)->21
          3) modify the group and miss entry flow in other vSwitches pointing to newNaptSwitch
          4) Remove nat flows in oldNaptSwitch
     */
    /*public void handleNaptSwitchDown(BigInteger dpnId){

        LOG.debug("handleNaptSwitchDown method is called with dpnId {}",dpnId);
        BigInteger naptSwitch;
        try {
            NaptSwitches naptSwitches = NatUtil.getNaptSwitch(dataBroker);
            if (naptSwitches == null || naptSwitches.getRouterToNaptSwitch() == null || naptSwitches.getRouterToNaptSwitch().isEmpty()) {
                LOG.debug("NaptSwitchDown: NaptSwitch is not allocated for none of the routers");
                return;
            }
            for (RouterToNaptSwitch routerToNaptSwitch : naptSwitches.getRouterToNaptSwitch()) {
                String routerName = routerToNaptSwitch.getRouterName();
                naptSwitch = routerToNaptSwitch.getPrimarySwitchId();
                boolean naptStatus = isNaptSwitchDown(routerName,dpnId,naptSwitch);
                if (!naptStatus) {
                    LOG.debug("NaptSwitchDown: Switch with DpnId {} is not naptSwitch for router {}",
                            dpnId, routerName);
                } else {
                    removeSnatFlowsInOldNaptSwitch(routerName,naptSwitch);
                    return;
                }
            }
        } catch (Exception ex) {
            LOG.error("Exception in handleNaptSwitchDown method {}",ex);
        }
    }*/

    protected void removeSnatFlowsInOldNaptSwitch(String routerName, BigInteger naptSwitch,HashMap<String,Long> externalIpmap) {
        externalIpsLabel = externalIpmap;
        //remove SNAT flows in old NAPT SWITCH
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("Invalid routerId returned for routerName {}",routerName);
            return;
        }

        //Remove the Terminating Service table entry which forwards the packet to Outbound NAPT Table
        String tsFlowRef = externalRouterListener.getFlowRefTs(naptSwitch, NwConstants.INTERNAL_TUNNEL_TABLE, routerId);
        FlowEntity tsNatFlowEntity = NatUtil.buildFlowEntity(naptSwitch, NwConstants.INTERNAL_TUNNEL_TABLE, tsFlowRef);

        LOG.info("Remove the flow in table {} for the old napt switch with the DPN ID {} and router ID {}"
                ,NwConstants.INTERNAL_TUNNEL_TABLE, naptSwitch, routerId);
        mdsalManager.removeFlow(tsNatFlowEntity);

        //Remove the Outbound flow entry which forwards the packet to Outbound NAPT Table
        String outboundNatFlowRef = externalRouterListener.getFlowRefOutbound(naptSwitch, NwConstants.OUTBOUND_NAPT_TABLE, routerId);
        FlowEntity outboundNatFlowEntity = NatUtil.buildFlowEntity(naptSwitch,
                NwConstants.OUTBOUND_NAPT_TABLE, outboundNatFlowRef);
        LOG.info("Remove the flow in table {} for the old napt switch with the DPN ID {} and router ID {}"
                ,NwConstants.OUTBOUND_NAPT_TABLE, naptSwitch, routerId);
        mdsalManager.removeFlow(outboundNatFlowEntity);

        //Remove the NAPT_PFIB_TABLE(47) flow entry forwards the packet to Fib Table for inbound traffic matching on the router ID.
        String naptPFibflowRef = externalRouterListener.getFlowRefTs(naptSwitch, NwConstants.NAPT_PFIB_TABLE, routerId);
        FlowEntity naptPFibFlowEntity = NatUtil.buildFlowEntity(naptSwitch, NwConstants.NAPT_PFIB_TABLE, naptPFibflowRef);
        LOG.info("Remove the flow in table {} for the old napt switch with the DPN ID {} and router ID {}",
                NwConstants.NAPT_PFIB_TABLE, naptSwitch, routerId);
        mdsalManager.removeFlow(naptPFibFlowEntity);

        //Remove the NAPT_PFIB_TABLE(47) flow entry forwards the packet to Fib Table for outbound traffic matching on the vpn ID.
        boolean switchSharedByRouters = false;
        Uuid extNetworkId = NatUtil.getNetworkIdFromRouterId(dataBroker, routerId);
        if (extNetworkId != null) {
            List<String> routerNamesAssociated = getRouterIdsForExtNetwork(extNetworkId);
            if (routerNamesAssociated != null) {
                for (String routerNameAssociated : routerNamesAssociated) {
                    if (!routerNameAssociated.equals(routerName)) {
                        Long routerIdAssociated = NatUtil.getVpnId(dataBroker,routerNameAssociated);
                        BigInteger naptDpn = NatUtil.getPrimaryNaptfromRouterId(dataBroker,routerIdAssociated);
                        if (naptDpn != null && naptDpn.equals(naptSwitch)) {
                            LOG.debug("Napt switch {} is also acting as primary for router {}",routerIdAssociated);
                            switchSharedByRouters = true;
                            break;
                        }
                    }
                }
                if (!switchSharedByRouters) {
                    Long vpnId = getVpnIdForRouter(routerId);
                    if (vpnId != NatConstants.INVALID_ID) {
                        String naptFibflowRef = externalRouterListener.getFlowRefTs(naptSwitch, NwConstants.NAPT_PFIB_TABLE, vpnId);
                        FlowEntity naptFibFlowEntity = NatUtil.buildFlowEntity(naptSwitch, NwConstants.NAPT_PFIB_TABLE,naptFibflowRef);
                        LOG.info("Remove the flow in table {} for the old napt switch with the DPN ID {} and vpnId {}",
                                NwConstants.NAPT_PFIB_TABLE, naptSwitch, vpnId);
                        mdsalManager.removeFlow(naptFibFlowEntity);
                    } else {
                        LOG.error("Invalid vpnId retrieved for routerId {}",routerId);
                        return;
                    }
                }
            }
        }

        //Remove Fib entries,tables 20->44 ,36-> 44
        String vpnName = getExtNetworkVpnName(routerId);
        if (vpnName == null) {
            LOG.debug("Vpn is not associated to externalN/w of router {}",routerName);
        } else {
            if (externalIpsLabel != null) {
                for (String externalIp : externalIpsLabel.keySet()) {
                    Long label = externalIpsLabel.get(externalIp);
                    externalRouterListener.delFibTsAndReverseTraffic(naptSwitch, routerId, externalIp, vpnName,label);
                    LOG.debug("Successfully removed fib entries in old naptswitch {} for router {} and externalIps {} label {}",
                            naptSwitch, routerId,externalIp,label);
                }
            } else {
                List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker,routerId);
                if (externalIps != null) {
                    Uuid networkId = NatUtil.getNetworkIdFromRouterId(dataBroker, routerId);
                    if (networkId != null) {
                        externalRouterListener.clearFibTsAndReverseTraffic(naptSwitch, routerId, networkId, externalIps, null);
                        LOG.debug("Successfully removed fib entries in old naptswitch {} for router {} with networkId {} and externalIps {}",
                                    naptSwitch,routerId,networkId,externalIps);
                    } else {
                        LOG.debug("External network not associated to router {}", routerId);
                    }
                } else {
                    LOG.debug("ExternalIps not found for router {}",routerName);
                }
            }
        }

        //For the router ID get the internal IP , internal port and the corresponding external IP and external Port.
        IpPortMapping ipPortMapping = NatUtil.getIportMapping(dataBroker, routerId);
        if (ipPortMapping == null || ipPortMapping.getIntextIpProtocolType() == null || ipPortMapping.getIntextIpProtocolType().isEmpty()) {
            LOG.debug("No Internal Ip Port mapping associated to router {}, no flows need to be removed in" +
                    "oldNaptSwitch {}", routerId, naptSwitch);
            return;
        }
        BigInteger cookieSnatFlow = NatUtil.getCookieNaptFlow(routerId);
        List<IntextIpProtocolType> intextIpProtocolTypes = ipPortMapping.getIntextIpProtocolType();
        for(IntextIpProtocolType intextIpProtocolType : intextIpProtocolTypes) {
            if (intextIpProtocolType.getIpPortMap() == null || intextIpProtocolType.getIpPortMap().isEmpty()) {
                LOG.debug("No {} session associated to router {},no flows need to be removed in oldNaptSwitch {}",
                        intextIpProtocolType.getProtocol(),routerId,naptSwitch);
                break;
            }
            List<IpPortMap> ipPortMaps = intextIpProtocolType.getIpPortMap();
            for(IpPortMap ipPortMap : ipPortMaps) {
                String ipPortInternal = ipPortMap.getIpPortInternal();
                String[] ipPortParts = ipPortInternal.split(":");
                if(ipPortParts.length != 2) {
                    LOG.error("Unable to retrieve the Internal IP and port");
                    continue;
                }
                String internalIp = ipPortParts[0];
                String internalPort = ipPortParts[1];

                //Build and remove flow in outbound NAPT table
                String switchFlowRef = NatUtil.getNaptFlowRef(naptSwitch, NwConstants.OUTBOUND_NAPT_TABLE, String.valueOf(routerId),
                        internalIp, Integer.valueOf(internalPort));
                FlowEntity outboundNaptFlowEntity = NatUtil.buildFlowEntity(naptSwitch, NwConstants.OUTBOUND_NAPT_TABLE,
                        cookieSnatFlow, switchFlowRef);

                LOG.info("Remove the flow in table {} for old napt switch with the DPN ID {} and router ID {}",
                        NwConstants.OUTBOUND_NAPT_TABLE,naptSwitch, routerId);
                mdsalManager.removeFlow(outboundNaptFlowEntity);

                IpPortExternal ipPortExternal = ipPortMap.getIpPortExternal();
                if (ipPortExternal == null) {
                    LOG.debug("External Ipport mapping not found for internalIp {} with port {} for router", internalIp,
                            internalPort, routerId);
                    continue;
                }
                String externalIp = ipPortExternal.getIpAddress();
                int externalPort = ipPortExternal.getPortNum();

                //Build and remove flow in  inbound NAPT table
                switchFlowRef = NatUtil.getNaptFlowRef(naptSwitch, NwConstants.INBOUND_NAPT_TABLE, String.valueOf(routerId),
                        externalIp, externalPort);
                FlowEntity inboundNaptFlowEntity = NatUtil.buildFlowEntity(naptSwitch, NwConstants.INBOUND_NAPT_TABLE,
                        cookieSnatFlow, switchFlowRef);

                LOG.info("Remove the flow in table {} for old napt switch with the DPN ID {} and router ID {}",
                        NwConstants.INBOUND_NAPT_TABLE,naptSwitch, routerId);
                mdsalManager.removeFlow(inboundNaptFlowEntity);
            }
        }

    }

    private List<String> getRouterIdsForExtNetwork(Uuid extNetworkId) {
        List<String> routerUuidsAsString = new ArrayList<>();
        InstanceIdentifier<Networks> extNetwork = InstanceIdentifier.builder(ExternalNetworks.class).child
                (Networks.class, new NetworksKey(extNetworkId)).build();
        Optional<Networks> extNetworkData = NatUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, extNetwork);
        if (extNetworkData.isPresent()) {
            List<Uuid> routerUuids= extNetworkData.get().getRouterIds();
            if (routerUuids != null){
                for(Uuid routerUuid : routerUuids){
                    routerUuidsAsString.add(routerUuid.getValue());
                }
            }
        }
        return routerUuidsAsString;
    }
    public boolean isNaptSwitchDown(String routerName, BigInteger dpnId , BigInteger naptSwitch,Long routerVpnId,List<String> externalIpCache){
        return isNaptSwitchDown(routerName, dpnId , naptSwitch, routerVpnId, externalIpCache, true);
    }

    public boolean isNaptSwitchDown(String routerName, BigInteger dpnId , BigInteger naptSwitch,Long routerVpnId,List<String> externalIpCache, boolean isClearBgpRts) {
        externalIpsCache = externalIpCache;
        if (!naptSwitch.equals(dpnId)) {
            LOG.debug("DpnId {} is not a naptSwitch {} for Router {}",dpnId, naptSwitch, routerName);
            return false;
        }
        LOG.debug("NaptSwitch {} is down for Router {}", naptSwitch, routerName);
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("Invalid routerId returned for routerName {}", routerName);
            return true;
        }
        //elect a new NaptSwitch
        naptSwitch = naptSwitchSelector.selectNewNAPTSwitch(routerName);
        if (naptSwitch.equals(BigInteger.ZERO)) {
            LOG.error("NAT Service : No napt switch is elected since all the switches for router {} are down. SNAT IS" +
                    " NOT SUPPORTED FOR ROUTER {}",routerName);
            boolean naptUpdatedStatus = updateNaptSwitch(routerName,naptSwitch);
            if(!naptUpdatedStatus) {
                LOG.debug("Failed to update naptSwitch {} for router {} in ds", naptSwitch,routerName);
            }
            //clearBgpRoutes
            if (externalIpsCache != null) {
                String vpnName = getExtNetworkVpnName(routerId);
                if (vpnName != null) {
                    //List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker, routerId);
                    //if (externalIps != null) {
                    if(isClearBgpRts){
                        LOG.debug("NAT Service : Clearing both FIB entries and the BGP routes");
                        for (String externalIp : externalIpsCache) {
                            externalRouterListener.clearBgpRoutes(externalIp, vpnName);
                        }
                    }else{
                        LOG.debug("NAT Service : Clearing the FIB entries but not the BGP routes");
                        String rd = NatUtil.getVpnRd(dataBroker, vpnName);
                        for (String externalIp : externalIpsCache) {
                            LOG.debug("NAT Service : Removing Fib entry rd {} prefix {}", rd, externalIp);
                            fibManager.removeFibEntry(dataBroker, rd, externalIp, null);
                        }
                    }
                } else {
                    LOG.debug("vpn is not associated to extn/w for router {}", routerName);
                }
            } else {
                LOG.debug("No ExternalIps found for subnets under router {}, no bgp routes need to be cleared",routerName);
            }
            return true;
        }
        //checking elected switch health status
        if (!getSwitchStatus(naptSwitch)) {
            LOG.error("Newly elected Napt switch {} for router {} is down", naptSwitch, routerName);
            return true;
        }
        LOG.debug("New NaptSwitch {} is up for Router {} and can proceed for flow installation",naptSwitch, routerName);
        //update napt model for new napt switch
        boolean naptUpdated = updateNaptSwitch(routerName, naptSwitch);
        if (naptUpdated) {
            //update group of ordinary switch point to naptSwitch tunnel port
            updateNaptSwitchBucketStatus(routerName, naptSwitch);
        } else {
            LOG.error("Failed to update naptSwitch model for newNaptSwitch {} for router {}",naptSwitch, routerName);
        }

        //update table26 forward packets to table46(outbound napt table)
        FlowEntity flowEntity = buildSnatFlowEntityForNaptSwitch(naptSwitch, routerName, routerVpnId, NatConstants.ADD_FLOW);
        if (flowEntity == null) {
            LOG.debug("Failed to populate flowentity for router {} in naptSwitch {}", routerName, naptSwitch);
        } else {
            LOG.debug("Successfully installed flow in naptSwitch {} for router {}", naptSwitch, routerName);
            mdsalManager.installFlow(flowEntity);
        }

        installSnatFlows(routerName,routerId,naptSwitch,routerVpnId);

        boolean flowInstalledStatus = handleNatFlowsInNewNaptSwitch(routerId, dpnId, naptSwitch,routerVpnId);
        if (flowInstalledStatus) {
            LOG.debug("Installed all active session flows in newNaptSwitch {} for routerName {}", naptSwitch, routerName);
        } else {
            LOG.error("Failed to install flows in newNaptSwitch {} for routerId {}", naptSwitch, routerId);
        }

        //remove group in new naptswitch, coz this switch acted previously as ordinary switch
        long groupId = NatUtil.createGroupId(NatUtil.getGroupIdKey(routerName), idManager);
        GroupEntity groupEntity = null;
        try {
            groupEntity = MDSALUtil.buildGroupEntity(naptSwitch, groupId, routerName,
                    GroupTypes.GroupAll, null);
            LOG.info("NAT Service : Removing NAPT Group in new naptSwitch {}", naptSwitch);
            mdsalManager.removeGroup(groupEntity);
        } catch (Exception ex) {
            LOG.debug("NAT Service : Failed to remove group in new naptSwitch {} : {}",groupEntity,ex);
        }
        return true;
    }

    private String getExtNetworkVpnName(long routerId) {
        Uuid networkId = NatUtil.getNetworkIdFromRouterId(dataBroker, routerId);
        if(networkId == null) {
            LOG.error("networkId is null for the router ID {}", routerId);
        } else {
            final String vpnName = NatUtil.getAssociatedVPN(dataBroker, networkId, LOG);
            if (vpnName != null) {
                LOG.debug("retrieved vpn name {} associated with ext nw {} in router {}",
                        vpnName,networkId,routerId);
                return vpnName;
            } else {
                LOG.error("No VPN associated with ext nw {} belonging to routerId {}",
                        networkId, routerId);
            }
        }
        return null;
    }

    public void updateNaptSwitchBucketStatus(String routerName, BigInteger naptSwitch) {
        LOG.debug("updateNaptSwitchBucketStatus method is called");

        List<BigInteger> dpnList = naptSwitchSelector.getDpnsForVpn(routerName);
        //List<BigInteger> dpnList = getDpnListForRouter(routerName);
        if (dpnList == null || dpnList.isEmpty()) {
            LOG.debug("No switches found for router {}",routerName);
            return;
        }
        for (BigInteger dpn : dpnList) {
            if (!dpn.equals(naptSwitch)) {
                LOG.debug("Updating SNAT_TABLE missentry for DpnId {} which is not naptSwitch for router {}",dpn,routerName);
                List<BucketInfo> bucketInfoList = handleGroupInNeighborSwitches(dpn, routerName, naptSwitch);
                if (bucketInfoList == null) {
                    LOG.debug("Failed to populate bucketInfo for orinaryswitch {} whose naptSwitch {} for router {} ",
                            dpn,naptSwitch,routerName);
                    return;
                }
                modifySnatGroupEntry(dpn, bucketInfoList, routerName);
            }
        }
    }

    private boolean handleNatFlowsInNewNaptSwitch(Long routerId,BigInteger oldNaptSwitch, BigInteger newNaptSwitch,Long routerVpnId) {
        LOG.debug("Proceeding to install flows in newNaptSwitch {} for routerId {}", newNaptSwitch,routerId);
        IpPortMapping ipPortMapping = NatUtil.getIportMapping(dataBroker,routerId);
        if (ipPortMapping == null || ipPortMapping.getIntextIpProtocolType() == null || ipPortMapping.getIntextIpProtocolType().isEmpty()) {
            LOG.debug("No Internal Ip Port mapping associated to router {}, no flows need to be installed in" +
                    "newNaptSwitch {}", routerId, newNaptSwitch);
            return true;
        }
        //getvpnId
        Long vpnId = getVpnIdForRouter(routerId);
        if (vpnId == NatConstants.INVALID_ID) {
            LOG.error("Invalid vpnId for routerId {}",routerId);
            return false;
        }
        Long bgpVpnId;
        if(routerId.equals(routerVpnId)) {
            bgpVpnId = NatConstants.INVALID_ID;
        } else {
            bgpVpnId = routerVpnId;
        }
        LOG.debug("retrieved bgpVpnId {} for router {}",bgpVpnId,routerId);
        for (IntextIpProtocolType protocolType : ipPortMapping.getIntextIpProtocolType()) {
            if (protocolType.getIpPortMap() == null || protocolType.getIpPortMap().isEmpty()) {
                LOG.debug("No {} session associated to router {}", protocolType.getProtocol(), routerId);
                return true;
            }
            for (IpPortMap intIpPortMap : protocolType.getIpPortMap()) {
                String internalIpAddress = intIpPortMap.getIpPortInternal().split(":")[0];
                String intportnum = intIpPortMap.getIpPortInternal().split(":")[1];

                //Get the external IP address and the port from the model
                NAPTEntryEvent.Protocol proto = protocolType.getProtocol().toString().equals(ProtocolTypes.TCP.toString())
                        ? NAPTEntryEvent.Protocol.TCP : NAPTEntryEvent.Protocol.UDP;
                IpPortExternal ipPortExternal = NatUtil.getExternalIpPortMap(dataBroker, routerId,
                        internalIpAddress, intportnum, proto);
                if (ipPortExternal == null) {
                    LOG.debug("External Ipport mapping is not found for internalIp {} with port {}", internalIpAddress, intportnum);
                    continue;
                }
                String externalIpAddress = ipPortExternal.getIpAddress();
                Integer extportNumber = ipPortExternal.getPortNum();
                LOG.debug("ExternalIPport {}:{} mapping for internal ipport {}:{}",externalIpAddress,extportNumber,
                        internalIpAddress,intportnum);

                SessionAddress sourceAddress = new SessionAddress(internalIpAddress,Integer.valueOf(intportnum));
                SessionAddress externalAddress = new SessionAddress(externalIpAddress,extportNumber);

                //checking naptSwitch status before installing flows
                if(getSwitchStatus(newNaptSwitch)) {
                    //Install the flow in newNaptSwitch Outbound NAPT table.
                    try {
                        NaptEventHandler.buildAndInstallNatFlows(newNaptSwitch, NwConstants.OUTBOUND_NAPT_TABLE,
                                vpnId,  routerId, bgpVpnId, sourceAddress, externalAddress, proto);
                    } catch (Exception ex) {
                        LOG.error("Failed to add flow in OUTBOUND_NAPT_TABLE for routerid {} dpnId {} ipport {}:{} proto {}" +
                                "extIpport {}:{} BgpVpnId {} - {}", routerId, newNaptSwitch, internalIpAddress
                                , intportnum, proto, externalAddress, extportNumber,bgpVpnId,ex);
                        return false;
                    }
                    LOG.debug("Successfully installed a flow in Primary switch {} Outbound NAPT table for router {} " +
                            "ipport {}:{} proto {} extIpport {}:{} BgpVpnId {}", newNaptSwitch,routerId, internalIpAddress
                            , intportnum, proto, externalAddress, extportNumber,bgpVpnId);
                    //Install the flow in newNaptSwitch Inbound NAPT table.
                    try {
                        NaptEventHandler.buildAndInstallNatFlows(newNaptSwitch, NwConstants.INBOUND_NAPT_TABLE,
                                vpnId, routerId, bgpVpnId, externalAddress, sourceAddress, proto);
                    } catch (Exception ex) {
                        LOG.error("Failed to add flow in INBOUND_NAPT_TABLE for routerid {} dpnId {} extIpport{}:{} proto {} " +
                                        "ipport {}:{} BgpVpnId {}", routerId, newNaptSwitch, externalAddress, extportNumber, proto,
                                internalIpAddress, intportnum,bgpVpnId);
                        return false;
                    }
                    LOG.debug("Successfully installed a flow in Primary switch {} Inbound NAPT table for router {} " +
                            "ipport {}:{} proto {} extIpport {}:{} BgpVpnId {}", newNaptSwitch,routerId, internalIpAddress
                            , intportnum, proto, externalAddress, extportNumber,bgpVpnId);

                } else {
                    LOG.error("NewNaptSwitch {} gone down while installing flows from oldNaptswitch {}",
                            newNaptSwitch,oldNaptSwitch);
                    return false;
                }
            }
        }
        return true;
    }

    private Long getVpnIdForRouter(Long routerId) {
        try {
            //getvpnId
            Uuid networkId = NatUtil.getNetworkIdFromRouterId(dataBroker, routerId);
            if (networkId == null) {
                LOG.debug("network is not associated to router {}", routerId);
            } else {
                Uuid vpnUuid = NatUtil.getVpnIdfromNetworkId(dataBroker, networkId);
                if (vpnUuid == null) {
                    LOG.debug("vpn is not associated for network {} in router {}", networkId, routerId);
                } else {
                    Long vpnId = NatUtil.getVpnId(dataBroker, vpnUuid.getValue());
                    if (vpnId > 0) {
                        LOG.debug("retrieved vpnId {} for router {}",vpnId,routerId);
                        return vpnId;
                    } else {
                        LOG.debug("retrieved invalid vpn Id");
                    }
                }
            }
        } catch (Exception ex){
            LOG.debug("Exception while retrieving vpnId for router {} - {}", routerId, ex);
        }
        return NatConstants.INVALID_ID;
    }

    public boolean getSwitchStatus(BigInteger switchId){
        NodeId nodeId = new NodeId("openflow:" + switchId);
        LOG.debug("Querying switch with dpnId {} is up/down", nodeId);
        InstanceIdentifier<Node> nodeInstanceId = InstanceIdentifier.builder(Nodes.class)
                .child(Node.class, new NodeKey(nodeId)).build();
        Optional<Node> nodeOptional = NatUtil.read(dataBroker,LogicalDatastoreType.OPERATIONAL,nodeInstanceId);
        if (nodeOptional.isPresent()) {
            LOG.debug("Switch {} is up", nodeId);
            return true;
        }
        LOG.debug("Switch {} is down", nodeId);
        return false;
    }

    public List<BucketInfo> handleGroupInPrimarySwitch() {
        List<BucketInfo> listBucketInfo = new ArrayList<>();
        List<ActionInfo> listActionInfoPrimary = new ArrayList<>();
        listActionInfoPrimary.add(new ActionInfo(ActionType.nx_resubmit,
                new String[]{String.valueOf(NwConstants.INTERNAL_TUNNEL_TABLE)}));
        BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);
        listBucketInfo.add(bucketPrimary);
        return listBucketInfo;
    }

    public List<BucketInfo> handleGroupInNeighborSwitches(BigInteger dpnId, String routerName, BigInteger naptSwitch) {
        List<BucketInfo> listBucketInfo = new ArrayList<>();
        String ifNamePrimary;
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("Invalid routerId returned for routerName {}",routerName);
            return listBucketInfo;
        }
        ifNamePrimary = getTunnelInterfaceName(dpnId, naptSwitch);
        if (ifNamePrimary != null) {
            LOG.debug("TunnelInterface {} between ordinary switch {} and naptSwitch {}",ifNamePrimary,dpnId,naptSwitch);
            List<ActionInfo> listActionInfoPrimary = NatUtil.getEgressActionsForInterface(interfaceManager, ifNamePrimary, routerId);
            BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);
            listBucketInfo.add(bucketPrimary);
        } else {
            LOG.debug("No TunnelInterface between ordinary switch {} and naptSwitch {}",dpnId,naptSwitch);
        }
        return listBucketInfo;
    }

    protected void installSnatGroupEntry(BigInteger dpnId, List<BucketInfo> bucketInfo, String routerName) {
        GroupEntity groupEntity = null;
        try {
            long groupId = NatUtil.createGroupId(NatUtil.getGroupIdKey(routerName), idManager);
            LOG.debug("install SnatMissEntry for groupId {} for dpnId {} for router {}", groupId, dpnId,routerName);
            groupEntity = MDSALUtil.buildGroupEntity(dpnId, groupId, routerName,
                    GroupTypes.GroupAll, bucketInfo);
            mdsalManager.installGroup(groupEntity);
            LOG.debug("installed the SNAT to NAPT GroupEntity:{}", groupEntity);
        } catch (Exception ex) {
            LOG.error("Failed to install group for groupEntity {} : {}",groupEntity,ex);
        }
    }

    private void modifySnatGroupEntry(BigInteger dpnId, List<BucketInfo> bucketInfo, String routerName) {
        installSnatGroupEntry(dpnId,bucketInfo,routerName);
        LOG.debug("modified SnatMissEntry for dpnId {} of router {}",dpnId,routerName);
    }

    protected String getTunnelInterfaceName(BigInteger srcDpId, BigInteger dstDpId) {
        Class<? extends TunnelTypeBase> tunType = TunnelTypeVxlan.class;
        RpcResult<GetTunnelInterfaceNameOutput> rpcResult;

        try {
            Future<RpcResult<GetTunnelInterfaceNameOutput>> result = itmManager.getTunnelInterfaceName(
                    new GetTunnelInterfaceNameInputBuilder().setSourceDpid(srcDpId).setDestinationDpid(dstDpId)
                            .setTunnelType(tunType).build());
            rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                tunType = TunnelTypeGre.class;
                result = itmManager.getTunnelInterfaceName(new GetTunnelInterfaceNameInputBuilder()
                        .setSourceDpid(srcDpId)
                        .setDestinationDpid(dstDpId)
                        .setTunnelType(tunType)
                        .build());
                rpcResult = result.get();
                if(!rpcResult.isSuccessful()) {
                    LOG.warn("RPC Call to getTunnelInterfaceId returned with Errors {}", rpcResult.getErrors());
                } else {
                    return rpcResult.getResult().getInterfaceName();
                }
                LOG.warn("RPC Call to getTunnelInterfaceId returned with Errors {}", rpcResult.getErrors());
            } else {
                return rpcResult.getResult().getInterfaceName();
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting tunnel interface Id for tunnel between {} and  {} :",
                    srcDpId, dstDpId, e);
        }

        return null;
    }

    public boolean updateNaptSwitch(String routerName, BigInteger naptSwitchId) {
        RouterToNaptSwitch naptSwitch = new RouterToNaptSwitchBuilder().setKey(new RouterToNaptSwitchKey(routerName))
                .setPrimarySwitchId(naptSwitchId).build();
        try {
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    NatUtil.buildNaptSwitchRouterIdentifier(routerName), naptSwitch);
        } catch (Exception ex) {
            LOG.error("Failed to write naptSwitch {} for router {} in ds",
                    naptSwitchId,routerName);
            return false;
        }
        LOG.debug("Successfully updated naptSwitch {} for router {} in ds",
                naptSwitchId,routerName);
        return true;
    }

    public FlowEntity buildSnatFlowEntity(BigInteger dpId, String routerName, long groupId, long routerVpnId, int addordel) {

        FlowEntity flowEntity;
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[]{ 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(routerVpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        String flowRef = getFlowRefSnat(dpId, NwConstants.PSNAT_TABLE, routerName);

        if (addordel == NatConstants.ADD_FLOW) {
            List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
            List<ActionInfo> actionsInfo = new ArrayList<ActionInfo>();

            ActionInfo actionSetField = new ActionInfo(ActionType.set_field_tunnel_id, new BigInteger[] {
                    BigInteger.valueOf(routerVpnId)}) ;
            actionsInfo.add(actionSetField);
            LOG.debug("Setting the tunnel to the list of action infos {}", actionsInfo);
            actionsInfo.add(new ActionInfo(ActionType.group, new String[] {String.valueOf(groupId)}));
            instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfo));

            flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                    NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                    NwConstants.COOKIE_SNAT_TABLE, matches, instructions);
        } else {
            flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                    NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                    NwConstants.COOKIE_SNAT_TABLE, matches, null);
        }
        return flowEntity;
    }

    public FlowEntity buildSnatFlowEntityForNaptSwitch(BigInteger dpId, String routerName, long routerVpnId, int addordel) {

        FlowEntity flowEntity;
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[]{ 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(routerVpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        String flowRef = getFlowRefSnat(dpId, NwConstants.PSNAT_TABLE, routerName);

        if (addordel == NatConstants.ADD_FLOW) {
            List<InstructionInfo> instructions = new ArrayList<>();

            instructions.add(new InstructionInfo(InstructionType.goto_table, new long[]
                    { NwConstants.OUTBOUND_NAPT_TABLE }));

            flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                    NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                    NwConstants.COOKIE_SNAT_TABLE, matches, instructions);
        } else {
            flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                    NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                    NwConstants.COOKIE_SNAT_TABLE, matches, null);
        }
        return flowEntity;
    }

    private String getFlowRefSnat(BigInteger dpnId, short tableId, String routerID) {
        return new StringBuilder().append(NatConstants.SNAT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
                append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID).toString();
    }

    protected void installSnatFlows(String routerName,Long routerId,BigInteger naptSwitch,Long routerVpnId) {

        if(routerId.equals(routerVpnId)) {
            LOG.debug("Installing flows for router with internalvpnId");
            //36 -> 46 ..Install flow forwarding packet to table46 from table36
            LOG.debug("installTerminatingServiceTblEntry in naptswitch with dpnId {} for routerName {} with routerId {}",
                    naptSwitch, routerName,routerId);
            externalRouterListener.installTerminatingServiceTblEntry(naptSwitch, routerName);

            //Install default flows punting to controller in table 46(OutBoundNapt table)
            LOG.debug("installOutboundMissEntry in naptswitch with dpnId {} for routerName {} with routerId {}",
                    naptSwitch, routerName, routerId);
            externalRouterListener.createOutboundTblEntry(naptSwitch, routerId);

            //Table 47 point to table 21 for inbound traffic
            LOG.debug("installNaptPfibEntry in naptswitch with dpnId {} for router {}", naptSwitch, routerId);
            externalRouterListener.installNaptPfibEntry(naptSwitch, routerId);
        } else {
            //36 -> 46 ..Install flow forwarding packet to table46 from table36
            LOG.debug("installTerminatingServiceTblEntry in naptswitch with dpnId {} for routerName {} with BgpVpnId {}",
                    naptSwitch, routerName, routerVpnId);
            externalRouterListener.installTerminatingServiceTblEntryWithUpdatedVpnId(naptSwitch, routerName, routerVpnId);

            //Install default flows punting to controller in table 46(OutBoundNapt table)
            LOG.debug("installOutboundMissEntry in naptswitch with dpnId {} for routerName {} with BgpVpnId {}",
                    naptSwitch, routerName, routerVpnId);
            externalRouterListener.createOutboundTblEntryWithBgpVpn(naptSwitch, routerId, routerVpnId);

            //Table 47 point to table 21 for inbound traffic
            LOG.debug("installNaptPfibEntry in naptswitch with dpnId {} for router {} with BgpVpnId {}",
                    naptSwitch, routerId, routerVpnId);
            externalRouterListener.installNaptPfibEntryWithBgpVpn(naptSwitch, routerId, routerVpnId);
        }

        String vpnName = getExtNetworkVpnName(routerId);
        if(vpnName != null) {
            //Table 47 point to table 21 for outbound traffic
            long vpnId = NatUtil.getVpnId(dataBroker, vpnName);
            if(vpnId > 0) {
                LOG.debug("installNaptPfibEntry fin naptswitch with dpnId {} for BgpVpnId {}", naptSwitch, vpnId);
                externalRouterListener.installNaptPfibEntry(naptSwitch, vpnId);
            } else {
                LOG.debug("Associated BgpvpnId not found for router {}",routerId);
            }

            //Install Fib entries for ExternalIps & program 36 -> 44
            List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker,routerId);
            String rd = NatUtil.getVpnRd(dataBroker, vpnName);
            if (externalIps != null) {
                for (String externalIp : externalIps) {
                    LOG.debug("NAT Service : Removing Fib entry rd {} prefix {}", rd, externalIp);
                    fibManager.removeFibEntry(dataBroker, rd, externalIp, null);
                    LOG.debug("advToBgpAndInstallFibAndTsFlows in naptswitch id {} with vpnName {} and externalIp {}",
                            naptSwitch, vpnName, externalIp);
                    externalRouterListener.advToBgpAndInstallFibAndTsFlows(naptSwitch, NwConstants.INBOUND_NAPT_TABLE,
                            vpnName, routerId, externalIp, vpnService, fibService, bgpManager, dataBroker, LOG);
                    LOG.debug("Successfully added fib entries in naptswitch {} for router {} with external IP {}", naptSwitch,
                            routerId, externalIp);
                }
            } else {
                LOG.debug("External Ip not found for routerId {}",routerId);
            }
        } else {
            LOG.debug("Associated vpnName not found for router {}",routerId);
        }
    }

    protected void bestEffortDeletion(long routerId,String routerName,HashMap<String,Long> externalIpLabel) {
        List<String> newExternalIps = NatUtil.getExternalIpsForRouter(dataBroker,routerId);
        if (newExternalIps != null && externalIpsCache != null) {
            Set<String> originalSubnetIds = Sets.newHashSet(externalIpsCache);
            Set<String> updatedSubnetIds = Sets.newHashSet(newExternalIps);
            Sets.SetView<String> removeExternalIp = Sets.difference(originalSubnetIds, updatedSubnetIds);
            if (removeExternalIp.isEmpty()) {
                LOG.debug("No external Ip needed to be removed in bestEffortDeletion method for router {}",routerName);
                return;
            }
            String vpnName = getExtNetworkVpnName(routerId);
            if (vpnName == null) {
                LOG.debug("Vpn is not associated to externalN/w of router {}",routerName);
                return;
            }
            if (externalIpLabel == null || externalIpLabel.size() == 0) {
                LOG.debug("ExternalIpLabel map is empty for router {}",routerName);
                return;
            }
            BigInteger naptSwitch = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
            if (naptSwitch == null || naptSwitch.equals(BigInteger.ZERO)) {
                LOG.debug("No naptSwitch is selected for router {}", routerName);
                return;
            }
            Long label;
            for (String externalIp : removeExternalIp) {
                if (externalIpLabel.containsKey(externalIp)) {
                    label = externalIpLabel.get(externalIp);
                    LOG.debug("Label {} for ExternalIp {} for router {}",label,externalIp,routerName);
                } else {
                    LOG.debug("Label for ExternalIp {} is not found for router {}",externalIp,routerName);
                    continue;
                }
                externalRouterListener.clearBgpRoutes(externalIp, vpnName);
                externalRouterListener.delFibTsAndReverseTraffic(naptSwitch, routerId, externalIp, vpnName,label);
                LOG.debug("Successfully removed fib entries in switch {} for router {} and externalIps {}",
                            naptSwitch, routerId, externalIp);
            }
        } else {
            LOG.debug("No external IP found for router {}",routerId);
        }
    }
}