/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.natservice.internal;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.JdkFutureAdapters;
import com.google.common.util.concurrent.ListenableFuture;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.*;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.DpnRoutersList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.DpnRoutersListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.dpn.routers.dpn.routers.list.RoutersList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.*;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.*;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.tunnels_state.StateTunnelList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.RouterPorts;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.floating.ip.info.router.ports.ports.InternalToExternalPortMap;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.Future;

public class NatTunnelInterfaceStateListener extends AsyncDataTreeChangeListenerBase<StateTunnelList, NatTunnelInterfaceStateListener> implements
        AutoCloseable{
    private static final Logger LOG = LoggerFactory.getLogger(NatTunnelInterfaceStateListener.class);
    private final DataBroker dataBroker;
    private IFibManager fibManager;
    private SNATDefaultRouteProgrammer defaultRouteProgrammer;
    private NaptSwitchHA naptSwitchHA;
    private IMdsalApiManager mdsalManager;
    private IdManagerService idManager;
    private IBgpManager bgpManager;
    private ExternalRoutersListener externalRouterListner;
    private OdlInterfaceRpcService interfaceService;
    private FloatingIPListener floatingIPListener;
    private FibRpcService fibRpcService;

    protected  enum TunnelAction {
        TUNNEL_EP_ADD,
        TUNNEL_EP_DELETE,
        TUNNEL_EP_UPDATE
    }

    /**
     * Responsible for listening to tunnel interface state change
     *
     * @param dataBroker - dataBroker service reference
     * @param bgpManager Used to advertise routes to the BGP Router
     * @param fibManager - FIB Manager
     * @param defaultRouteProgrammer - Default Route Programmer
     * @param naptSwitchHA - NAPT Switch HA
     * @param mdsalManager - MDSAL Manager
     * @param idManager - ID manager
     * @param externalRouterListner - External Router Listner
     * @param interfaceService - Interface Service
     * @param floatingIPListener -  Floating IP Listner
     * @param fibRpcService - FIB RPC Service
     */
    public NatTunnelInterfaceStateListener(final DataBroker dataBroker,
                                           final IBgpManager bgpManager,
                                           final IFibManager fibManager,
                                           final SNATDefaultRouteProgrammer defaultRouteProgrammer,
                                           final NaptSwitchHA naptSwitchHA,
                                           final IMdsalApiManager mdsalManager,
                                           final IdManagerService idManager,
                                           final ExternalRoutersListener externalRouterListner,
                                           final OdlInterfaceRpcService interfaceService,
                                           final FloatingIPListener floatingIPListener,
                                           final FibRpcService fibRpcService) {
        super(StateTunnelList.class, NatTunnelInterfaceStateListener.class);
        this.dataBroker = dataBroker;
        this.bgpManager = bgpManager;
        this.fibManager = fibManager;
        this.defaultRouteProgrammer = defaultRouteProgrammer;
        this.naptSwitchHA = naptSwitchHA;
        this.mdsalManager = mdsalManager;
        this.idManager = idManager;
        this.externalRouterListner = externalRouterListner;
        this.interfaceService = interfaceService;
        this.floatingIPListener = floatingIPListener;
        this.fibRpcService = fibRpcService;
    }

    @Override
    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<StateTunnelList> getWildCardPath() {
        return InstanceIdentifier.create(TunnelsState.class).child(StateTunnelList.class);
    }

    @Override
    protected NatTunnelInterfaceStateListener getDataTreeChangeListener() {
        return NatTunnelInterfaceStateListener.this;
    }

    @Override
    protected void add(InstanceIdentifier<StateTunnelList> instanceIdentifier, StateTunnelList add) {
        LOG.trace("NAT Service : TEP addtion---- {}", add);
        hndlTepEvntsForDpn(add, TunnelAction.TUNNEL_EP_ADD);
    }

    @Override
    protected void remove(InstanceIdentifier<StateTunnelList> identifier, StateTunnelList del) {
        LOG.trace("NAT Service : TEP deletion---- {}", del);
        hndlTepEvntsForDpn(del, TunnelAction.TUNNEL_EP_DELETE);
    }

    @Override
    protected void update(InstanceIdentifier<StateTunnelList> identifier, StateTunnelList original, StateTunnelList update) {
        LOG.trace("NAT Service : Tunnel updation---- {}", update);
        //UPDATE IS A SEQUENCE OF DELETE AND ADD EVENTS . DELETE MIGHT HAVE CHANGED THE PRIMARY AND ADVERTISED. SO
        // NOTHING TO HANDLE
    }

    private int getTunnelType (StateTunnelList stateTunnelList) {
        int tunTypeVal = 0;
        if (stateTunnelList.getDstInfo().getTepDeviceType() == TepTypeInternal.class) {
            tunTypeVal = NatConstants.ITMTunnelLocType.Internal.getValue();
        } else if (stateTunnelList.getDstInfo().getTepDeviceType() == TepTypeExternal.class) {
            tunTypeVal = NatConstants.ITMTunnelLocType.External.getValue();
        } else if (stateTunnelList.getDstInfo().getTepDeviceType() == TepTypeHwvtep.class) {
            tunTypeVal = NatConstants.ITMTunnelLocType.Hwvtep.getValue();
        } else {
            tunTypeVal = NatConstants.ITMTunnelLocType.Invalid.getValue();
        }
        return tunTypeVal;
    }

    void removeSNATFromDPN(BigInteger dpnId, String routerName, long routerVpnId, Uuid networkId) {
        //irrespective of naptswitch or non-naptswitch, SNAT default miss entry need to be removed
        //remove miss entry to NAPT switch
        //if naptswitch elect new switch and install Snat flows and remove those flows in oldnaptswitch

        //get ExternalIpIn prior
        List<String> externalIpCache;
        //HashMap Label
        HashMap<String,Long> externalIpLabel;
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("NAT Service : SNAT -> Invalid routerId returned for routerName {}",routerName);
            return;
        }
        externalIpCache = NatUtil.getExternalIpsForRouter(dataBroker,routerId);
        externalIpLabel = NatUtil.getExternalIpsLabelForRouter(dataBroker,routerId);
        try {
            final String externalVpnName = NatUtil.getAssociatedVPN(dataBroker, networkId, LOG);
            if (externalVpnName == null) {
                LOG.error("NAT Service : SNAT -> No VPN associated with ext nw {} in router {}",
                        networkId, routerId);
                return;
            }

            BigInteger naptSwitch = dpnId;
            boolean naptStatus = naptSwitchHA.isNaptSwitchDown(routerName,dpnId,naptSwitch,routerVpnId,externalIpCache,false);
            if (!naptStatus) {
                LOG.debug("NAT Service : SNAT -> NaptSwitchDown: Switch with DpnId {} is not naptSwitch for router {}",
                        dpnId, routerName);
                long groupId = NatUtil.createGroupId(NatUtil.getGroupIdKey(routerName), idManager);
                FlowEntity flowEntity = null;
                try {
                    flowEntity = naptSwitchHA.buildSnatFlowEntity(dpnId, routerName, groupId, routerVpnId, NatConstants.DEL_FLOW);
                    if (flowEntity == null) {
                        LOG.debug("NAT Service : SNAT -> Failed to populate flowentity for router {} with dpnId {} groupIs {}",routerName,dpnId,groupId);
                        return;
                    }
                    LOG.debug("NAT Service : SNAT -> Removing default SNAT miss entry flow entity {}",flowEntity);
                    mdsalManager.removeFlow(flowEntity);

                } catch (Exception ex) {
                    LOG.debug("NAT Service : SNAT -> Failed to remove default SNAT miss entry flow entity {} : {}",flowEntity,ex);
                    return;
                }
                LOG.debug("NAT Service : SNAT -> Removed default SNAT miss entry flow for dpnID {} with routername {}", dpnId, routerName);

                //remove group
                GroupEntity groupEntity = null;
                try {
                    groupEntity = MDSALUtil.buildGroupEntity(dpnId, groupId, routerName,
                            GroupTypes.GroupAll, null);
                    LOG.info("NAT Service : SNAT -> Removing NAPT GroupEntity:{}", groupEntity);
                    mdsalManager.removeGroup(groupEntity);
                } catch (Exception ex) {
                    LOG.debug("NAT Service : SNAT -> Failed to remove group entity {} : {}",groupEntity,ex);
                    return;
                }
                LOG.debug("NAT Service : SNAT -> Removed default SNAT miss entry flow for dpnID {} with routerName {}", dpnId, routerName);
            } else {
                naptSwitchHA.removeSnatFlowsInOldNaptSwitch(routerName, dpnId,externalIpLabel);
                //remove table 26 flow ppointing to table46
                FlowEntity flowEntity = null;
                try {
                    flowEntity = naptSwitchHA.buildSnatFlowEntityForNaptSwitch(dpnId, routerName, routerVpnId, NatConstants.DEL_FLOW);
                    if (flowEntity == null) {
                        LOG.debug("NAT Service : SNAT -> Failed to populate flowentity for router {} with dpnId {}",routerName,dpnId);
                        return;
                    }
                    LOG.debug("NAT Service : SNAT -> Removing default SNAT miss entry flow entity for router {} with dpnId {} in napt switch {}"
                            ,routerName,dpnId,naptSwitch);
                    mdsalManager.removeFlow(flowEntity);

                } catch (Exception ex) {
                    LOG.debug("NAT Service : SNAT -> Failed to remove default SNAT miss entry flow entity {} : {}",flowEntity,ex);
                    return;
                }
                LOG.debug("NAT Service : SNAT -> Removed default SNAT miss entry flow for dpnID {} with routername {}", dpnId, routerName);

                //best effort to check IntExt model
                naptSwitchHA.bestEffortDeletion(routerId,routerName,externalIpLabel);
            }
        } catch (Exception ex) {
            LOG.debug("NAT Service : SNAT -> Exception while handling naptSwitch down for router {} : {}",routerName,ex);
        }
    }

    private void hndlTepEvntsForDpn(StateTunnelList stateTunnelList, TunnelAction tunnelAction) {
        final BigInteger srcDpnId = new BigInteger(stateTunnelList.getSrcInfo().getTepDeviceId());
        final String srcTepIp = String.valueOf(stateTunnelList.getSrcInfo().getTepIp().getValue());
        final String destTepIp = String.valueOf(stateTunnelList.getDstInfo().getTepIp().getValue());
        LOG.trace("NAT Service : Handle tunnel event for srcDpn {} SrcTepIp {} DestTepIp {} ", srcDpnId, srcTepIp,
                destTepIp);
        int tunTypeVal = getTunnelType(stateTunnelList);

        LOG.trace("NAT Service : tunTypeVal is {}", tunTypeVal);

        try {
            String srcTepId = stateTunnelList.getSrcInfo().getTepDeviceId();
            String tunnelType = stateTunnelList.getTransportType().toString();
            String tunnelName = stateTunnelList.getTunnelInterfaceName();

            if (tunTypeVal == NatConstants.ITMTunnelLocType.Invalid.getValue()) {
                LOG.warn("NAT Service : Ignoring TEP event {} for the DPN {} "
                        + "since its a INVALID TUNNEL TYPE {} b/w SRC IP {} and DST IP {} and " + "TUNNEL NAME {} ",
                        tunnelAction, srcTepId, tunnelType, srcTepIp, destTepIp, tunnelName);
                return;
            }

            switch(tunnelAction){
                case TUNNEL_EP_ADD:
                    if(!hndlTepAddForAllRtrs(srcDpnId, tunnelType, tunnelName, srcTepIp, destTepIp)){
                        LOG.debug("NAT Service : Unable to process TEP ADD");
                    }
                    break;
                case TUNNEL_EP_DELETE:
                    if(!handleTepDelForAllRtrs(srcDpnId, tunnelType, tunnelName, srcTepIp, destTepIp)){
                        LOG.debug("NAT Service : Unable to process TEP DEL");
                    }
                    break;
            }
        } catch (Exception e) {
            LOG.error("NAT Service : Unable to handle the TEP event.", e);
            return;
        }
    }

    private boolean hndlTepAddForAllRtrs(BigInteger srcDpnId, String tunnelType, String tunnelName, String srcTepIp,
                                               String destTepIp) throws Exception{
        LOG.trace("NAT Service: TEP ADD ----- for EXTERNAL/HWVTEP ITM Tunnel, TYPE {} ,State is UP b/w SRC IP" +
                " : {} and DEST IP: {}", fibManager.getTransportTypeStr(tunnelType), srcTepIp, destTepIp);

        InstanceIdentifier<DpnRoutersList> dpnRoutersListId = NatUtil.getDpnRoutersId(srcDpnId);
        Optional<DpnRoutersList> optionalRouterDpnList = NatUtil.read(dataBroker, LogicalDatastoreType
                .OPERATIONAL, dpnRoutersListId);
        if (!optionalRouterDpnList.isPresent()) {
            LOG.warn("NAT Service : RouterDpnList model is empty for DPN {}. Hence ignoring TEP add event for the ITM " +
                            "TUNNEL TYPE {} b/w SRC IP {} and DST IP {} and TUNNEL NAME {} ", srcDpnId,
                    tunnelType, srcTepIp, destTepIp, tunnelName);
            return false;
        }

        List<RoutersList> routersList = optionalRouterDpnList.get().getRoutersList();
        if(routersList == null) {
            LOG.debug("NAT Service : Ignoring TEP add for the DPN {} since no routers are associated" +
                    " for the DPN having the TUNNEL TYPE {} b/w SRC IP {} and DST IP {} and" +
                    "TUNNEL NAME {} ", srcDpnId, tunnelType, srcTepIp, destTepIp, tunnelName);
            return false;
        }

        String nextHopIp = NatUtil.getEndpointIpAddressForDPN(dataBroker, srcDpnId);
        for (RoutersList router : routersList) {

            LOG.debug("NAT Service : TEP ADD : DNAT -> Advertising routes for router {} ", router.getRouter());
            hndlTepAddForDnatInEachRtr(router, nextHopIp, srcDpnId);

            LOG.debug("NAT Service : TEP ADD : SNAT -> Advertising routes for router {} ", router.getRouter());
            hndlTepAddForSnatInEachRtr(router, srcDpnId, tunnelType, srcTepIp, destTepIp,
                    tunnelName, nextHopIp);
        }
        return true;
    }

    private boolean handleTepDelForAllRtrs(BigInteger srcDpnId, String tunnelType, String tunnelName, String srcTepIp,
                                               String destTepIp) throws Exception{

        LOG.trace("NAT Service: TEP DEL ----- for EXTERNAL/HWVTEP ITM Tunnel, TYPE {} ,State is UP b/w SRC IP" +
                " : {} and DEST IP: {}", fibManager.getTransportTypeStr(tunnelType), srcTepIp, destTepIp);

        // When tunnel EP is deleted on a DPN , VPN gets two deletion event.
        // One for a DPN on which tunnel EP was deleted and another for other-end DPN.
        // Handle only the DPN on which it was deleted , ignore other event.
        // DPN on which TEP is deleted , endpoint IP will be null.
        String endpointIpForDPN = null;
        try {
            endpointIpForDPN = NatUtil.getEndpointIpAddressForDPN(dataBroker, srcDpnId);
        } catch (Exception e) {
                /* this dpn does not have the VTEP */
            LOG.debug("NAT Service : DPN {} does not have the VTEP", srcDpnId);
            endpointIpForDPN = null;
        }

        if (endpointIpForDPN != null) {
            LOG.trace("NAT Service : Ignore TEP DELETE event received for DPN {} VTEP IP {} since its the other end DPN w.r.t the delted TEP", srcDpnId,
                    srcTepIp);
            return false;
        }

        List<RoutersList> routersList = null;
        InstanceIdentifier<DpnRoutersList> dpnRoutersListId = NatUtil.getDpnRoutersId(srcDpnId);
        Optional<DpnRoutersList> optionalRouterDpnList = NatUtil.read(dataBroker, LogicalDatastoreType
                .OPERATIONAL, dpnRoutersListId);
        if (optionalRouterDpnList.isPresent()) {
            routersList = optionalRouterDpnList.get().getRoutersList();
        }else{
            LOG.warn("NAT Service : RouterDpnList is empty for DPN {}. Hence ignoring TEP DEL event for the ITM " +
                            "TUNNEL TYPE {} b/w SRC IP {} and DST IP {} and TUNNEL NAME {} ", srcDpnId,
                    tunnelType, srcTepIp, destTepIp, tunnelName);
            return false;
        }

        if(routersList == null) {
            LOG.debug("NAT Service : DPN {} does not have the Routers presence", srcDpnId);
            return false;
        }

        for (RoutersList router : routersList) {
            LOG.debug("NAT Service :  TEP DEL : DNAT -> Withdrawing routes for router {} ", router.getRouter());
            hndlTepDelForDnatInEachRtr(router, srcDpnId);
            LOG.debug("NAT Service :  TEP DEL : SNAT -> Withdrawing and Advertising routes for router {} ",
                    router.getRouter());
            hndlTepDelForSnatInEachRtr(router, srcDpnId, tunnelType, srcTepIp, destTepIp, tunnelName);
        }
        return true;
    }

    private void hndlTepAddForSnatInEachRtr(RoutersList router, final BigInteger srcDpnId, String tunnelType,
                                        String srcTepIp, String destTepIp, String tunnelName, String nextHopIp){

        /*SNAT : Remove the old routes to the external IP having the old TEP IP as the next hop IP
                 Advertise to the BGP about the new route to the external IP having the new TEP IP
                  added as the next hop IP
         */
        String routerName = router.getRouter();

        // Check if this is externalRouter else ignore
        InstanceIdentifier<Routers> extRoutersId = NatUtil.buildRouterIdentifier(routerName);
        Optional<Routers> routerData = NatUtil.read(dataBroker, LogicalDatastoreType
                .CONFIGURATION, extRoutersId);
        if (!routerData.isPresent()) {
            LOG.debug("NAT Service : SNAT -> Ignoring TEP add for router {} since its not External Router",
                    routerName);
            return;
        }

        long routerId = NatUtil.getVpnId(dataBroker, routerName);
        BigInteger naptId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
        if (naptId == null || naptId.equals(BigInteger.ZERO)) {
            LOG.warn("NAT Service : SNAT -> Ignoring TEP add for the DPN {} having the router {} since" +
                    " the router is not part of the NAT service  - the TUNNEL TYPE {} b/w SRC IP {} and DST IP {} and" +
                    "TUNNEL NAME {} ", srcDpnId, routerName, tunnelType, srcTepIp, destTepIp, tunnelName);
            return;
        }

        //Check if the DPN having the router is the NAPT switch
        if( !naptId.equals(srcDpnId)){
            /*
            1) Install default NAT rule from table 21 to 26
            2) Install the group which forward packet to the tunnel port for the NAPT switch.
            3) Install the flow 26 which forwards the packet to the group.
            */
            if (!hndlTepAddOnNonNaptSwitch(srcDpnId, naptId, tunnelType, srcTepIp, destTepIp, tunnelName, routerName, routerId)){
                LOG.debug("NAT Service : Unable to process the TEP add event on NON-NAPT switch {}", srcDpnId);
                return;
            }
            return;
        }
        if (!hndlTepAddOnNaptSwitch(srcDpnId, tunnelType, srcTepIp, destTepIp, tunnelName, routerId, routerData, nextHopIp)){
            LOG.debug("NAT Service : Unable to process the TEP add event on NAPT switch {}", srcDpnId);
            return;
        }
        return;
    }

    private boolean hndlTepAddOnNonNaptSwitch(BigInteger srcDpnId, BigInteger primaryDpnId, String tunnelType,
            String srcTepIp, String destTepIp, String tunnelName, String routerName, long routerId) {

        /*
        1) Install default NAT rule from table 21 to 26
        2) Install the group which forward packet to the tunnel port for the NAPT switch.
        3) Install the flow 26 which forwards the packet to the group.
        */
        LOG.debug("NAT Service : SNAT -> Processing TEP add for the DPN {} having the router {} since " +
                        "its THE NON NAPT switch for the TUNNEL TYPE {} b/w SRC IP {} and DST IP {} " + "and TUNNEL NAME {} ",
                srcDpnId, routerName, tunnelType, srcTepIp, destTepIp, tunnelName);
        LOG.debug("NAT Service : SNAT -> Install default NAT rule from table 21 to 26");
        Uuid vpnName = NatUtil.getVpnForRouter(dataBroker, routerName);
        Long vpnId;
        if (vpnName == null) {
            LOG.debug("NAT Service : SNAT -> Internal VPN associated to router {}",routerId);
            vpnId = routerId;
            if (vpnId == NatConstants.INVALID_ID) {
                LOG.error("NAT Service : SNAT -> Invalid Internal VPN ID returned for routerName {}",routerId);
                return false;
            }
            LOG.debug("NAT Service : SNAT -> Retrieved vpnId {} for router {}", vpnId, routerName);
            //Install default entry in FIB to SNAT table
            LOG.debug("NAT Service : Installing default route in FIB on DPN {} for router {} with" +
                    " vpn {}...", srcDpnId,routerName,vpnId);
            defaultRouteProgrammer.installDefNATRouteInDPN(srcDpnId, vpnId);

            LOG.debug("NAT Service : SNAT -> Install the group which forward packet to the tunnel port for the NAPT switch {}" +
                    " and the flow 26 which forwards to group", primaryDpnId);
            externalRouterListner.handleSwitches(srcDpnId, routerName, primaryDpnId);
        } else {
            LOG.debug("NAT Service : SNAT -> External BGP VPN (Private BGP) associated to router {}",routerId);
            vpnId = NatUtil.getVpnId(dataBroker, vpnName.getValue());
            if (vpnId == NatConstants.INVALID_ID) {
                LOG.error("NAT Service : SNAT -> Invalid Private BGP VPN ID returned for routerName {}", routerId);
                return false;
            }
            if (routerId == NatConstants.INVALID_ID) {
                LOG.error("NAT Service : SNAT -> Invalid routId returned for routerName {}",routerId);
                return false;
            }
            LOG.debug("NAT Service : SNAT -> Retrieved vpnId {} for router {}",vpnId, routerId);
            //Install default entry in FIB to SNAT table
            LOG.debug("NAT Service : Installing default route in FIB on dpn {} for routerId {} " +
                    "with vpnId {}...", srcDpnId,routerId,vpnId);
            defaultRouteProgrammer.installDefNATRouteInDPN(srcDpnId, vpnId, routerId);

            LOG.debug("NAT Service : Install group in non NAPT switch {}", srcDpnId);
            List<BucketInfo> bucketInfoForNonNaptSwitches = externalRouterListner.getBucketInfoForNonNaptSwitches(srcDpnId, srcDpnId, routerName);
            long groupId = externalRouterListner.installGroup(srcDpnId, routerName, bucketInfoForNonNaptSwitches);

            LOG.debug("NAT Service : SNAT -> in the SNAT miss entry pointing to group {} in the non NAPT switch {}",
                    vpnId, groupId, srcDpnId);
            FlowEntity flowEntity = externalRouterListner.buildSnatFlowEntityWithUpdatedVpnId(srcDpnId, routerName, groupId, vpnId);
            mdsalManager.installFlow(flowEntity);
        }
        return true;
    }

    private boolean hndlTepAddOnNaptSwitch(BigInteger srcDpnId, String tunnelType, String srcTepIp,
                                             String destTepIp, String tunnelName, long routerId,
                                             Optional<Routers> routerData, String nextHopIp){
        String routerName = routerData.get().getRouterName();
        LOG.debug("NAT Service : SNAT -> Processing TEP add for the DPN {} having the router {} since " +
                "its THE NAPT switch for the TUNNEL TYPE {} b/w SRC IP {} and DST IP {} " +
                "and TUNNEL NAME {} ", srcDpnId, routerName, tunnelType, srcTepIp, destTepIp, tunnelName);

        Uuid networkId = routerData.get().getNetworkId();
        if (networkId == null) {
            LOG.warn("NAT Service : SNAT -> Ignoring TEP add since the router {} is not associated to the " +
                    "external network", routerName);
            return false;
        }

        LOG.debug("NAT Service : SNAT -> Router {} is associated with Ext nw {}", routerId, networkId);
        Uuid vpnName = NatUtil.getVpnForRouter(dataBroker, routerName);
        Long vpnId;
        if (vpnName == null) {
            LOG.debug("NAT Service : SNAT -> Internal VPN associated to router {}", routerId);
            vpnId = NatUtil.getVpnId(dataBroker, routerId);
            if (vpnId == null || vpnId == NatConstants.INVALID_ID) {
                LOG.error("Invalid External VPN-ID returned for routerName {}", routerName);
                return false;
            }
            LOG.debug("NAT Service : SNAT -> Retrieved External VPN-ID {} for router {}", vpnId, routerId);
        } else {
            LOG.debug("NAT Service : SNAT -> Private BGP VPN associated to router {}", routerId);
            vpnId = NatUtil.getVpnId(dataBroker, vpnName.getValue());
            if (vpnId == null || vpnId == NatConstants.INVALID_ID) {
                LOG.error("NAT Service : Invalid vpnId returned for routerName {}", routerName);
                return false;
            }
            LOG.debug("NAT Service : SNAT -> Retrieved vpnId {} for router {}", vpnId, routerId);
        }

        /*1) Withdraw the old route to the external IP from the BGP which was having the
             next hop as the old TEP IP.
          2) Advertise to the BGP about the new route to the external IP having the
          new TEP IP as the next hop.
          3) Populate a new FIB entry with the next hop IP as the new TEP IP using the
          FIB manager.
        */

        //Withdraw the old route to the external IP from the BGP which was having the
        //next hop as the old TEP IP.
        final String externalVpnName = NatUtil.getAssociatedVPN(dataBroker, networkId, LOG);
        if (externalVpnName == null) {
            LOG.error("NAT Service :  SNAT -> No VPN associated with ext nw {} in router {}",
                    networkId, routerId);
            return false;
        }
        List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker, routerId);
        if (externalIps != null) {
            LOG.debug("NAT Service : Clearing the FIB entries but not the BGP routes");
            for (String externalIp : externalIps) {
                String rd = NatUtil.getVpnRd(dataBroker, externalVpnName);
                LOG.debug("NAT Service : Removing Fib entry rd {} prefix {}", rd, externalIp);
                fibManager.removeFibEntry(dataBroker, rd, externalIp, null);
            }
        }

        /*
        Advertise to the BGP about the new route to the external IP having the
        new TEP IP as the next hop.
        Populate a new FIB entry with the next hop IP as the new TEP IP using the
        FIB manager.
        */
        String rd = NatUtil.getVpnRd(dataBroker, externalVpnName);
        if (externalIps != null) {
            for (final String externalIp : externalIps) {
                Long label = externalRouterListner.checkExternalIpLabel(routerId,
                        externalIp);
                if(label == null || label == NatConstants.INVALID_ID){
                    LOG.debug("NAT Service : SNAT -> Unable to advertise to the DC GW since label is invalid" );
                    return false;
                }

                LOG.debug("NAT Service : SNAT -> Advertise the route to the externalIp {} having nextHopIp {}", externalIp,
                        nextHopIp);
                NatUtil.addPrefixToBGP(dataBroker, bgpManager, fibManager, rd, externalIp, nextHopIp,
                        label, LOG, RouteOrigin.STATIC);

                LOG.debug("NAT Service : SNAT -> Install custom FIB routes ( Table 21 -> Push MPLS label to Tunnel port");
                List<Instruction> customInstructions = new ArrayList<>();
                customInstructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.INBOUND_NAPT_TABLE }).
                        buildInstruction(0));
                CreateFibEntryInput input = new CreateFibEntryInputBuilder().setVpnName(externalVpnName).setSourceDpid(srcDpnId).
                        setInstruction(customInstructions).setIpAddress(externalIp + "/32").setServiceId(label).setInstruction(customInstructions).build();
                Future<RpcResult<Void>> future = fibRpcService.createFibEntry(input);
                ListenableFuture<RpcResult<Void>> listenableFuture = JdkFutureAdapters.listenInPoolThread(future);

                Futures.addCallback(listenableFuture, new FutureCallback<RpcResult<Void>>() {

                    @Override
                    public void onFailure(Throwable error) {
                        LOG.error("NAT Service : SNAT -> Error in generate label or fib install process", error);
                    }

                    @Override
                    public void onSuccess(RpcResult<Void> result) {
                        if(result.isSuccessful()) {
                            LOG.info("NAT Service : SNAT -> Successfully installed custom FIB routes for prefix {}", externalIp);
                        } else {
                            LOG.error("NAT Service : SNAT -> Error in rpc call to create custom Fib entries for prefix {} in DPN {}, {}",
                                    externalIp, srcDpnId, result.getErrors());
                        }
                    }
                });
            }
        }
        return true;
    }

    private void hndlTepAddForDnatInEachRtr(RoutersList router, String nextHopIp, BigInteger tepAddedDpnId){
        //DNAT : Advertise the new route to the floating IP having the new TEP IP as the next hop IP
        final String routerName = router.getRouter();

        InstanceIdentifier<RouterPorts> routerPortsId = NatUtil.getRouterPortsId(routerName);
        Optional<RouterPorts> optRouterPorts = MDSALUtil.read(dataBroker, LogicalDatastoreType
                .CONFIGURATION, routerPortsId);
        if (!optRouterPorts.isPresent()) {
            LOG.debug("NAT Service : DNAT -> Could not read Router Ports data object with id: {} from DNAT " +
                    "FloatinIpInfo", routerName);
            return;
        }
        RouterPorts routerPorts = optRouterPorts.get();
        List<Ports> interfaces = routerPorts.getPorts();

        Uuid extNwId = routerPorts.getExternalNetworkId();
        final String vpnName = NatUtil.getAssociatedVPN(dataBroker, extNwId, LOG);
        if (vpnName == null) {
            LOG.info("NAT Service : DNAT -> No External VPN associated with ext nw {} for router {}",
                    extNwId, routerName);
            return;
        }

        String rd = NatUtil.getVpnRd(dataBroker, vpnName);
        for (Ports port : interfaces) {
            //Get the DPN on which this interface resides
            final String interfaceName = port.getPortName();
            final BigInteger fipCfgdDpnId = NatUtil.getDpnForInterface(interfaceService, interfaceName);
            if(fipCfgdDpnId.equals(BigInteger.ZERO)) {
                LOG.info("NAT Service : DNAT -> Skip processing Floating ip configuration for the port {}, since no DPN present for it", interfaceName);
                continue;
            }
            if(!fipCfgdDpnId.equals(tepAddedDpnId)) {
                LOG.debug("NAT Service : DNAT -> TEP added DPN {} is not the DPN {} which has the floating IP configured for the port: {}",
                        tepAddedDpnId, fipCfgdDpnId, interfaceName);
                continue;
            }
            List<InternalToExternalPortMap> intExtPortMapList = port.getInternalToExternalPortMap();
            for(InternalToExternalPortMap intExtPortMap : intExtPortMapList) {
                final String internalIp = intExtPortMap.getInternalIp();
                final String externalIp = intExtPortMap.getExternalIp();
                LOG.debug("NAT Service : DNAT -> Advertising the FIB route to the floating IP {} configured for the port: {}",
                        externalIp, interfaceName);
                long label = floatingIPListener.getOperationalIpMapping(routerName, interfaceName, internalIp);
                if(label == NatConstants.INVALID_ID){
                    LOG.debug("NAT Service : DNAT -> Unable to advertise to the DC GW since label is invalid" );
                    return;
                }
                NatUtil.addPrefixToBGP(dataBroker, bgpManager, fibManager, rd, externalIp + "/32", nextHopIp, label, LOG, RouteOrigin.STATIC);

                //Install custom FIB routes ( Table 21 -> Push MPLS label to Tunnel port
                List<Instruction> customInstructions = new ArrayList<>();
                customInstructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { NwConstants.PDNAT_TABLE }).buildInstruction(0));
                CreateFibEntryInput input = new CreateFibEntryInputBuilder().setVpnName(vpnName).setSourceDpid(fipCfgdDpnId).setInstruction(customInstructions)
                        .setIpAddress(externalIp + "/32").setServiceId(label).setInstruction(customInstructions).build();
                Future<RpcResult<Void>> future = fibRpcService.createFibEntry(input);
                ListenableFuture<RpcResult<Void>> listenableFuture = JdkFutureAdapters.listenInPoolThread(future);

                Futures.addCallback(listenableFuture, new FutureCallback<RpcResult<Void>>() {

                    @Override
                    public void onFailure(Throwable error) {
                        LOG.error("NAT Service : DNAT -> Error in generate label or fib install process", error);
                    }

                    @Override
                    public void onSuccess(RpcResult<Void> result) {
                        if(result.isSuccessful()) {
                            LOG.info("NAT Service : DNAT -> Successfully installed custom FIB routes for prefix {}", externalIp);
                        } else {
                            LOG.error("NAT Service : DNAT -> Error in rpc call to create custom Fib entries for prefix {} in DPN {}, {}", externalIp, fipCfgdDpnId, result.getErrors());
                        }
                    }
                });

            }
        }
    }

    private void hndlTepDelForSnatInEachRtr(RoutersList router, BigInteger dpnId, String tunnelType,
                                              String srcTepIp, String destTepIp, String tunnelName){
        /*SNAT :
            1) Elect a new switch as the primary NAPT
            2) Advertise the new routes to BGP for the newly elected TEP IP as the DPN IP
            3) This will make sure old routes are withdrawn and new routes are advertised.
         */

        String routerName = router.getRouter();
        LOG.debug("NAT Service : SNAT -> Trying to clear routes to the External fixed IP associated to the router" +
                " {}", routerName);

        // Check if this is externalRouter else ignore
        InstanceIdentifier<Routers> extRoutersId = NatUtil.buildRouterIdentifier(routerName);
        Optional<Routers> routerData = NatUtil.read(dataBroker, LogicalDatastoreType
                .CONFIGURATION, extRoutersId);
        if (!routerData.isPresent()) {
            LOG.debug("NAT Service : SNAT -> Ignoring TEP del for router {} since its not External Router",
                    routerName);
            return;
        }

        //Check if the router ID is valid
        long routerId = NatUtil.getVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("NAT Service : SNAT -> Invalid ROUTER-ID {} returned for routerName {}", routerId, routerName);
            return;
        }

        //Check if the DPN having the router is the NAPT switch
        BigInteger naptId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
        if (naptId == null || naptId.equals(BigInteger.ZERO) || (!naptId.equals(dpnId))) {
            LOG.warn("NAT Service : SNAT -> Ignoring TEP delete for the DPN {} since" +
                    " its NOT a NAPT switch for the TUNNEL TYPE {} b/w SRC IP {} and DST IP {} and" +
                    "TUNNEL NAME {} ", dpnId, tunnelType, srcTepIp, destTepIp, tunnelName);
            return;
        }

        Uuid networkId = routerData.get().getNetworkId();
        if(networkId == null) {
            LOG.debug("NAT Service : SNAT -> Ignoring TEP delete for the DPN {} having the router {} " +
                    "since the Router instance {} not found in ExtRouters model b/w SRC IP {} and DST IP {} " +
                    "and TUNNEL NAME {} ", dpnId, tunnelType, srcTepIp, destTepIp, tunnelName);
            return;
        }

        LOG.debug("NAT Service : SNAT -> Router {} is associated with ext nw {}", routerId, networkId);
        Uuid vpnName = NatUtil.getVpnForRouter(dataBroker, routerName);
        Long vpnId;
        if (vpnName == null) {
            LOG.debug("NAT Service : SNAT -> Internal VPN-ID {} associated to router {}", routerId, routerName);
            vpnId = routerId;

            //Install default entry in FIB to SNAT table
            LOG.debug("NAT Service : Installing default route in FIB on DPN {} for router {} with" +
                    " vpn {}...", dpnId,routerName,vpnId);
            defaultRouteProgrammer.installDefNATRouteInDPN(dpnId, vpnId);
        } else {
            vpnId = NatUtil.getVpnId(dataBroker, vpnName.getValue());
            if (vpnId == NatConstants.INVALID_ID) {
                LOG.error("NAT Service : SNAT -> Invalid Private BGP VPN ID returned for routerName {}", routerName);
                return;
            }
            LOG.debug("NAT Service : SNAT -> External BGP VPN (Private BGP) {} associated to router {}", vpnId, routerName);
            //Install default entry in FIB to SNAT table
            LOG.debug("NAT Service : Installing default route in FIB on dpn {} for routerId {} " +
                    "with vpnId {}...", dpnId, routerId, vpnId);
            defaultRouteProgrammer.installDefNATRouteInDPN(dpnId, vpnId, routerId);
        }

        if (routerData.get().isEnableSnat()) {
            LOG.info("NAT Service : SNAT enabled for router {}", routerId);

            long routerVpnId = routerId;
            long bgpVpnId = NatConstants.INVALID_ID;
            Uuid bgpVpnUuid = NatUtil.getVpnForRouter(dataBroker, routerName);
            if (bgpVpnUuid != null) {
                bgpVpnId = NatUtil.getVpnId(dataBroker, bgpVpnUuid.getValue());
            }
            if (bgpVpnId != NatConstants.INVALID_ID){
                LOG.debug("NAT Service : SNAT -> Private BGP VPN ID (Internal BGP VPN ID) {} associated to the router {}", bgpVpnId, routerName);
                routerVpnId = bgpVpnId;
            }else{
                LOG.debug("NAT Service : SNAT -> Internal L3 VPN ID (Router ID) {} associated to the router {}", routerVpnId, routerName);
            }
            //Re-elect the other available switch as the NAPT switch and program the NAT flows.
            removeSNATFromDPN(dpnId, routerName ,routerVpnId, networkId);
        } else {
            LOG.info("NAT Service : SNAT is not enabled for router {} to handle addDPN event {}", routerId, dpnId);
        }
    }

    private void hndlTepDelForDnatInEachRtr(RoutersList router, BigInteger tepDeletedDpnId){
        //DNAT : Withdraw the routes from the BGP
        String routerName = router.getRouter();
        LOG.debug("NAT Service : DNAT -> Trying to clear routes to the Floating IP associated to the router {}",
                routerName);

        InstanceIdentifier<RouterPorts> routerPortsId = NatUtil.getRouterPortsId(routerName);
        Optional<RouterPorts> optRouterPorts = MDSALUtil.read(dataBroker, LogicalDatastoreType
                .CONFIGURATION, routerPortsId);
        if(!optRouterPorts.isPresent()) {
            LOG.debug("NAT Service : DNAT -> Could not read Router Ports data object with id: {} from DNAT " +
                            "FloatingIpInfo",
                    routerName);
            return;
        }
        RouterPorts routerPorts = optRouterPorts.get();
        List<Ports> interfaces = routerPorts.getPorts();
        Uuid extNwId = routerPorts.getExternalNetworkId();
        final String vpnName = NatUtil.getAssociatedVPN(dataBroker, extNwId, LOG);
        if(vpnName == null) {
            LOG.info("NAT Service : DNAT -> No External VPN associated with Ext N/W {} for Router {}",
                    extNwId, routerName);
            return;
        }
        String rd = NatUtil.getVpnRd(dataBroker, vpnName);
        for(Ports port : interfaces) {
            //Get the DPN on which this interface resides
            String interfaceName = port.getPortName();
            BigInteger fipCfgdDpnId = NatUtil.getDpnForInterface(interfaceService, interfaceName);
            if(fipCfgdDpnId.equals(BigInteger.ZERO)) {
                LOG.info("NAT Service : DNAT -> Abort processing Floating ip configuration. No DPN for port : {}", interfaceName);
                continue;
            }
            if(!fipCfgdDpnId.equals(tepDeletedDpnId)) {
                LOG.info("NAT Service : DNAT -> TEP deleted DPN {} is not the DPN {} which has the floating IP configured for the port: {}",
                        tepDeletedDpnId, fipCfgdDpnId, interfaceName);
                continue;
            }
            List<InternalToExternalPortMap> intExtPortMapList = port.getInternalToExternalPortMap();
            for(InternalToExternalPortMap intExtPortMap : intExtPortMapList) {
                String internalIp = intExtPortMap.getInternalIp();
                String externalIp = intExtPortMap.getExternalIp();
                LOG.debug("NAT Service : DNAT -> Withdrawing the FIB route to the floating IP {} configured for the port: {}",
                        externalIp, interfaceName);
                NatUtil.removePrefixFromBGP(dataBroker, bgpManager, fibManager, rd, externalIp + "/32", LOG);
                long label = floatingIPListener.getOperationalIpMapping(routerName, interfaceName, internalIp);
                if(label == NatConstants.INVALID_ID){
                    LOG.debug("NAT Service : DNAT -> Unable to remove the table 21 entry pushing the MPLS label to the tunnel since label is invalid" );
                    return;
                }
                RemoveFibEntryInput input = new RemoveFibEntryInputBuilder().setVpnName(vpnName).setSourceDpid(fipCfgdDpnId).setIpAddress(externalIp + "/32").setServiceId(label).build();
                Future<RpcResult<Void>> future = fibRpcService.removeFibEntry(input);
                ListenableFuture<RpcResult<Void>> listenableFuture = JdkFutureAdapters.listenInPoolThread(future);

                Futures.addCallback(listenableFuture, new FutureCallback<RpcResult<Void>>() {

                    @Override
                    public void onFailure(Throwable error) {
                        LOG.error("NAT Service : DNAT -> Error in removing the table 21 entry pushing the MPLS label to the tunnel since label is invalid ", error);
                    }

                    @Override
                    public void onSuccess(RpcResult<Void> result) {
                        if(result.isSuccessful()) {
                            LOG.info("NAT Service : DNAT -> Successfully removed the entry pushing the MPLS label to the tunnel");
                        } else {
                            LOG.error("NAT Service : DNAT -> Error in fib rpc call to remove the table 21 entry pushing the MPLS label to the tunnnel due to {}", result.getErrors());
                        }
                    }
                });

            }
        }
    }
}
