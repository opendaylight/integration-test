/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.Future;

import com.google.common.util.concurrent.ListenableFuture;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.DataStoreJobCoordinator;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpnInterfaceListInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpnInterfaceListOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.TepTypeExternal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.TepTypeHwvtep;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.TepTypeInternal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.TunnelsState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.TunnelOperStatus;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.tunnels_state.StateTunnelList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.IsDcgwPresentInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.IsDcgwPresentOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.Adjacencies;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.PortOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TunnelInterfaceStateListener extends AsyncDataTreeChangeListenerBase<StateTunnelList,
        TunnelInterfaceStateListener> implements AutoCloseable{
    private static final Logger LOG = LoggerFactory.getLogger(TunnelInterfaceStateListener.class);
    private final DataBroker dataBroker;
    private final IBgpManager bgpManager;
    private final IFibManager fibManager;
    private final ItmRpcService itmRpcService;
    private OdlInterfaceRpcService intfRpcService;
    private VpnInterfaceManager vpnInterfaceManager;
    private VpnSubnetRouteHandler vpnSubnetRouteHandler;
    protected enum UpdateRouteAction {
        ADVERTISE_ROUTE, WITHDRAW_ROUTE
    }

    protected  enum TunnelAction {
        TUNNEL_EP_ADD,
        TUNNEL_EP_DELETE,
        TUNNEL_EP_UPDATE
    }
    /**
     * Responsible for listening to tunnel interface state change
     *
     * @param dataBroker dataBroker
     * @param bgpManager bgpManager
     * @param fibManager fibManager
     * @param itmRpcService itmRpcService
     */
    public TunnelInterfaceStateListener(final DataBroker dataBroker,
                                        final IBgpManager bgpManager,
                                        final IFibManager fibManager,
                                        final ItmRpcService itmRpcService,
                                        final OdlInterfaceRpcService ifaceMgrRpcService,
                                        final VpnInterfaceManager vpnInterfaceManager,
                                        final VpnSubnetRouteHandler vpnSubnetRouteHandler) {
        super(StateTunnelList.class, TunnelInterfaceStateListener.class);
        this.dataBroker = dataBroker;
        this.bgpManager = bgpManager;
        this.fibManager = fibManager;
        this.itmRpcService = itmRpcService;
        this.intfRpcService = ifaceMgrRpcService;
        this.vpnInterfaceManager = vpnInterfaceManager;
        this.vpnSubnetRouteHandler = vpnSubnetRouteHandler;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<StateTunnelList> getWildCardPath() {
        return InstanceIdentifier.create(TunnelsState.class).child(StateTunnelList.class);
    }

    @Override
    protected TunnelInterfaceStateListener getDataTreeChangeListener() {
        return TunnelInterfaceStateListener.this;
    }

    @Override
    protected void remove(InstanceIdentifier<StateTunnelList> identifier, StateTunnelList del) {
        LOG.trace("Tunnel deletion---- {}", del);
        handleTunnelEventForDPN(del, UpdateRouteAction.WITHDRAW_ROUTE , TunnelAction.TUNNEL_EP_DELETE);
    }

    @Override
    protected void update(InstanceIdentifier<StateTunnelList> identifier, StateTunnelList original, StateTunnelList update) {
        LOG.trace("Tunnel updation---- {}", update);
        LOG.trace("ITM Tunnel {} of type {} state event changed from :{} to :{}",
                update.getTunnelInterfaceName(),
                fibManager.getTransportTypeStr(update.getTransportType().toString()),
                original.getOperState(), update.getOperState());
        //withdraw all prefixes in all vpns for this dpn
        TunnelOperStatus tunOpStatus = update.getOperState();
        if ((tunOpStatus != TunnelOperStatus.Down) && (tunOpStatus != TunnelOperStatus.Up)) {
            LOG.trace("Returning from unsupported tunnelOperStatus {}", tunOpStatus);
            return;
        }
        boolean isTunnelUp = (tunOpStatus == TunnelOperStatus.Up);
        handleTunnelEventForDPN(update,
                                isTunnelUp ? UpdateRouteAction.ADVERTISE_ROUTE : UpdateRouteAction.WITHDRAW_ROUTE,
                                TunnelAction.TUNNEL_EP_UPDATE);
    }

    @Override
    protected void add(InstanceIdentifier<StateTunnelList> identifier, StateTunnelList add) {
        LOG.trace("Tunnel addition---- {}", add);
        TunnelOperStatus tunOpStatus = add.getOperState();
        if ((tunOpStatus != TunnelOperStatus.Down) && (tunOpStatus != TunnelOperStatus.Up)) {
            LOG.trace("Returning from unsupported tunnelOperStatus {}", tunOpStatus);
            return;
        }
        boolean isTunnelUp = (tunOpStatus == TunnelOperStatus.Up);
        if (!isTunnelUp) {
            LOG.trace("Tunnel {} is not yet UP.",
                    add.getTunnelInterfaceName());
            return;
        } else {
            LOG.trace("ITM Tunnel ,type {} ,State is UP b/w src: {} and dest: {}",
                    fibManager.getTransportTypeStr(add.getTransportType().toString()),
                    add.getSrcInfo().getTepDeviceId(), add.getDstInfo().getTepDeviceId());
            handleTunnelEventForDPN(add, UpdateRouteAction.ADVERTISE_ROUTE, TunnelAction.TUNNEL_EP_ADD);
        }
    }

    private void handleTunnelEventForDPN(StateTunnelList stateTunnelList, UpdateRouteAction action, TunnelAction tunnelAction) {
        final BigInteger srcDpnId = new BigInteger(stateTunnelList.getSrcInfo().getTepDeviceId());
        final String srcTepIp = String.valueOf(stateTunnelList.getSrcInfo().getTepIp().getValue());
        String destTepIp = String.valueOf(stateTunnelList.getDstInfo().getTepIp().getValue());
        String rd;
        BigInteger remoteDpnId = null;
        boolean isTepDeletedOnDpn = false;

        LOG.trace("Handle tunnel event for srcDpn {} SrcTepIp {} DestTepIp {} ", srcDpnId, srcTepIp, destTepIp);
        int tunTypeVal = getTunnelType(stateTunnelList);

        LOG.trace("tunTypeVal is {}", tunTypeVal);

        try {
            if (tunnelAction == TunnelAction.TUNNEL_EP_ADD) {
                LOG.trace(" Tunnel ADD event received for Dpn {} VTEP Ip {} ", srcDpnId, srcTepIp);
            } else if (tunnelAction == TunnelAction.TUNNEL_EP_DELETE) {
                LOG.trace(" Tunnel DELETE event received for Dpn {} VTEP Ip {} ", srcDpnId, srcTepIp);
                // When tunnel EP is deleted on a DPN , VPN gets two deletion event.
                // One for a DPN on which tunnel EP was deleted and another for other-end DPN.
                // Update the adj for the vpninterfaces for a DPN on which TEP is deleted.
                // Update the adj & VRF for the vpninterfaces for a DPN on which TEP is deleted.
                // Dont update the adj & VRF for vpninterfaces for a DPN on which TEP is not deleted.
                String endpointIpForDPN = null;
                try {
                    endpointIpForDPN = InterfaceUtils.getEndpointIpAddressForDPN(dataBroker, srcDpnId);
                } catch (Exception e) {
                    /* this dpn does not have the VTEP */
                    endpointIpForDPN = null;
                }

                if (endpointIpForDPN == null) {
                    LOG.trace("Tunnel TEP is deleted on Dpn {} VTEP Ip {}", srcDpnId, srcTepIp);
                    isTepDeletedOnDpn = true;
                }
            }

            // Get the list of VpnInterfaces from Intf Mgr for a SrcDPN on which TEP is added/deleted
            Future<RpcResult<GetDpnInterfaceListOutput>> result;
            List<String> srcDpninterfacelist = new ArrayList<>();
            List<String> destDpninterfacelist = new ArrayList<>();
            try {
                result = intfRpcService.getDpnInterfaceList(new GetDpnInterfaceListInputBuilder().setDpid(srcDpnId).build());
                RpcResult<GetDpnInterfaceListOutput> rpcResult = result.get();
                if (!rpcResult.isSuccessful()) {
                    LOG.warn("RPC Call to GetDpnInterfaceList for dpnid {} returned with Errors {}", srcDpnId, rpcResult.getErrors());
                } else {
                    srcDpninterfacelist = rpcResult.getResult().getInterfacesList();
                }
            } catch (Exception e) {
                LOG.warn("Exception {} when querying for GetDpnInterfaceList for dpnid {}, trace {}", e, srcDpnId, e.getStackTrace());
            }

            // Get the list of VpnInterfaces from Intf Mgr for a destDPN only for internal tunnel.
            if (tunTypeVal == VpnConstants.ITMTunnelLocType.Internal.getValue()) {
                remoteDpnId = new BigInteger(stateTunnelList.getDstInfo().getTepDeviceId());
                try {
                    result = intfRpcService.getDpnInterfaceList(new GetDpnInterfaceListInputBuilder().setDpid(remoteDpnId).build());
                    RpcResult<GetDpnInterfaceListOutput> rpcResult = result.get();
                    if (!rpcResult.isSuccessful()) {
                        LOG.warn("RPC Call to GetDpnInterfaceList for dpnid {} returned with Errors {}", srcDpnId, rpcResult.getErrors());
                    } else {
                        destDpninterfacelist = rpcResult.getResult().getInterfacesList();
                    }
                } catch (Exception e) {
                    LOG.warn("Exception {} when querying for GetDpnInterfaceList for dpnid {}, trace {}", e, srcDpnId, e.getStackTrace());
                }
            }

            /*
             * Iterate over the list of VpnInterface for a SrcDpn on which TEP is added or deleted and read the adj.
             * Update the adjacencies with the updated nexthop.
             */
            Iterator<String> interfacelistIter = srcDpninterfacelist.iterator();
            String intfName = null;
            List<Uuid> subnetList = new ArrayList<Uuid>();
            Map<Long, String> vpnIdRdMap = new HashMap<Long, String>();

            while (interfacelistIter.hasNext()) {
                intfName = interfacelistIter.next();
                final VpnInterface vpnInterface = VpnUtil.getOperationalVpnInterface(dataBroker, intfName);
                if (vpnInterface != null) {

                    DataStoreJobCoordinator dataStoreCoordinator = DataStoreJobCoordinator.getInstance();
                    dataStoreCoordinator.enqueueJob("VPNINTERFACE-" + intfName,
                            new UpdateVpnInterfaceOnTunnelEvent(dataBroker,
                                    vpnInterfaceManager,
                                    tunnelAction,
                                    vpnInterface,
                                    stateTunnelList,
                                    isTepDeletedOnDpn));

                    // Populate the List of subnets
                    InstanceIdentifier<PortOpDataEntry> portOpIdentifier = InstanceIdentifier.builder(PortOpData.class).
                            child(PortOpDataEntry.class, new PortOpDataEntryKey(intfName)).build();
                    Optional<PortOpDataEntry> optionalPortOp = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
                    if (optionalPortOp.isPresent()) {
                        Uuid subnetId = optionalPortOp.get().getSubnetId();
                        if (!subnetList.contains(subnetId)) {
                            subnetList.add(subnetId);
                        }
                    }
                    //Populate the map for VpnId-to-Rd
                    long vpnId = VpnUtil.getVpnId(dataBroker, vpnInterface.getVpnInstanceName());
                    rd = VpnUtil.getVpnRd(dataBroker, vpnInterface.getVpnInstanceName());
                    vpnIdRdMap.put(vpnId, rd);
                }
            }

            /*
             * Iterate over the list of VpnInterface for destDPN and get the prefix .
             * Create remote rule for each of those prefix on srcDPN.
             */
            interfacelistIter = destDpninterfacelist.iterator();
            while (interfacelistIter.hasNext()) {
                intfName = interfacelistIter.next();
                final VpnInterface vpnInterface = VpnUtil.getOperationalVpnInterface(dataBroker, intfName);
                if (vpnInterface != null) {
                    Adjacencies adjacencies = vpnInterface.getAugmentation(Adjacencies.class);
                    List<Adjacency> adjList = adjacencies != null ? adjacencies.getAdjacency()
                            : Collections.emptyList();
                    String prefix = null;
                    long vpnId = VpnUtil.getVpnId(dataBroker, vpnInterface.getVpnInstanceName());
                    if (vpnIdRdMap.containsKey(vpnId)) {
                        rd = vpnIdRdMap.get(vpnId);
                        LOG.trace(" Remote DpnId {} VpnId {} rd {} VpnInterface {}", remoteDpnId, vpnId, rd , vpnInterface);
                        for (Adjacency adj : adjList) {
                            prefix = adj.getIpAddress();
                            if ((tunnelAction == TunnelAction.TUNNEL_EP_ADD) &&
                                    (tunTypeVal == VpnConstants.ITMTunnelLocType.Internal.getValue())) {
                                fibManager.manageRemoteRouteOnDPN(true, srcDpnId, vpnId, rd, prefix, destTepIp);
                            }

                            if ((tunnelAction == TunnelAction.TUNNEL_EP_DELETE) &&
                                    (tunTypeVal == VpnConstants.ITMTunnelLocType.Internal.getValue())) {
                                fibManager.manageRemoteRouteOnDPN(false, srcDpnId, vpnId, rd, prefix, destTepIp);
                            }
                        }
                    }
                }
            }

            //Iterate over the VpnId-to-Rd map.
            Iterator<Map.Entry<Long, String>> entries = vpnIdRdMap.entrySet().iterator();
            while (entries.hasNext()) {
                Map.Entry<Long, String> entry = entries.next();
                Long vpnId = entry.getKey();
                rd = entry.getValue();
                if ((tunnelAction == TunnelAction.TUNNEL_EP_ADD) &&
                        (tunTypeVal == VpnConstants.ITMTunnelLocType.External.getValue())) {
                    fibManager.populateExternalRoutesOnDpn(srcDpnId, vpnId, rd, srcTepIp, destTepIp);
                } else if ((tunnelAction == TunnelAction.TUNNEL_EP_DELETE) &&
                        (tunTypeVal == VpnConstants.ITMTunnelLocType.External.getValue())) {
                    fibManager.cleanUpExternalRoutesOnDpn(srcDpnId, vpnId, rd, srcTepIp, destTepIp);
                }
            }

            if (tunnelAction == TunnelAction.TUNNEL_EP_ADD) {
                for (Uuid subnetId : subnetList) {
                    // Populate the List of subnets
                    vpnSubnetRouteHandler.updateSubnetRouteOnTunnelUpEvent(subnetId, srcDpnId);
                }
            }

            if ((tunnelAction == TunnelAction.TUNNEL_EP_DELETE) && isTepDeletedOnDpn) {
                for (Uuid subnetId : subnetList) {
                    // Populate the List of subnets
                    vpnSubnetRouteHandler.updateSubnetRouteOnTunnelDownEvent(subnetId, srcDpnId);
                }
            }
        } catch (Exception e) {
            LOG.error("Unable to handle the tunnel event.", e);
            return;
        }

    }


    private class UpdateVpnInterfaceOnTunnelEvent implements Callable {
        private VpnInterface vpnInterface;
        private StateTunnelList stateTunnelList;
        private VpnInterfaceManager vpnInterfaceManager;
        private  DataBroker broker;
        private TunnelAction tunnelAction;
        private boolean isTepDeletedOnDpn;

        UpdateVpnInterfaceOnTunnelEvent(DataBroker broker,
                                        VpnInterfaceManager vpnInterfaceManager,
                                        TunnelAction tunnelAction,
                                        VpnInterface vpnInterface,
                                        StateTunnelList stateTunnelList,
                                        boolean isTepDeletedOnDpn) {
            this.broker = broker;
            this.vpnInterfaceManager = vpnInterfaceManager;
            this.stateTunnelList = stateTunnelList;
            this.vpnInterface = vpnInterface;
            this.tunnelAction = tunnelAction;
            this.isTepDeletedOnDpn = isTepDeletedOnDpn;
        }

        @Override
        public List<ListenableFuture<Void>> call() throws Exception {

            if(tunnelAction == TunnelAction.TUNNEL_EP_ADD) {
                vpnInterfaceManager.updateVpnInterfaceOnTepAdd(vpnInterface, stateTunnelList);
            }

            if((tunnelAction == TunnelAction.TUNNEL_EP_DELETE) && isTepDeletedOnDpn) {
                vpnInterfaceManager.updateVpnInterfaceOnTepDelete(vpnInterface, stateTunnelList);
            }

            return null;
        }
    }

    private int getTunnelType (StateTunnelList stateTunnelList) {
        int tunTypeVal = 0;
        if (stateTunnelList.getDstInfo().getTepDeviceType() == TepTypeInternal.class) {
            tunTypeVal = VpnConstants.ITMTunnelLocType.Internal.getValue();
        } else if (stateTunnelList.getDstInfo().getTepDeviceType() == TepTypeExternal.class) {
            tunTypeVal = VpnConstants.ITMTunnelLocType.External.getValue();
        } else if (stateTunnelList.getDstInfo().getTepDeviceType() == TepTypeHwvtep.class) {
            tunTypeVal = VpnConstants.ITMTunnelLocType.Hwvtep.getValue();
        } else {
            tunTypeVal = VpnConstants.ITMTunnelLocType.Invalid.getValue();
        }
        return tunTypeVal;
    }
}
