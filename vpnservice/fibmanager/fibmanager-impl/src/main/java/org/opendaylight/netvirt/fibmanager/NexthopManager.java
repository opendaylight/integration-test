/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.fibmanager;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.GroupEntity;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.L2vlan;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.iana._if.type.rev140508.Tunnel;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfaceType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.action.OutputActionCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.action.PushVlanActionCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.action.SetFieldCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.Adjacencies;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.AdjacencyKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.prefix.to._interface.vpn.ids.Prefixes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetInternalOrExternalInterfaceNameInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetInternalOrExternalInterfaceNameOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetTunnelInterfaceNameInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetTunnelInterfaceNameOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeFlat;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.SegmentTypeVlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.L3nexthop;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.VpnNexthops;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.VpnNexthopsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.vpnnexthops.VpnNexthop;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.vpnnexthops.VpnNexthopBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3nexthop.rev150409.l3nexthop.vpnnexthops.VpnNexthopKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.add.group.input.buckets.bucket.action.action.NxActionResubmitRpcAddGroupCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nodes.node.table.flow.instructions.instruction.instruction.apply.actions._case.apply.actions.action.action.NxActionRegLoadNodesNodeTableFlowApplyActionsCase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.nx.action.reg.load.grouping.NxRegLoad;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.opendaylight.genius.itm.globals.ITMConstants;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.ConfTransportTypeL3vpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.ConfTransportTypeL3vpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeMplsOverGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

public class NexthopManager implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NexthopManager.class);
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalApiManager;
    private final OdlInterfaceRpcService interfaceManager;
    private final ItmRpcService itmManager;
    private final IdManagerService idManager;
    private final IElanService elanService;
    private static final short LPORT_INGRESS_TABLE = 0;
    private static final short LFIB_TABLE = 20;
    private static final short FIB_TABLE = 21;
    private static final short DEFAULT_FLOW_PRIORITY = 10;
    private static final String NEXTHOP_ID_POOL_NAME = "nextHopPointerPool";
    private static final long FIXED_DELAY_IN_MILLISECONDS = 4000;
    private L3VPNTransportTypes configuredTransportTypeL3VPN = L3VPNTransportTypes.Invalid;
    private Long waitTimeForSyncInstall;

    private static final FutureCallback<Void> DEFAULT_CALLBACK =
            new FutureCallback<Void>() {
                @Override
                public void onSuccess(Void result) {
                    LOG.debug("Success in Datastore write operation");
                }
                @Override
                public void onFailure(Throwable error) {
                    LOG.error("Error in Datastore write operation", error);
                };
            };

    /**
     * Provides nexthop functions
     * Creates group ID pool
     *
     * @param dataBroker - dataBroker reference
     * @param mdsalApiManager - mdsalApiManager reference
     * @param idManager - idManager reference
     * @param interfaceManager - interfaceManager reference
     * @param itmManager - itmManager reference
     */
    public NexthopManager(final DataBroker dataBroker,
                          final IMdsalApiManager mdsalApiManager,
                          final IdManagerService idManager,
                          final OdlInterfaceRpcService interfaceManager,
                          final ItmRpcService itmManager,
                          final IElanService elanService) {
        this.dataBroker = dataBroker;
        this.mdsalApiManager = mdsalApiManager;
        this.idManager = idManager;
        this.interfaceManager = interfaceManager;
        this.itmManager = itmManager;
        this.elanService = elanService;
        waitTimeForSyncInstall = Long.getLong("wait.time.sync.install");
        if (waitTimeForSyncInstall == null) {
            waitTimeForSyncInstall = 1000L;
        }

        createIdPool();
    }

    private void createIdPool() {
        CreateIdPoolInput createPool = new CreateIdPoolInputBuilder()
                .setPoolName(NEXTHOP_ID_POOL_NAME)
                .setLow(150000L)
                .setHigh(175000L)
                .build();
        try {
            Future<RpcResult<Void>> result = idManager.createIdPool(createPool);
            if ((result != null) && (result.get().isSuccessful())) {
                LOG.info("Created IdPool for NextHopPointerPool");
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to create idPool for NextHopPointerPool",e);
        }
    }

    private BigInteger getDpnId(String ofPortId) {
        String[] fields = ofPortId.split(":");
        BigInteger dpn = new BigInteger(fields[1]);
        LOG.debug("DpnId: {}", dpn);
        return dpn;
    }

    private String getNextHopKey(long vpnId, String ipAddress){
        String nhKey = new String("nexthop." + vpnId + ipAddress);
        return nhKey;
    }

    private String getNextHopKey(String ifName, String ipAddress){
        String nhKey = new String("nexthop." + ifName + ipAddress);
        return nhKey;
    }

    protected long createNextHopPointer(String nexthopKey) {
        AllocateIdInput getIdInput = new AllocateIdInputBuilder()
                .setPoolName(NEXTHOP_ID_POOL_NAME).setIdKey(nexthopKey)
                .build();
        //TODO: Proper error handling once IdManager code is complete
        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            return rpcResult.getResult().getIdValue();
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.trace("",e);
        }
        return 0;
    }

    protected void removeNextHopPointer(String nexthopKey) {
        ReleaseIdInput idInput = new ReleaseIdInputBuilder().
                setPoolName(NEXTHOP_ID_POOL_NAME)
                .setIdKey(nexthopKey).build();
        try {
            Future<RpcResult<Void>> result = idManager.releaseId(idInput);
            RpcResult<Void> rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to Get Unique Id returned with Errors {}", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting Unique Id for key {}", nexthopKey, e);
        }
    }

    protected List<ActionInfo> getEgressActionsForInterface(String ifName) {
        List<ActionInfo> listActionInfo = new ArrayList<ActionInfo>();
        try {
            Future<RpcResult<GetEgressActionsForInterfaceOutput>> result =
                    interfaceManager.getEgressActionsForInterface(
                            new GetEgressActionsForInterfaceInputBuilder().setIntfName(ifName).build());
            RpcResult<GetEgressActionsForInterfaceOutput> rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to Get egress actions for interface {} returned with Errors {}", ifName, rpcResult.getErrors());
            } else {
                List<org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action> actions =
                        rpcResult.getResult().getAction();
                for (Action action : actions) {
                    org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.Action actionClass = action.getAction();
                    if (actionClass instanceof OutputActionCase) {
                        listActionInfo.add(new ActionInfo(ActionType.output,
                                new String[] {((OutputActionCase)actionClass).getOutputAction()
                                        .getOutputNodeConnector().getValue()}));
                    } else if (actionClass instanceof PushVlanActionCase) {
                        listActionInfo.add(new ActionInfo(ActionType.push_vlan, new String[] {}));
                    } else if (actionClass instanceof SetFieldCase) {
                        if (((SetFieldCase)actionClass).getSetField().getVlanMatch() != null) {
                            int vlanVid = ((SetFieldCase)actionClass).getSetField().getVlanMatch().getVlanId().getVlanId().getValue();
                            listActionInfo.add(new ActionInfo(ActionType.set_field_vlan_vid,
                                    new String[] { Long.toString(vlanVid) }));
                        }
                    } else if (actionClass instanceof NxActionResubmitRpcAddGroupCase) {
                        Short tableId = ((NxActionResubmitRpcAddGroupCase)actionClass).getNxResubmit().getTable();
                        listActionInfo.add(new ActionInfo(ActionType.nx_resubmit,
                            new String[] { tableId.toString() }, action.getKey().getOrder() + 1));
                    } else if (actionClass instanceof NxActionRegLoadNodesNodeTableFlowApplyActionsCase) {
                        NxRegLoad nxRegLoad =
                            ((NxActionRegLoadNodesNodeTableFlowApplyActionsCase)actionClass).getNxRegLoad();
                        listActionInfo.add(new ActionInfo(ActionType.nx_load_reg_6,
                            new String[] { nxRegLoad.getDst().getStart().toString(),
                                nxRegLoad.getDst().getEnd().toString(),
                                nxRegLoad.getValue().toString(10)}, action.getKey().getOrder() + 1));
                    }
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when egress actions for interface {}", ifName, e);
        }
        return listActionInfo;
    }

    protected String getTunnelInterfaceName(BigInteger srcDpId, BigInteger dstDpId) {
        Class<? extends TunnelTypeBase> tunType = getReqTunType(getReqTransType().toUpperCase());
        Future<RpcResult<GetTunnelInterfaceNameOutput>> result;
        try {
            result = itmManager.getTunnelInterfaceName(new GetTunnelInterfaceNameInputBuilder()
                    .setSourceDpid(srcDpId)
                    .setDestinationDpid(dstDpId)
                    .setTunnelType(tunType)
                    .build());
            RpcResult<GetTunnelInterfaceNameOutput> rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to getTunnelInterfaceId returned with Errors {}", rpcResult.getErrors());
            } else {
                return rpcResult.getResult().getInterfaceName();
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting tunnel interface Id for tunnel between {} and  {}", srcDpId, dstDpId, e);
        }
        return null;
    }

    protected String getTunnelInterfaceName(BigInteger srcDpId, org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress dstIp) {
        Class<? extends TunnelTypeBase> tunType = getReqTunType(getReqTransType().toUpperCase());
        Future<RpcResult<GetInternalOrExternalInterfaceNameOutput>> result;
        try {
            result = itmManager.getInternalOrExternalInterfaceName(new GetInternalOrExternalInterfaceNameInputBuilder()
                    .setSourceDpid(srcDpId)
                    .setDestinationIp(dstIp)
                    .setTunnelType(tunType)
                    .build());
            RpcResult<GetInternalOrExternalInterfaceNameOutput> rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                LOG.warn("RPC Call to getTunnelInterfaceName returned with Errors {}", rpcResult.getErrors());
            } else {
                return rpcResult.getResult().getInterfaceName();
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when getting tunnel interface Id for tunnel between {} and  {}", srcDpId, dstIp, e);
        }
        return null;
    }

    public long createLocalNextHop(long vpnId, BigInteger dpnId,
                                   String ifName, String ipNextHopAddress, String ipPrefixAddress) {
        String macAddress = FibUtil.getMacAddressFromPrefix(dataBroker, ifName, ipPrefixAddress);
        String ipAddress = (macAddress != null) ? ipPrefixAddress: ipNextHopAddress;

        long groupId = createNextHopPointer(getNextHopKey(vpnId, ipAddress));
        if (groupId == 0) {
            LOG.error("Unable to allocate groupId for vpnId {} , prefix {}", vpnId, ipAddress);
            return groupId;
        }
        String nextHopLockStr = new String(vpnId + ipAddress);
        synchronized (nextHopLockStr.intern()) {
            VpnNexthop nexthop = getVpnNexthop(vpnId, ipAddress);
            LOG.trace("nexthop: {} retrieved for vpnId {}, prefix {}, ifName {} on dpn {}", nexthop,
                    vpnId, ipAddress, ifName, dpnId);
            if (nexthop == null) {
                if (macAddress == null ) {
                    macAddress = FibUtil.getMacAddressFromPrefix(dataBroker, ifName, ipAddress);
                }
                List<BucketInfo> listBucketInfo = new ArrayList<BucketInfo>();
                List<ActionInfo> listActionInfo = new ArrayList<>();
                // MAC re-write
                if (macAddress != null) {
                    int actionKey = listActionInfo.size();
                    listActionInfo.add(new ActionInfo(ActionType.set_field_eth_dest,
                        new String[]{macAddress}, actionKey));
                    //listActionInfo.add(0, new ActionInfo(ActionType.pop_mpls, new String[]{}));
                } else {
                    //FIXME: Log message here.
                    LOG.debug("mac address for new local nexthop is null");
                }
                listActionInfo.addAll(getEgressActionsForInterface(ifName));
                BucketInfo bucket = new BucketInfo(listActionInfo);

                listBucketInfo.add(bucket);
                GroupEntity groupEntity = MDSALUtil.buildGroupEntity(
                        dpnId, groupId, ipAddress, GroupTypes.GroupAll, listBucketInfo);
                LOG.trace("Install LNH Group: id {}, mac address {}, interface {} for prefix {}", groupId, macAddress, ifName, ipAddress);

                // install Group
                mdsalApiManager.syncInstallGroup(groupEntity, FIXED_DELAY_IN_MILLISECONDS);
                try{
                    LOG.info("Sleeping for {} to wait for the groups to get programmed.", waitTimeForSyncInstall);
                    Thread.sleep(waitTimeForSyncInstall);
                }catch(InterruptedException error){
                    LOG.warn("Error while waiting for group {} to install.", groupId);
                    LOG.debug("{}", error);
                }
                //update MD-SAL DS
                addVpnNexthopToDS(dpnId, vpnId, ipAddress, groupId);

            } else {
                //nexthop exists already; a new flow is going to point to it, increment the flowrefCount by 1
                int flowrefCnt = nexthop.getFlowrefCount() + 1;
                VpnNexthop nh = new VpnNexthopBuilder().setKey(new VpnNexthopKey(ipAddress)).setFlowrefCount(flowrefCnt).build();
                LOG.trace("Updating vpnnextHop {} for refCount {} to Operational DS", nh, flowrefCnt);
                syncWrite(LogicalDatastoreType.OPERATIONAL, getVpnNextHopIdentifier(vpnId, ipAddress), nh, DEFAULT_CALLBACK);

            }
        }
        return groupId;
    }

    protected void addVpnNexthopToDS(BigInteger dpnId, long vpnId, String ipPrefix, long egressPointer) {

        InstanceIdentifierBuilder<VpnNexthops> idBuilder = InstanceIdentifier.builder(
                L3nexthop.class)
                .child(VpnNexthops.class, new VpnNexthopsKey(vpnId));

        // Add nexthop to vpn node
        VpnNexthop nh = new VpnNexthopBuilder().
                setKey(new VpnNexthopKey(ipPrefix)).
                setDpnId(dpnId).
                setIpAddress(ipPrefix).
                setFlowrefCount(1).
                setEgressPointer(egressPointer).build();

        InstanceIdentifier<VpnNexthop> id1 = idBuilder
                .child(VpnNexthop.class, new VpnNexthopKey(ipPrefix)).build();
        LOG.trace("Adding vpnnextHop {} to Operational DS", nh);
        syncWrite(LogicalDatastoreType.OPERATIONAL, id1, nh, DEFAULT_CALLBACK);

    }

    protected InstanceIdentifier<VpnNexthop> getVpnNextHopIdentifier(long vpnId, String ipAddress) {
        InstanceIdentifier<VpnNexthop> id = InstanceIdentifier.builder(
                L3nexthop.class)
                .child(VpnNexthops.class, new VpnNexthopsKey(vpnId)).child(VpnNexthop.class, new VpnNexthopKey(ipAddress)).build();
        return id;
    }

    protected VpnNexthop getVpnNexthop(long vpnId, String ipAddress) {

        // check if vpn node is there
        InstanceIdentifierBuilder<VpnNexthops> idBuilder =
                InstanceIdentifier.builder(L3nexthop.class).child(VpnNexthops.class,
                        new VpnNexthopsKey(vpnId));
        InstanceIdentifier<VpnNexthops> id = idBuilder.build();
        Optional<VpnNexthops> vpnNexthops = read(LogicalDatastoreType.OPERATIONAL, id);
        if (vpnNexthops.isPresent()) {
            // get nexthops list for vpn
            List<VpnNexthop> nexthops = vpnNexthops.get().getVpnNexthop();
            for (VpnNexthop nexthop : nexthops) {
                if (nexthop.getIpAddress().equals(ipAddress)) {
                    // return nexthop
                    LOG.trace("VpnNextHop : {}", nexthop);
                    return nexthop;
                }
            }
            // return null if not found
        }
        return null;
    }

    public AdjacencyResult getRemoteNextHopPointer(BigInteger remoteDpnId, long vpnId, String prefixIp,
            String nextHopIp) {
        String egressIfName = null;
        LOG.trace("getRemoteNextHopPointer: input [remoteDpnId {}, vpnId {}, prefixIp {}, nextHopIp {} ]", remoteDpnId,
                vpnId, prefixIp, nextHopIp);

        Class<? extends InterfaceType> egressIfType;
        ElanInstance elanInstance = getElanInstanceForPrefix(vpnId, prefixIp);
        if (elanInstance != null) {
            egressIfType = getInterfaceType(elanInstance);
        } else {
            LOG.warn("Failed to determine network type for prefixIp {} using tunnel", prefixIp);
            egressIfType = Tunnel.class;
        }

        if (Tunnel.class.equals(egressIfType)) {
            egressIfName = getTunnelRemoteNextHopPointer(remoteDpnId, nextHopIp);
        } else {
            egressIfName = getExtPortRemoteNextHopPointer(remoteDpnId, elanInstance);
        }

        LOG.trace("NextHop pointer for prefixIp {} vpnId {} dpnId {} is {}", prefixIp, vpnId, remoteDpnId,
                egressIfName);
        return egressIfName != null ? new AdjacencyResult(egressIfName, egressIfType) : null;
    }

    public BigInteger getDpnForPrefix(long vpnId, String prefixIp) {
        VpnNexthop vpnNexthop = getVpnNexthop(vpnId, prefixIp);
        BigInteger localDpnId = (vpnNexthop == null) ? null : vpnNexthop.getDpnId();
        return localDpnId;
    }

    private void removeVpnNexthopFromDS(long vpnId, String ipPrefix) {

        InstanceIdentifierBuilder<VpnNexthop> idBuilder = InstanceIdentifier.builder(L3nexthop.class)
                .child(VpnNexthops.class, new VpnNexthopsKey(vpnId))
                .child(VpnNexthop.class, new VpnNexthopKey(ipPrefix));
        InstanceIdentifier<VpnNexthop> id = idBuilder.build();
        // remove from DS
        LOG.trace("Removing vpn next hop from datastore : {}", id);
        syncDelete(LogicalDatastoreType.OPERATIONAL, id);
    }

    public void removeLocalNextHop(BigInteger dpnId, Long vpnId, String ipNextHopAddress, String ipPrefixAddress ) {
        String ipPrefixStr = new String(vpnId + ipPrefixAddress);
        VpnNexthop prefixNh = null;
        synchronized (ipPrefixStr.intern()) {
            prefixNh = getVpnNexthop(vpnId, ipPrefixAddress);
        }
        String ipAddress = (prefixNh != null) ? ipPrefixAddress : ipNextHopAddress;

        String nextHopLockStr = new String(vpnId + ipAddress);
        synchronized (nextHopLockStr.intern()) {
            VpnNexthop nh = getVpnNexthop(vpnId, ipAddress);
            if (nh != null) {
                int newFlowrefCnt = nh.getFlowrefCount() - 1;
                if (newFlowrefCnt == 0) { //remove the group only if there are no more flows using this group
                    GroupEntity groupEntity = MDSALUtil.buildGroupEntity(
                            dpnId, nh.getEgressPointer(), ipAddress, GroupTypes.GroupAll, null);
                    // remove Group ...
                    mdsalApiManager.removeGroup(groupEntity);
                    //update MD-SAL DS
                    removeVpnNexthopFromDS(vpnId, ipAddress);
                    //release groupId
                    removeNextHopPointer(getNextHopKey(vpnId, ipAddress));
                    LOG.debug("Local Next hop {} for {} {} on dpn {} successfully deleted", nh.getEgressPointer(), vpnId, ipAddress, dpnId);
                } else {
                    //just update the flowrefCount of the vpnNexthop
                    VpnNexthop currNh = new VpnNexthopBuilder().setKey(new VpnNexthopKey(ipAddress)).setFlowrefCount(newFlowrefCnt).build();
                    LOG.trace("Updating vpnnextHop {} for refCount {} to Operational DS", currNh, newFlowrefCnt);
                    syncWrite(LogicalDatastoreType.OPERATIONAL, getVpnNextHopIdentifier(vpnId, ipAddress), currNh, DEFAULT_CALLBACK);
                }
            } else {
                //throw error
                LOG.error("Local Next hop for {} on dpn {} not deleted", ipAddress, dpnId);
            }
        }

    }


    private <T extends DataObject> Optional<T> read(LogicalDatastoreType datastoreType,
                                                    InstanceIdentifier<T> path) {

        ReadOnlyTransaction tx = dataBroker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return result;
    }

    private <T extends DataObject> void asyncWrite(LogicalDatastoreType datastoreType,
                                                   InstanceIdentifier<T> path, T data,
                                                   FutureCallback<Void> callback) {
        WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
        tx.merge(datastoreType, path, data, true);
        Futures.addCallback(tx.submit(), callback);
    }

    private <T extends DataObject> void syncWrite(LogicalDatastoreType datastoreType,
                                                  InstanceIdentifier<T> path, T data,
                                                  FutureCallback<Void> callback) {
        WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
        tx.merge(datastoreType, path, data, true);
        CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
        try {
            futures.get();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error writing to datastore (path, data) : ({}, {})", path, data, e);
            throw new RuntimeException(e.getMessage());
        }
    }

    private <T extends DataObject> void syncDelete(LogicalDatastoreType datastoreType, InstanceIdentifier<T> path) {
        WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
        tx.delete(datastoreType, path);
        CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
        try {
            futures.get();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error deleting from datastore (path) : ({})", path, e);
            throw new RuntimeException(e.getMessage());
        }
    }

    InstanceIdentifier<Adjacency> getAdjacencyIdentifier(String vpnInterfaceName, String ipAddress) {
        return InstanceIdentifier.builder(VpnInterfaces.class)
                .child(VpnInterface.class, new VpnInterfaceKey(vpnInterfaceName)).augmentation(
                        Adjacencies.class).child(Adjacency.class, new AdjacencyKey(ipAddress)).build();
    }

    InstanceIdentifier<Adjacencies> getAdjListPath(String vpnInterfaceName) {
        return InstanceIdentifier.builder(VpnInterfaces.class)
                .child(VpnInterface.class, new VpnInterfaceKey(vpnInterfaceName)).augmentation(
                        Adjacencies.class).build();
    }

    public void setConfTransType(String service,String transportType) {

        if (!service.toUpperCase().equals("L3VPN")) {
            System.out.println("Please provide a valid service name. Available value(s): L3VPN");
            LOG.error("Incorrect service {} provided for setting the transport type.", service);
            return;
        }

        L3VPNTransportTypes transType = L3VPNTransportTypes.validateTransportType(transportType.toUpperCase());

        if (transType != L3VPNTransportTypes.Invalid) {
            configuredTransportTypeL3VPN = transType;
        }
    }

    public void writeConfTransTypeConfigDS() {
        FibUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, getConfTransportTypeIdentifier(),
                createConfTransportType(configuredTransportTypeL3VPN.getTransportType()),
                FibUtil.DEFAULT_CALLBACK);
    }

    public L3VPNTransportTypes getConfiguredTransportTypeL3VPN() {
        return this.configuredTransportTypeL3VPN;
    }

    public String getReqTransType() {
        if (configuredTransportTypeL3VPN == L3VPNTransportTypes.Invalid) {
            /*
            * Restart scenario, Read from the ConfigDS.
            * if the value is Unset, cache value as VxLAN.
            */
            LOG.trace("configureTransportType is not yet set.");
            Optional<ConfTransportTypeL3vpn>  configuredTransTypeFromConfig =
                    FibUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, getConfTransportTypeIdentifier());

            if (configuredTransTypeFromConfig.isPresent()) {
                if (configuredTransTypeFromConfig.get().getTransportType().equals(TunnelTypeGre.class)) {
                    configuredTransportTypeL3VPN.setL3VPNTransportTypes(ITMConstants.TUNNEL_TYPE_GRE);
                } else {
                    configuredTransportTypeL3VPN.setL3VPNTransportTypes(ITMConstants.TUNNEL_TYPE_VXLAN);
                }
                LOG.trace("configuredTransportType set from config DS to " + getConfiguredTransportTypeL3VPN().getTransportType());
            } else {
                setConfTransType("L3VPN", L3VPNTransportTypes.VxLAN.getTransportType());
                LOG.trace("configuredTransportType is not set in the Config DS. VxLAN as default will be used.");
            }
        } else {
            LOG.trace("configuredTransportType is set as {}", getConfiguredTransportTypeL3VPN().getTransportType());
        }
        return getConfiguredTransportTypeL3VPN().getTransportType();
    }
    public InstanceIdentifier<ConfTransportTypeL3vpn> getConfTransportTypeIdentifier() {
        return InstanceIdentifier.builder(ConfTransportTypeL3vpn.class).build();
    }

    private ConfTransportTypeL3vpn createConfTransportType (String type) {
        ConfTransportTypeL3vpn confTransType;
        if (type.equals(ITMConstants.TUNNEL_TYPE_GRE)) {
            confTransType = new ConfTransportTypeL3vpnBuilder().setTransportType(TunnelTypeGre.class).build();
            LOG.trace("Setting the confTransportType to GRE.");
        } else if (type.equals(ITMConstants.TUNNEL_TYPE_VXLAN)) {
            confTransType = new ConfTransportTypeL3vpnBuilder().setTransportType(TunnelTypeVxlan.class).build();
            LOG.trace("Setting the confTransportType to VxLAN.");
        } else {
            LOG.trace("Invalid transport type {} passed to Config DS ", type);
            confTransType = null;
        }
        return  confTransType;
    }

    public Class<? extends TunnelTypeBase> getReqTunType(String transportType) {
        if (transportType.equals("VXLAN")) {
            return TunnelTypeVxlan.class;
        } else if (transportType.equals("GRE")) {
            return TunnelTypeGre.class;
        } else {
            return TunnelTypeMplsOverGre.class;
        }
    }

    public String getTransportTypeStr ( String tunType) {
        if (tunType.equals(TunnelTypeVxlan.class.toString())) {
            return ITMConstants.TUNNEL_TYPE_VXLAN;
        } else if (tunType.equals(TunnelTypeGre.class.toString())) {
            return ITMConstants.TUNNEL_TYPE_GRE;
        } else if (tunType.equals(TunnelTypeMplsOverGre.class.toString())){
            return ITMConstants.TUNNEL_TYPE_MPLSoGRE;
        } else {
            return ITMConstants.TUNNEL_TYPE_INVALID;
        }
    }

    @Override
    public void close() throws Exception {
        LOG.info("{} close", getClass().getSimpleName());
    }

    private String getTunnelRemoteNextHopPointer(BigInteger remoteDpnId, String nextHopIp) {
        if (nextHopIp != null && !nextHopIp.isEmpty()) {
            try {
                // here use the config for tunnel type param
                return getTunnelInterfaceName(remoteDpnId,
                        org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddressBuilder
                                .getDefaultInstance(nextHopIp));
            } catch (Exception ex) {
                LOG.error("Error while retrieving nexthop pointer for nexthop {} : ", nextHopIp, ex);
            }
        }

        return null;
    }

    private String getExtPortRemoteNextHopPointer(BigInteger remoteDpnId, ElanInstance elanInstance) {
        return elanService.getExternalElanInterface(elanInstance.getElanInstanceName(), remoteDpnId);
    }

    /**
     * Get the interface type associated with the type of ELAN used for routing
     * traffic to/from remote compute nodes
     *
     * @param elanInstance
     * @return L2vlan for flat/VLAN network type and Tunnel otherwise
     */
    private Class<? extends InterfaceType> getInterfaceType(ElanInstance elanInstance) {
        Class<? extends SegmentTypeBase> segmentType = elanInstance.getSegmentType();
        if (SegmentTypeFlat.class.equals(segmentType) || SegmentTypeVlan.class.equals(segmentType)) {
            return L2vlan.class;
        }

        return Tunnel.class;
    }

    private ElanInstance getElanInstanceForPrefix(long vpnId, String prefixIp) {
        Prefixes prefix = FibUtil.getPrefixToInterface(dataBroker, vpnId, prefixIp);
        if (prefix == null) {
            LOG.warn("No prefix info was found for VPN id {} prefix {}", vpnId, prefixIp);
            return null;
        }

        String interfaceName = prefix.getVpnInterfaceName();
        if (interfaceName == null) {
            LOG.warn("No VPN interface found for VPN id {} prefix {}", vpnId, prefixIp);
            return null;
        }

        ElanInterface elanInterface = elanService.getElanInterfaceByElanInterfaceName(interfaceName);
        if (elanInterface == null) {
            LOG.warn("No ELAN interface found for VPN interface {} on VPN id {}", interfaceName, vpnId);
            return null;
        }

        return elanService.getElanInstance(elanInterface.getElanInstanceName());
    }

    static class AdjacencyResult {
        private String interfaceName;
        private Class<? extends InterfaceType> interfaceType;

        public AdjacencyResult(String interfaceName, Class<? extends InterfaceType> interfaceType) {
            this.interfaceName = interfaceName;
            this.interfaceType = interfaceType;
        }

        public String getInterfaceName() {
            return interfaceName;
        }

        public Class<? extends InterfaceType> getInterfaceType() {
            return interfaceType;
        }

        @Override
        public int hashCode() {
            final int prime = 31;
            int result = 1;
            result = prime * result + ((interfaceName == null) ? 0 : interfaceName.hashCode());
            return result;
        }

        @Override
        public boolean equals(Object obj) {
            boolean result = false;
            if (getClass() != obj.getClass())
                return result;
            else {
                AdjacencyResult other = (AdjacencyResult) obj;
                result = interfaceName.equals(other.interfaceName);
            }
            return result;
        }
    }
}
