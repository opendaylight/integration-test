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
import com.google.common.collect.Sets.SetView;
import com.google.common.util.concurrent.AsyncFunction;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.JdkFutureAdapters;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.GroupEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.api.IVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeGre;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetTunnelInterfaceNameInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.GetTunnelInterfaceNameOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rpcs.rev160406.ItmRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.CreateFibEntryInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.CreateFibEntryInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.FibRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.RemoveFibEntryInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fib.rpc.rev160121.RemoveFibEntryInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExtRouters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalIpsCounter;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.IntextIpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.NaptSwitches;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ProtocolTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.RouterIdName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.RoutersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.ExternalCounters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.external.counters.ExternalIpCounter;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.IntextIpProtocolType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.ip.port.map.IpPortExternal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitch;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.napt.switches.RouterToNaptSwitchKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.id.name.RouterIds;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.id.name.RouterIdsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.router.id.name.RouterIdsKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.Subnetmaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.GenerateVpnLabelInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.GenerateVpnLabelInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.GenerateVpnLabelOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.RemoveVpnLabelInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.RemoveVpnLabelInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.VpnRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ExternalRoutersListener extends AsyncDataTreeChangeListenerBase<Routers, ExternalRoutersListener> {
    private static final Logger LOG = LoggerFactory.getLogger( ExternalRoutersListener.class);
    private ListenerRegistration<DataChangeListener> listenerRegistration;
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private final ItmRpcService itmManager;
    private final OdlInterfaceRpcService interfaceManager;
    private final IdManagerService idManager;
    private final NaptManager naptManager;
    private final NAPTSwitchSelector naptSwitchSelector;
    private final IBgpManager bgpManager;
    private final VpnRpcService vpnService;
    private final FibRpcService fibService;
    private final SNATDefaultRouteProgrammer defaultRouteProgrammer;
    private final NaptEventHandler naptEventHandler;
    private final NaptPacketInHandler naptPacketInHandler;
    private final IFibManager fibManager;
    private final IVpnManager vpnManager;
    private static final BigInteger COOKIE_TUNNEL = new BigInteger("9000000", 16);
    static final BigInteger COOKIE_VM_LFIB_TABLE = new BigInteger("8000022", 16);

    public ExternalRoutersListener(final DataBroker dataBroker, final IMdsalApiManager mdsalManager,
                                   final ItmRpcService itmManager,
                                   final OdlInterfaceRpcService interfaceManager,
                                   final IdManagerService idManager,
                                   final NaptManager naptManager,
                                   final NAPTSwitchSelector naptSwitchSelector,
                                   final IBgpManager bgpManager,
                                   final VpnRpcService vpnService,
                                   final FibRpcService fibService,
                                   final SNATDefaultRouteProgrammer snatDefaultRouteProgrammer,
                                   final NaptEventHandler naptEventHandler,
                                   final NaptPacketInHandler naptPacketInHandler,
                                   final IFibManager fibManager,
                                   final IVpnManager vpnManager) {
        super(Routers.class, ExternalRoutersListener.class);
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.itmManager = itmManager;
        this.interfaceManager = interfaceManager;
        this.idManager = idManager;
        this.naptManager = naptManager;
        this.naptSwitchSelector = naptSwitchSelector;
        this.bgpManager = bgpManager;
        this.vpnService = vpnService;
        this.fibService = fibService;
        this.defaultRouteProgrammer = snatDefaultRouteProgrammer;
        this.naptEventHandler = naptEventHandler;
        this.naptPacketInHandler = naptPacketInHandler;
        this.fibManager = fibManager;
        this.vpnManager = vpnManager;
    }

    @Override
    public void init() {
        LOG.info("{} init", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
        createGroupIdPool();
    }

    @Override
    protected InstanceIdentifier<Routers> getWildCardPath() {
        return InstanceIdentifier.create(ExtRouters.class).child(Routers.class);
    }

    @Override
    protected void add(InstanceIdentifier<Routers> identifier, Routers routers) {

        LOG.info("NAT Service : Add external router event for {}", routers.getRouterName());

        // Populate the router-id-name container
        String routerName = routers.getRouterName();
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        RouterIds rtrs = new RouterIdsBuilder().setKey(new RouterIdsKey(routerId)).setRouterId(routerId).setRouterName(routerName).build();
        MDSALUtil.syncWrite( dataBroker, LogicalDatastoreType.CONFIGURATION, getRoutersIdentifier(routerId), rtrs);

        LOG.info("NAT Service : Installing NAT default route on all dpns part of router {}", routers.getRouterName());
        try {
            addOrDelDefFibRouteToSNAT(routers.getRouterName(), true);
        } catch (Exception ex) {
            LOG.debug("NAT Service : Exception {} while Installing NAT default route on all dpns part of router {}",ex,routers.getRouterName());
        }

        long segmentId = NatUtil.getVpnId(dataBroker, routerName);
        // Allocate Primary Napt Switch for this router
        BigInteger primarySwitchId = getPrimaryNaptSwitch(routerName, segmentId);
        if(primarySwitchId == null || primarySwitchId.equals(BigInteger.ZERO)){
            LOG.error("NAT Service: Failed to get or allocated NAPT switch");
            return;
        }

        handleRouterGwFlows(routers, primarySwitchId, NwConstants.ADD_FLOW);
        if( !routers.isEnableSnat()) {
            LOG.info("NAT Service : SNAT is disabled for external router {} ", routerName);
            return;
        }

        handleEnableSnat(routers, segmentId, primarySwitchId);
    }

    public void handleEnableSnat(Routers routers, long segmentId, BigInteger primarySwitchId) {
        String routerName = routers.getRouterName();
        LOG.info("NAT Service : Handling SNAT for router {}", routerName);

        naptManager.initialiseExternalCounter(routers, segmentId);
        subnetRegisterMapping(routers,segmentId);

        LOG.debug("NAT Service : About to create and install outbound miss entry in Primary Switch {} for router {}", primarySwitchId, routerName);

        long bgpVpnId = NatConstants.INVALID_ID;
        Uuid bgpVpnUuid = NatUtil.getVpnForRouter(dataBroker, routerName);
        if (bgpVpnUuid != null) {
            bgpVpnId = NatUtil.getVpnId(dataBroker, bgpVpnUuid.getValue());
        }
        if (bgpVpnId != NatConstants.INVALID_ID){
            installFlowsWithUpdatedVpnId(primarySwitchId, routerName, bgpVpnId, segmentId, false);
        } else {
            // write metadata and punt
            installOutboundMissEntry(routerName, primarySwitchId);
            // Now install entries in SNAT tables to point to Primary for each router
            List<BigInteger> switches = naptSwitchSelector.getDpnsForVpn(routerName);
            if (switches != null) {
                for (BigInteger dpnId : switches) {
                    // Handle switches and NAPT switches separately
                    if (!dpnId.equals(primarySwitchId)) {
                        LOG.debug("NAT Service : Handle Ordinary switch");
                        handleSwitches(dpnId, routerName, primarySwitchId);
                    } else {
                        LOG.debug("NAT Service : Handle NAPT switch");
                        handlePrimaryNaptSwitch(dpnId, routerName);
                        installNaptPfibExternalOutputFlow(routers, dpnId);
                    }
                }
            }
        }

        List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker,segmentId);
        if (externalIps == null || externalIps.isEmpty()) {
            LOG.debug("NAT Service : Internal External mapping found for router {}",routerName);
            return;
        } else {
            for (String externalIpAddrPrefix : externalIps) {
                LOG.debug("NAT Service : Calling handleSnatReverseTraffic for primarySwitchId {}, routerName {} and externalIpAddPrefix {}", primarySwitchId, routerName, externalIpAddrPrefix);
                handleSnatReverseTraffic(primarySwitchId, segmentId, externalIpAddrPrefix);
            }
        }

        /*// call registerMapping Api
        LOG.debug("NAT Service : Preparing to call registerMapping for routerName {} and Id {}", routerName, segmentId);

        List<Uuid> subnetList = null;
        List<String> externalIps = null;

        InstanceIdentifier<Routers> id = InstanceIdentifier
                .builder(ExtRouters.class)
                .child(Routers.class, new RoutersKey(routerName))
                .build();

        Optional<Routers> extRouters = read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);

        if(extRouters.isPresent())
        {
            LOG.debug("NAT Service : Fetching values from extRouters model");
            Routers routerEntry= extRouters.get();
            subnetList = routerEntry.getSubnetIds();
            externalIps = routerEntry.getExternalIps();
            int counter = 0;
            int extIpCounter = externalIps.size();
            LOG.debug("NAT Service : counter values before looping counter {} and extIpCounter {}", counter, extIpCounter);
            for(Uuid subnet : subnetList) {
                  LOG.debug("NAT Service : Looping internal subnets for subnet {}", subnet);
                  InstanceIdentifier<Subnetmap> subnetmapId = InstanceIdentifier
                         .builder(Subnetmaps.class)
                         .child(Subnetmap.class, new SubnetmapKey(subnet))
                         .build();
                  Optional<Subnetmap> sn = read(dataBroker, LogicalDatastoreType.CONFIGURATION, subnetmapId);
                  if(sn.isPresent()){
                      // subnets
                      Subnetmap subnetmapEntry = sn.get();
                      String subnetString = subnetmapEntry.getSubnetIp();
                      String[] subnetSplit = subnetString.split("/");
                      String subnetIp = subnetSplit[0];
                      String subnetPrefix = "0";
                      if(subnetSplit.length ==  2) {
                          subnetPrefix = subnetSplit[1];
                      }
                      IPAddress subnetAddr = new IPAddress(subnetIp, Integer.parseInt(subnetPrefix));
                      LOG.debug("NAT Service : subnetAddr is {} and subnetPrefix is {}", subnetAddr.getIpAddress(), subnetAddr.getPrefixLength());
                      //externalIps
                      LOG.debug("NAT Service : counter values counter {} and extIpCounter {}", counter, extIpCounter);
                      if(extIpCounter != 0) {
                            if(counter < extIpCounter) {
                                   String[] IpSplit = externalIps.get(counter).split("/");
                                   String externalIp = IpSplit[0];
                                   String extPrefix = Short.toString(NatConstants.DEFAULT_PREFIX);
                                   if(IpSplit.length==2) {
                                       extPrefix = IpSplit[1];
                                   }
                                   IPAddress externalIpAddr = new IPAddress(externalIp, Integer.parseInt(extPrefix));
                                   LOG.debug("NAT Service : externalIp is {} and extPrefix  is {}", externalIpAddr.getIpAddress(), externalIpAddr.getPrefixLength());
                                   naptManager.registerMapping(segmentId, subnetAddr, externalIpAddr);
                                   LOG.debug("NAT Service : Called registerMapping for subnetIp {}, prefix {}, externalIp {}. prefix {}", subnetIp, subnetPrefix,
                                            externalIp, extPrefix);

                                   String externalIpAddrPrefix = externalIpAddr.getIpAddress() + "/" + externalIpAddr.getPrefixLength();
                                   LOG.debug("NAT Service : Calling handleSnatReverseTraffic for primarySwitchId {}, routerName {} and externalIpAddPrefix {}", primarySwitchId, routerName, externalIpAddrPrefix);
                                   handleSnatReverseTraffic(primarySwitchId, segmentId, externalIpAddrPrefix);

                            } else {
                                   counter = 0;    //Reset the counter which runs on externalIps for round-robbin effect
                                   LOG.debug("NAT Service : Counter on externalIps got reset");
                                   String[] IpSplit = externalIps.get(counter).split("/");
                                   String externalIp = IpSplit[0];
                                   String extPrefix = Short.toString(NatConstants.DEFAULT_PREFIX);
                                   if(IpSplit.length==2) {
                                       extPrefix = IpSplit[1];
                                   }
                                   IPAddress externalIpAddr = new IPAddress(externalIp, Integer.parseInt(extPrefix));
                                   LOG.debug("NAT Service : externalIp is {} and extPrefix  is {}", externalIpAddr.getIpAddress(), externalIpAddr.getPrefixLength());
                                   naptManager.registerMapping(segmentId, subnetAddr, externalIpAddr);
                                   LOG.debug("NAT Service : Called registerMapping for subnetIp {}, prefix {}, externalIp {}. prefix {}", subnetIp, subnetPrefix,
                                            externalIp, extPrefix);

                                   String externalIpAddrPrefix = externalIpAddr.getIpAddress() + "/" + externalIpAddr.getPrefixLength();
                                   LOG.debug("NAT Service : Calling handleSnatReverseTraffic for primarySwitchId {}, routerName {} and externalIpAddPrefix {}", primarySwitchId, routerName, externalIpAddrPrefix);
                                   handleSnatReverseTraffic(primarySwitchId, segmentId, externalIpAddrPrefix);

                            }
                      }
                      counter++;
                      LOG.debug("NAT Service : Counter on externalIps incremented to {}", counter);

                  } else {
                      LOG.warn("NAT Service : No internal subnets present in extRouters Model");
                  }
            }
        }*/
        LOG.info("NAT Service : handleEnableSnat() Exit");
    }

    private BigInteger getPrimaryNaptSwitch(String routerName, long segmentId) {
        // Allocate Primary Napt Switch for this router
        BigInteger primarySwitchId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, segmentId);
        if (primarySwitchId != null && !primarySwitchId.equals(BigInteger.ZERO)) {
            LOG.debug("NAT Service : Primary NAPT switch with DPN ID {} is already elected for router",primarySwitchId,routerName);
            return primarySwitchId;
        }

        primarySwitchId = naptSwitchSelector.selectNewNAPTSwitch(routerName);
        LOG.debug("NAT Service : Primary NAPT switch DPN ID {}", primarySwitchId);
        if(primarySwitchId == null || primarySwitchId.equals(BigInteger.ZERO)){
            LOG.error("NAT Service : Unable to to select the primary NAPT switch");
        }

        return primarySwitchId;
    }

    private void installNaptPfibExternalOutputFlow(Routers routers, BigInteger dpnId) {
        Long extVpnId = NatUtil.getVpnId(dataBroker, routers.getNetworkId().getValue());

        String ip = getExternalIpFromRouter(routers);
        Uuid subnetId = getSubnetIdOfIp(ip);

        if (subnetId != null) {
            FlowEntity postNaptFlowEntity = buildNaptFibExternalOutputFlowEntity(dpnId, extVpnId, subnetId, ip);
            mdsalManager.installFlow(postNaptFlowEntity);
        }
    }

    private Uuid getSubnetIdOfIp(String ip) {
        if (ip != null) {
            IpAddress externalIpv4Address = new IpAddress(new Ipv4Address(ip));
            Port port = NatUtil.getNeutronPortForRouterGetewayIp(dataBroker, externalIpv4Address);
            Uuid subnetId = NatUtil.getSubnetIdForFloatingIp(port, externalIpv4Address);
            return subnetId;
        }
        return null;
    }

    private String getExternalIpFromRouter(Routers routers) {
        List<String> extIps = routers.getExternalIps();
        if (extIps != null && !extIps.isEmpty()) {
            return extIps.get(0);
        }
        return null;
    }

    private void subnetRegisterMapping(Routers routerEntry,Long segmentId) {
        List<Uuid> subnetList = null;
        List<String> externalIps = null;
        LOG.debug("NAT Service : Fetching values from extRouters model");
        subnetList = routerEntry.getSubnetIds();
        externalIps = routerEntry.getExternalIps();
        int counter = 0;
        int extIpCounter = externalIps.size();
        LOG.debug("NAT Service : counter values before looping counter {} and extIpCounter {}", counter, extIpCounter);
        for(Uuid subnet : subnetList) {
            LOG.debug("NAT Service : Looping internal subnets for subnet {}", subnet);
            InstanceIdentifier<Subnetmap> subnetmapId = InstanceIdentifier
                    .builder(Subnetmaps.class)
                    .child(Subnetmap.class, new SubnetmapKey(subnet))
                    .build();
            Optional<Subnetmap> sn = read(dataBroker, LogicalDatastoreType.CONFIGURATION, subnetmapId);
            if(sn.isPresent()){
                // subnets
                Subnetmap subnetmapEntry = sn.get();
                String subnetString = subnetmapEntry.getSubnetIp();
                String[] subnetSplit = subnetString.split("/");
                String subnetIp = subnetSplit[0];
                String subnetPrefix = "0";
                if(subnetSplit.length ==  2) {
                    subnetPrefix = subnetSplit[1];
                }
                IPAddress subnetAddr = new IPAddress(subnetIp, Integer.parseInt(subnetPrefix));
                LOG.debug("NAT Service : subnetAddr is {} and subnetPrefix is {}", subnetAddr.getIpAddress(), subnetAddr.getPrefixLength());
                //externalIps
                LOG.debug("NAT Service : counter values counter {} and extIpCounter {}", counter, extIpCounter);
                if(extIpCounter != 0) {
                    if(counter < extIpCounter) {
                        String[] IpSplit = externalIps.get(counter).split("/");
                        String externalIp = IpSplit[0];
                        String extPrefix = Short.toString(NatConstants.DEFAULT_PREFIX);
                        if(IpSplit.length==2) {
                            extPrefix = IpSplit[1];
                        }
                        IPAddress externalIpAddr = new IPAddress(externalIp, Integer.parseInt(extPrefix));
                        LOG.debug("NAT Service : externalIp is {} and extPrefix  is {}", externalIpAddr.getIpAddress(), externalIpAddr.getPrefixLength());
                        naptManager.registerMapping(segmentId, subnetAddr, externalIpAddr);
                        LOG.debug("NAT Service : Called registerMapping for subnetIp {}, prefix {}, externalIp {}. prefix {}", subnetIp, subnetPrefix,
                                externalIp, extPrefix);
                    } else {
                        counter = 0;    //Reset the counter which runs on externalIps for round-robbin effect
                        LOG.debug("NAT Service : Counter on externalIps got reset");
                        String[] IpSplit = externalIps.get(counter).split("/");
                        String externalIp = IpSplit[0];
                        String extPrefix = Short.toString(NatConstants.DEFAULT_PREFIX);
                        if(IpSplit.length==2) {
                            extPrefix = IpSplit[1];
                        }
                        IPAddress externalIpAddr = new IPAddress(externalIp, Integer.parseInt(extPrefix));
                        LOG.debug("NAT Service : externalIp is {} and extPrefix  is {}", externalIpAddr.getIpAddress(), externalIpAddr.getPrefixLength());
                        naptManager.registerMapping(segmentId, subnetAddr, externalIpAddr);
                        LOG.debug("NAT Service : Called registerMapping for subnetIp {}, prefix {}, externalIp {}. prefix {}", subnetIp, subnetPrefix,
                                externalIp, extPrefix);
                    }
                }
                counter++;
                LOG.debug("NAT Service : Counter on externalIps incremented to {}", counter);
            } else {
                LOG.warn("NAT Service : No internal subnets present in extRouters Model");
            }
        }
    }

    private void addOrDelDefFibRouteToSNAT(String routerName, boolean create) {
        //Check if BGP VPN exists. If exists then invoke the new method.
        long bgpVpnId = NatUtil.getBgpVpnId(dataBroker, routerName);
        if(bgpVpnId != NatConstants.INVALID_ID) {
            Uuid bgpVpnUuid = NatUtil.getVpnForRouter(dataBroker, routerName);
            if (bgpVpnUuid != null) {
                String bgpVpnName = bgpVpnUuid.getValue();
                LOG.debug("Populate the router-id-name container with the mapping BGP VPN-ID {} -> BGP VPN-NAME {}", bgpVpnId, bgpVpnName);
                RouterIds rtrs = new RouterIdsBuilder().setKey(new RouterIdsKey(bgpVpnId)).setRouterId(bgpVpnId).setRouterName(bgpVpnName).build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, getRoutersIdentifier(bgpVpnId), rtrs);
            }
            addOrDelDefaultFibRouteForSNATWIthBgpVpn(routerName, bgpVpnId, create);
            return;
        }

        //Router ID is used as the internal VPN's name, hence the vrf-id in VpnInstance Op DataStore
        addOrDelDefaultFibRouteForSNAT(routerName, create);
    }

    private void addOrDelDefaultFibRouteForSNAT(String routerName, boolean create) {
        List<BigInteger> switches = naptSwitchSelector.getDpnsForVpn(routerName);
        if (switches == null || switches.isEmpty()) {
            LOG.debug("No switches found for router {}",routerName);
            return;
        }
        long routerId = NatUtil.readVpnId(dataBroker, routerName);
        if (routerId == NatConstants.INVALID_ID) {
            LOG.error("Could not retrieve router Id for {} to program default NAT route in FIB", routerName);
            return;
        }
        for (BigInteger dpnId : switches) {
            if (create) {
                LOG.debug("NAT Service : installing default NAT route for router {} in dpn {} for the internal vpn",routerId,dpnId);
                defaultRouteProgrammer.installDefNATRouteInDPN(dpnId, routerId);
            } else {
                LOG.debug("NAT Service : removing default NAT route for router {} in dpn {} for the internal vpn",routerId,dpnId);
                defaultRouteProgrammer.removeDefNATRouteInDPN(dpnId, routerId);
            }
        }
    }

    private void addOrDelDefaultFibRouteForSNATWIthBgpVpn(String routerName, long bgpVpnId, boolean create) {
        List<BigInteger> dpnIds = NatUtil.getDpnsForRouter(dataBroker, routerName);
        if(dpnIds == null || dpnIds.isEmpty()) {
            LOG.debug("NAT Service : Current no dpns part of router {} to program default NAT route", routerName);
            return;
        }
        long routerId = NatUtil.getVpnId(dataBroker, routerName);
        for (BigInteger dpnId : dpnIds) {
            if (create) {
                if (bgpVpnId != NatConstants.INVALID_ID) {
                    LOG.debug("NAT Service : installing default NAT route for router {} in dpn {} for the BGP vpnID {}",routerId,dpnId,bgpVpnId);
                    defaultRouteProgrammer.installDefNATRouteInDPN(dpnId, bgpVpnId, routerId);
                } else {
                    LOG.debug("NAT Service : installing default NAT route for router {} in dpn {} for the internal vpn",routerId,dpnId);
                    defaultRouteProgrammer.installDefNATRouteInDPN(dpnId, routerId);
                }
            } else {
                if (bgpVpnId != NatConstants.INVALID_ID) {
                    LOG.debug("NAT Service : removing default NAT route for router {} in dpn {} for the BGP vpnID {}",routerId,dpnId,bgpVpnId);
                    defaultRouteProgrammer.removeDefNATRouteInDPN(dpnId, bgpVpnId, routerId);
                } else {
                    LOG.debug("NAT Service : removing default NAT route for router {} in dpn {} for the internal vpn",routerId,dpnId);
                    defaultRouteProgrammer.removeDefNATRouteInDPN(dpnId, routerId);
                }
            }
        }
    }

    public static <T extends DataObject> Optional<T> read(DataBroker broker, LogicalDatastoreType datastoreType, InstanceIdentifier<T> path)
    {
        ReadOnlyTransaction tx = broker.newReadOnlyTransaction();

        Optional<T> result = Optional.absent();
        try
        {
            result = tx.read(datastoreType, path).get();
        }
        catch (Exception e)
        {
            throw new RuntimeException(e);
        }

        return result;
    }

    @Override
    public void close() throws Exception
    {
        if (listenerRegistration != null)
        {
            try
            {
                listenerRegistration.close();
            }
            catch (final Exception e)
            {
                LOG.error("Error when cleaning up ExternalRoutersListener.", e);
            }

            listenerRegistration = null;
        }
        LOG.debug("ExternalRoutersListener Closed");
    }

    protected void installOutboundMissEntry(String routerName, BigInteger primarySwitchId) {
        long routerId = NatUtil.getVpnId(dataBroker, routerName);
        LOG.debug("NAT Service : Router ID from getVpnId {}", routerId);
        if(routerId != NatConstants.INVALID_ID) {
            LOG.debug("NAT Service : Creating miss entry on primary {}, for router {}", primarySwitchId, routerId);
            createOutboundTblEntry(primarySwitchId, routerId);
        } else {
            LOG.error("NAT Service : Unable to fetch Router Id  for RouterName {}, failed to createAndInstallMissEntry", routerName);
        }
    }

    public String getFlowRefOutbound(BigInteger dpnId, short tableId, long routerID) {
        return new StringBuilder().append(NatConstants.NAPT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
                append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID).toString();
    }

    private String getFlowRefNaptFib(BigInteger dpnId, short tableId, long routerID, String externalIp) {
        return new StringBuilder().append(NatConstants.NAPT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
                append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID).
                append(NatConstants.FLOWID_SEPARATOR).append(externalIp).toString();
    }

    public BigInteger getCookieOutboundFlow(long routerId) {
        return NwConstants.COOKIE_OUTBOUND_NAPT_TABLE.add(new BigInteger("0110001", 16)).add(
                BigInteger.valueOf(routerId));
    }

    protected FlowEntity buildOutboundFlowEntity(BigInteger dpId, long routerId) {
        LOG.debug("NAT Service : buildOutboundFlowEntity called for dpId {} and routerId{}", dpId, routerId);
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(routerId), MetaDataUtil.METADATA_MASK_VRFID }));

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller, new String[] {}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        instructions.add(new InstructionInfo(InstructionType.write_metadata,
                new BigInteger[] { MetaDataUtil.getVpnIdMetadata(routerId), MetaDataUtil.METADATA_MASK_VRFID }));

        String flowRef = getFlowRefOutbound(dpId, NwConstants.OUTBOUND_NAPT_TABLE, routerId);
        BigInteger cookie = getCookieOutboundFlow(routerId);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.OUTBOUND_NAPT_TABLE, flowRef,
                5, flowRef, 0, 0,
                cookie, matches, instructions);
        LOG.debug("NAT Service : returning flowEntity {}", flowEntity);
        return flowEntity;
    }

    public void createOutboundTblEntry(BigInteger dpnId, long routerId) {
        LOG.debug("NAT Service : createOutboundTblEntry called for dpId {} and routerId {}", dpnId, routerId);
        FlowEntity flowEntity = buildOutboundFlowEntity(dpnId, routerId);
        LOG.debug("NAT Service : Installing flow {}", flowEntity);
        mdsalManager.installFlow(flowEntity);
    }

    protected String getTunnelInterfaceName(BigInteger srcDpId, BigInteger dstDpId) {
        Class<? extends TunnelTypeBase> tunType = TunnelTypeVxlan.class;
        RpcResult<GetTunnelInterfaceNameOutput> rpcResult;
        try {
            Future<RpcResult<GetTunnelInterfaceNameOutput>> result = itmManager.getTunnelInterfaceName(new GetTunnelInterfaceNameInputBuilder()
                                                                                 .setSourceDpid(srcDpId)
                                                                                 .setDestinationDpid(dstDpId)
                                                                                .setTunnelType(tunType)
                                                                                .build());
            rpcResult = result.get();
            if(!rpcResult.isSuccessful()) {
                tunType = TunnelTypeGre.class ;
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
        } catch (InterruptedException | ExecutionException | NullPointerException e) {
            LOG.warn("NAT Service : Exception when getting tunnel interface Id for tunnel between {} and  {}", srcDpId, dstDpId);
        }

        return null;
    }

    protected void installSnatMissEntryForPrimrySwch(BigInteger dpnId, String routerName) {
        LOG.debug("NAT Service : installSnatMissEntry called for for the primary NAOT switch dpnId {} ", dpnId);
        // Install miss entry pointing to group
        FlowEntity flowEntity = buildSnatFlowEntityForPrmrySwtch(dpnId, routerName);
        mdsalManager.installFlow(flowEntity);
    }

    protected void installSnatMissEntry(BigInteger dpnId, List<BucketInfo> bucketInfo, String routerName) {
        LOG.debug("NAT Service : installSnatMissEntry called for dpnId {} with primaryBucket {} ", dpnId, bucketInfo.get(0));
        // Install the select group
        long groupId = createGroupId(getGroupIdKey(routerName));
        GroupEntity groupEntity = MDSALUtil.buildGroupEntity(dpnId, groupId, routerName, GroupTypes.GroupAll, bucketInfo);
        LOG.debug("NAT Service : installing the SNAT to NAPT GroupEntity:{}", groupEntity);
        mdsalManager.installGroup(groupEntity);
        // Install miss entry pointing to group
        FlowEntity flowEntity = buildSnatFlowEntity(dpnId, routerName, groupId);
        mdsalManager.installFlow(flowEntity);
    }

    long installGroup(BigInteger dpnId, String routerName, List<BucketInfo> bucketInfo){
        long groupId = createGroupId(getGroupIdKey(routerName));
        GroupEntity groupEntity = MDSALUtil.buildGroupEntity(dpnId, groupId, routerName, GroupTypes.GroupAll, bucketInfo);
        LOG.debug("NAT Service : installing the SNAT to NAPT GroupEntity:{}", groupEntity);
        mdsalManager.installGroup(groupEntity);
        return groupId;
    }

    public FlowEntity buildSnatFlowEntity(BigInteger dpId, String routerName, long groupId) {

        LOG.debug("NAT Service : buildSnatFlowEntity is called for dpId {}, routerName {} and groupId {}", dpId, routerName, groupId );
        long routerId = NatUtil.getVpnId(dataBroker, routerName);
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(routerId), MetaDataUtil.METADATA_MASK_VRFID }));


        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfo = new ArrayList<>();

        ActionInfo actionSetField = new ActionInfo(ActionType.set_field_tunnel_id, new BigInteger[] {
                        BigInteger.valueOf(routerId)}) ;
        actionsInfo.add(actionSetField);
        LOG.debug("NAT Service : Setting the tunnel to the list of action infos {}", actionsInfo);
        actionsInfo.add(new ActionInfo(ActionType.group, new String[] {String.valueOf(groupId)}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfo));
        String flowRef = getFlowRefSnat(dpId, NwConstants.PSNAT_TABLE, routerName);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_SNAT_TABLE, matches, instructions);

        LOG.debug("NAT Service : Returning SNAT Flow Entity {}", flowEntity);
        return flowEntity;
    }

    public FlowEntity buildSnatFlowEntityForPrmrySwtch(BigInteger dpId, String routerName) {

        LOG.debug("NAT Service : buildSnatFlowEntity is called for primary NAPT switch dpId {}, routerName {}", dpId,
                routerName );
        long routerId = NatUtil.getVpnId(dataBroker, routerName);
        List<MatchInfo> matches = new ArrayList<MatchInfo>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(routerId), MetaDataUtil.METADATA_MASK_VRFID }));

        List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[]
                { NwConstants.OUTBOUND_NAPT_TABLE }));

        String flowRef = getFlowRefSnat(dpId, NwConstants.PSNAT_TABLE, routerName);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_SNAT_TABLE, matches, instructions);

        LOG.debug("NAT Service : Returning SNAT Flow Entity {}", flowEntity);
        return flowEntity;
    }

    // TODO : Replace this with ITM Rpc once its available with full functionality
    protected void installTerminatingServiceTblEntry(BigInteger dpnId, String routerName) {
        LOG.debug("NAT Service : creating entry for Terminating Service Table for switch {}, routerName {}", dpnId, routerName);
        FlowEntity flowEntity = buildTsFlowEntity(dpnId, routerName);
        mdsalManager.installFlow(flowEntity);

    }

    private FlowEntity buildTsFlowEntity(BigInteger dpId, String routerName) {

        BigInteger routerId = BigInteger.valueOf (NatUtil.getVpnId(dataBroker, routerName));
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.tunnel_id, new  BigInteger[] {routerId }));

        List<InstructionInfo> instructions = new ArrayList<>();
        instructions.add(new InstructionInfo(InstructionType.write_metadata, new BigInteger[]
                { MetaDataUtil.getVpnIdMetadata(routerId.longValue()), MetaDataUtil.METADATA_MASK_VRFID }));
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[]
                { NwConstants.OUTBOUND_NAPT_TABLE }));
        String flowRef = getFlowRefTs(dpId, NwConstants.INTERNAL_TUNNEL_TABLE, routerId.longValue());
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.INTERNAL_TUNNEL_TABLE, flowRef,
                NatConstants.DEFAULT_TS_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_TS_TABLE, matches, instructions);
        return flowEntity;
    }

    public String getFlowRefTs(BigInteger dpnId, short tableId, long routerID) {
        return new StringBuilder().append(NatConstants.NAPT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
                append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID).toString();
    }

    public static String getFlowRefSnat(BigInteger dpnId, short tableId, String routerID) {
        return new StringBuilder().append(NatConstants.SNAT_FLOWID_PREFIX).append(dpnId).append(NatConstants.FLOWID_SEPARATOR).
            append(tableId).append(NatConstants.FLOWID_SEPARATOR).append(routerID).toString();
    }

    private String getGroupIdKey(String routerName){
        String groupIdKey = new String("snatmiss." + routerName);
        return groupIdKey;
    }

    protected long createGroupId(String groupIdKey) {
        AllocateIdInput getIdInput = new AllocateIdInputBuilder()
            .setPoolName(NatConstants.SNAT_IDPOOL_NAME).setIdKey(groupIdKey)
            .build();
        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            return rpcResult.getResult().getIdValue();
        } catch (NullPointerException | InterruptedException | ExecutionException e) {
            LOG.trace("",e);
        }
        return 0;
    }

    protected void createGroupIdPool() {
        CreateIdPoolInput createPool = new CreateIdPoolInputBuilder()
            .setPoolName(NatConstants.SNAT_IDPOOL_NAME)
            .setLow(NatConstants.SNAT_ID_LOW_VALUE)
            .setHigh(NatConstants.SNAT_ID_HIGH_VALUE)
            .build();
        try {
            Future<RpcResult<Void>> result = idManager.createIdPool(createPool);
                if ((result != null) && (result.get().isSuccessful())) {
                    LOG.debug("NAT Service : Created GroupIdPool");
                } else {
                    LOG.error("NAT Service : Unable to create GroupIdPool");
                }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to create PortPool for NAPT Service",e);
        }
    }

    protected void handleSwitches (BigInteger dpnId, String routerName, BigInteger primarySwitchId) {
        LOG.debug("NAT Service : Installing SNAT miss entry in switch {}", dpnId);
        List<ActionInfo> listActionInfoPrimary = new ArrayList<>();
        String ifNamePrimary = getTunnelInterfaceName( dpnId, primarySwitchId);
        List<BucketInfo> listBucketInfo = new ArrayList<>();
        long routerId = NatUtil.getVpnId(dataBroker, routerName);

        if(ifNamePrimary != null) {
            LOG.debug("NAT Service : On Non- Napt switch , Primary Tunnel interface is {}", ifNamePrimary);
            listActionInfoPrimary = NatUtil.getEgressActionsForInterface(interfaceManager, ifNamePrimary, routerId);
        }
        BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);

        listBucketInfo.add(0, bucketPrimary);
        installSnatMissEntry(dpnId, listBucketInfo, routerName);

    }
    List<BucketInfo> getBucketInfoForNonNaptSwitches(BigInteger nonNaptSwitchId, BigInteger primarySwitchId, String routerName) {
        List<ActionInfo> listActionInfoPrimary = new ArrayList<>();
        String ifNamePrimary = getTunnelInterfaceName(nonNaptSwitchId, primarySwitchId);
        List<BucketInfo> listBucketInfo = new ArrayList<>();
        long routerId = NatUtil.getVpnId(dataBroker, routerName);

        if (ifNamePrimary != null) {
            LOG.debug("NAT Service : On Non- Napt switch , Primary Tunnel interface is {}", ifNamePrimary);
            listActionInfoPrimary = NatUtil.getEgressActionsForInterface(interfaceManager, ifNamePrimary, routerId);
        }
        BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);

        listBucketInfo.add(0, bucketPrimary);
        return listBucketInfo;
    }
    protected void handlePrimaryNaptSwitch (BigInteger dpnId, String routerName) {

           /*
            * Primary NAPT Switch â€“ bucket Should always point back to its own Outbound Table
            */

            LOG.debug("NAT Service : Installing SNAT miss entry in Primary NAPT switch {} ", dpnId);

/*
            List<BucketInfo> listBucketInfo = new ArrayList<>();
            List<ActionInfo> listActionInfoPrimary = new ArrayList<>();
            listActionInfoPrimary.add(new ActionInfo(ActionType.nx_resubmit, new String[]{String.valueOf(NatConstants.TERMINATING_SERVICE_TABLE)}));
            BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);
            listBucketInfo.add(0, bucketPrimary);
*/

            long routerId = NatUtil.getVpnId(dataBroker, routerName);

            installSnatMissEntryForPrimrySwch(dpnId, routerName);
            installTerminatingServiceTblEntry(dpnId, routerName);
            //Install the NAPT PFIB TABLE which forwards the outgoing packet to FIB Table matching on the router ID.
            installNaptPfibEntry(dpnId, routerId);
            Long vpnId = NatUtil.getVpnId(dataBroker, routerId);
           //Install the NAPT PFIB TABLE which forwards the outgoing packet to FIB Table matching on the VPN ID.
            if(vpnId != null && vpnId != NatConstants.INVALID_ID) {
                installNaptPfibEntry(dpnId, vpnId);
            }
    }

    List<BucketInfo> getBucketInfoForPrimaryNaptSwitch(){
        List<BucketInfo> listBucketInfo = new ArrayList<>();
        List<ActionInfo> listActionInfoPrimary =  new ArrayList<>();
        listActionInfoPrimary.add(new ActionInfo(ActionType.nx_resubmit, new String[]{String.valueOf(NwConstants.INTERNAL_TUNNEL_TABLE)}));
        BucketInfo bucketPrimary = new BucketInfo(listActionInfoPrimary);
        listBucketInfo.add(0, bucketPrimary);
        return listBucketInfo;
    }

    public void installNaptPfibEntry(BigInteger dpnId, long segmentId) {
        LOG.debug("NAT Service : installNaptPfibEntry called for dpnId {} and segmentId {} ", dpnId, segmentId);
        FlowEntity naptPfibFlowEntity = buildNaptPfibFlowEntity(dpnId, segmentId);
        mdsalManager.installFlow(naptPfibFlowEntity);
    }

    public FlowEntity buildNaptPfibFlowEntity(BigInteger dpId, long segmentId) {

        LOG.debug("NAT Service : buildNaptPfibFlowEntity is called for dpId {}, segmentId {}", dpId, segmentId );
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(segmentId), MetaDataUtil.METADATA_MASK_VRFID }));

        ArrayList<ActionInfo> listActionInfo = new ArrayList<>();
        ArrayList<InstructionInfo> instructionInfo = new ArrayList<>();
        listActionInfo.add(new ActionInfo(ActionType.nx_resubmit, new String[] { Integer.toString(NwConstants.L3_FIB_TABLE) }));
        instructionInfo.add(new InstructionInfo(InstructionType.apply_actions, listActionInfo));

        String flowRef = getFlowRefTs(dpId, NwConstants.NAPT_PFIB_TABLE, segmentId);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.NAPT_PFIB_TABLE, flowRef,
                NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_SNAT_TABLE, matches, instructionInfo);

        LOG.debug("NAT Service : Returning NaptPFib Flow Entity {}", flowEntity);
        return flowEntity;
    }

    private void handleSnatReverseTraffic(BigInteger dpnId, long routerId, String externalIp) {
        LOG.debug("NAT Service : handleSnatReverseTraffic() entry for DPN ID, routerId, externalIp : {}", dpnId, routerId, externalIp);
        Uuid networkId = NatUtil.getNetworkIdFromRouterId(dataBroker, routerId);
        if(networkId == null) {
            LOG.error("NAT Service : networkId is null for the router ID {}", routerId);
            return;
        }
        final String vpnName = NatUtil.getAssociatedVPN(dataBroker, networkId, LOG);
        if(vpnName == null) {
            LOG.error("NAT Service : No VPN associated with ext nw {} to handle add external ip configuration {} in router {}",
                    networkId, externalIp, routerId);
            return;
        }
        advToBgpAndInstallFibAndTsFlows(dpnId, NwConstants.INBOUND_NAPT_TABLE, vpnName, routerId, externalIp, vpnService, fibService, bgpManager, dataBroker, LOG);
        LOG.debug("NAT Service : handleSnatReverseTraffic() exit for DPN ID, routerId, externalIp : {}", dpnId, routerId, externalIp);
    }

    public void advToBgpAndInstallFibAndTsFlows(final BigInteger dpnId, final short tableId, final String vpnName, final long routerId, final String externalIp,
                                                VpnRpcService vpnService, final FibRpcService fibService, final IBgpManager bgpManager, final DataBroker dataBroker,
                                                final Logger log){
        LOG.debug("NAT Service : advToBgpAndInstallFibAndTsFlows() entry for DPN ID {}, tableId {}, vpnname {} and externalIp {}", dpnId, tableId, vpnName, externalIp);
        //Generate VPN label for the external IP
        GenerateVpnLabelInput labelInput = new GenerateVpnLabelInputBuilder().setVpnName(vpnName).setIpPrefix(externalIp).build();
        Future<RpcResult<GenerateVpnLabelOutput>> labelFuture = vpnService.generateVpnLabel(labelInput);

        //On successful generation of the VPN label, advertise the route to the BGP and install the FIB routes.
        ListenableFuture<RpcResult<Void>> future = Futures.transform(JdkFutureAdapters.listenInPoolThread(labelFuture), new AsyncFunction<RpcResult<GenerateVpnLabelOutput>, RpcResult<Void>>() {

            @Override
            public ListenableFuture<RpcResult<Void>> apply(RpcResult<GenerateVpnLabelOutput> result) throws Exception {
                if (result.isSuccessful()) {
                    LOG.debug("NAT Service : inside apply with result success");
                    GenerateVpnLabelOutput output = result.getResult();
                    final long label = output.getLabel();

                    int externalIpInDsFlag = 0;
                    //Get IPMaps from the DB for the router ID
                    List<IpMap> dbIpMaps = NaptManager.getIpMapList(dataBroker, routerId);
                    if (dbIpMaps != null) {
                        for (IpMap dbIpMap : dbIpMaps) {
                            String dbExternalIp = dbIpMap.getExternalIp();
                            //Select the IPMap, whose external IP is the IP for which FIB is installed
                            if (externalIp.equals(dbExternalIp)) {
                                String dbInternalIp = dbIpMap.getInternalIp();
                                IpMapKey dbIpMapKey = dbIpMap.getKey();
                                LOG.debug("Setting label {} for internalIp {} and externalIp {}", label, dbInternalIp, externalIp);
                                IpMap newIpm = new IpMapBuilder().setKey(dbIpMapKey).setInternalIp(dbInternalIp).setExternalIp(dbExternalIp).setLabel(label).build();
                                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, naptManager.getIpMapIdentifier(routerId, dbInternalIp), newIpm);
                                externalIpInDsFlag++;
                            }
                        }
                        if (externalIpInDsFlag <=0) {
                            LOG.debug("NAT Service : External Ip {} not found in DS,Failed to update label {} for routerId {} in DS", externalIp, label, routerId);
                            String errMsg = String.format("Failed to update label %s due to external Ip %s not found in DS for router %s", externalIp, label, routerId);
                            return Futures.immediateFailedFuture(new Exception(errMsg));
                        }
                    } else {
                        LOG.error("NAT Service : Failed to write label {} for externalIp {} for routerId {} in DS", label, externalIp, routerId);
                    }


                    //Inform BGP
                    String rd = NatUtil.getVpnRd(dataBroker, vpnName);
                    String nextHopIp = NatUtil.getEndpointIpAddressForDPN(dataBroker, dpnId);
                    NatUtil.addPrefixToBGP(dataBroker, bgpManager, fibManager, rd, externalIp, nextHopIp, label, log, RouteOrigin.STATIC);

                    //Install custom FIB routes
                    List<Instruction> customInstructions = new ArrayList<>();
                    customInstructions.add(new InstructionInfo(InstructionType.goto_table, new long[]{tableId}).buildInstruction(0));
                    makeTunnelTableEntry(dpnId, label, customInstructions);
                    makeLFibTableEntry(dpnId, label, tableId);

                    CreateFibEntryInput input = new CreateFibEntryInputBuilder().setVpnName(vpnName).setSourceDpid(dpnId)
                            .setIpAddress(externalIp).setServiceId(label).setInstruction(customInstructions).build();
                    Future<RpcResult<Void>> future = fibService.createFibEntry(input);
                    return JdkFutureAdapters.listenInPoolThread(future);
                } else {
                    LOG.error("NAT Service : inside apply with result failed");
                    String errMsg = String.format("Could not retrieve the label for prefix %s in VPN %s, %s", externalIp, vpnName, result.getErrors());
                    return Futures.immediateFailedFuture(new RuntimeException(errMsg));
                }
            }
        });

            Futures.addCallback(future, new FutureCallback<RpcResult<Void>>() {

                @Override
                public void onFailure(Throwable error) {
                    log.error("NAT Service : Error in generate label or fib install process", error);
                }

                @Override
                public void onSuccess(RpcResult<Void> result) {
                    if (result.isSuccessful()) {
                        log.info("NAT Service : Successfully installed custom FIB routes for prefix {}", externalIp);
                    } else {
                        log.error("NAT Service : Error in rpc call to create custom Fib entries for prefix {} in DPN {}, {}", externalIp, dpnId, result.getErrors());
                    }
                }
            });
     }

    private void makeLFibTableEntry(BigInteger dpId, long serviceId, long tableId) {
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[]{0x8847L}));
        matches.add(new MatchInfo(MatchFieldType.mpls_label, new String[]{Long.toString(serviceId)}));

        List<Instruction> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.pop_mpls, new String[]{}));
        Instruction writeInstruction = new InstructionInfo(InstructionType.apply_actions, actionsInfos).buildInstruction(0);
        instructions.add(writeInstruction);
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[]{tableId}).buildInstruction(1));

        // Install the flow entry in L3_LFIB_TABLE
        String flowRef = getFlowRef(dpId, NwConstants.L3_LFIB_TABLE, serviceId, "");

        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.L3_LFIB_TABLE, flowRef,
                10, flowRef, 0, 0,
                COOKIE_VM_LFIB_TABLE, matches, instructions);

        mdsalManager.installFlow(dpId, flowEntity);

        LOG.debug("NAT Service : LFIB Entry for dpID {} : label : {} modified successfully {}",dpId, serviceId );
    }

    private void makeTunnelTableEntry(BigInteger dpnId, long serviceId, List<Instruction> customInstructions) {
        List<MatchInfo> mkMatches = new ArrayList<>();

        LOG.debug("NAT Service : Create terminatingServiceAction on DpnId = {} and serviceId = {} and actions = {}", dpnId , serviceId);

        mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] {BigInteger.valueOf(serviceId)}));

        Flow terminatingServiceTableFlowEntity = MDSALUtil.buildFlowNew(NwConstants.INTERNAL_TUNNEL_TABLE,
                getFlowRef(dpnId, NwConstants.INTERNAL_TUNNEL_TABLE, serviceId, ""), 5, String.format("%s:%d", "TST Flow Entry ", serviceId),
                0, 0, COOKIE_TUNNEL.add(BigInteger.valueOf(serviceId)), mkMatches, customInstructions);

        mdsalManager.installFlow(dpnId, terminatingServiceTableFlowEntity);
    }

    protected InstanceIdentifier<RouterIds> getRoutersIdentifier(long routerId) {
        InstanceIdentifier<RouterIds> id = InstanceIdentifier.builder(
                RouterIdName.class).child(RouterIds.class, new RouterIdsKey(routerId)).build();
        return id;
    }

    private String getFlowRef(BigInteger dpnId, short tableId, long id, String ipAddress) {
        return new StringBuilder(64).append(NatConstants.SNAT_FLOWID_PREFIX).append(dpnId).append(NwConstants.FLOWID_SEPARATOR)
                .append(tableId).append(NwConstants.FLOWID_SEPARATOR)
                .append(id).append(NwConstants.FLOWID_SEPARATOR).append(ipAddress).toString();
    }

    @Override
    protected void update(InstanceIdentifier<Routers> identifier, Routers original, Routers update) {
        String routerName = original.getRouterName();
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        BigInteger dpnId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
        Uuid networkId = original.getNetworkId();

        // Check if its update on SNAT flag
        boolean originalSNATEnabled = original.isEnableSnat();
        boolean updatedSNATEnabled = update.isEnableSnat();
        LOG.debug("NAT Service : update of externalRoutersListener called with originalFlag and updatedFlag as {} and {}", originalSNATEnabled, updatedSNATEnabled);
        if(originalSNATEnabled != updatedSNATEnabled) {
            if(originalSNATEnabled) {
                //SNAT disabled for the router
                Uuid networkUuid = original.getNetworkId();
                LOG.info("NAT Service : SNAT disabled for Router {}", routerName);
                if (routerId == NatConstants.INVALID_ID) {
                    LOG.error("NAT Service : Invalid routerId returned for routerName {}", routerName);
                    return;
                }
                List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker,routerId);
                handleDisableSnat(original, networkUuid, externalIps, false, null, dpnId);
            } else {
                LOG.info("NAT Service : SNAT enabled for Router {}", original.getRouterName());
                handleEnableSnat(original, routerId, dpnId);
            }
        }

        if (!Objects.equals(original.getExtGwMacAddress(), update.getExtGwMacAddress())) {
            handleRouterGwFlows(original, dpnId, NwConstants.DEL_FLOW);
            handleRouterGwFlows(update, dpnId, NwConstants.ADD_FLOW);
        }

        //Check if the Update is on External IPs
        LOG.debug("NAT Service : Checking if this is update on External IPs");
        List<String> originalExternalIpsList = original.getExternalIps();
        List<String> updatedExternalIpsList = update.getExternalIps();
        Set<String> originalExternalIps = Sets.newHashSet(originalExternalIpsList);
        Set<String> updatedExternalIps = Sets.newHashSet(updatedExternalIpsList);

        //Check if the External IPs are added during the update.
        SetView<String> addedExternalIps = Sets.difference(updatedExternalIps, originalExternalIps);
        if(addedExternalIps.size() != 0) {
            LOG.debug("NAT Service : Start processing of the External IPs addition during the update operation");
            vpnManager.setupArpResponderFlowsToExternalNetworkIps(routerName, addedExternalIps, update.getExtGwMacAddress(), dpnId,
                    update.getNetworkId(), null, NwConstants.ADD_FLOW);

            for (String addedExternalIp : addedExternalIps) {
                /*
                    1) Do nothing in the IntExtIp model.
                    2) Initialise the count of the added external IP to 0 in the ExternalCounter model.
                */
                String[] externalIpParts = NatUtil.getExternalIpAndPrefix(addedExternalIp);
                String externalIp = externalIpParts[0];
                String externalIpPrefix = externalIpParts[1];
                String externalpStr = externalIp + "/" + externalIpPrefix;
                LOG.debug("NAT Service : Initialise the count mapping of the external IP {} for the router ID {} in the ExternalIpsCounter model.",
                        externalpStr, routerId);
                naptManager.initialiseNewExternalIpCounter(routerId, externalpStr);
            }
            LOG.debug("NAT Service : End processing of the External IPs addition during the update operation");
        }

        //Check if the External IPs are removed during the update.
        SetView<String> removedExternalIps = Sets.difference(originalExternalIps, updatedExternalIps);
        if(removedExternalIps.size() > 0) {
            LOG.debug("NAT Service : Start processing of the External IPs removal during the update operation");
            vpnManager.setupArpResponderFlowsToExternalNetworkIps(routerName, removedExternalIps, original.getExtGwMacAddress(),
                    dpnId, networkId, null, NwConstants.DEL_FLOW);

            List<String> removedExternalIpsAsList = new ArrayList<>();
            for (String removedExternalIp : removedExternalIps) {
             /*
                1) Remove the mappings in the IntExt IP model which has external IP.
                2) Remove the external IP in the ExternalCounter model.
                3) For the corresponding subnet IDs whose external IP mapping was removed, allocate one of the least loaded external IP.
                   Store the subnet IP and the reallocated external IP mapping in the IntExtIp model.
                4) Increase the count of the allocated external IP by one.
                5) Advertise to the BGP if external IP is allocated for the first time for the router i.e. the route for the external IP is absent.
                6) Remove the NAPT translation entries from Inbound and Outbound NAPT tables for the removed external IPs and also from the model.
                7) Advertise to the BGP for removing the route for the removed external IPs.
              */

                String[] externalIpParts = NatUtil.getExternalIpAndPrefix(removedExternalIp);
                String externalIp = externalIpParts[0];
                String externalIpPrefix = externalIpParts[1];
                String externalIpAddrStr = externalIp + "/" + externalIpPrefix;

                LOG.debug("NAT Service : Clear the routes from the BGP and remove the FIB and TS entries for removed external IP {}", externalIpAddrStr);
                Uuid vpnUuId = NatUtil.getVpnIdfromNetworkId(dataBroker, networkId);
                String vpnName = "";
                if(vpnUuId != null){
                    vpnName = vpnUuId.getValue();
                }
                clrRtsFromBgpAndDelFibTs(dpnId, routerId, externalIpAddrStr, vpnName);

                LOG.debug("NAT Service : Remove the mappings in the IntExtIP model which has external IP.");
                //Get the internal IPs which are associated to the removed external IPs
                List<IpMap> ipMaps = naptManager.getIpMapList(dataBroker, routerId);
                List<String> removedInternalIps = new ArrayList<>();
                for(IpMap ipMap : ipMaps){
                    if(ipMap.getExternalIp().equals(externalIpAddrStr)){
                        removedInternalIps.add(ipMap.getInternalIp());
                    }
                }

                LOG.debug("Remove the mappings of the internal IPs from the IntExtIP model.");
                for(String removedInternalIp : removedInternalIps){
                    LOG.debug("NAT Service : Remove the IP mapping of the internal IP {} for the router ID {} from the IntExtIP model",
                            removedInternalIp, routerId);
                    naptManager.removeFromIpMapDS(routerId, removedInternalIp);
                }

                LOG.debug("NAT Service : Remove the count mapping of the external IP {} for the router ID {} from the ExternalIpsCounter model.",
                        externalIpAddrStr, routerId );
                naptManager.removeExternalIpCounter(routerId, externalIpAddrStr);
                removedExternalIpsAsList.add(externalIpAddrStr);

                LOG.debug("NAT Service : Allocate the least loaded external IPs to the subnets whose external IPs were removed.");
                for(String removedInternalIp : removedInternalIps) {
                    allocateExternalIp(dpnId, routerId, networkId, removedInternalIp);
                }

                LOG.debug("NAT Service : Remove the NAPT translation entries from Inbound and Outbound NAPT tables for the removed external IPs.");
                //Get the internalIP and internal Port which were associated to the removed external IP.
                List<Integer> externalPorts = new ArrayList<>();
                Map<ProtocolTypes, List<String>> protoTypesIntIpPortsMap = new HashMap<>();
                InstanceIdentifier<IpPortMapping> ipPortMappingId = InstanceIdentifier.builder(IntextIpPortMap.class)
                        .child(IpPortMapping.class, new IpPortMappingKey(routerId)).build();
                Optional<IpPortMapping> ipPortMapping = MDSALUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, ipPortMappingId);
                if (ipPortMapping.isPresent()) {
                    List<IntextIpProtocolType> intextIpProtocolTypes = ipPortMapping.get().getIntextIpProtocolType();
                    for(IntextIpProtocolType intextIpProtocolType : intextIpProtocolTypes){
                        ProtocolTypes protoType = intextIpProtocolType.getProtocol();
                        List<IpPortMap> ipPortMaps = intextIpProtocolType.getIpPortMap();
                        for(IpPortMap ipPortMap : ipPortMaps){
                            IpPortExternal ipPortExternal = ipPortMap.getIpPortExternal();
                            if(ipPortExternal.getIpAddress().equals(externalIp)){
                                externalPorts.add(ipPortExternal.getPortNum());
                                List<String> removedInternalIpPorts = protoTypesIntIpPortsMap.get(protoType);
                                if(removedInternalIpPorts != null){
                                    removedInternalIpPorts.add(ipPortMap.getIpPortInternal());
                                    protoTypesIntIpPortsMap.put(protoType, removedInternalIpPorts);
                                }else{
                                    removedInternalIpPorts = new ArrayList<>();
                                    removedInternalIpPorts.add(ipPortMap.getIpPortInternal());
                                    protoTypesIntIpPortsMap.put(protoType, removedInternalIpPorts);
                                }
                            }
                        }
                    }
                }

                //Remove the IP port map from the intext-ip-port-map model, which were containing the removed external IP.
                Set<Map.Entry<ProtocolTypes, List<String>>> protoTypesIntIpPorts = protoTypesIntIpPortsMap.entrySet();
                Map<String, List<String>> internalIpPortMap = new HashMap<>();
                for(Map.Entry protoTypesIntIpPort : protoTypesIntIpPorts){
                    ProtocolTypes protocolType = (ProtocolTypes)protoTypesIntIpPort.getKey();
                    List<String> removedInternalIpPorts = (List<String>)protoTypesIntIpPort.getValue();
                    for(String removedInternalIpPort : removedInternalIpPorts){
                        //Remove the IP port map from the intext-ip-port-map model, which were containing the removed external IP
                        naptManager.removeFromIpPortMapDS(routerId, removedInternalIpPort, protocolType);
                        //Remove the IP port incomint packer map.
                        naptPacketInHandler.removeIncomingPacketMap(removedInternalIpPort);
                        String[] removedInternalIpPortParts = removedInternalIpPort.split(":");
                        if(removedInternalIpPortParts.length == 2){
                            String removedInternalIp = removedInternalIpPortParts[0];
                            String removedInternalPort = removedInternalIpPortParts[1];
                            List<String> removedInternalPortsList =  internalIpPortMap.get(removedInternalPort);
                            if (removedInternalPortsList != null){
                                removedInternalPortsList.add(removedInternalPort);
                                internalIpPortMap.put(removedInternalIp, removedInternalPortsList);
                            }else{
                                removedInternalPortsList = new ArrayList<>();
                                removedInternalPortsList.add(removedInternalPort);
                                internalIpPortMap.put(removedInternalIp, removedInternalPortsList);
                            }
                        }
                    }
                }

                // Delete the entry from SnatIntIpPortMap DS
                Set<String> internalIps = internalIpPortMap.keySet();
                for(String internalIp : internalIps){
                    LOG.debug("NAT Service : Removing IpPort having the internal IP {} from the model SnatIntIpPortMap", internalIp);
                    naptManager.removeFromSnatIpPortDS(routerId, internalIp);
                }

                naptManager.removeNaptPortPool(externalIp);

                LOG.debug("Remove the NAPT translation entries from Inbound NAPT tables for the removed external IP {}", externalIp);
                for(Integer externalPort : externalPorts) {
                    //Remove the NAPT translation entries from Inbound NAPT table
                    naptEventHandler.removeNatFlows(dpnId, NwConstants.INBOUND_NAPT_TABLE, routerId, externalIp, externalPort);
                }

                Set<Map.Entry<String, List<String>>> internalIpPorts = internalIpPortMap.entrySet();
                for(Map.Entry<String, List<String>> internalIpPort : internalIpPorts) {
                    String internalIp = internalIpPort.getKey();
                    LOG.debug("Remove the NAPT translation entries from Outbound NAPT tables for the removed internal IP {}", internalIp);
                    List<String> internalPorts = internalIpPort.getValue();
                    for(String internalPort : internalPorts){
                        //Remove the NAPT translation entries from Outbound NAPT table
                        naptEventHandler.removeNatFlows(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, routerId, internalIp, Integer.valueOf(internalPort));
                    }
                }
            }
            LOG.debug("NAT Service : End processing of the External IPs removal during the update operation");
        }

        //Check if its Update on subnets
        LOG.debug("NAT Service : Checking if this is update on subnets");
        List<Uuid> originalSubnetIdsList = original.getSubnetIds();
        List<Uuid> updatedSubnetIdsList = update.getSubnetIds();
        Set<Uuid> originalSubnetIds = Sets.newHashSet(originalSubnetIdsList);
        Set<Uuid> updatedSubnetIds = Sets.newHashSet(updatedSubnetIdsList);
        SetView<Uuid> addedSubnetIds = Sets.difference(updatedSubnetIds, originalSubnetIds);

        //Check if the Subnet IDs are added during the update.
        if(addedSubnetIds.size() != 0){
            LOG.debug("NAT Service : Start processing of the Subnet IDs addition during the update operation");
            for(Uuid addedSubnetId : addedSubnetIds){
                /*
                1) Select the least loaded external IP for the subnet and store the mapping of the subnet IP and the external IP in the IntExtIp model.
                2) Increase the count of the selected external IP by one.
                3) Advertise to the BGP if external IP is allocated for the first time for the router i.e. the route for the external IP is absent.
                */
                String subnetIp = NatUtil.getSubnetIp(dataBroker, addedSubnetId);
                if(subnetIp != null) {
                    allocateExternalIp(dpnId, routerId, networkId, subnetIp);
                }
            }
            LOG.debug("NAT Service : End processing of the Subnet IDs addition during the update operation");
        }

        //Check if the Subnet IDs are removed during the update.
        SetView<Uuid> removedSubnetIds = Sets.difference(originalSubnetIds, updatedSubnetIds);
        if(removedSubnetIds.size() != 0){
            LOG.debug("NAT Service : Start processing of the Subnet IDs removal during the update operation");
            for(Uuid removedSubnetId : removedSubnetIds){
                String[] subnetAddr = NatUtil.getSubnetIpAndPrefix(dataBroker, removedSubnetId);
                if(subnetAddr != null){
                    /*
                    1) Remove the subnet IP and the external IP in the IntExtIp map
                    2) Decrease the count of the coresponding external IP by one.
                    3) Advertise to the BGP for removing the routes of the corresponding external IP if its not allocated to any other internal IP.
                    */

                    String externalIp = naptManager.getExternalIpAllocatedForSubnet(routerId, subnetAddr[0] + "/" + subnetAddr[1]);
                    if (externalIp == null) {
                        LOG.debug("No mapping found for router ID {} and internal IP {}", routerId, subnetAddr[0]);
                        return;
                    }

                    naptManager.updateCounter(routerId, externalIp, false);
                    //Traverse entire model of external-ip counter whether external ip is not used by any other internal ip in any router
                    if (!isExternalIpAllocated(externalIp)) {
                        LOG.debug("NAT Service : external ip is not allocated to any other internal IP so proceeding to remove routes");
                        List<String> externalIps = new ArrayList<>();
                        externalIps.add(externalIp);
                        clrRtsFromBgpAndDelFibTs(dpnId, routerId, networkId, externalIps, null);
                        LOG.debug("Successfully removed fib entries in switch {} for router {} with networkId {} and externalIps {}",
                                dpnId,routerId,networkId,externalIps);
                    }

                    LOG.debug("NAT Service : Remove the IP mapping for the router ID {} and internal IP {} external IP {}", routerId, subnetAddr[0],externalIp);
                    naptManager.removeIntExtIpMapDS(routerId, subnetAddr[0] + "/" + subnetAddr[1]);
                }
            }
            LOG.debug("NAT Service : End processing of the Subnet IDs removal during the update operation");
        }
    }

    private boolean isExternalIpAllocated(String externalIp) {
        InstanceIdentifier<ExternalIpsCounter> id = InstanceIdentifier.builder(ExternalIpsCounter.class).build();
        Optional <ExternalIpsCounter> externalCountersData = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        if (externalCountersData.isPresent()) {
            ExternalIpsCounter externalIpsCounters = externalCountersData.get();
            List<ExternalCounters> externalCounters = externalIpsCounters.getExternalCounters();
            for(ExternalCounters ext : externalCounters) {
                for (ExternalIpCounter externalIpCount : ext.getExternalIpCounter()) {
                    if (externalIpCount.getExternalIp().equals(externalIp)) {
                        if (externalIpCount.getCounter() != 0) {
                            return true;
                        }
                        break;
                    }
                }
            }
        }
        return false;
    }

    private void allocateExternalIp(BigInteger dpnId, long routerId, Uuid networkId, String subnetIp){
        String leastLoadedExtIpAddr = NatUtil.getLeastLoadedExternalIp(dataBroker, routerId);
        if (leastLoadedExtIpAddr != null) {
            String[] externalIpParts = NatUtil.getExternalIpAndPrefix(leastLoadedExtIpAddr);
            String leastLoadedExtIp = externalIpParts[0];
            String leastLoadedExtIpPrefix = externalIpParts[1];
            String leastLoadedExtIpAddrStr = leastLoadedExtIp + "/" + leastLoadedExtIpPrefix;
            IPAddress externalIpAddr = new IPAddress(leastLoadedExtIp, Integer.parseInt(leastLoadedExtIpPrefix));
            String[] subnetIpParts = NatUtil.getSubnetIpAndPrefix(subnetIp);
            subnetIp = subnetIpParts[0];
            String subnetIpPrefix = subnetIpParts[1];
            IPAddress subnetIpAddr = new IPAddress(subnetIp, Integer.parseInt(subnetIpPrefix));
            LOG.debug("NAT Service : Add the IP mapping for the router ID {} and internal IP {} and prefix {} -> external IP {} and prefix {}",
                    routerId, subnetIp, subnetIpPrefix, leastLoadedExtIp, leastLoadedExtIpPrefix);
            naptManager.registerMapping(routerId, subnetIpAddr, externalIpAddr);


            //Check if external IP is already assigned a route. (i.e. External IP is previously allocated to any of the subnets)
            //If external IP is already assigned a route, (, do not re-advertise to the BGP
            Long label = checkExternalIpLabel(routerId, leastLoadedExtIpAddrStr);
            if(label != null){
                //update
                String internalIp = subnetIpParts[0] + "/" + subnetIpParts[1];
                IpMapKey ipMapKey = new IpMapKey(internalIp);
                LOG.debug("Setting label {} for internalIp {} and externalIp {}", label, internalIp, leastLoadedExtIpAddrStr);
                IpMap newIpm = new IpMapBuilder().setKey(ipMapKey).setInternalIp(internalIp).setExternalIp(leastLoadedExtIpAddrStr).setLabel(label).build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, naptManager.getIpMapIdentifier(routerId, internalIp), newIpm);
                return;
            }

            //Re-advertise to the BGP for the external IP, which is allocated to the subnet for the first time and hence not having a route.
            //Get the VPN Name using the network ID
            final String vpnName = NatUtil.getAssociatedVPN(dataBroker, networkId, LOG);
            if (vpnName != null) {
                LOG.debug("Retrieved vpnName {} for networkId {}", vpnName, networkId);
                if (dpnId == null || dpnId.equals(BigInteger.ZERO)) {
                    LOG.debug("Best effort for getting primary napt switch when router i/f are added after gateway-set");
                    dpnId = NatUtil.getPrimaryNaptfromRouterId(dataBroker,routerId);
                }
                advToBgpAndInstallFibAndTsFlows(dpnId, NwConstants.INBOUND_NAPT_TABLE, vpnName, routerId,
                        leastLoadedExtIp + "/" + leastLoadedExtIpPrefix, vpnService, fibService, bgpManager, dataBroker, LOG);
            }
        }
    }

    protected Long checkExternalIpLabel(long routerId, String externalIp){
        List<IpMap> ipMaps = naptManager.getIpMapList(dataBroker, routerId);
        for(IpMap ipMap : ipMaps){
            if(ipMap.getExternalIp().equals(externalIp)){
                if (ipMap.getLabel() != null){
                    return ipMap.getLabel();
                }
            }
        }
        return null;
    }

    @Override
    protected void remove(InstanceIdentifier<Routers> identifier, Routers router) {
        LOG.trace("NAT Service : Router delete method");
        {
        /*
            ROUTER DELETE SCENARIO
            1) Get the router ID from the event.
            2) Build the cookie information from the router ID.
            3) Get the primary and secondary switch DPN IDs using the router ID from the model.
            4) Build the flow with the cookie value.
            5) Delete the flows which matches the cookie information from the NAPT outbound, inbound tables.
            6) Remove the flows from the other switches which points to the primary and secondary switches for the flows related the router ID.
            7) Get the list of external IP address maintained for the router ID.
            8) Use the NaptMananager removeMapping API to remove the list of IP addresses maintained.
            9) Withdraw the corresponding routes from the BGP.
         */

            if (identifier == null || router == null) {
                LOG.info("++++++++++++++NAT Service : ExternalRoutersListener:remove:: returning without processing since routers is null");
                return;
            }

            String routerName = router.getRouterName();
            LOG.info("Removing default NAT route from FIB on all dpns part of router {} ", routerName);
            addOrDelDefFibRouteToSNAT(routerName, false);
            Uuid networkUuid = router.getNetworkId();
            Long routerId = NatUtil.getVpnId(dataBroker, routerName);
            if (routerId == NatConstants.INVALID_ID) {
                LOG.error("NAT Service : Invalid routerId returned for routerName {}", routerName);
                return;
            }

            BigInteger primarySwitchId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);
            handleRouterGwFlows(router, primarySwitchId, NwConstants.DEL_FLOW);
            List<String> externalIps = NatUtil.getExternalIpsForRouter(dataBroker, routerId);
            handleDisableSnat(router, networkUuid, externalIps, true, null, primarySwitchId);
        }
    }

    private void handleRouterGwFlows(Routers router, BigInteger primarySwitchId, int addOrRemove) {
        WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
        vpnManager.setupRouterGwMacFlow(router.getRouterName(), router.getExtGwMacAddress(), primarySwitchId,
                router.getNetworkId(), writeTx, addOrRemove);
        vpnManager.setupArpResponderFlowsToExternalNetworkIps(router.getRouterName(), router.getExternalIps(),
                router.getExtGwMacAddress(), primarySwitchId, router.getNetworkId(), writeTx, addOrRemove);
        writeTx.submit();
    }

    public void handleDisableSnat(Routers router, Uuid networkUuid, List<String> externalIps, boolean routerFlag,
            String vpnId, BigInteger naptSwitchDpnId) {
        LOG.info("NAT Service : handleDisableSnat() Entry");
        String routerName = router.getRouterName();
        try {
            Long routerId = NatUtil.getVpnId(dataBroker, routerName);

            LOG.debug("NAT Service : got primarySwitch as dpnId{} ", naptSwitchDpnId);
            if (naptSwitchDpnId == null || naptSwitchDpnId.equals(BigInteger.ZERO)){
                LOG.error("NAT Service : Unable to retrieve the primary NAPT switch for the router ID {} from RouterNaptSwitch model", routerId);
                return;
            }
            removeNaptFlowsFromActiveSwitch(routerId, routerName, naptSwitchDpnId, networkUuid, vpnId, externalIps);
            removeFlowsFromNonActiveSwitches(routerName, naptSwitchDpnId, networkUuid);
            try {
                clrRtsFromBgpAndDelFibTs(naptSwitchDpnId, routerId, networkUuid, externalIps, vpnId);
            } catch (Exception ex) {
                LOG.debug("Failed to remove fib entries for routerId {} in naptSwitchDpnId {} : {}", routerId, naptSwitchDpnId,ex);
            }

            //Use the NaptMananager removeMapping API to remove the entire list of IP addresses maintained for the router ID.
            LOG.debug("NAT Service : Remove the Internal to external IP address maintained for the router ID {} in the DS", routerId);
            naptManager.removeMapping(routerId);

            if(routerFlag) {
                removeNaptSwitch(routerName);
            } else {
                updateNaptSwitch(routerName, BigInteger.ZERO);
            }

            LOG.debug("NAT Service : Remove the ExternalCounter model for the router ID {}", routerId);
            naptManager.removeExternalCounter(routerId);
        } catch (Exception ex) {
            LOG.error("Exception while handling disableSNAT : {}", ex);
        }
        LOG.info("NAT Service : handleDisableSnat() Exit");
    }

    public void handleDisableSnatInternetVpn(String routerName, Uuid networkUuid, List<String> externalIps, boolean routerFlag, String vpnId){
        LOG.debug("NAT Service : handleDisableSnatInternetVpn() Entry");
        try {
            Long routerId = NatUtil.getVpnId(dataBroker, routerName);
            BigInteger naptSwitchDpnId = null;
            InstanceIdentifier<RouterToNaptSwitch> routerToNaptSwitch = NatUtil.buildNaptSwitchRouterIdentifier(routerName);
            Optional<RouterToNaptSwitch> rtrToNapt = read(dataBroker, LogicalDatastoreType.CONFIGURATION, routerToNaptSwitch);
            if (rtrToNapt.isPresent()) {
                naptSwitchDpnId = rtrToNapt.get().getPrimarySwitchId();
            }
            LOG.debug("NAT Service : got primarySwitch as dpnId{} ", naptSwitchDpnId);

            removeNaptFlowsFromActiveSwitchInternetVpn(routerId, routerName, naptSwitchDpnId, networkUuid, vpnId );
            try {
                clrRtsFromBgpAndDelFibTs(naptSwitchDpnId, routerId, networkUuid, externalIps, vpnId);
            } catch (Exception ex) {
                LOG.debug("Failed to remove fib entries for routerId {} in naptSwitchDpnId {} : {}", routerId, naptSwitchDpnId,ex);
            }
          } catch (Exception ex) {
            LOG.error("Exception while handling disableSNATInternetVpn : {}", ex);
        }
        LOG.debug("NAT Service : handleDisableSnatInternetVpn() Exit");
    }

    public void updateNaptSwitch(String routerName, BigInteger naptSwitchId) {
        RouterToNaptSwitch naptSwitch = new RouterToNaptSwitchBuilder().setKey(new RouterToNaptSwitchKey(routerName))
                .setPrimarySwitchId(naptSwitchId).build();
        try {
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION,
                    NatUtil.buildNaptSwitchRouterIdentifier(routerName), naptSwitch);
        } catch (Exception ex) {
            LOG.error("Failed to write naptSwitch {} for router {} in ds",
                    naptSwitchId,routerName);
        }
        LOG.debug("Successfully updated naptSwitch {} for router {} in ds",
                naptSwitchId,routerName);
    }

    protected void removeNaptSwitch(String routerName){
        // Remove router and switch from model
        InstanceIdentifier<RouterToNaptSwitch> id = InstanceIdentifier.builder(NaptSwitches.class).child(RouterToNaptSwitch.class, new RouterToNaptSwitchKey(routerName)).build();
        LOG.debug("NAPT Service : Removing NaptSwitch and Router for the router {} from datastore", routerName);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
    }

     public void removeNaptFlowsFromActiveSwitch(long routerId, String routerName, BigInteger dpnId, Uuid networkId, String vpnName, List<String> externalIps){

        LOG.debug("NAT Service : Remove NAPT flows from Active switch");
        BigInteger cookieSnatFlow = NatUtil.getCookieNaptFlow(routerId);

        //Remove the PSNAT entry which forwards the packet to Outbound NAPT Table (For the
        // traffic which comes from the  VMs of the NAPT switches)
        String pSNatFlowRef = getFlowRefSnat(dpnId, NwConstants.PSNAT_TABLE, routerName);
        FlowEntity pSNatFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.PSNAT_TABLE, pSNatFlowRef);

        LOG.info("NAT Service : Remove the flow in the " + NwConstants.PSNAT_TABLE + " for the active switch with the DPN ID {} and router ID {}", dpnId, routerId);
        mdsalManager.removeFlow(pSNatFlowEntity);

        //Remove the Terminating Service table entry which forwards the packet to Outbound NAPT Table (For the
        // traffic which comes from the VMs of the non NAPT switches)
        String tsFlowRef = getFlowRefTs(dpnId, NwConstants.INTERNAL_TUNNEL_TABLE, routerId);
        FlowEntity tsNatFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.INTERNAL_TUNNEL_TABLE, tsFlowRef);

        LOG.info("NAT Service : Remove the flow in the " + NwConstants.INTERNAL_TUNNEL_TABLE + " for the active switch with the DPN ID {} and router ID {}", dpnId, routerId);
        mdsalManager.removeFlow(tsNatFlowEntity);

        //Remove the Outbound flow entry which forwards the packet to FIB Table
        String outboundNatFlowRef = getFlowRefOutbound(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, routerId);
        FlowEntity outboundNatFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, outboundNatFlowRef);

        LOG.info("NAT Service : Remove the flow in the " + NwConstants.OUTBOUND_NAPT_TABLE + " for the active switch with the DPN ID {} and router ID {}", dpnId, routerId);
        mdsalManager.removeFlow(outboundNatFlowEntity);

        removeNaptFibExternalOutputFlows(routerId, dpnId, externalIps);

        //Remove the NAPT PFIB TABLE which forwards the incoming packet to FIB Table matching on the router ID.
        String natPfibFlowRef = getFlowRefTs(dpnId, NwConstants.NAPT_PFIB_TABLE, routerId);
        FlowEntity natPfibFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.NAPT_PFIB_TABLE, natPfibFlowRef);

        LOG.info("NAT Service : Remove the flow in the " + NwConstants.NAPT_PFIB_TABLE + " for the active switch with the DPN ID {} and router ID {}", dpnId, routerId);
        mdsalManager.removeFlow(natPfibFlowEntity);

        //Long vpnId = NatUtil.getVpnId(dataBroker, routerId); - This does not work since ext-routers is deleted already - no network info
        //Get the VPN ID from the ExternalNetworks model
        long vpnId = -1;
        if( (vpnName == null) || (vpnName.isEmpty()) ) {
            // ie called from router delete cases
            Uuid vpnUuid = NatUtil.getVpnIdfromNetworkId(dataBroker, networkId);
            LOG.debug("NAT Service : vpnUuid is {}", vpnUuid);
            if(vpnUuid != null) {
                vpnId = NatUtil.getVpnId(dataBroker, vpnUuid.getValue());
                LOG.debug("NAT Service : vpnId for routerdelete or disableSNAT scenario {}", vpnId );
            }
        } else {
            // ie called from disassociate vpn case
            LOG.debug("NAT Service: This is disassociate nw with vpn case with vpnName {}", vpnName);
            vpnId = NatUtil.getVpnId(dataBroker, vpnName);
            LOG.debug("NAT Service : vpnId for disassociate nw with vpn scenario {}", vpnId );
        }

        if(vpnId != NatConstants.INVALID_ID){
           //Remove the NAPT PFIB TABLE which forwards the outgoing packet to FIB Table matching on the VPN ID.
           String natPfibVpnFlowRef = getFlowRefTs(dpnId, NwConstants.NAPT_PFIB_TABLE, vpnId);
           FlowEntity natPfibVpnFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.NAPT_PFIB_TABLE, natPfibVpnFlowRef);
           LOG.info("NAT Service : Remove the flow in the " + NwConstants.NAPT_PFIB_TABLE + " for the active switch with the DPN ID {} and VPN ID {}", dpnId, vpnId);
           mdsalManager.removeFlow(natPfibVpnFlowEntity);
        }

        //For the router ID get the internal IP , internal port and the corresponding external IP and external Port.
        IpPortMapping ipPortMapping = NatUtil.getIportMapping(dataBroker, routerId);
        if(ipPortMapping == null){
            LOG.error("NAT Service : Unable to retrieve the IpPortMapping");
            return;
        }

        List<IntextIpProtocolType> intextIpProtocolTypes = ipPortMapping.getIntextIpProtocolType();
        for(IntextIpProtocolType intextIpProtocolType : intextIpProtocolTypes){
            List<IpPortMap> ipPortMaps = intextIpProtocolType.getIpPortMap();
            for(IpPortMap ipPortMap : ipPortMaps){
                String ipPortInternal = ipPortMap.getIpPortInternal();
                String[] ipPortParts = ipPortInternal.split(":");
                if(ipPortParts.length != 2) {
                    LOG.error("NAT Service : Unable to retrieve the Internal IP and port");
                    return;
                }
                String internalIp = ipPortParts[0];
                String internalPort = ipPortParts[1];

                //Build the flow for the outbound NAPT table
                String switchFlowRef = NatUtil.getNaptFlowRef(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, String.valueOf(routerId), internalIp, Integer.valueOf(internalPort));
                FlowEntity outboundNaptFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, cookieSnatFlow, switchFlowRef);

                LOG.info("NAT Service : Remove the flow in the " + NwConstants.OUTBOUND_NAPT_TABLE + " for the active switch with the DPN ID {} and router ID {}", dpnId, routerId);
                mdsalManager.removeFlow(outboundNaptFlowEntity);

                IpPortExternal ipPortExternal = ipPortMap.getIpPortExternal();
                String externalIp = ipPortExternal.getIpAddress();
                int externalPort = ipPortExternal.getPortNum();

                //Build the flow for the inbound NAPT table
                switchFlowRef = NatUtil.getNaptFlowRef(dpnId, NwConstants.INBOUND_NAPT_TABLE, String.valueOf(routerId), externalIp, externalPort);
                FlowEntity inboundNaptFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.INBOUND_NAPT_TABLE, cookieSnatFlow, switchFlowRef);

                LOG.info("NAT Service : Remove the flow in the " + NwConstants.INBOUND_NAPT_TABLE + " for the active active switch with the DPN ID {} and router ID {}", dpnId, routerId);
                mdsalManager.removeFlow(inboundNaptFlowEntity);
            }
        }
    }

    private void removeNaptFibExternalOutputFlows(long routerId, BigInteger dpnId, List<String> externalIps) {
        for (String ip : externalIps) {
            String extIp = removeMaskFromIp(ip);
            String postNaptFlowRef = getFlowRefNaptFib(dpnId, NwConstants.NAPT_PFIB_TABLE, routerId, extIp);
            LOG.info("NAT Service : Remove the flow in the " + NwConstants.NAPT_PFIB_TABLE + " for the active switch with the DPN ID {} and router ID {} and IP {}", dpnId, routerId, extIp);
            mdsalManager.removeFlow(NatUtil.buildFlowEntity(dpnId,NwConstants.NAPT_PFIB_TABLE, postNaptFlowRef));
        }
    }

    private String removeMaskFromIp(String ip) {
        if (ip != null && !ip.trim().isEmpty()) {
            return ip.split("/")[0];
        }
        return ip;
    }

     public void removeNaptFlowsFromActiveSwitchInternetVpn(long routerId, String routerName, BigInteger dpnId, Uuid networkId, String vpnName){

         LOG.debug("NAT Service : Remove NAPT flows from Active switch Internet Vpn");
         BigInteger cookieSnatFlow = NatUtil.getCookieNaptFlow(routerId);

         //Remove the NAPT PFIB TABLE entry
         long vpnId = -1;
         if(vpnName != null) {
             // ie called from disassociate vpn case
             LOG.debug("NAT Service: This is disassociate nw with vpn case with vpnName {}", vpnName);
             vpnId = NatUtil.getVpnId(dataBroker, vpnName);
             LOG.debug("NAT Service : vpnId for disassociate nw with vpn scenario {}", vpnId );
         }

         if(vpnId != NatConstants.INVALID_ID){
            //Remove the NAPT PFIB TABLE which forwards the outgoing packet to FIB Table matching on the VPN ID.
            String natPfibVpnFlowRef = getFlowRefTs(dpnId, NwConstants.NAPT_PFIB_TABLE, vpnId);
            FlowEntity natPfibVpnFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.NAPT_PFIB_TABLE, natPfibVpnFlowRef);
            LOG.info("NAT Service : Remove the flow in the " + NwConstants.NAPT_PFIB_TABLE + " for the active switch with the DPN ID {} and VPN ID {}", dpnId, vpnId);
            mdsalManager.removeFlow(natPfibVpnFlowEntity);

             // Remove IP-PORT active NAPT entries and release port from IdManager
             //For the router ID get the internal IP , internal port and the corresponding external IP and external Port.
             IpPortMapping ipPortMapping = NatUtil.getIportMapping(dataBroker, routerId);
             if(ipPortMapping == null){
                 LOG.error("NAT Service : Unable to retrieve the IpPortMapping");
                 return;
             }
             List<IntextIpProtocolType> intextIpProtocolTypes = ipPortMapping.getIntextIpProtocolType();
             for(IntextIpProtocolType intextIpProtocolType : intextIpProtocolTypes){
                 List<IpPortMap> ipPortMaps = intextIpProtocolType.getIpPortMap();
                 for(IpPortMap ipPortMap : ipPortMaps){
                     String ipPortInternal = ipPortMap.getIpPortInternal();
                     String[] ipPortParts = ipPortInternal.split(":");
                     if(ipPortParts.length != 2) {
                         LOG.error("NAT Service : Unable to retrieve the Internal IP and port");
                         return;
                     }
                     String internalIp = ipPortParts[0];
                     String internalPort = ipPortParts[1];

                     //Build the flow for the outbound NAPT table
                     String switchFlowRef = NatUtil.getNaptFlowRef(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, String.valueOf(routerId), internalIp, Integer.valueOf(internalPort));
                     FlowEntity outboundNaptFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, cookieSnatFlow, switchFlowRef);

                     LOG.info("NAT Service : Remove the flow in the " + NwConstants.OUTBOUND_NAPT_TABLE + " for the active switch with the DPN ID {} and router ID {}", dpnId, routerId);
                     mdsalManager.removeFlow(outboundNaptFlowEntity);

                     IpPortExternal ipPortExternal = ipPortMap.getIpPortExternal();
                     String externalIp = ipPortExternal.getIpAddress();
                     int externalPort = ipPortExternal.getPortNum();

                     //Build the flow for the inbound NAPT table
                     switchFlowRef = NatUtil.getNaptFlowRef(dpnId, NwConstants.INBOUND_NAPT_TABLE, String.valueOf(routerId), externalIp, externalPort);
                     FlowEntity inboundNaptFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.INBOUND_NAPT_TABLE, cookieSnatFlow, switchFlowRef);

                     LOG.info("NAT Service : Remove the flow in the " + NwConstants.INBOUND_NAPT_TABLE + " for the active active switch with the DPN ID {} and router ID {}", dpnId, routerId);
                     mdsalManager.removeFlow(inboundNaptFlowEntity);

                     // Finally release port from idmanager
                     String internalIpPort = internalIp +":"+internalPort;
                     naptManager.removePortFromPool(internalIpPort, externalIp);

                     //Remove sessions from models
                     naptManager.removeIpPortMappingForRouterID(routerId);
                     naptManager.removeIntIpPortMappingForRouterID(routerId);
                 }
             }
         } else {
             LOG.error("NAT Service : Invalid vpnId {}", vpnId);
         }
     }

    public void removeFlowsFromNonActiveSwitches(String routerName, BigInteger naptSwitchDpnId, Uuid networkId){
        LOG.debug("NAT Service : Remove NAPT related flows from non active switches");

        //Remove the flows from the other switches which points to the primary and secondary switches for the flows related the router ID.
        List<BigInteger> allSwitchList = naptSwitchSelector.getDpnsForVpn(routerName);
        if(allSwitchList == null || allSwitchList.isEmpty()){
            LOG.error("NAT Service : Unable to get the swithces for the router {}", routerName);
            return;
        }
        Long routerId = NatUtil.getVpnId(dataBroker, routerName);
        for (BigInteger dpnId : allSwitchList) {
            if (!naptSwitchDpnId.equals(dpnId)) {
                LOG.info("NAT Service : Handle Ordinary switch");

                //Remove the PSNAT entry which forwards the packet to Terminating Service table
                String pSNatFlowRef = getFlowRefSnat(dpnId, NwConstants.PSNAT_TABLE, String.valueOf(routerName));
                FlowEntity pSNatFlowEntity = NatUtil.buildFlowEntity(dpnId, NwConstants.PSNAT_TABLE, pSNatFlowRef);

                LOG.info("Remove the flow in the " + NwConstants.PSNAT_TABLE + " for the non active switch with the DPN ID {} and router ID {}", dpnId, routerId);
                mdsalManager.removeFlow(pSNatFlowEntity);

                //Remove the group entry which forwards the traffic to the out port (VXLAN tunnel).
                long groupId = createGroupId(getGroupIdKey(routerName));
                List<BucketInfo> listBucketInfo = new ArrayList<>();
                GroupEntity pSNatGroupEntity = MDSALUtil.buildGroupEntity(dpnId, groupId, routerName, GroupTypes.GroupAll, listBucketInfo);

                LOG.info("NAT Service : Remove the group {} for the non active switch with the DPN ID {} and router ID {}", groupId, dpnId, routerId);
                mdsalManager.removeGroup(pSNatGroupEntity);

            }
        }
    }

    public void clrRtsFromBgpAndDelFibTs(final BigInteger dpnId, Long routerId, Uuid networkUuid, List<String> externalIps, String vpnName) {
        //Withdraw the corresponding routes from the BGP.
        //Get the network ID using the router ID.
        LOG.debug("NAT Service : Advertise to BGP and remove routes for externalIps {} with routerId {}, network Id {} and vpnName {}",
                externalIps,routerId,networkUuid, vpnName);
        if(networkUuid == null ){
            LOG.error("NAT Service : networkId is null");
            return;
        }

        if (externalIps == null || externalIps.isEmpty()) {
            LOG.debug("NAT Service : externalIps is null");
            return;
        }

        if(vpnName ==null) {
            //Get the VPN Name using the network ID
            vpnName = NatUtil.getAssociatedVPN(dataBroker, networkUuid, LOG);
            if (vpnName == null) {
                LOG.error("No VPN associated with ext nw {} for the router {}",
                        networkUuid, routerId);
                return;
            }
        }
        LOG.debug("Retrieved vpnName {} for networkId {}",vpnName,networkUuid);

        //Remove custom FIB routes
        //Future<RpcResult<java.lang.Void>> removeFibEntry(RemoveFibEntryInput input);
        for (String extIp : externalIps) {
            clrRtsFromBgpAndDelFibTs(dpnId, routerId, extIp, vpnName);
        }
    }

    protected void clrRtsFromBgpAndDelFibTs(final BigInteger dpnId, long routerId, String extIp, final String vpnName) {
        clearBgpRoutes(extIp,vpnName);
        delFibTsAndReverseTraffic(dpnId,routerId,extIp,vpnName);
    }

    protected void delFibTsAndReverseTraffic(final BigInteger dpnId, long routerId, String extIp, final String vpnName,long tempLabel) {
        LOG.debug("Removing fib entry for externalIp {} in routerId {}",extIp,routerId);

        if (tempLabel < 0 || tempLabel == NatConstants.INVALID_ID) {
            LOG.error("NAT Service : Label not found for externalIp {} with router id {}",extIp,routerId);
            return;
        }

        final long label = tempLabel;
        final String externalIp = extIp;

        RemoveFibEntryInput input = new RemoveFibEntryInputBuilder().setVpnName(vpnName).setSourceDpid(dpnId).setIpAddress(externalIp).setServiceId(label).build();
        Future<RpcResult<Void>> future = fibService.removeFibEntry(input);

        ListenableFuture<RpcResult<Void>> labelFuture = Futures.transform(JdkFutureAdapters.listenInPoolThread(future), new AsyncFunction<RpcResult<Void>, RpcResult<Void>>() {

            @Override
            public ListenableFuture<RpcResult<Void>> apply(RpcResult<Void> result) throws Exception {
                //Release label
                if (result.isSuccessful()) {
                    removeTunnelTableEntry(dpnId, label);
                    removeLFibTableEntry(dpnId, label);
                    RemoveVpnLabelInput labelInput = new RemoveVpnLabelInputBuilder().setVpnName(vpnName).setIpPrefix(externalIp).build();
                    Future<RpcResult<Void>> labelFuture = vpnService.removeVpnLabel(labelInput);
                    return JdkFutureAdapters.listenInPoolThread(labelFuture);
                } else {
                    String errMsg = String.format("RPC call to remove custom FIB entries on dpn %s for prefix %s Failed - %s", dpnId, externalIp, result.getErrors());
                    LOG.error(errMsg);
                    return Futures.immediateFailedFuture(new RuntimeException(errMsg));
                }
            }

        });

        Futures.addCallback(labelFuture, new FutureCallback<RpcResult<Void>>() {

            @Override
            public void onFailure(Throwable error) {
                LOG.error("NAT Service : Error in removing the label or custom fib entries", error);
            }

            @Override
            public void onSuccess(RpcResult<Void> result) {
                if (result.isSuccessful()) {
                    LOG.debug("NAT Service : Successfully removed the label for the prefix {} from VPN {}", externalIp, vpnName);
                } else {
                    LOG.error("NAT Service : Error in removing the label for prefix {} from VPN {}, {}", externalIp, vpnName, result.getErrors());
                }
            }
        });
    }

    private void delFibTsAndReverseTraffic(final BigInteger dpnId, long routerId, String extIp, final String vpnName) {
        LOG.debug("Removing fib entry for externalIp {} in routerId {}",extIp,routerId);
        //Get IPMaps from the DB for the router ID
        List<IpMap> dbIpMaps = NaptManager.getIpMapList(dataBroker, routerId);
        if (dbIpMaps == null || dbIpMaps.isEmpty()) {
            LOG.error("NAT Service : IPMaps not found for router {}",routerId);
            return;
        }

        long tempLabel = NatConstants.INVALID_ID;
        for (IpMap dbIpMap : dbIpMaps) {
            String dbExternalIp = dbIpMap.getExternalIp();
            LOG.debug("Retrieved dbExternalIp {} for router id {}",dbExternalIp,routerId);
            //Select the IPMap, whose external IP is the IP for which FIB is installed
            if (extIp.equals(dbExternalIp)) {
                tempLabel = dbIpMap.getLabel();
                LOG.debug("Retrieved label {} for dbExternalIp {} with router id {}",tempLabel,dbExternalIp,routerId);
                break;
            }
        }
        if (tempLabel < 0 || tempLabel == NatConstants.INVALID_ID) {
            LOG.error("NAT Service : Label not found for externalIp {} with router id {}",extIp,routerId);
            return;
        }

        final long label = tempLabel;
        final String externalIp = extIp;

        RemoveFibEntryInput input = new RemoveFibEntryInputBuilder().setVpnName(vpnName).setSourceDpid(dpnId).setIpAddress(externalIp).setServiceId(label).build();
        Future<RpcResult<Void>> future = fibService.removeFibEntry(input);

        ListenableFuture<RpcResult<Void>> labelFuture = Futures.transform(JdkFutureAdapters.listenInPoolThread(future), new AsyncFunction<RpcResult<Void>, RpcResult<Void>>() {

            @Override
            public ListenableFuture<RpcResult<Void>> apply(RpcResult<Void> result) throws Exception {
                //Release label
                if (result.isSuccessful()) {
                    removeTunnelTableEntry(dpnId, label);
                    removeLFibTableEntry(dpnId, label);
                    RemoveVpnLabelInput labelInput = new RemoveVpnLabelInputBuilder().setVpnName(vpnName).setIpPrefix(externalIp).build();
                    Future<RpcResult<Void>> labelFuture = vpnService.removeVpnLabel(labelInput);
                    return JdkFutureAdapters.listenInPoolThread(labelFuture);
                } else {
                    String errMsg = String.format("RPC call to remove custom FIB entries on dpn %s for prefix %s Failed - %s", dpnId, externalIp, result.getErrors());
                    LOG.error(errMsg);
                    return Futures.immediateFailedFuture(new RuntimeException(errMsg));
                }
            }

        });

        Futures.addCallback(labelFuture, new FutureCallback<RpcResult<Void>>() {

            @Override
            public void onFailure(Throwable error) {
                LOG.error("NAT Service : Error in removing the label or custom fib entries", error);
            }

            @Override
            public void onSuccess(RpcResult<Void> result) {
                if (result.isSuccessful()) {
                    LOG.debug("NAT Service : Successfully removed the label for the prefix {} from VPN {}", externalIp, vpnName);
                } else {
                    LOG.error("NAT Service : Error in removing the label for prefix {} from VPN {}, {}", externalIp, vpnName, result.getErrors());
                }
            }
        });
    }

    protected void clearFibTsAndReverseTraffic(final BigInteger dpnId, Long routerId, Uuid networkUuid, List<String> externalIps, String vpnName) {
        //Withdraw the corresponding routes from the BGP.
        //Get the network ID using the router ID.
        LOG.debug("NAT Service : clearFibTsAndReverseTraffic for externalIps {} with routerId {}, network Id {} and vpnName {}",
                externalIps,routerId,networkUuid, vpnName);
        if (networkUuid == null) {
            LOG.error("NAT Service : networkId is null");
            return;
        }

        if (externalIps == null || externalIps.isEmpty()) {
            LOG.debug("NAT Service : externalIps is null");
            return;
        }

        if (vpnName == null) {
            //Get the VPN Name using the network ID
            vpnName = NatUtil.getAssociatedVPN(dataBroker, networkUuid, LOG);
            if (vpnName == null) {
                LOG.error("No VPN associated with ext nw {} for the router {}",
                        networkUuid, routerId);
                return;
            }
        }
        LOG.debug("Retrieved vpnName {} for networkId {}",vpnName,networkUuid);

        //Remove custom FIB routes
        //Future<RpcResult<java.lang.Void>> removeFibEntry(RemoveFibEntryInput input);
        for (String extIp : externalIps) {
            delFibTsAndReverseTraffic(dpnId,routerId,extIp,vpnName);
        }
    }

    protected  void clearBgpRoutes(String externalIp, final String vpnName) {
        //Inform BGP about the route removal
        LOG.info("Informing BGP to remove route for externalIP {} of vpn {}",externalIp,vpnName);
        String rd = NatUtil.getVpnRd(dataBroker, vpnName);
        NatUtil.removePrefixFromBGP(dataBroker, bgpManager, fibManager, rd, externalIp, LOG);
    }

    private void removeTunnelTableEntry(BigInteger dpnId, long serviceId) {
        LOG.info("NAT Service : remove terminatingServiceActions called with DpnId = {} and label = {}", dpnId , serviceId);
        List<MatchInfo> mkMatches = new ArrayList<>();
        // Matching metadata
        mkMatches.add(new MatchInfo(MatchFieldType.tunnel_id, new BigInteger[] {BigInteger.valueOf(serviceId)}));
        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.INTERNAL_TUNNEL_TABLE,
                getFlowRef(dpnId, NwConstants.INTERNAL_TUNNEL_TABLE, serviceId, ""),
                5, String.format("%s:%d","TST Flow Entry ",serviceId), 0, 0,
                COOKIE_TUNNEL.add(BigInteger.valueOf(serviceId)), mkMatches, null);
        mdsalManager.removeFlow(dpnId, flowEntity);
        LOG.debug("NAT Service : Terminating service Entry for dpID {} : label : {} removed successfully {}",dpnId, serviceId);
    }

    private void removeLFibTableEntry(BigInteger dpnId, long serviceId) {
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x8847L }));
        matches.add(new MatchInfo(MatchFieldType.mpls_label, new String[]{Long.toString(serviceId)}));

        String flowRef = getFlowRef(dpnId, NwConstants.L3_LFIB_TABLE, serviceId, "");

        LOG.debug("NAT Service : removing LFib entry with flow ref {}", flowRef);

        Flow flowEntity = MDSALUtil.buildFlowNew(NwConstants.L3_LFIB_TABLE, flowRef,
                10, flowRef, 0, 0,
                COOKIE_VM_LFIB_TABLE, matches, null);

        mdsalManager.removeFlow(dpnId, flowEntity);

        LOG.debug("NAT Service : LFIB Entry for dpID : {} label : {} removed successfully {}",dpnId, serviceId);
    }

    /**
     * router association to vpn
     *@param routerName - Name of router
     *@param bgpVpnName BGP VPN name
     */
    public void changeLocalVpnIdToBgpVpnId(String routerName, String bgpVpnName){
        LOG.debug("NAT Service : Router associated to BGP VPN");
        if (chkExtRtrAndSnatEnbl(new Uuid(routerName))) {
            long bgpVpnId = NatUtil.getVpnId(dataBroker, bgpVpnName);

            LOG.debug("BGP VPN ID value {} ", bgpVpnId);

            if(bgpVpnId != NatConstants.INVALID_ID){
                LOG.debug("Populate the router-id-name container with the mapping BGP VPN-ID {} -> BGP VPN-NAME {}", bgpVpnId, bgpVpnName);
                RouterIds rtrs = new RouterIdsBuilder().setKey(new RouterIdsKey(bgpVpnId)).setRouterId(bgpVpnId).setRouterName(bgpVpnName).build();
                MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, getRoutersIdentifier(bgpVpnId), rtrs);

                // Get the allocated Primary NAPT Switch for this router
                long routerId = NatUtil.getVpnId(dataBroker, routerName);
                LOG.debug("Router ID value {} ", routerId);
                BigInteger primarySwitchId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);

                LOG.debug("NAT Service : Update the Router ID {} to the BGP VPN ID {} ", routerId, bgpVpnId);
                addOrDelDefaultFibRouteForSNATWIthBgpVpn(routerName, bgpVpnId, true);

                // Get the group ID
                long groupId = createGroupId(getGroupIdKey(routerName));
                installFlowsWithUpdatedVpnId(primarySwitchId, routerName, bgpVpnId, routerId, true);
            }
        }
    }

    /**
     * router disassociation from vpn
     *@param routerName - Name of router
     *@param bgpVpnName BGP VPN name
     */
    public void changeBgpVpnIdToLocalVpnId(String routerName, String bgpVpnName){
        LOG.debug("NAT Service : Router dissociated from BGP VPN");
        if(chkExtRtrAndSnatEnbl(new Uuid(routerName))) {
            long bgpVpnId = NatUtil.getVpnId(dataBroker, bgpVpnName);
            LOG.debug("BGP VPN ID value {} ", bgpVpnId);

            // Get the allocated Primary NAPT Switch for this router
            long routerId = NatUtil.getVpnId(dataBroker, routerName);
            LOG.debug("Router ID value {} ", routerId);
            BigInteger primarySwitchId = NatUtil.getPrimaryNaptfromRouterId(dataBroker, routerId);

            LOG.debug("NAT Service : Update the BGP VPN ID {} to the Router ID {}", bgpVpnId, routerId);
            addOrDelDefaultFibRouteForSNATWIthBgpVpn(routerName, NatConstants.INVALID_ID, true);

            // Get the group ID
            long groupId = createGroupId(getGroupIdKey(routerName));
            installFlowsWithUpdatedVpnId(primarySwitchId, routerName, NatConstants.INVALID_ID, routerId, true);
        }
    }

    boolean chkExtRtrAndSnatEnbl(Uuid routerUuid){
        InstanceIdentifier<Routers> routerInstanceIndentifier = InstanceIdentifier.builder(ExtRouters.class).child
                (Routers.class, new RoutersKey(routerUuid.getValue())).build();
        Optional<Routers> routerData = read(dataBroker, LogicalDatastoreType.CONFIGURATION, routerInstanceIndentifier);
        if (routerData.isPresent() && routerData.get().isEnableSnat()) {
            return true;
        }
        return false;
    }
    public void installFlowsWithUpdatedVpnId(BigInteger primarySwitchId, String routerName, long bgpVpnId, long
            routerId, boolean isSnatCfgd){
        installFlowsWithUpdatedVpnId(primarySwitchId, routerName, bgpVpnId, routerId, isSnatCfgd, null);
    }

    public void installFlowsWithUpdatedVpnId(BigInteger primarySwitchId, String routerName, long bgpVpnId, long
            routerId, boolean isSnatCfgd, Routers router){
        long changedVpnId = bgpVpnId;
        String logMsg = "NAT Service : Update the BGP VPN ID {}";
        if (bgpVpnId == NatConstants.INVALID_ID){
            changedVpnId = routerId;
            logMsg = "NAT Service : Update the router ID {}";
        }

        List<BigInteger> switches = NatUtil.getDpnsForRouter(dataBroker, routerName);
        if (switches == null || switches.isEmpty()) {
            LOG.debug("No switches found for router {}",routerName);
            return;
        }
        for(BigInteger dpnId : switches) {
            // Update the BGP VPN ID in the SNAT miss entry to group
            if( !dpnId.equals(primarySwitchId) ) {
                LOG.debug("NAT Service : Install group in non NAPT switch {}", dpnId);
                List<BucketInfo> bucketInfoForNonNaptSwitches = getBucketInfoForNonNaptSwitches(dpnId, primarySwitchId, routerName);
                long groupId = createGroupId(getGroupIdKey(routerName));
                if(!isSnatCfgd){
                    groupId = installGroup(dpnId, routerName, bucketInfoForNonNaptSwitches);
                }

                LOG.debug(logMsg + " in the SNAT miss entry pointing to group {} in the non NAPT switch {}",
                        changedVpnId, groupId, dpnId);
                FlowEntity flowEntity = buildSnatFlowEntityWithUpdatedVpnId(dpnId, routerName, groupId, changedVpnId);
                mdsalManager.installFlow(flowEntity);
            }else{

                LOG.debug(logMsg + " in the SNAT miss entry pointing to group {} in the primary switch {}",
                        changedVpnId, primarySwitchId);
                FlowEntity flowEntity = buildSnatFlowEntityWithUpdatedVpnIdForPrimrySwtch(primarySwitchId, routerName, changedVpnId);
                mdsalManager.installFlow(flowEntity);

                LOG.debug(logMsg + " in the Terminating Service table (table ID 36) which forwards the packet" +
                        " to the table 46 in the Primary switch {}",  changedVpnId, primarySwitchId);
                installTerminatingServiceTblEntryWithUpdatedVpnId(primarySwitchId, routerName, changedVpnId);

                LOG.debug(logMsg + " in the Outbound NAPT table (table ID 46) which punts the packet to the" +
                        " controller in the Primary switch {}", changedVpnId, primarySwitchId);
                createOutboundTblEntryWithBgpVpn(primarySwitchId, routerId, changedVpnId);

                LOG.debug(logMsg + " in the NAPT PFIB TABLE which forwards the outgoing packet to FIB Table in the Primary switch {}",
                        changedVpnId, primarySwitchId);
                installNaptPfibEntryWithBgpVpn(primarySwitchId, routerId, changedVpnId);

                LOG.debug(logMsg + " in the NAPT flows for the Outbound NAPT table (table ID 46) and the INBOUND NAPT table (table ID 44)" +
                        " in the Primary switch {}", changedVpnId, primarySwitchId);
                updateNaptFlowsWithVpnId(primarySwitchId, routerId, bgpVpnId);

                LOG.debug("NAT Service : Installing SNAT PFIB flow in the primary switch {}", primarySwitchId);
                Long vpnId = NatUtil.getVpnId(dataBroker, routerId);
                //Install the NAPT PFIB TABLE which forwards the outgoing packet to FIB Table matching on the VPN ID.
                if (vpnId != null && vpnId != NatConstants.INVALID_ID) {
                    installNaptPfibEntry(primarySwitchId, vpnId);
                }
            }
        }
    }

    public void updateNaptFlowsWithVpnId(BigInteger dpnId, long routerId, long bgpVpnId){
        //For the router ID get the internal IP , internal port and the corresponding external IP and external Port.
        IpPortMapping ipPortMapping = NatUtil.getIportMapping(dataBroker, routerId);
        if(ipPortMapping == null){
            LOG.error("NAT Service : Unable to retrieve the IpPortMapping");
            return;
        }

        List<IntextIpProtocolType> intextIpProtocolTypes = ipPortMapping.getIntextIpProtocolType();
        for(IntextIpProtocolType intextIpProtocolType : intextIpProtocolTypes){
            List<IpPortMap> ipPortMaps = intextIpProtocolType.getIpPortMap();
            for(IpPortMap ipPortMap : ipPortMaps){
                String ipPortInternal = ipPortMap.getIpPortInternal();
                String[] ipPortParts = ipPortInternal.split(":");
                if(ipPortParts.length != 2) {
                    LOG.error("NAT Service : Unable to retrieve the Internal IP and port");
                    return;
                }
                String internalIp = ipPortParts[0];
                String internalPort = ipPortParts[1];

                ProtocolTypes protocolTypes = intextIpProtocolType.getProtocol();
                NAPTEntryEvent.Protocol protocol;
                switch (protocolTypes){
                    case TCP:
                        protocol = NAPTEntryEvent.Protocol.TCP;
                        break;
                    case UDP:
                        protocol = NAPTEntryEvent.Protocol.UDP;
                        break;
                    default:
                        protocol = NAPTEntryEvent.Protocol.TCP;
                }
                SessionAddress internalAddress = new SessionAddress(internalIp, Integer.valueOf(internalPort));
                SessionAddress externalAddress = naptManager.getExternalAddressMapping(routerId, internalAddress, protocol);
                long internetVpnid = NatUtil.getVpnId(dataBroker, routerId);
                NaptEventHandler.buildAndInstallNatFlows(dpnId, NwConstants.OUTBOUND_NAPT_TABLE, internetVpnid, routerId, bgpVpnId,
                        internalAddress, externalAddress, protocol);
                NaptEventHandler.buildAndInstallNatFlows(dpnId, NwConstants.INBOUND_NAPT_TABLE, internetVpnid, routerId, bgpVpnId,
                        externalAddress, internalAddress, protocol);

            }
        }
    }

    public FlowEntity buildSnatFlowEntityWithUpdatedVpnId(BigInteger dpId, String routerName, long groupId, long changedVpnId) {

        LOG.debug("NAT Service : buildSnatFlowEntity is called for dpId {}, routerName {} groupId {} changed VPN ID {}", dpId, routerName, groupId, changedVpnId );
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(changedVpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfo = new ArrayList<>();

        ActionInfo actionSetField = new ActionInfo(ActionType.set_field_tunnel_id, new BigInteger[] {
                BigInteger.valueOf(changedVpnId)}) ;
        actionsInfo.add(actionSetField);
        LOG.debug("NAT Service : Setting the tunnel to the list of action infos {}", actionsInfo);
        actionsInfo.add(new ActionInfo(ActionType.group, new String[] {String.valueOf(groupId)}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfo));
        String flowRef = getFlowRefSnat(dpId, NwConstants.PSNAT_TABLE, routerName);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_SNAT_TABLE, matches, instructions);

        LOG.debug("NAT Service : Returning SNAT Flow Entity {}", flowEntity);
        return flowEntity;
    }

    public FlowEntity buildSnatFlowEntityWithUpdatedVpnIdForPrimrySwtch(BigInteger dpId, String routerName, long changedVpnId) {

        LOG.debug("NAT Service : buildSnatFlowEntity is called for dpId {}, routerName {} changed VPN ID {}", dpId, routerName, changedVpnId );
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(changedVpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        List<InstructionInfo> instructions = new ArrayList<InstructionInfo>();
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[]
                { NwConstants.OUTBOUND_NAPT_TABLE }));

        String flowRef = getFlowRefSnat(dpId, NwConstants.PSNAT_TABLE, routerName);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.PSNAT_TABLE, flowRef,
                NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_SNAT_TABLE, matches, instructions);

        LOG.debug("NAT Service : Returning SNAT Flow Entity {}", flowEntity);
        return flowEntity;
    }

    // TODO : Replace this with ITM Rpc once its available with full functionality
    protected void installTerminatingServiceTblEntryWithUpdatedVpnId(BigInteger dpnId, String routerName, long changedVpnId) {
        LOG.debug("NAT Service : installTerminatingServiceTblEntryWithUpdatedVpnId called for switch {}, routerName {}, BGP VPN ID {}", dpnId, routerName, changedVpnId);
        FlowEntity flowEntity = buildTsFlowEntityWithUpdatedVpnId(dpnId, routerName, changedVpnId);
        mdsalManager.installFlow(flowEntity);

    }

    private FlowEntity buildTsFlowEntityWithUpdatedVpnId(BigInteger dpId, String routerName, long changedVpnId) {
        LOG.debug("NAT Service : buildTsFlowEntityWithUpdatedVpnId called for switch {}, routerName {}, BGP VPN ID {}", dpId, routerName, changedVpnId);
        BigInteger routerId = BigInteger.valueOf (NatUtil.getVpnId(dataBroker, routerName));
        BigInteger bgpVpnIdAsBigInt = BigInteger.valueOf(changedVpnId);
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.tunnel_id, new  BigInteger[] {bgpVpnIdAsBigInt }));

        List<InstructionInfo> instructions = new ArrayList<>();
        instructions.add(new InstructionInfo(InstructionType.write_metadata, new BigInteger[]
                { MetaDataUtil.getVpnIdMetadata(changedVpnId), MetaDataUtil.METADATA_MASK_VRFID }));
        instructions.add(new InstructionInfo(InstructionType.goto_table, new long[]
                { NwConstants.OUTBOUND_NAPT_TABLE }));
        String flowRef = getFlowRefTs(dpId, NwConstants.INTERNAL_TUNNEL_TABLE, routerId.longValue());
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.INTERNAL_TUNNEL_TABLE, flowRef,
                NatConstants.DEFAULT_TS_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_TS_TABLE, matches, instructions);
        return flowEntity;
    }

    public void createOutboundTblEntryWithBgpVpn(BigInteger dpnId, long routerId, long changedVpnId) {
        LOG.debug("NAT Service : createOutboundTblEntry called for dpId {} and routerId {}, BGP VPN ID {}", dpnId, routerId, changedVpnId);
        FlowEntity flowEntity = buildOutboundFlowEntityWithBgpVpn(dpnId, routerId, changedVpnId);
        LOG.debug("NAT Service : Installing flow {}", flowEntity);
        mdsalManager.installFlow(flowEntity);
    }

    protected FlowEntity buildOutboundFlowEntityWithBgpVpn(BigInteger dpId, long routerId, long changedVpnId) {
        LOG.debug("NAT Service : buildOutboundFlowEntityWithBgpVpn called for dpId {} and routerId {}, BGP VPN ID {}", dpId, routerId, changedVpnId);
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[]{0x0800L}));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[]{
                MetaDataUtil.getVpnIdMetadata(changedVpnId), MetaDataUtil.METADATA_MASK_VRFID}));

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.punt_to_controller, new String[] {}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        instructions.add(new InstructionInfo(InstructionType.write_metadata,
                new BigInteger[] { MetaDataUtil.getVpnIdMetadata(changedVpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        String flowRef = getFlowRefOutbound(dpId, NwConstants.OUTBOUND_NAPT_TABLE, routerId);
        BigInteger cookie = getCookieOutboundFlow(routerId);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.OUTBOUND_NAPT_TABLE, flowRef, 5, flowRef, 0, 0,
                cookie, matches, instructions);
        LOG.debug("NAT Service : returning flowEntity {}", flowEntity);
        return flowEntity;
    }

    protected FlowEntity buildNaptFibExternalOutputFlowEntity(BigInteger dpId, long extVpnId, Uuid subnetId, String externalIp) {
        LOG.debug("NAT Service : buildPostSnatFlowEntity called for dpId {}, routerId {}, srcIp {}", dpId, extVpnId,
                externalIp);

        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type, new long[] { NwConstants.ETHTYPE_IPV4 }));
        matches.add(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] { MetaDataUtil.getVpnIdMetadata(extVpnId), MetaDataUtil.METADATA_MASK_VRFID }));
        matches.add(new MatchInfo(MatchFieldType.ipv4_source, new String[] { externalIp , "32" }));

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        long groupId = NatUtil.createGroupId(NatUtil.getGroupIdKey(subnetId.getValue()), idManager);
        actionsInfos.add(new ActionInfo(ActionType.group, new String[] { String.valueOf(groupId) }));

        String flowRef = getFlowRefNaptFib(dpId, NwConstants.NAPT_PFIB_TABLE, extVpnId, externalIp);
        BigInteger cookie = getCookieOutboundFlow(extVpnId);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.NAPT_PFIB_TABLE, flowRef, 6, flowRef, 0,
                0, cookie, matches, instructions);
        LOG.debug("NAT Service : returning flowEntity {}", flowEntity);
        return flowEntity;
    }

    public void installNaptPfibEntryWithBgpVpn(BigInteger dpnId, long segmentId, long changedVpnId) {
        LOG.debug("NAT Service : installNaptPfibEntryWithBgpVpn called for dpnId {} and segmentId {} ,BGP VPN ID {}", dpnId, segmentId, changedVpnId);
        FlowEntity naptPfibFlowEntity = buildNaptPfibFlowEntityWithUpdatedVpnId(dpnId, segmentId, changedVpnId);
        mdsalManager.installFlow(naptPfibFlowEntity);
    }

    public FlowEntity buildNaptPfibFlowEntityWithUpdatedVpnId(BigInteger dpId, long segmentId, long changedVpnId) {

        LOG.debug("NAT Service : buildNaptPfibFlowEntityWithUpdatedVpnId is called for dpId {}, segmentId {}, BGP VPN ID {}", dpId, segmentId, changedVpnId);
        List<MatchInfo> matches = new ArrayList<>();
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { 0x0800L }));
        matches.add(new MatchInfo(MatchFieldType.metadata, new BigInteger[] {
                MetaDataUtil.getVpnIdMetadata(changedVpnId), MetaDataUtil.METADATA_MASK_VRFID }));

        ArrayList<ActionInfo> listActionInfo = new ArrayList<>();
        ArrayList<InstructionInfo> instructionInfo = new ArrayList<>();
        listActionInfo.add(new ActionInfo(ActionType.nx_resubmit, new String[] { Integer.toString(NwConstants.L3_FIB_TABLE) }));
        instructionInfo.add(new InstructionInfo(InstructionType.apply_actions, listActionInfo));

        String flowRef = getFlowRefTs(dpId, NwConstants.NAPT_PFIB_TABLE, segmentId);
        FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, NwConstants.NAPT_PFIB_TABLE, flowRef,
                NatConstants.DEFAULT_PSNAT_FLOW_PRIORITY, flowRef, 0, 0,
                NwConstants.COOKIE_SNAT_TABLE, matches, instructionInfo);

        LOG.debug("NAT Service : Returning NaptPFib Flow Entity {}", flowEntity);
        return flowEntity;
    }

    @Override
    protected ExternalRoutersListener getDataTreeChangeListener()
    {
        return ExternalRoutersListener.this;
    }

}